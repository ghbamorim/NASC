from uuid import UUID

from fastapi import APIRouter, Response, status

from app.core.auth import CurrentAdminUser
from app.core.dependencies.database import DbSession
from app.schemas.user import UserCreate, UserPatch, UserResponse, UserUpdate
from app.services.user import UserService

router = APIRouter(prefix="/users", tags=["Users"])


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    data: UserCreate,
    db: DbSession,
    _: CurrentAdminUser,
) -> UserResponse:
    user = await UserService(db).create_user(data)
    return UserResponse.model_validate(user)


@router.get("", response_model=list[UserResponse])
async def get_users(db: DbSession, _: CurrentAdminUser) -> list[UserResponse]:
    users = await UserService(db).get_users()
    return [UserResponse.model_validate(user) for user in users]


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: UUID, db: DbSession, _: CurrentAdminUser) -> UserResponse:
    user = await UserService(db).get_user(user_id)
    return UserResponse.model_validate(user)


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: UUID, data: UserUpdate, db: DbSession, _: CurrentAdminUser
) -> UserResponse:
    user = await UserService(db).update_user(user_id, data)
    return UserResponse.model_validate(user)


@router.patch("/{user_id}", response_model=UserResponse)
async def patch_user(
    user_id: UUID, data: UserPatch, db: DbSession, _: CurrentAdminUser
) -> UserResponse:
    user = await UserService(db).update_user(user_id, data)
    return UserResponse.model_validate(user)


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: UUID, db: DbSession, _: CurrentAdminUser) -> Response:
    await UserService(db).delete_user(user_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
