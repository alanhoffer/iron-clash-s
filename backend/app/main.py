from __future__ import annotations

from dataclasses import dataclass
import random
from typing import Any, Literal

from fastapi import FastAPI
from pydantic import BaseModel, Field


app = FastAPI(title="IronClash Backend", version="0.1.0")


class Stats(BaseModel):
    hp: int = Field(ge=1, le=999999)
    atk: int = Field(ge=0, le=999999)
    dfn: int = Field(ge=0, le=999999)
    spd: int = Field(ge=1, le=999999)
    crit: float = Field(ge=0.0, le=1.0)
    eva: float = Field(ge=0.0, le=1.0)
    block: float = Field(default=0.0, ge=0.0, le=1.0)


class Fighter(BaseModel):
    id: str = Field(min_length=1, max_length=64)
    name: str = Field(min_length=1, max_length=64)
    stats: Stats


class SimulateRequest(BaseModel):
    seed: int = Field(default=1, ge=0, le=2**31 - 1)
    a: Fighter
    b: Fighter
    max_events: int = Field(default=200, ge=10, le=5000)


class ReplayEvent(BaseModel):
    t: int
    type: Literal["attack", "result", "end"]
    data: dict[str, Any]


class SimulateResponse(BaseModel):
    seed: int
    winner_id: str
    events: list[ReplayEvent]
    final: dict[str, Any]


@dataclass
class _SimFighter:
    id: str
    name: str
    hp: int
    atk: int
    dfn: int
    spd: int
    crit: float
    eva: float
    block: float
    atb: float = 0.0


def _clamp01(x: float) -> float:
    return 0.0 if x < 0.0 else 1.0 if x > 1.0 else x


def _damage(atk: int, dfn: int) -> int:
    # MVP: simple, predictable damage model.
    base = atk - int(dfn * 0.35)
    return max(1, base)


def _step_atb(a: _SimFighter, b: _SimFighter) -> _SimFighter:
    # Mixed ATB: fill until someone reaches 100.
    a.atb += a.spd
    b.atb += b.spd
    if a.atb >= 100 and b.atb >= 100:
        # tie breaker: higher SPD wins; if tied, deterministic by id.
        if a.spd != b.spd:
            return a if a.spd > b.spd else b
        return a if a.id < b.id else b
    if a.atb >= 100:
        return a
    if b.atb >= 100:
        return b
    return _step_atb(a, b)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/combat/simulate", response_model=SimulateResponse)
def simulate(req: SimulateRequest) -> SimulateResponse:
    rng = random.Random(req.seed)

    a0 = req.a.stats
    b0 = req.b.stats
    a = _SimFighter(
        id=req.a.id,
        name=req.a.name,
        hp=a0.hp,
        atk=a0.atk,
        dfn=a0.dfn,
        spd=a0.spd,
        crit=_clamp01(a0.crit),
        eva=_clamp01(a0.eva),
        block=_clamp01(a0.block),
    )
    b = _SimFighter(
        id=req.b.id,
        name=req.b.name,
        hp=b0.hp,
        atk=b0.atk,
        dfn=b0.dfn,
        spd=b0.spd,
        crit=_clamp01(b0.crit),
        eva=_clamp01(b0.eva),
        block=_clamp01(b0.block),
    )

    events: list[ReplayEvent] = []
    t = 0

    def push(type_: str, data: dict[str, Any]) -> None:
        nonlocal t
        events.append(ReplayEvent(t=t, type=type_, data=data))
        t += 1

    push(
        "result",
        {
            "msg": "start",
            "a": {"id": a.id, "name": a.name, "hp": a.hp},
            "b": {"id": b.id, "name": b.name, "hp": b.hp},
        },
    )

    while a.hp > 0 and b.hp > 0 and len(events) < req.max_events:
        actor = _step_atb(a, b)
        target = b if actor is a else a
        actor.atb -= 100

        push(
            "attack",
            {"attacker_id": actor.id, "target_id": target.id},
        )

        # 1) Dodge
        dodged = rng.random() < target.eva
        if dodged:
            push(
                "result",
                {"msg": "dodge", "attacker_id": actor.id, "target_id": target.id},
            )
            continue

        # 2) Block
        blocked = rng.random() < target.block
        block_mult = 1.0
        if blocked:
            block_mult = 1.0 - rng.uniform(0.40, 0.70)

        # 3) Crit
        crit = rng.random() < actor.crit
        crit_mult = 1.5 if crit else 1.0

        raw = _damage(actor.atk, target.dfn)
        dealt = int(max(1, raw * block_mult * crit_mult))
        target.hp = max(0, target.hp - dealt)

        push(
            "result",
            {
                "msg": "hit",
                "attacker_id": actor.id,
                "target_id": target.id,
                "raw": raw,
                "blocked": blocked,
                "crit": crit,
                "dmg": dealt,
                "target_hp": target.hp,
            },
        )

    winner = a if a.hp > 0 else b
    push("end", {"winner_id": winner.id})

    return SimulateResponse(
        seed=req.seed,
        winner_id=winner.id,
        events=events,
        final={
            "a": {"id": a.id, "hp": a.hp},
            "b": {"id": b.id, "hp": b.hp},
        },
    )

