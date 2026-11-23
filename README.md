# FIRA AI

FIRA is a Flutter Android client with a Python engine designed for local-first AI learning and software assistance.

## Architecture without an AI API key
- No paid AI provider and no provider API key are required.
- Python calls an OpenAI-compatible local model server (default: \`http://127.0.0.1:8081/v1\`).
- Configure \`FIRA_LOCAL_MODEL_URL\` and \`FIRA_LOCAL_MODEL\`. The local model server must be installed and running; FIRA does not download a model automatically.
- No AI secret is embedded in Dart or the APK.
- YouTube endpoint: \`POST /v1/learn/youtube\`; it reads available public captions and asks the local model to summarize the lesson, explain commands and design a defensive exercise.
- Dart client helper: \`lib/services/youtube_learning.dart\`.

## Run the Python engine
\`\`\`bash
cd engine
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
FIRA_LOCAL_MODEL_URL=http://127.0.0.1:8081/v1 uvicorn app.main:app --host 0.0.0.0 --port 8000
\`\`\`
Run a compatible local inference server separately. For a model on another computer on the same trusted Wi-Fi, set its LAN address instead of 127.0.0.1. Android local inference may require a quantized model and substantial RAM/storage.

## YouTube learning workflow
1. Submit a public YouTube URL.
2. Python validates the YouTube host and fetches available captions/transcript.
3. The transcript is treated as untrusted material and bounded in size.
4. The local model returns a summary, explanations, prerequisites, risks and a defensive lab exercise.
5. Review the exercise before running anything.

Videos without accessible captions cannot be transcribed by this endpoint. This does not bypass private videos, paywalls or access controls.

## Network security learning
FIRA can teach network concepts and help assess devices you own or are authorized to test. Begin with passive discovery, configuration review and non-destructive checks on a selected lab target. It must not automatically execute arbitrary commands extracted from a video or attack third-party systems. The current engine does not execute shell commands or run penetration tests; \`agent_execution_enabled\` remains false until an isolated, permissioned lab runner is implemented and tested.

## Android / Dart
Configure the FIRA engine URL in app settings. Use HTTPS for remote access. Local-network HTTP may require Android network-security configuration for development. The Dart YouTube service sends the video URL and learning objective to the FIRA engine.

## Tests
\`\`\`bash
cd engine
pip install -r requirements.txt
pip install pytest
PYTHONPATH=. pytest -q
\`\`\`
A successful Git commit does not mean the APK has compiled; verify GitHub Actions for the actual result.
