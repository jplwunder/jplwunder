#!/usr/bin/env python3

import os
import json
import subprocess
import sys
import termios
import tty
import urllib.request
import urllib.error
from pathlib import Path

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "llama3.1:8b"

PROMPT_TEMPLATE = """You are a commit message generator. Output ONLY the commit message — no explanations, no commentary, no markdown formatting, no code blocks, no quotes.

Use conventional commits format (e.g. feat:, fix:, refactor:, docs:, chore:).
Write a short subject line, then two newlines, then a bullet-point body with details.

Diff:
{diff}"""

REFINE_PROMPT_TEMPLATE = """You are a commit message generator. Output ONLY the commit message — no explanations, no commentary, no markdown formatting, no code blocks, no quotes.

Current commit message:
{message}

Requested changes: {feedback}

Rewrite the commit message incorporating the requested changes."""


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
    result = subprocess.run(["git", "diff", "--cached"], capture_output=True, text=True)
    return result.stdout.strip() or None


MAX_DIFF_CHARS = 6000


def fetch_message(prompt: str, token: str) -> str:
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

    full_message = ""
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
                        full_message += chunk
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
    return full_message.strip()


def generate_commit_message(diff: str, token: str) -> str:
    if len(diff) > MAX_DIFF_CHARS:
        diff = diff[:MAX_DIFF_CHARS] + "\n... (diff truncated)"
        print(f"[warn] diff truncated to {MAX_DIFF_CHARS} chars", file=sys.stderr)

    print("Generating commit message...\n", file=sys.stderr)
    return fetch_message(PROMPT_TEMPLATE.format(diff=diff), token)


def refine_commit_message(message: str, feedback: str, token: str) -> str:
    print("\nRefining commit message...\n", file=sys.stderr)
    return fetch_message(REFINE_PROMPT_TEMPLATE.format(message=message, feedback=feedback), token)


def git_commit(message: str) -> bool:
    result = subprocess.run(["git", "commit", "-m", message])
    return result.returncode == 0


def git_push() -> bool:
    result = subprocess.run(["git", "push"])
    return result.returncode == 0


MENU_OPTIONS = ["Commit", "Commit and Push", "Propose changes", "Exit"]


def read_key() -> str:
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == "\x1b":
            ch += sys.stdin.read(2)
        return ch
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


def arrow_menu(options: list[str]) -> int:
    selected = 0
    RESET = "\033[0m"
    BOLD_GREEN = "\033[1;32m"
    CLEAR_LINE = "\033[2K\r"

    # Print initial menu
    for i, opt in enumerate(options):
        if i == selected:
            print(f"  {BOLD_GREEN}> {opt}{RESET}")
        else:
            print(f"    {opt}")

    while True:
        key = read_key()

        if key in ("\x1b[A", "\x1b[D"):  # up / left
            selected = (selected - 1) % len(options)
        elif key in ("\x1b[B", "\x1b[C"):  # down / right
            selected = (selected + 1) % len(options)
        elif key in ("\r", "\n"):  # enter
            # Move cursor back up and clear menu
            print(f"\033[{len(options)}A", end="")
            for opt in options:
                print(f"{CLEAR_LINE}{opt}")
            print(f"\033[{len(options)}A", end="")
            for _ in options:
                print(f"{CLEAR_LINE}", end="")
            print(f"\033[{len(options)}A", end="")
            return selected
        elif key == "\x03":  # ctrl+c
            print()
            sys.exit(0)
        else:
            continue

        # Redraw menu in place
        print(f"\033[{len(options)}A", end="")
        for i, opt in enumerate(options):
            if i == selected:
                print(f"{CLEAR_LINE}  {BOLD_GREEN}> {opt}{RESET}")
            else:
                print(f"{CLEAR_LINE}    {opt}")


def main() -> None:
    load_env_file()
    token = get_token()

    diff = get_git_diff()
    if not diff:
        print("No staged changes found. Run `git add` before ai_commit.", file=sys.stderr)
        sys.exit(1)

    message = generate_commit_message(diff, token)

    while True:
        print("\n")
        choice = arrow_menu(MENU_OPTIONS)
        print()

        if choice == 0:  # Commit
            if git_commit(message):
                print("Committed.")
            break

        elif choice == 1:  # Commit and Push
            if git_commit(message):
                print("Committed. Pushing...")
                git_push()
            break

        elif choice == 2:  # Propose changes
            try:
                feedback = input("What changes do you want? ").strip()
            except (KeyboardInterrupt, EOFError):
                print("\nExiting.")
                sys.exit(0)
            if feedback:
                message = refine_commit_message(message, feedback, token)

        elif choice == 3:  # Exit
            print("Exiting.")
            break


if __name__ == "__main__":
    main()
