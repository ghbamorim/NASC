from uuid import UUID

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.whatsapp_contact import WhatsAppContact
from app.models.whatsapp_message_receipt import WhatsAppMessageReceipt


class WhatsAppRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def claim_message(self, message_id: str) -> bool:
        stmt = (
            insert(WhatsAppMessageReceipt)
            .values(message_id=message_id)
            .on_conflict_do_nothing()
            .returning(WhatsAppMessageReceipt.message_id)
        )

        result = await self.db.execute(stmt)

        return result.scalar_one_or_none() is not None

    async def get_conversation_id(self, phone_number: str) -> UUID | None:
        stmt = select(WhatsAppContact.conversation_id).where(
            WhatsAppContact.phone_number == phone_number
        )

        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def link_conversation(self, phone_number: str, conversation_id: UUID) -> None:
        stmt = (
            insert(WhatsAppContact)
            .values(phone_number=phone_number, conversation_id=conversation_id)
            .on_conflict_do_nothing()
        )

        await self.db.execute(stmt)
