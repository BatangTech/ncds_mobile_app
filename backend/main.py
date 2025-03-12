from fastapi import FastAPI, HTTPException,Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from ai.converse import converse  
from decouple import config
import logging
import traceback
from ai.converse import start_chat
from ai.converse import new_chat 
import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate("firebase-adminsdk.json")  
    firebase_admin.initialize_app(cred)

db = firestore.client()  


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BOT_NAME = config("NCD_NAME", default="Health Assistant")

class ChatRequest(BaseModel):
    user_id: str  
    message: str


@app.post("/chat")
def chat(request: ChatRequest):
    """Receives a user ID and message from Flutter and returns an AI response."""
    user_id = request.user_id  
    user_message = request.message.strip()

    if not user_message:
        return JSONResponse(
            content={"error": "Message cannot be empty"},
            status_code=400
        )

    try:
        ai_response = converse(user_id, user_message)

        
        if not ai_response:
            return JSONResponse(
                content={"error": "AI response is empty"},
                status_code=500
            )

        response_data = {"response": ai_response.get("response", "ขอโทษค่ะ ฉันไม่สามารถประมวลผลคำขอของคุณได้")}

        if "risk_level" in ai_response and ai_response["risk_level"]:
            response_data["risk_level"] = ai_response["risk_level"]

        return JSONResponse(
            content=response_data,
            headers={"Content-Type": "application/json; charset=utf-8"}
        )

    except Exception as e:
        error_details = traceback.format_exc()
        logger.error(f"❌ Internal Server Error: {e}\n{error_details}")

        return JSONResponse(
            content={"error": "Internal server error"},
            status_code=500
        )

def get_user_name(user_id: str):
    """🔹 ดึงชื่อผู้ใช้จาก Firestore"""
    try:
        user_doc = firestore.client().collection("users").document(user_id).get()
        if user_doc.exists:
            return user_doc.to_dict().get("name", "คุณ")  # ถ้าไม่มีชื่อให้ใช้ "คุณ"
    except Exception as e:
        logger.error(f"❌ Error fetching user name: {e}")
    return "คุณ"


@app.get("/start_chat")
async def start_chat_route(request: Request):
    """🔹 เริ่มการสนทนา พร้อมแสดงชื่อผู้ใช้"""
    user_id = request.query_params.get("user_id")
    if not user_id:
        return JSONResponse(content={"error": "user_id is required"}, status_code=400)

    
    user_name = get_user_name(user_id)

    response_data = start_chat(user_id, user_name)

    return JSONResponse(content=response_data, media_type="application/json; charset=utf-8")


@app.get("/new_chat")
def reset_chat(user_id: str):
    return new_chat(user_id)


@app.get("/")
def read_root():
    return {"message": "Hello, World!"}

@app.get("/health")
def health_check():
    """✅ Health Check Endpoint"""
    return {"status": "ok", "message": "Service is running"}

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8080)
