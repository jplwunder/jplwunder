#!/usr/bin/env python3

import os
import json
import subprocess
import sys
import urllib.request
import urllib.error
from pathlib import Path

OLLAMA_URL = "http://192.168.0.13:11435/api/generate"
MODEL = "llama3.1:8b"

PROMPT_TEMPLATE = """Generate a concise git commit message for the following diff.
Use the conventional commits format (e.g. feat:, fix:, refactor:, docs:, chore:, etc.).
Add details about the changes in the commit message.
Use two newlines to separate the main commit message from the details section.

Diff:
{diff}"""


def load_env_file():
    """Load .env from the script's directory into os.environ."""
    env_path = Path(__file__).parent / ".env"
    if not env_path.exists():
        return
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def get_token() -> str:
    token = os.environ.get("OLLAMA_TOKEN")
    if not token:
        print("Error: OLLAMA_TOKEN not set. Add it to your .env file.", file=sys.stderr)
        sys.exit(1)
    return token


def get_git_diff() -> str | None:
    # Prefer staged diff, fall back to unstaged
    for args in [["git", "diff", "--cached"], ["git", "diff"]]:
        result = subprocess.run(args, capture_output=True, text=True)
        diff = result.stdout.strip()
        if diff:
            return diff
    return None


MAX_DIFF_CHARS = 6000


def stream_commit_message(diff: str, token: str) -> None:
    if len(diff) > MAX_DIFF_CHARS:
        diff = diff[:MAX_DIFF_CHARS] + "\n... (diff truncated)"
        print(f"[warn] diff truncated to {MAX_DIFF_CHARS} chars", file=sys.stderr)

    prompt = PROMPT_TEMPLATE.format(diff=diff)
    payload = json.dumps({"model": MODEL, "prompt": prompt, "stream": True}).encode()

    req = urllib.request.Request(
        OLLAMA_URL,
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as response:
            for line in response:
                raw = line.decode().strip()
                if not raw:
                    continue
                try:
                    obj = json.loads(raw)
                    chunk = obj.get("response", "")
                    if chunk:
                        print(chunk, end="", flush=True)
                    if obj.get("done", False):
                        break
                except json.JSONDecodeError:
                    continue
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        sys.exit(1)
    except (urllib.error.URLError, ConnectionResetError) as e:
        print(f"Request failed: {e}", file=sys.stderr)
        sys.exit(1)

    print()


def main() -> None:
    load_env_file()
    token = get_token()

    diff = get_git_diff()
    if not diff:
        print("No changes found. Stage or make changes before running.", file=sys.stderr)
        sys.exit(1)

    print("Generating commit message...\n", file=sys.stderr)
    stream_commit_message(diff, token)


if __name__ == "__main__":
    main()
