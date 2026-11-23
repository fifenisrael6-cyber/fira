"""FIRA engine foundation; no AI model provider is connected yet."""
from fastapi import FastAPI

app = FastAPI(title="FIRA Engine", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "fira-engine", "version": "0.1.0"}


@app.get("/v1/capabilities")
def capabilities() -> dict[str, object]:
    return {
        "model_connected": False,
        "agent_execution_enabled": False,
        "autonomy_profile": "high",
        "security_profile": "sensitive",
        "planned_features": [
            "task_planning", "code_generation", "patch_review",
            "test_execution_in_isolated_workspace"
        ],
    }
