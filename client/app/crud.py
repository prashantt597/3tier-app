from sqlalchemy.orm import Session
from .models import User
from .utils.security import get_password_hash
import logging

logger = logging.getLogger(__name__)

def get_user_by_username(db: Session, username: str) -> User | None:
    logger.debug(f"Fetching user: {username}")
    return db.query(User).filter(User.username == username).first()

def create_user(db: Session, username: str, password: str) -> User:
    logger.info(f"Creating user: {username}")
    hashed_password = get_password_hash(password)
    db_user = User(username=username, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user
