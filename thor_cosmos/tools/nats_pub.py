"""Wrapper around `just nats-publish`."""
from __future__ import annotations

import json
import os

from strands import tool
from ._common import just_run, ok, err


@tool
def nats_publish(
    subject: str,
    payload: dict,
    servers: str = "",
) -> dict:
    """Publish a JSON payload to a NATS subject via `just nats-publish`.

    Args:
        subject: NATS subject (e.g. "perception.vlm").
        payload: JSON-serializable dict payload.
        servers: NATS URL(s). Default: NATS_URL env or nats://127.0.0.1:4222.
    """
    try:
        payload_json = json.dumps(payload)
    except Exception as e:  # noqa: BLE001
        return err(f"payload not JSON-serializable: {e}")

    extra_env = {"NATS_URL": servers} if servers else None
    proc = just_run("nats-publish", subject, payload_json,
                    timeout_s=10, extra_env=extra_env)
    if not proc.get("ok"):
        return err(f"NATS publish failed: {proc.get('stderr', '')[:200]}",
                   data={"subject": subject, "cmd": proc.get("cmd")})
    return ok(
        f"📡 published to {subject} ({len(payload_json)}B)",
        data={"subject": subject, "bytes_sent": len(payload_json),
              "servers": servers or os.getenv("NATS_URL", "nats://127.0.0.1:4222")},
    )
