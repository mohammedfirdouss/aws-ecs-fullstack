from fastapi import FastAPI

app = FastAPI(title="ECS Fullstack Backend", version="0.1.0")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/api/health")
def api_health():
    return {"status": "ok"}
