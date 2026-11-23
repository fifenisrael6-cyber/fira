from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_capabilities_keep_shell_execution_disabled():
    data = client.get("/v1/capabilities").json()
    assert data["autonomy_profile"] == "high"
    assert data["security_profile"] == "sensitive"
    assert data["agent_execution_enabled"] is False

def test_chat_requires_server_side_key(monkeypatch):
    monkeypatch.delenv("FIRA_API_KEY", raising=False)
    response = client.post("/v1/chat", json={"message": "Bonjour"})
    assert response.status_code == 503

def test_chat_rejects_empty_message():
    assert client.post("/v1/chat", json={"message": ""}).status_code == 422
