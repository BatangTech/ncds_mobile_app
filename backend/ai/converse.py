import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore
from langchain_chroma import Chroma
from decouple import config
from langchain_huggingface import HuggingFaceEmbeddings
import time
import traceback 


api_key = config("GOOGLE_GEMINI_API_KEY")

if not firebase_admin._apps:
    try:
        cred = credentials.Certificate("firebase-adminsdk.json")  
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"❌ Firebase initialization failed: {e}")
        exit(1)

db = firestore.client()


embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2", model_kwargs={"device": "cpu"})
vector_db = Chroma(persist_directory="./chroma_db_ncd", embedding_function=embeddings)


GEMINI_API_KEY = api_key
genai.configure(api_key=GEMINI_API_KEY)
genai_model = genai.GenerativeModel(model_name="gemini-1.5-flash")


def generate_rag_prompt(query, context, conversation_history):
    """🔹 Generate a concise prompt for Gemini with context from ChromaDB and health group analysis."""
    return f"""
    You are an AI health assistant specializing in Non-Communicable Diseases (NCDs). 
    Please **respond in Thai** and maintain a friendly tone. 
    Your response should be concise (max 3 sentences) and clear. If the user asks something unrelated to health, politely decline and redirect the conversation. 

    ### Instructions:
    - Always answer in Thai.
    - Keep responses short and relevant to NCDs.
    - If the user asks unrelated questions, say: "Sorry, I can't answer that."
    - After every 5 questions, classify the user's risk level into "green" (low risk) or "red" (high risk), based on the conversation.

    ### Context:
    {context}

    ### Conversation:
    {conversation_history}

    ### User's Question:
    {query}

    ### AI's Response (in Thai):
    """


def generate_followup_question(conversation_history):
    """🔹 Generate follow-up questions and analyze user's health risk"""
    if not conversation_history:
        return None
    
    prompt = f"""
    You are a Thai-speaking AI specializing in Non-Communicable Diseases (NCDs).
    Please generate relevant follow-up questions based on the user's previous responses. 
    Your goal is to better understand the user's health status by asking clear and simple questions.

    ### Instructions:
    - Always generate questions in **Thai**.
    - The question should be clear, concise (max 15 words), and directly related to NCDs.
    - If the user’s response is ambiguous, ask for clarification in a friendly tone.
    - If no follow-up question is needed, respond with No further questions.

    ### Conversation History:
    {conversation_history}

    ### Next Question (in Thai):
    """
    try:
        response = genai_model.generate_content(prompt)
        followup_text = response.text.strip() if response and response.text.strip() else None
        return None if "ไม่มีคำถามเพิ่มเติม" in followup_text else followup_text
    except Exception as e:
        print(f"❌ Error generating follow-up question: {e}")
        return None


def converse(user_id, query):  
    """🔹 AI responds to user input and determines if follow-up is needed"""
    if not query.strip():
        return {"response": "ฉันไม่ได้ยินคุณเลยค่ะ ช่วยพูดอีกครั้งได้ไหมคะ?"}

    try:
        
        context = get_relevant_context_from_db(query)
        
      
        conversation_history = get_conversation_history(user_id)
        
        
        prompt = generate_rag_prompt(query, context, conversation_history)
        
       
        response = genai_model.generate_content(prompt)
        response_text = response.text.strip() if response and response.text.strip() else None
        ai_response = response_text or "ขอโทษค่ะ ฉันไม่สามารถประมวลผลคำขอของคุณได้ในขณะนี้"

        
        followup_question = generate_followup_question(conversation_history)
        
        if followup_question:
            ai_response += f"\nคำถามถัดไป: {followup_question}"


        risk_level = analyze_risk(user_id) if len(conversation_history.split("\n")) >= 5 else None

    except Exception as e:
        print(f"❌ AI generation error: {e}")
        ai_response = "ขอโทษค่ะ ฉันไม่สามารถประมวลผลคำขอของคุณได้ในขณะนี้"
        risk_level = None

    save_conversation_to_firestore(user_id, {"query": query, "response": ai_response}, risk_level=risk_level)

    return {
        "response": ai_response, 
        "risk_level": risk_level
    }


def save_conversation_to_firestore(user_id, conversation_data, risk_level=None):
    """🔹 Save conversation data (query, response) to Firestore with message ID"""
    try:
        doc_ref = db.collection("conversations").document(user_id)
        doc = doc_ref.get()

        # สร้าง message ID โดยใช้ timestamp
        message_id = f"{user_id}_{int(time.time() * 1000)}"
        
        # เพิ่ม message ID ลงใน conversation_data
        conversation_data["id"] = message_id

        if not doc.exists:
            doc_ref.set({
                "conversation": [],
                "questions": [],
                "last_question_index": 0,
                "risk_level": "ไม่ระบุ"
            })

        doc_ref.update({
            "conversation": firestore.ArrayUnion([conversation_data]),
            "timestamp": firestore.SERVER_TIMESTAMP,
            "risk_level": risk_level if risk_level else "ไม่ระบุ"
        })
        
        return message_id

    except Exception as e:
        print(f"❌ Error saving conversation: {e}")
        return None


