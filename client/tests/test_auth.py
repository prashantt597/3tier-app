import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.models import User, Base
from app.database import engine, SessionLocal
from app.auth import get_password_hash
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@pytest.fixture
def client():
    Base.metadata.create_all(bind=engine)
    app.dependency_overrides = {}
    yield TestClient(app)
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def db():
    db = SessionLocal()
    yield db
    db.close()

def test_register_success(client, db):
    response = client.post('/auth/register', data={'username': 'testuser', 'password': 'Testpass123!'})
    assert response.status_code == 200
    assert 'Registration successful' in response.text
    user = db.query(User).filter(User.username == 'testuser').first()
    assert user is not None
    assert user.username == 'testuser'

def test_register_duplicate_username(client, db):
    client.post('/auth/register', data={'username': 'testuser', 'password': 'Testpass123!'})
    response = client.post('/auth/register', data={'username': 'testuser', 'password': 'Testpass123!'})
    assert response.status_code == 200
    assert 'Username already exists' in response.text

def test_register_invalid_password(client):
    response = client.post('/auth/register', data={'username': 'testuser', 'password': 'weak'})
    assert response.status_code == 200
    assert 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character' in response.text

def test_register_long_username(client):
    response = client.post('/auth/register', data={'username': 'a' * 51, 'password': 'Testpass123!'})
    assert response.status_code == 200
    assert 'ensure this value has at most 50 characters' in response.text

def test_register_invalid_username(client):
    response = client.post('/auth/register', data={'username': 'test@user', 'password': 'Testpass123!'})
    assert response.status_code == 200
    assert 'Username must be alphanumeric or include underscores' in response.text

def test_login_success(client, db):
    client.post('/auth/register', data={'username': 'testuser', 'password': 'Testpass123!'})
    response = client.post('/auth/login', data={'username': 'testuser', 'password': 'Testpass123!'})
    assert response.status_code == 200
    assert 'Welcome, testuser!' in response.text

def test_login_invalid_credentials(client):
    response = client.post('/auth/login', data={'username': 'wronguser', 'password': 'wrongpass'})
    assert response.status_code == 200
    assert 'Invalid username or password' in response.text