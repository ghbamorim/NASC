from typing import Literal
from uuid import UUID

from fastapi import APIRouter, HTTPException, Response, status

from app.core.auth import CurrentAdminUser
from app.core.dependencies.database import DbSession
from app.core.settings import settings
from app.schemas.channel_user import ChannelLinkResponse, ChannelUserResponse
from app.services.channel_link_token import ChannelLinkTokenService
from app.services.channel_user import ChannelUserService
from app.services.user import UserService

router = APIRouter(
    prefix="/users/{user_id}/channels",
    tags=["Channel Users"],
)


@router.post(
    "/telegram/link",
    response_model=ChannelLinkResponse,
    status_code=status.HTTP_201_CREATED,
)
async def generate_telegram_link(
    user_id: UUID,
    db: DbSession,
    _: CurrentAdminUser,
    response: Response,
) -> ChannelLinkResponse:
    await UserService(db).get_user(user_id)

    service = ChannelLinkTokenService(
        db,
        expire_minutes=settings.channel_link_token_expire_minutes,
    )

    try:
        token = await service.generate(
            user_id=user_id,
            channel="telegram",
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc),
        ) from exc

    response.headers["Cache-Control"] = "no-store"

    return ChannelLinkResponse(
        channel="telegram",
        link=f"https://t.me/{settings.telegram_bot_username}?start={token}",
        expires_in_seconds=settings.channel_link_token_expire_minutes * 60,
    )


@router.get("", response_model=list[ChannelUserResponse])
async def list_channel_users(
    user_id: UUID,
    db: DbSession,
    _: CurrentAdminUser,
) -> list[ChannelUserResponse]:
    await UserService(db).get_user(user_id)

    channel_users = await ChannelUserService(db).list_by_user(
        user_id=user_id,
    )

    return [
        ChannelUserResponse.model_validate(channel_user)
        for channel_user in channel_users
    ]


@router.delete(
    "/{channel}/token",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def revoke_channel_tokens(
    user_id: UUID,
    channel: Literal["telegram"],
    db: DbSession,
    _: CurrentAdminUser,
) -> Response:
    await UserService(db).get_user(user_id)

    await ChannelLinkTokenService(db).revoke(
        user_id=user_id,
        channel=channel,
    )

    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete(
    "/{channel}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def unlink_channel_user(
    user_id: UUID,
    channel: Literal["telegram"],
    db: DbSession,
    _: CurrentAdminUser,
) -> Response:
    await UserService(db).get_user(user_id)

    try:
        await ChannelUserService(db).unlink(
            user_id=user_id,
            channel=channel,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc),
        ) from exc

    return Response(status_code=status.HTTP_204_NO_CONTENT)
