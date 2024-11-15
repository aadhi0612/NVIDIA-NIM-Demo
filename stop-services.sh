#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PID_FILE="$SCRIPT_DIR/.service_pids"

# Source conda
source /home/ubuntu/miniconda3/etc/profile.d/conda.sh

echo "Stopping services..."

if [ -f "$PID_FILE" ]; then
    while read -r pid; do
        if ps -p "$pid" > /dev/null; then
            echo "Stopping process $pid"
            kill "$pid" 2>/dev/null
        fi
    done < "$PID_FILE"
    rm "$PID_FILE"
    echo "All services stopped"
else
    echo "No running services found"
fi

# Kill any remaining npm or Python processes related to our app
pkill -f "node.*react-scripts start" || true
pkill -f "python.*app.py" || true

# Deactivate conda environment
conda deactivate

echo "Cleanup complete" 