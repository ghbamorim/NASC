from collections.abc import Collection
from typing import TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class LoadFromPydantic:
    def __init__(self) -> None:
        pass

    def load_from_pydantic(
        self,
        model: T,
        data: BaseModel,
        *,
        exclude_unset: bool = True,
        exclude: Collection[str] = (),
    ) -> T:
        values = data.model_dump(exclude_unset=exclude_unset, exclude=set(exclude))

        for field, value in values.items():
            setattr(model, field, value)
        return model
