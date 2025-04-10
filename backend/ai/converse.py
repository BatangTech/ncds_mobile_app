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
    """🔹 Generate a comprehensive and responsible prompt for Gemini with enhanced safety and credibility"""
    return f"""
    ### AI Health Assistant Role
    You are a professional AI health assistant specializing in Non-Communicable Diseases (NCDs).
    - You are NOT a licensed medical professional
    - Your goal is to provide general health information and guidance
    - ALWAYS recommend consulting a healthcare professional for personalized medical advice

    ### Communication Guidelines
    - Respond in Thai with a compassionate and professional tone
    - Be clear, concise, and use simple medical language
    - Maximum response length: 3-4 sentences
    - Focus on providing helpful, evidence-based information

    ### Ethical and Safety Principles
    1. Never diagnose medical conditions
    2. Do not prescribe treatments or medications
    3. Acknowledge the limitations of AI health advice
    4. Emphasize the importance of professional medical consultation
    5. Provide general health recommendations based on available context

    ### Risk Communication Framework
    - Use neutral, non-alarming language
    - Provide constructive health suggestions
    - Avoid causing unnecessary anxiety
    - Encourage preventive health behaviors

    ### Context from Knowledge Base:
    {context}

    ### Conversation History:
    {conversation_history}

    ### User's Question:
    {query}

    ### Response Requirements:
    - Answer in Thai
    - Include a clear disclaimer about consulting healthcare professionals
    - Provide general, supportive health guidance
    - If query is unrelated to health, politely redirect

    ### AI's Recommended Response (in Thai):
    """


