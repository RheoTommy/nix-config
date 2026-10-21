# Attaches to a herdr pane through Ovis's WebSocket and checks that a typed
# command comes back as terminal output.
import asyncio
import json
import sys

import websockets

URL, PANE = sys.argv[1], sys.argv[2]
MARKER = "ovis-attach-ok"


async def main():
    async with websockets.connect(URL) as ws:
        await ws.send(json.dumps({"type": "attach", "pane_id": PANE, "cols": 80, "rows": 24}))
        output = ""
        typed = False
        while MARKER not in output:
            message = json.loads(await ws.recv())
            if message.get("pane_id") != PANE:
                continue
            if message["type"] == "error":
                sys.exit(f"attach failed: {message}")
            if message["type"] == "input-ready" and not typed:
                # Split so the echoed command line alone cannot match.
                await ws.send(json.dumps({"type": "input", "pane_id": PANE, "text": "echo ovis-attach-''ok\r"}))
                typed = True
            if message["type"] == "pty-data":
                output += message["data"]


asyncio.run(asyncio.wait_for(main(), 30))
print("attached")
