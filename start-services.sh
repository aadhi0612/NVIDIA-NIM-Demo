#!/bin/bash

# Store the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PID_FILE="$SCRIPT_DIR/.service_pids"

# Define ports
FLASK_PORT=5007
REACT_PORT=3007

# Source conda
source /home/ubuntu/miniconda3/etc/profile.d/conda.sh

# Function to cleanup processes on exit
cleanup() {
    echo -e "\nStopping services..."
    if [ -f "$PID_FILE" ]; then
        while read -r pid; do
            if ps -p "$pid" > /dev/null; then
                echo "Killing process $pid"
                kill "$pid" 2>/dev/null
            fi
        done < "$PID_FILE"
        rm "$PID_FILE"
    fi
    echo "All services stopped"
    conda deactivate
    exit 0
}

# Set up trap to catch SIGINT (Ctrl+C) and SIGTERM
trap cleanup SIGINT SIGTERM

echo -e "\n=== Starting Riva Translation Demo Services ===\n"

# Start the Flask backend
echo "Starting Flask backend..."
cd "$SCRIPT_DIR/backend"

# Activate conda environment
echo "Activating aws conda environment..."
conda activate aws

if [ $? -eq 0 ]; then
    echo "Successfully activated aws environment"
else
    echo "Failed to activate aws environment"
    exit 1
fi

# Install Flask dependencies if needed
pip install -r requirements.txt

# Start Flask backend in the background
echo "Starting Flask backend on port ${FLASK_PORT}..."
/home/ubuntu/miniconda3/envs/aws/bin/python app.py &
FLASK_PID=$!
echo $FLASK_PID > "$PID_FILE"
echo -e "\n✅ Flask backend started with PID: $FLASK_PID"
echo -e "   Backend URL: http://localhost:${FLASK_PORT}"

# Wait a moment for Flask to start
sleep 2

# Start the React frontend
echo -e "\nStarting React frontend..."
cd "$SCRIPT_DIR/react-amplify-nim-demo"

# Update the .env file with the correct backend port
cat > .env << EOL
REACT_APP_RIVA_API_ENDPOINT=http://localhost:${FLASK_PORT}
EOL

# Start React in the foreground
echo -e "\n✅ Starting React frontend"
echo -e "   Frontend URL: http://localhost:${REACT_PORT}"
echo -e "\nPress Ctrl+C to stop all services\n"

npm start

# Cleanup on exit (this will be called when npm start is terminated)
cleanup