from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from ..auth import get_current_user
from ..models import User
from ..database import get_db
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/users", tags=["users"])
templates = Jinja2Templates(directory="app/templates")

@router.get("/home", response_class=HTMLResponse)
async def home(request: Request, current_user: User = Depends(get_current_user)):
    logger.info(f"Serving home page for user: {current_user.username}")
    return templates.TemplateResponse("home.html", {"request": request, "username": current_user.username})
