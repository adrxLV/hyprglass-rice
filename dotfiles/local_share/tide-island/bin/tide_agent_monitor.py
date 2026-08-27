#!/usr/bin/env python3
"""
Tide Agent Background IPC Monitor for Tide Island QML.
Listens for task_completed broadcasts from tide-agent socket and outputs events to stdout.
"""

import sys
import json
import socket
from pathlib import Path

SOCKET_PATH = Path.home() / ".local" / "share" / "tide-agent" / "socket"


def main():
    if not SOCKET_PATH.exists():
        sys.exit(0)

    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(str(SOCKET_PATH))
        
        # Register as event listener
        reg_payload = json.dumps({"type": "ping"}) + "\n"
        client.sendall(reg_payload.encode("utf-8"))

        buffer = ""
        while True:
            data = client.recv(4096)
            if not data:
                break
            buffer += data.decode("utf-8", errors="replace")
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()
                if line:
                    try:
                        msg = json.loads(line)
                        if msg.get("type") in ["task_completed", "task_plan", "step_result", "permission_request"]:
                            print(json.dumps(msg, ensure_ascii=False), flush=True)
                    except Exception:
                        pass
    except Exception as e:
        pass


if __name__ == "__main__":
    main()
