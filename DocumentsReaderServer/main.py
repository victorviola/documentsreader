from fastapi import FastAPI
from dotenv import load_dotenv

from routes import (healthcheck, auth, documents)

load_dotenv()

app = FastAPI(title="iProov Document Reader API")

app.include_router(healthcheck.router)
app.include_router(auth.router)
app.include_router(documents.router)


