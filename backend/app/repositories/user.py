from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.core.load_from_pydantic import LoadFromPydantic
from app.core.security import hash_password
from app.models.user import User
from app.schemas.user import UserCreate, UserPatch, UserUpdate


class UserRepository(LoadFromPydantic):
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(self, user: UserCreate) -> User:
        result = User(
            **user.model_dump(exclude={"password"}),
            password_hash=await hash_password(user.password),
        )

        self.db.add(result)
        await self.db.flush()
        return result

    async def get(self, user_id: UUID) -> User | None:
        return await self.db.get(User, user_id)

    async def get_by_email(self, email: str) -> User | None:
        stmt = select(User).where(User.email == email)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def update(self, user_id: UUID, data: UserUpdate | UserPatch) -> User:
        exclude_unset = isinstance(data, UserPatch)

        user: User | None = await self.get(user_id)
        if user is None:
            raise NotFoundError("User")

        self.load_from_pydantic(user, data, exclude_unset=exclude_unset)

        await self.db.flush()
        return user

    async def delete_user(self, user_id: UUID) -> None:
        user: User | None = await self.get(user_id)
        if user is None:
            raise NotFoundError("User")
        await self.db.delete(user)

    async def get_all(self) -> list[User]:
        stmt = select(User)
        result = await self.db.execute(stmt)

        return list(result.scalars().all())
