# FIRA AI — plan technique et premier moteur

## Vision
FIRA is intended to become an independently developed AI system trained from scratch. The new learning baseline uses no commercial AI API, pretrained weights, hosted model endpoint, or external inference provider.

## Important reality check
The first engine is a small second-order word-level n-gram statistical language model written with the Python standard library. It learns word-transition frequencies from text supplied for training and generates short continuations. It does **not** understand meaning, reason, write reliable code, or perform like ChatGPT. It is a measurable first experiment, not a finished conversational assistant.

A ChatGPT-class system requires large curated datasets, substantial compute, evaluation, safety research, and significant time and resources. FIRA will progress through measured stages and will not claim equivalence prematurely.

## Architecture
- Flutter app: interface, conversation history, training-data entry and reports.
- Python engine: API, data validation, training, persistence and evaluation.
- Model storage: local JSON checkpoint for this first baseline.
- GitHub: source control, review, tests and reproducible builds.
- Future compute: optional cloud worker for larger training jobs. No cloud account is needed for the first CPU experiment.

## First engine endpoints
- GET /v1/learn/status: model type, documents, tokens and learned contexts.
- POST /v1/learn/train: trains on supplied text; requires explicit permission confirmation; maximum 100,000 characters.
- POST /v1/learn/generate: probabilistic text continuation.
- GET /v1/capabilities: declares from-scratch mode and no pretrained weights.

Only train on material you created, have permission to use, or that is appropriately licensed. Never submit passwords, API keys, private records or sensitive personal data.

## Tiny neural model added in this iteration\n\nA small trainable word-level neural bigram model is implemented in `engine/app/neural_learning.py` using NumPy. Its embedding table and output layer start from random values, are updated with cross-entropy gradients, and are saved to a compressed NPZ checkpoint. The API exposes `/v1/learn/neural/status`, `/v1/learn/neural/train`, and `/v1/learn/neural/generate`. The Flutter app has an `Apprentissage FIRA` screen to submit permitted text, select 1–10 epochs, inspect basic metrics, and test a short continuation.\n\nThis tiny model only predicts a next word from a one-word context. It is not a chatbot or reasoning system. The existing chat can use it only as a clearly labelled experimental fallback if the separate local inference service is unavailable and the neural model has been trained.\n\n## Multi-year roadmap
1. Baseline: tokenizer, n-gram model, persistence, API and tests.
2. Data discipline: curated French/Python/Dart corpora, provenance and licence records, deduplication, held-out validation, quality and memorization checks.
3. Neural foundations: tokenizer, embeddings, attention and a tiny decoder-only Transformer trained on small permitted datasets.
4. Training operations: checkpoints, reproducible configurations, training/validation loss, experiment registry and rollback.
5. Assistant capabilities: instruction tuning from permitted examples, retrieval over approved documents, permissioned tools and independent safety evaluations.
6. Scaling: compare quality, compute cost and latency before increasing model size.

## Current limitations
- The Android app still needs a reachable FIRA Python API URL. This change does not deploy or host the API.
- The existing /v1/chat endpoint still expects a compatible local inference service. The n-gram model is exposed separately and is not misrepresented as a conversational assistant.
- The cloud runner workflow is only a build worker. It is not provisioned and is not a GPU training service.
- No active penetration testing is implemented; existing security features remain defensive planning and configuration review.

## Run locally
From engine/: create a virtual environment, install requirements, then run `PYTHONPATH=. pytest -q` and `uvicorn app.main:app --host 127.0.0.1 --port 8000`.
