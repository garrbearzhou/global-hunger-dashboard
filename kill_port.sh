#!/bin/bash
# Quick script to kill process on port 3838
# Usage: ./kill_port.sh [port_number]

PORT=${1:-3838}
echo "Checking for processes on port $PORT..."

PID=$(lsof -ti:$PORT 2>/dev/null)

if [ -z "$PID" ]; then
    echo "No process found on port $PORT"
else
    echo "Found process $PID on port $PORT"
    echo "Killing process..."
    kill -9 $PID 2>/dev/null
    sleep 2
    echo "✅ Port $PORT should now be free"
fi




