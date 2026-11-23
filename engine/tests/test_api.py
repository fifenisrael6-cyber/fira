from fastapi.testclient import TestClient
import app.main as main

client = TestClient(main.app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_capabilities_keep_active_execution_disabled():
    data = client.get("/v1/capabilities").json()
    assert data["autonomy_profile"] == "high"
    assert data["security_profile"] == "defensive-authorized-audits"
    assert data["active_scanning_enabled"] is False
    assert data["agent_execution_enabled"] is False
    assert data["youtube_learning"] is True
    assert data["security_audit_planning"] is True
    assert data["provider_mode"] == "local-first-no-api-key"


def test_chat_uses_local_model_without_provider_key(monkeypatch):
    async def fake_model(messages):
        assert messages[0]["role"] == "system"
        return "Bonjour depuis le modèle local."

    monkeypatch.setattr(main, "ask_local_model", fake_model)
    response = client.post("/v1/chat", json={"message": "Bonjour"})
    assert response.status_code == 200
    assert response.json()["answer"] == "Bonjour depuis le modèle local."


def test_chat_rejects_empty_message():
    assert client.post("/v1/chat", json={"message": ""}).status_code == 422


def test_youtube_rejects_non_youtube_url():
    response = client.post("/v1/learn/youtube", json={"url": "https://example.com/video"})
    assert response.status_code == 400


def test_youtube_rejects_invalid_video_id():
    response = client.post("/v1/learn/youtube", json={"url": "https://youtube.com/watch?v=bad"})
    assert response.status_code == 400


def test_audit_plan_requires_authorization_confirmation():
    response = client.post("/v1/security/audit-plan", json={
        "scope": "Site de test de mon association",
        "authorization_confirmed": False,
    })
    assert response.status_code == 403


def test_audit_plan_only_generates_a_plan(monkeypatch):
    async def fake_model(messages):
        assert "plan d'audit défensif" in messages[0]["content"]
        assert "mon-site.example" in messages[1]["content"]
        return "Plan d'audit passif."

    monkeypatch.setattr(main, "ask_local_model", fake_model)
    response = client.post("/v1/security/audit-plan", json={
        "authorization_confirmed": True,
        "scope": "Site de démonstration dont je suis administrateur",
        "assets": ["mon-site.example"],
        "objective": "Vérifier la configuration",
    })
    assert response.status_code == 200
    assert response.json() == {
        "plan": "Plan d'audit passif.",
        "execution_performed": "false",
    }

def test_wifi_audit_requires_authorization():
    response = client.post("/v1/security/wifi-audit", json={"security_mode": "open"})
    assert response.status_code == 403


def test_wifi_audit_reports_open_network_without_scanning():
    response = client.post("/v1/security/wifi-audit", json={
        "authorization_confirmed": True,
        "security_mode": "open",
        "wps_enabled": True,
        "firmware_updated": False,
        "admin_password_changed": False,
        "remote_admin_enabled": True,
    })
    assert response.status_code == 200
    data = response.json()
    assert data["overall_level"] == "critical"
    assert any(item["title"] == "Réseau sans chiffrement" for item in data["findings"])
    assert "Aucun réseau n’a été scanné" in data["disclaimer"]


def test_wifi_audit_rejects_unknown_security_mode():
    response = client.post("/v1/security/wifi-audit", json={
        "authorization_confirmed": True,
        "security_mode": "crack-me",
    })
    assert response.status_code == 422




def test_capabilities_report_from_scratch_mode():
    data = client.get("/v1/capabilities").json()
    assert data["provider_mode"] == "from-scratch-no-external-ai"
    assert data["model_connected"] is False
    assert data["active_scanning_enabled"] is False


def test_learning_status_is_available():
    response = client.get("/v1/learn/status")
    assert response.status_code == 200
    assert response.json()["pretrained_weights"] is False


def test_training_requires_permission():
    response = client.post("/v1/learn/train", json={
        "text": "Voici un texte suffisamment long pour commencer un apprentissage simple."
    })
    assert response.status_code == 403


def test_train_generate_and_reload(tmp_path, monkeypatch):
    from app.learning_engine import NGramLanguageModel
    model = NGramLanguageModel(tmp_path / "fira.json")
    monkeypatch.setattr(main, "language_model", model)
    trained = client.post("/v1/learn/train", json={
        "authorization_confirmed": True,
        "source_label": "corpus de test",
        "text": "FIRA apprend le langage. FIRA apprend le code. Le langage aide FIRA.",
    })
    assert trained.status_code == 200
    assert trained.json()["model"]["total_tokens"] > 0
    generated = client.post("/v1/learn/generate", json={
        "seed_text": "FIRA apprend", "max_tokens": 10, "seed": 4
    })
    assert generated.status_code == 200
    assert generated.json()["text"]
    assert NGramLanguageModel(tmp_path / "fira.json").status()["trained"] is True


def test_generate_rejects_untrained_model(tmp_path, monkeypatch):
    from app.learning_engine import NGramLanguageModel
    monkeypatch.setattr(main, "language_model", NGramLanguageModel(tmp_path / "empty.json"))
    response = client.post("/v1/learn/generate", json={"max_tokens": 10})
    assert response.status_code == 409
