import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.models import User, Base
from app.database import engine, SessionLocal
from app.auth import create_access_token
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

def test_home_page_access(client, db):
    client.post('/auth/register', data={'username': 'testuser', 'password': 'Testpass123'})
    response = client.post('/auth/login', data={'username': 'testuser', 'password': 'Testpass123'})
    token = response.text.split('token')[1].split('value="')[1].split('"')[0]
    response = client.get('/users/home', headers={'Authorization': f'Bearer {token}'})
    assert response.status_code == 200
    assert 'Welcome, testuser!' in response.text

def test_home_page_unauthorized(client):
    response = client.get('/users/home')
    assert response.status_code == 401
    assert 'Could not validate credentials' in response.text
