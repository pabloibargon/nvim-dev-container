import json
import os
import sys

import zmq

runtimes_path = os.path.join(
    os.environ["HOME"], ".local", "share", "jupyter", "runtime"
)
kernel_json_file_path = os.listdir(runtimes_path)[0]
kernel_json_file_path = os.path.join(runtimes_path, kernel_json_file_path)

assert kernel_json_file_path.endswith("json")
with open(kernel_json_file_path, mode="r", encoding="utf8") as f:
    port = json.load(f)["iopub_port"]

context = zmq.Context()
socket = context.socket(zmq.SUB)
socket.connect(f"tcp://localhost:{port}")

# Subscribe to all topics
socket.setsockopt_string(zmq.SUBSCRIBE, "")

while True:
    message = socket.recv_string()
    try:
        d = json.loads(message)
        if d["name"] == "stderr":
            outbuf = sys.stderr
        else:
            outbuf = sys.stdout
        print(d["text"], end = "",file=outbuf)
    except:
        pass
