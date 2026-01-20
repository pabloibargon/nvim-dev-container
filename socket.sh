#!/bin/bash

# Path to the Unix socket
SOCKET_PATH="/tmp/container_socket"

# Ensure the socket exists
if [[ ! -e $SOCKET_PATH ]]; then
    mkfifo $SOCKET_PATH
fi

# Function to handle graceful exit
cleanup() {
    rm -f $SOCKET_PATH  # Remove the socket file
    exit 0
}

# Trap termination signals (like Ctrl+C or when the container exits)
trap cleanup SIGINT SIGTERM

# Listen for input from the socket (filenames or URLs)
while true; do
    if read -r target < $SOCKET_PATH; then
        /mnt/c/Windows/explorer.exe "$target"
    fi
done

