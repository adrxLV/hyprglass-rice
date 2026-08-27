#!/usr/bin/env python3
"""
Tide Agent IPC Client Helper for Tide Island QML components.
Communicates with tide-agent daemon via Unix Domain Socket (~/.local/share/tide-agent/socket).
Supports edge-tts speech synthesis triggers.
"""

import sys
import json
import socket
from pathlib import Path

SOCKET_PATH = Path.home() / ".local" / "share" / "tide-agent" / "socket"


def send_ipc_request(payload: dict) -> dict:
    if not SOCKET_PATH.exists():
        return {
            "status": "offline",
            "error": f"Tide Agent daemon is not running (socket not found at {SOCKET_PATH}).",
        }

    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.settimeout(10.0)
        client.connect(str(SOCKET_PATH))

        request_str = json.dumps(payload) + "\n"
        client.sendall(request_str.encode("utf-8"))

        response_bytes = b""
        while True:
            chunk = client.recv(4096)
            if not chunk:
                break
            response_bytes += chunk
            if b"\n" in response_bytes:
                break

        client.close()

        if response_bytes:
            line = response_bytes.decode("utf-8").strip().split("\n")[0]
            return json.loads(line)
        return {"status": "error", "error": "Empty response from Tide Agent"}
    except Exception as e:
        return {"status": "error", "error": str(e)}


def send_ipc_prompt_and_wait(prompt_text: str, speak: bool = False, timeout: float = 120.0) -> dict:
    """Send prompt and wait until task_completed broadcast is received."""
    if not SOCKET_PATH.exists():
        return {
            "status": "offline",
            "error": f"Tide Agent daemon is not running (socket not found at {SOCKET_PATH}).",
        }

    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.settimeout(timeout)
        client.connect(str(SOCKET_PATH))

        request_str = json.dumps({"type": "prompt", "content": prompt_text, "speak": speak}) + "\n"
        client.sendall(request_str.encode("utf-8"))

        buffer = ""
        while True:
            chunk = client.recv(4096)
            if not chunk:
                break
            buffer += chunk.decode("utf-8", errors="replace")
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()
                if line:
                    try:
                        msg = json.loads(line)
                        if msg.get("type") == "task_completed":
                            client.close()
                            return {
                                "status": "success",
                                "task_id": msg.get("task_id"),
                                "response": msg.get("response", ""),
                            }
                        elif msg.get("type") == "step_error":
                            client.close()
                            return {
                                "status": "error",
                                "error": msg.get("error", "Error executing step"),
                            }
                    except json.JSONDecodeError:
                        pass

        client.close()
        return {"status": "error", "error": "Connection closed before completion"}
    except Exception as e:
        return {"status": "error", "error": str(e)}


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"status": "error", "error": "No command specified"}))
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "status":
        res = send_ipc_request({"type": "status"})
        print(json.dumps(res, ensure_ascii=False))

    elif cmd == "prompt" and len(sys.argv) >= 3:
        speak = "--speak" in sys.argv
        args = [a for a in sys.argv[2:] if a != "--speak"]
        prompt_text = " ".join(args)
        res = send_ipc_prompt_and_wait(prompt_text, speak=speak)
        print(json.dumps(res, ensure_ascii=False))

    elif cmd == "speak" and len(sys.argv) >= 3:
        text = " ".join(sys.argv[2:])
        res = send_ipc_request({"type": "speak", "text": text})
        print(json.dumps(res, ensure_ascii=False))

    elif cmd == "list_tools":
        res = send_ipc_request({"type": "list_tools"})
        print(json.dumps(res, ensure_ascii=False))

    elif cmd == "list_skills":
        res = send_ipc_request({"type": "list_skills"})
        print(json.dumps(res, ensure_ascii=False))

    else:
        print(json.dumps({"status": "error", "error": f"Unknown command '{cmd}'"}))


if __name__ == "__main__":
    main()