def analyze_risk(user_id):
    """🔹 Analyze the user's risk level after 5 questions"""
    doc_ref = db.collection("conversations").document(user_id)
    doc = doc_ref.get()

    if not doc.exists or "conversation" not in doc.to_dict():
        return "Sorry, I cannot analyze your risk at the moment."

    conversation = doc.to_dict().get("conversation", [])
    
   
    if len(conversation) < 5:
        analysis_prompt = f"""
        Analyze the user's health from the conversation history and classify them as:
        - "green" (low risk)
        - "red" (high risk)
        
        -------------------------
        🔹 Conversation History:
        {conversation[-5:]}  # Only use the last 5 to reduce token usage

        📝 The user's risk level (green, or red only):
        
        Please respond in **Thai** with the appropriate risk level and explain **why** the user belongs to that group. Provide specific health-related reasons based on their conversation history, such as symptoms, conditions, or lifestyle habits.
        """
        try:
            response = genai_model.generate_content(analysis_prompt)
            risk_level = response.text.strip() if response and response.text.strip() else "Unable to determine."
            doc_ref.update({"risk_level": risk_level})
            return risk_level
        except Exception as e:
            print(f"❌ Error analyzing risk: {e}")
            return "Unable to analyze."
    else:
        return "Risk analysis cannot be done yet because 5 questions haven't been asked."


def get_relevant_context_from_db(query):
    """🔹 Retrieve relevant context from Chroma DB."""
    try:
        search_results = vector_db.similarity_search(query, k=5)
        context = "\n".join([doc.page_content for doc in search_results])
        return context
    except Exception as e:
        print(f"❌ Error retrieving context: {e}")
        return ""


def get_conversation_history(user_id, limit=5):
    """🔹 ดึงประวัติการสนทนาเฉพาะ 5 รายการล่าสุด"""
    try:
        doc_ref = db.collection("conversations").document(user_id)
        doc = doc_ref.get()
        if doc.exists:
            history = doc.to_dict().get("conversation", [])
            last_n_conversations = history[-limit:]  

           
            formatted_history = []
            for entry in last_n_conversations:
                query = entry.get("query", "ไม่ทราบคำถาม")
                response = entry.get("response", "ไม่มีคำตอบ")
                formatted_history.append(f"{query} {response}")

            return "\n".join(formatted_history)

        return ""
    except Exception as e:
        print(f"❌ Error retrieving conversation history: {e}")
        return ""


def start_chat(user_id: str, user_name: str = "คุณ"):
    """🔹 ให้ AI ทักทายด้วยชื่อที่รับมาจาก Firestore"""
    initial_message = f"สวัสดี! {user_name} วันนี้คุณรู้สึกอย่างไรบ้าง? กรุณาอธิบายอาการหรือความกังวลของคุณ"

    try:
        chat_ref = db.collection("conversations").document(user_id)
        doc = chat_ref.get()

        if not doc.exists:
            chat_ref.set({
                "conversation": [{"sender": "bot", "message": initial_message}],
                "risk_level": "ไม่ระบุ",
                "timestamp": firestore.SERVER_TIMESTAMP
            })
        else:
            chat_ref.update({
                "conversation": firestore.ArrayUnion([{"sender": "bot", "message": initial_message}]),
                "timestamp": firestore.SERVER_TIMESTAMP
            })

        return {"response": initial_message}

    except Exception as e:
        print(f"❌ Error in start_chat: {e}")
        return {"response": "ขอโทษค่ะ มีข้อผิดพลาดในการเริ่มการสนทนา"}


def get_user_name(user_id):
    """🔹 ดึงชื่อผู้ใช้จาก Firestore"""
    try:
        user_doc = db.collection("users").document(user_id).get()
        if user_doc.exists:
            return user_doc.to_dict().get("name", "คุณ")  
    except Exception as e:
        print(f"❌ Error fetching user name: {e}")
    return "คุณ"


def new_chat(user_id: str):
    """🔹 เริ่มแชทใหม่โดยการลบประวัติการสนทนาเดิม"""
    try:
        chat_ref = db.collection("conversations").document(user_id)

        chat_ref.set({
            "conversation": [],
            "risk_level": "ไม่ระบุ",
            "timestamp": firestore.SERVER_TIMESTAMP
        })

        return {"response": "เริ่มแชทใหม่แล้วค่ะ! กรุณาอธิบายอาการหรือความกังวลของคุณ"}
    
    except Exception as e:
        print(f"❌ Error in new_chat: {e}")
        return {"response": "ขอโทษค่ะ มีข้อผิดพลาดในการเริ่มแชทใหม่"}


def get_specific_message(user_id, message_id):
    """🔹 ดึงข้อความสนทนาตาม message_id ที่ระบุ"""
    try:
        
        doc_ref = db.collection("conversations").document(user_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return {"error": "ไม่พบข้อมูลผู้ใช้"}
        
        conversation = doc.to_dict().get("conversation", [])
        
       
        try:
            message_index = int(message_id)
            if 0 <= message_index < len(conversation):
                return {"message": conversation[message_index].get("response", "")}
            else:
                return {"error": "ไม่พบข้อความที่ระบุ"}
        except ValueError:
            for message in conversation:
                if message.get("id") == message_id:
                    return {"message": message.get("response", "")}
            return {"error": "ไม่พบข้อความที่ระบุ"}
            
    except Exception as e:
        print(f"❌ Error fetching specific message: {e}")
        traceback.print_exc()
        return {"error": f"ข้อผิดพลาดในการค้นหาข้อความ: {str(e)}"}

def send_fcm_notification(token, title, body, data=None):
    """ส่งการแจ้งเตือนผ่าน FCM API v1 โดย Firebase Admin SDK"""
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            data=data or {},
            token=token
        )
        
        response = messaging.send(message)
        print(f"Successfully sent message: {response}")
        return True
    except Exception as e:
        print(f"Error sending message: {e}")
        return False