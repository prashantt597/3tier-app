import pytest
from fastapi.testclient import TestClient
from app.main import app
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@pytest.fixture
def client():
    return TestClient(app)

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "version": "1.0.0", "environment": "production"}