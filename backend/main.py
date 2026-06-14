from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints import (
    stories,
    revisit,
    parent_child,
    kindness,
    ai_features,
    batch_jobs,
)

app = FastAPI(
    title="小学コレ！道徳 API",
    description="小学3-4年生向け道徳学習アプリのバックエンド API",
    version="1.2.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(stories.router, prefix="/api/v1")
app.include_router(revisit.router, prefix="/api/v1")
app.include_router(parent_child.router, prefix="/api/v1")
app.include_router(kindness.router, prefix="/api/v1")
app.include_router(ai_features.router, prefix="/api/v1")
app.include_router(batch_jobs.router, prefix="/api/v1")

@app.get("/health")
async def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
