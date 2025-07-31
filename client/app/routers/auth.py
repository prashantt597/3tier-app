from fastapi import APIRouter, Depends, Form, Request, HTTPException, status
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from ..auth import create_access_token, get_password_hash, verify_password
from ..crud import get_user_by_username, create_user
from ..database import get_db
from ..config import settings
from ..schemas import UserCreate
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["auth"])
templates = Jinja2Templates(directory="app/templates")

@router.get("/", response_class=HTMLResponse)
async def get_login(request: Request):
    logger.info("Serving login page")
    return templates.TemplateResponse("login.html", {"request": request})

@router.get("/register", response_class=HTMLResponse)
async def get_register(request: Request):
    logger.info("Serving register page")
    return templates.TemplateResponse("register.html", {"request": request})

@router.post("/register", response_class=HTMLResponse)
async def post_register(request: Request, username: str = Form(...), password: str = Form(...), db: Session = Depends(get_db)):
    logger.info(f"Register attempt for username: {username}")
    try:
        user_data = UserCreate(username=username, password=password)
    except ValueError as e:
        logger.warning(f"Registration failed: {str(e)}")
        return templates.TemplateResponse("register.html", {"request": request, "error": str(e)})
    if get_user_by_username(db, username):
        logger.warning(f"Registration failed: Username {username} already exists")
        return templates.TemplateResponse("register.html", {"request": request, "error": "Username already exists"})
    create_user(db, username, password)
    logger.info(f"User {username} registered successfully")
    return templates.TemplateResponse("login.html", {"request": request, "message": "Registration successful, please login"})

@router.post("/login", response_class=HTMLResponse)
async def login(request: Request, form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    logger.info(f"Login attempt for username: {form_data.username}")
    user = get_user_by_username(db, form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        logger.warning(f"Login failed for username: {form_data.username}")
        return templates.TemplateResponse("login.html", {"request": request, "error": "Invalid username or password"})
    access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
    access_token = create_access_token(data={"sub": user.username}, expires_delta=access_token_expires)
    logger.info(f"Login successful for username: {form_data.username}")
    return templates.TemplateResponse("home.html", {"request": request, "username": user.username, "token": access_token})
