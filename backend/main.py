from fastapi import FastAPI

app = FastAPI(title="AI Social App Backend")


@app.get("/")
def root():
    return {"status": "ok", "message": "AI Social App Backend"}
