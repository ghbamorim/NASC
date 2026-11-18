from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.core.load_from_pydantic import LoadFromPydantic
from app.models.user import User
from app.repositories.user import UserRepository
from app.schemas.user import UserCreate, UserPatch, UserUpdate


class UserService(LoadFromPydantic):
    def __init__(
        self, db: AsyncSession, user_repository: UserRepository | None = None
    ) -> None:
        super().__init__()
        self.db = db
        self.user_repository = user_repository or UserRepository(db)

    async def get_user(self, user_id: UUID) -> User:
        result = await self.user_repository.get(user_id)
        if not result:
            raise NotFoundError("User")
        return result

    async def get_users(self) -> list[User]:
        return await self.user_repository.get_all()

    async def get_user_by_email(self, email: str) -> User:
        result = await self.user_repository.get_by_email(email)
        if not result:
            raise NotFoundError("User")
        return result

    async def create_user(self, user: UserCreate) -> User:
        return await self.user_repository.create(user)

    async def update_user(self, user_id: UUID, data: UserUpdate | UserPatch) -> User:
        return await self.user_repository.update(user_id, data)

    async def delete_user(self, user_id: UUID) -> None:
        await self.user_repository.delete_user(user_id)