def generate_followup_question(conversation_history):
    """🔹 Generate targeted follow-up questions and analyze user's health risk"""
    if not conversation_history:
        return None
    
    prompt = f"""
    You are a Thai-speaking AI specializing in Non-Communicable Diseases (NCDs).
    Please generate relevant follow-up questions based on the user's previous responses.
    Your goal is to better understand the user's health status by asking clear and simple questions.

    ### Instructions:
    - Always generate questions in **Thai**.
    - The question should be clear, concise (max 15 words), and directly related to NCDs.
    - Ask questions that help assess the user's risk level.
    - Try to ask questions related to:
      * Eating habits
      * Exercise patterns
      * Family history
      * Stress and sleep
      * Abnormal symptoms related to NCDs
    - If the user's response is ambiguous, ask for clarification in a friendly tone.
    - If no follow-up question is needed, respond with "ไม่มีคำถามเพิ่มเติม"

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


def prepare_conversation_response(user_id, query):
    """Prepare the core response logic for the conversation"""
    if not query.strip():
        return {"response": "ฉันไม่ได้ยินคุณเลยค่ะ ช่วยพูดอีกครั้งได้ไหมคะ?"}

    # Retrieve context and conversation history
    context = get_relevant_context_from_db(query)
    conversation_history = get_conversation_history(user_id)
    
    # Generate prompt for AI
    prompt = generate_rag_prompt(query, context, conversation_history)
    
    # Get AI response
    try:
        response = genai_model.generate_content(prompt)
        ai_response = response.text.strip() if response and response.text.strip() else "ขอโทษค่ะ ฉันไม่สามารถประมวลผลคำขอของคุณได้ในขณะนี้"
    except Exception as e:
        print(f"❌ AI generation error: {e}")
        ai_response = "ขอโทษค่ะ ฉันไม่สามารถประมวลผลคำขอของคุณได้ในขณะนี้"
    
    return ai_response, conversation_history

def handle_followup_and_risk(user_id, conversation_history, ai_response):
    # Generate follow-up question
    followup_question = generate_followup_question(conversation_history)
    
    # Analyze risk every 5 questions
    conversation_count = get_conversation_count(user_id)
    risk_result = None
    
    # เพิ่มเงื่อนไขเพื่อให้แน่ใจว่ามีคำถามติดตาม
    if followup_question:
        ai_response += f"\n\nคำถามถัดไป: {followup_question}"
    
    # ตรวจสอบความเสี่ยงทุก 5 คำถาม
    if conversation_count >= 5 and conversation_count % 5 == 0:
        risk_result = analyze_risk(user_id)
        
        if risk_result and risk_result["status"] == "success":
            risk_level = risk_result["risk_level"]
            ai_response += f"\n\n[{risk_level}]"
            ai_response += "\n\nการวิเคราะห์เสร็จสิ้น หากมีข้อสงสัยเพิ่มเติมกรุณาเริ่มการสนทนาใหม่"
    
    return ai_response, risk_result

def converse(user_id, query):
    """Main conversation function with reduced complexity"""
    # Prepare core conversation response
    ai_response, conversation_history = prepare_conversation_response(user_id, query)
    
    # Handle follow-up and risk analysis
    ai_response, risk_result = handle_followup_and_risk(user_id, conversation_history, ai_response)
    
    # Determine risk level for saving
    risk_level = risk_result["risk_level"] if risk_result and "risk_level" in risk_result else None
    
    # Save conversation to Firestore
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

        message_id = f"{user_id}_{int(time.time() * 1000)}"
        
        conversation_data["id"] = message_id

        if not doc.exists:
            doc_ref.set({
                "conversation": [],
                "questions": [],
                "last_question_index": 0,
                "risk_level": "ไม่ระบุ"
            })

        update_data = {
            "conversation": firestore.ArrayUnion([conversation_data]),
            "timestamp": firestore.SERVER_TIMESTAMP
        }
        
        if risk_level:
            update_data["risk_level"] = risk_level
            
        doc_ref.update(update_data)
        
        return message_id

    except Exception as e:
        print(f"❌ Error saving conversation: {e}")
        return None


def analyze_risk(user_id):
    """🔹 Analyze the user's risk level after 5 questions"""
    doc_ref = db.collection("conversations").document(user_id)
    doc = doc_ref.get()

    if not doc.exists or "conversation" not in doc.to_dict():
        return {"status": "error", "message": "ไม่พบข้อมูลการสนทนา"}

    conversation = doc.to_dict().get("conversation", [])
    
    if len(conversation) >= 5:
        analysis_prompt = f"""
        Analyze the user's health from the conversation history and classify them as:
        - "green" (low risk)
        - "red" (high risk)
        
        ### Risk Classification Criteria:
        - Green (Low Risk): No symptoms indicating NCDs, good health behaviors, regular exercise, healthy diet.
        - Red (High Risk): Symptoms possibly related to NCDs, family history of NCDs, lack of exercise, unbalanced diet, smoking, regular alcohol consumption.
        
        -------------------------
        ### Conversation History:
        {conversation[-5:]}
        
        ### Instructions:
        1. First line of your response must be ONLY ONE of these exact words: "green" or "red" based on your analysis.
        2. On the next line, explain WHY you classified them this way in Thai language.
        3. Provide specific health-related reasons based on their conversation history.
        """
        try:
            response = genai_model.generate_content(analysis_prompt)
            full_response = response.text.strip() if response and response.text.strip() else "Unable to determine."
            
            # แยกส่วน risk level และ เหตุผล
            lines = full_response.split('\n', 1)
            original_risk_level = lines[0].strip().lower() 
            reasoning = lines[1].strip() if len(lines) > 1 else ""
            
            risk_name = "แดง (red)" if original_risk_level == "red" else "เขียว (green)"
            
            full_risk_assessment = f"ระดับความเสี่ยง: **{risk_name}** เหตุผล: {reasoning}"
            
            if original_risk_level not in ["green", "red"]:
                original_risk_level = "ไม่ระบุ"
                full_risk_assessment = "ไม่สามารถระบุระดับความเสี่ยงได้"
            
            doc_ref.update({
                "risk_level": full_risk_assessment
            })
            
            return {
                "status": "success", 
                "original_risk_level": original_risk_level,
                "risk_level": full_risk_assessment
            }
        except Exception as e:
            print(f"❌ Error analyzing risk: {e}")
            return {"status": "error", "message": "ไม่สามารถวิเคราะห์ความเสี่ยงได้"}
    else:
        return {"status": "pending", "message": "ต้องการข้อมูลเพิ่มเติม"}


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
    try:
        chat_ref = db.collection("conversations").document(user_id)
        doc = chat_ref.get()
        
        previous_risk = None
        if doc.exists:
            previous_risk = doc.to_dict().get("risk_level")
        
        initial_message = f"สวัสดี! {user_name} วันนี้คุณรู้สึกอย่างไรบ้าง? กรุณาอธิบายอาการหรือความกังวลของคุณ"
        
        if previous_risk and previous_risk not in ["ไม่ระบุ"]:
            initial_message += f"\n\nจากการสนทนาครั้งก่อน คุณอยู่ในกลุ่มความเสี่ยง: {previous_risk}"
            
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

        return {"response": initial_message, "previous_risk": previous_risk}

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
    """🔹 เริ่มแชทใหม่โดยการย้ายประวัติการสนทนาเดิมไปยัง sessions"""
    try:
        # 1. ดึงข้อมูลการสนทนาปัจจุบัน
        chat_ref = db.collection("conversations").document(user_id)
        current_chat = chat_ref.get()
        
        # 2. ถ้ามีประวัติการสนทนา ให้บันทึกไว้ใน sessions subcollection
        if current_chat.exists:
            current_data = current_chat.to_dict()
            
            # ตรวจสอบว่ามีประวัติการสนทนาที่ไม่ว่างเปล่า
            if current_data and "conversation" in current_data and current_data["conversation"]:
                # สร้าง session ID จากเวลาปัจจุบัน
                session_id = str(int(time.time() * 1000))  # milliseconds timestamp
                
                # บันทึกประวัติการสนทนาเก่าใน sessions subcollection
                chat_ref.collection("sessions").document(session_id).set({
                    "conversation": current_data.get("conversation", []),
                    "risk_level": current_data.get("risk_level", "ไม่ระบุ"),
                    "timestamp": current_data.get("timestamp", firestore.SERVER_TIMESTAMP),
                    "session_id": session_id
                })
        
        # 3. เริ่มแชทใหม่ด้วยข้อความทักทาย
        chat_ref.set({
            "conversation": [],
            "risk_level": "ไม่ระบุ",
            "timestamp": firestore.SERVER_TIMESTAMP,
            "session_id": str(int(time.time() * 1000))  # กำหนด session_id สำหรับแชทใหม่
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

def get_conversation_count(user_id):
    """🔹 Get the count of conversation entries for a user"""
    try:
        doc_ref = db.collection("conversations").document(user_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return 0
            
        conversation = doc.to_dict().get("conversation", [])
        return len(conversation)
        
    except Exception as e:
        print(f"❌ Error getting conversation count: {e}")
        return 0