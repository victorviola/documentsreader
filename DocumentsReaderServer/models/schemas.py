from pydantic import BaseModel

class EmailRequest(BaseModel):
    email: str

class EmailConfirmationRequest(BaseModel):
    email: str
    code: str

class DocumentRequest(BaseModel):
    email: str
    token: str

class EnrolRequest(BaseModel):
    email: str
