"""Shared helpers for strands tool results and `just`-based execution.

Tool return format (rich, @tool-compatible):
    {
        "status": "success" | "error",
        "content": [
            {"text": "..."},          # human-readable
            {"json": {...}},          # structured payload
            {"image": {"format": "jpeg", "source": {"bytes": b"..."}}},
        ],
    }

Anything returned from a @tool function is passed to the LLM.

Design:
    All pipelines live in the top-level `justfile`. Python tools are *thin
    wrappers* that invoke `just <recipe> <args...>` and normalize the result.
    This keeps the agent, the operator's CLI, and the Cosmos upstream repos
    (all of which use justfiles) consistent with zero duplication.
"""
from __future__ import annotations

import json as _json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any


# ── ToolResult builders ──────────────────────────────────────────────────
def ok(text: str = "", data: dict | None = None, image_path: str | None = None,
       image_bytes: bytes | None = None, image_format: str | None = None) -> dict:
    """Build a success ToolResult. Any combination of text/json/image is allowed."""
    content: list[dict] = []
    if text:
        content.append({"text": text})
    if data is not None:
        content.append({"json": data})
    if image_bytes is not None:
        fmt = image_format or "jpeg"
        content.append({"image": {"format": fmt, "source": {"bytes": image_bytes}}})
    elif image_path:
        p = Path(image_path).expanduser()
        if p.exists():
            fmt = image_format or (p.suffix.lower().lstrip(".") or "jpeg")
            if fmt == "jpg":
                fmt = "jpeg"
            if fmt not in ("png", "jpeg", "gif", "webp"):
                fmt = "png"
            content.append({"image": {"format": fmt, "source": {"bytes": p.read_bytes()}}})
    if not content:
        content.append({"text": "ok"})
    return {"status": "success", "content": content}


def err(msg: str, data: dict | None = None) -> dict:
    """Build an error ToolResult."""
    content: list[dict] = [{"text": f"❌ {msg}"}]
    if data is not None:
        content.append({"json": data})
    return {"status": "error", "content": content}


# ── just runner ──────────────────────────────────────────────────────────
_JUST_BIN = os.getenv("THOR_COSMOS_JUST", "just")


def _find_justfile() -> Path | None:
    """Walk up from CWD to find the nearest justfile."""
    p = Path.cwd()
    for parent in [p] + list(p.parents):
        f = parent / "justfile"
        if f.is_file():
            return f
    # Fall back to the package's repo root
    pkg_root = Path(__file__).resolve().parent.parent.parent
    f = pkg_root / "justfile"
    return f if f.is_file() else None


def just_run(recipe: str, *args: str, timeout_s: int = 3600,
             env: dict | None = None, cwd: str | None = None,
             extra_env: dict | None = None) -> dict:
    """Invoke `just <recipe> <args...>` and return a normalized proc dict.

    Args:
        recipe: justfile recipe name (e.g. "download", "quantize").
        *args: positional args for the recipe.
        timeout_s: command timeout.
        env: full env to use (default: inherit).
        cwd: directory to run `just` in (default: repo root).
        extra_env: extra env vars to merge into the existing environment.

    Returns:
        {"ok": bool, "returncode": int, "stdout": str, "stderr": str, "cmd": str}
    """
    if not shutil.which(_JUST_BIN):
        return {
            "ok": False, "returncode": 127,
            "stdout": "",
            "stderr": f"`{_JUST_BIN}` not found on PATH. Install: brew install just",
            "cmd": f"{_JUST_BIN} {recipe} " + " ".join(args),
        }

    justfile = _find_justfile()
    workdir = cwd or (str(justfile.parent) if justfile else None)

    cmd = [_JUST_BIN, recipe, *[str(a) for a in args]]
    run_env = os.environ.copy() if env is None else dict(env)
    if extra_env:
        run_env.update(extra_env)

    try:
        p = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout_s,
            cwd=workdir, env=run_env,
        )
        return {
            "ok": p.returncode == 0,
            "returncode": p.returncode,
            "stdout": p.stdout[-8000:],
            "stderr": p.stderr[-4000:],
            "cmd": " ".join(cmd),
            "cwd": workdir,
        }
    except subprocess.TimeoutExpired:
        return {"ok": False, "returncode": -1, "stdout": "", "stderr": f"timeout after {timeout_s}s",
                "cmd": " ".join(cmd), "cwd": workdir}
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "returncode": -1, "stdout": "", "stderr": str(e),
                "cmd": " ".join(cmd), "cwd": workdir}


def proc_result(proc: dict, success_text: str, fail_text: str = "") -> dict:
    """Convert a just_run / run_proc output into a ToolResult."""
    if proc.get("ok"):
        tail = proc.get("stdout", "")[-1500:]
        return ok(
            text=success_text + (f"\n\n--- stdout (tail) ---\n{tail}" if tail else ""),
            data=proc,
        )
    stderr_tail = proc.get("stderr", "")[-400:]
    return err(fail_text or f"exit {proc.get('returncode')}: {stderr_tail}",
               data=proc)


# ── Legacy subprocess helpers (kept for tools that don't go through just) ──
def run_proc(cmd: list[str], timeout_s: int = 3600, cwd: str | None = None,
             env: dict | None = None) -> dict:
    """Run a subprocess, capture output, return a normalized dict.

    Never raises — returns ok=False on any error.
    """
    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)
    try:
        p = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout_s,
            cwd=cwd, env=merged_env,
        )
        return {
            "ok": p.returncode == 0,
            "returncode": p.returncode,
            "stdout": p.stdout[-8000:],
            "stderr": p.stderr[-4000:],
            "cmd": " ".join(cmd),
        }
    except FileNotFoundError as e:
        return {"ok": False, "returncode": 127, "stdout": "",
                "stderr": str(e), "cmd": " ".join(cmd)}
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "returncode": -1, "stdout": "",
                "stderr": str(e), "cmd": " ".join(cmd)}


def which(binary: str) -> str | None:
    return shutil.which(binary)


def env_default(key: str, fallback: str) -> str:
    return os.getenv(key, fallback)


def safe_json(obj: Any) -> str:
    try:
        return _json.dumps(obj, indent=2, default=str)
    except Exception:  # noqa: BLE001
        return str(obj)
