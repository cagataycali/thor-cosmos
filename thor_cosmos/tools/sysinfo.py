"""Wrapper around `just sysinfo` — host/Jetson/GPU summary."""
from __future__ import annotations

from strands import tool
from ._common import just_run, ok, err


@tool
def system_info() -> dict:
    """Host summary via `just sysinfo`: OS, Jetson model, GPU, memory, thermal."""
    proc = just_run("sysinfo", timeout_s=10)
    if not proc.get("ok"):
        return err(f"sysinfo failed: {proc.get('stderr', '')[:200]}")
    return ok(
        text=proc.get("stdout", "").strip() or "no output",
        data={"cmd": proc.get("cmd"), "cwd": proc.get("cwd")},
    )
