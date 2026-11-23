# FIRA AI

FIRA is a Flutter mobile client and a Python AI gateway for software-development assistance.

## Current features
- Flutter app in French: Assistant, Projects, History, Settings.
- The Assistant calls the Python API at `POST /v1/chat`.
- The server URL is saved locally on the device.
- The Python gateway supports OpenAI-compatible chat-completions providers.
- Provider credentials are read only from server environment variables.
- Dockerfile and CI checks for Flutter, Python, and Android APK builds.

## Configure the AI provider
Set these variables on the server hosting the Python engine:

- `FIRA_API_KEY`: secret key from your chosen AI provider.
- `FIRA_BASE_URL`: provider API base URL (default: `https://api.openai.com/v1`).
- `FIRA_MODEL`: model supported by that provider (default: `gpt-4o-mini`).

Never put a real API key in Flutter code, the APK, or this repository. The default provider/model are examples; access and billing depend on the provider account.

## Run the engine
```bash
cd engine
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

For a public deployment, use HTTPS and configure secrets in the hosting platform. Enter the resulting HTTPS base URL in FIRA > Réglages.

## Run engine tests
```bash
cd engine
pip install -r requirements.txt
pip install pytest
PYTHONPATH=. pytest -q
```

## Current agent limits
Autonomy is high for planning and software guidance. The current version does not execute shell commands, modify repositories, or deploy applications. Sensitive actions require explicit approval. A future code-execution worker must be separately isolated and resource-limited before it can be enabled.

## Deploy the engine on Render

The repository includes a `render.yaml` blueprint. In Render, create a new Blueprint from this repository and add your provider key as the secret value for `FIRA_API_KEY`. Do not add the key to GitHub files or to the mobile app. Once the service is live, copy its HTTPS URL into FIRA > Réglages. The free hosting tier, if selected, may sleep when idle and respond slowly on its first request.
