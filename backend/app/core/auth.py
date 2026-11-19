from typing import Annotated
from uuid import UUID

import jwt
from fastapi import Cookie, Depends, HTTPException, status
from jwt.exceptions import InvalidTokenError

from app.core.dependencies.database import DbSession
from app.core.settings import settings
from app.models.user import User

type Token = Annotated[str | None, Cookie(alias=settings.auth_cookie_name)]


async def get_current_user(db: DbSession, token: Token = None) -> User:
    if token is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )

    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key.get_secret_value(),
            algorithms=[settings.jwt_algorithm],
            options={"require": ["sub", "exp", "iat"]},
        )

        user_id = UUID(payload["sub"])

    except (InvalidTokenError, ValueError, TypeError) as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        ) from exc

    user: User | None = await db.get(User, user_id)

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is inactive",
        )

    return user


type CurrentUser = Annotated[User, Depends(get_current_user)]


async def get_current_admin_user(user: CurrentUser) -> User:
    if not user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required",
        )

    return user


type CurrentAdminUser = Annotated[
    User,
    Depends(get_current_admin_user),
]
