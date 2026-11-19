from fastapi import APIRouter, HTTPException, Response, status
from pydantic import BaseModel, EmailStr

from app.core.dependencies.database import DbSession
from app.core.security import create_access_token, verify_password
from app.core.settings import settings
from app.repositories.user import UserRepository

router = APIRouter(prefix="/auth", tags=["Auth"])


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


@router.post("")
async def login(data: LoginRequest, db: DbSession) -> Response:
    user = await UserRepository(db).get_by_email(data.email)

    if user is None or not await verify_password(data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is inactive",
        )

    token = create_access_token(user.id)

    response = Response(status_code=status.HTTP_204_NO_CONTENT)

    response.set_cookie(
        key=settings.auth_cookie_name,
        value=token,
        httponly=True,
        secure=settings.auth_cookie_secure,
        samesite=settings.auth_cookie_samesite,
        max_age=settings.jwt_access_token_expire_minutes * 60,
        path="/",
    )

    return response


@router.delete("")
async def logout() -> Response:
    response = Response(status_code=status.HTTP_204_NO_CONTENT)

    response.delete_cookie(
        key=settings.auth_cookie_name,
        path="/",
        secure=settings.auth_cookie_secure,
        httponly=True,
        samesite=settings.auth_cookie_samesite,
    )

    return response
