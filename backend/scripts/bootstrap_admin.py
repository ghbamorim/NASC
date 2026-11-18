import asyncio
from getpass import getpass

from sqlalchemy import select

from app.core.dependencies.database import SessionLocal
from app.core.security import hash_password
from app.models.user import User


async def bootstrap_admin() -> None:
    async with SessionLocal() as db, db.begin():
        result = await db.execute(
            select(User.id).where(User.is_admin.is_(True)).limit(1)
        )

        if result.scalar_one_or_none() is not None:
            print("An administrator already exists.")
            return

        email = input("Admin email: ").strip().lower()
        password = getpass("Admin password: ")

        if not email or not password:
            raise ValueError("Email and password are required.")

        existing = await db.execute(select(User.id).where(User.email == email))

        if existing.scalar_one_or_none() is not None:
            raise ValueError("Email already registered.")

        user = User(
            email=email,
            password_hash=await hash_password(password),
            is_admin=True,
            is_active=True,
        )

        db.add(user)
        await db.flush()

    print("Administrator created successfully.")


if __name__ == "__main__":
    asyncio.run(bootstrap_admin())
