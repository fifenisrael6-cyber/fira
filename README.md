# FIRA AI

FIRA is a Flutter client with a Python engine designed for local-first AI learning and software assistance.

## Architecture without an AI API key
- No paid AI provider and no provider API key are required.
- Python calls an OpenAI-compatible local model server (default: `http://127.0.0.1:8081/v1`).
- Configure `FIRA_LOCAL_MODEL_URL` and `FIRA_LOCAL_MODEL`. The local model server must be installed and running; FIRA does not download a model automatically.
- No AI secret is embedded in Dart or the APK.
- YouTube endpoint: `POST /v1/learn/youtube`; it reads available captions and asks the local model to explain the lesson.
- Dart client helper: `lib/services/youtube_learning.dart`.

## Run the Python engine
```bash
cd engine
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
FIRA_LOCAL_MODEL_URL=http://127.0.0.1:8081/v1 uvicorn app.main:app --host 0.0.0.0 --port 8000
```
Run a compatible local inference server separately. Android local inference may require a quantized model and substantial RAM/storage.

## YouTube learning workflow
1. Submit a public YouTube URL in the FIRA chat.
2. Python validates the YouTube host and fetches available captions/transcript.
3. The transcript is treated as untrusted material and bounded in size.
4. The local model returns a summary, explanations, prerequisites, risks and a defensive exercise.

Videos without accessible captions cannot be transcribed by this endpoint. This does not bypass private videos, paywalls or access controls. The current feature analyzes captions; it does not visually watch or listen to the video itself.

## Authorized security audit planning
- `POST /v1/security/audit-plan` accepts a declared scope, optional asset labels, an objective, and an explicit authorization confirmation.
- The endpoint produces a passive, non-destructive audit plan through the configured local model.
- If authorization is not confirmed, the endpoint rejects the request.
- This endpoint does not connect to targets, scan ports, exploit vulnerabilities, execute shell commands, or prove ownership/authorization.
- The chat can explain defensive security concepts and review user-provided code, configuration, and logs. Active penetration testing is not implemented.
- `active_scanning_enabled` and `agent_execution_enabled` remain false.

## Android / Dart
Configure the FIRA engine URL in app settings. Use HTTPS for remote access. The Dart YouTube service sends the video URL and learning objective to the FIRA engine.

## Tests
```bash
cd engine
pip install -r requirements.txt
pip install pytest
PYTHONPATH=. pytest -q
```
A successful Git commit does not mean the APK has compiled; verify GitHub Actions for the actual result.
