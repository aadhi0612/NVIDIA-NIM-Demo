from flask import Flask, request, jsonify
from flask_cors import CORS
import subprocess
import os
import logging
import socket
from datetime import datetime

app = Flask(__name__)
# Configure CORS more explicitly
CORS(app, resources={
    r"/*": {
        "origins": ["http://localhost:3007"],
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "Origin"]
    }
})

# Enhanced logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('flask_app.log')
    ]
)
logger = logging.getLogger(__name__)

# Get the absolute path to the Riva directory
RIVA_DIR = "/home/ubuntu/NVIDIA-AI"

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

@app.route('/translate', methods=['POST', 'OPTIONS'])
def translate():
    if request.method == 'OPTIONS':
        return '', 204

    try:
        logger.info("=== New Translation Request ===")
        logger.info(f"Time: {datetime.now()}")
        logger.info(f"Headers: {dict(request.headers)}")
        
        data = request.json
        logger.info(f"Request data: {data}")

        text = data.get('text')
        source_lang = data.get('source_language_code')
        target_lang = data.get('target_language_code')

        # Verify Riva directory exists
        if not os.path.exists(RIVA_DIR):
            logger.error(f"Riva directory not found: {RIVA_DIR}")
            return jsonify({'error': 'Riva directory not found'}), 500

        # Verify script exists
        # script_path = os.path.join(RIVA_DIR, 'python-clients/scripts/nmt/nmt.py')
        script_path = os.path.join(RIVA_DIR, 'backend/nmt.py')
        if not os.path.exists(script_path):
            logger.error(f"NMT script not found: {script_path}")
            return jsonify({'error': 'NMT script not found'}), 500

        # Construct command
        cmd = [
            'python3',
            script_path,
            '--server', '0.0.0.0:50051',
            '--text', text,
            '--source-language-code', source_lang,
            '--target-language-code', target_lang
        ]

        logger.info(f"Executing command: {' '.join(cmd)}")

        # Execute command with timeout
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=RIVA_DIR,
            timeout=30  # 30 seconds timeout
        )

        logger.info(f"Command return code: {result.returncode}")
        logger.info(f"Command stdout: {result.stdout}")
        logger.info(f"Command stderr: {result.stderr}")

        if result.returncode == 0:
            translated_text = result.stdout.strip()
            logger.info(f"Translation successful: {translated_text}")
            response = jsonify({'translated_text': translated_text})
            
            # Add CORS headers explicitly
            response.headers.add('Access-Control-Allow-Origin', 'http://localhost:3007')
            response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
            response.headers.add('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
            
            return response
        else:
            logger.error(f"Translation failed with return code {result.returncode}")
            return jsonify({'error': result.stderr.strip()}), 400

    except subprocess.TimeoutExpired:
        logger.error("Translation process timed out")
        return jsonify({'error': 'Translation process timed out'}), 504
    except Exception as e:
        logger.error(f"Exception occurred: {str(e)}", exc_info=True)
        return jsonify({'error': str(e)}), 500

@app.route('/')
def health_check():
    logger.info("Health check endpoint called")
    return jsonify({'status': 'healthy'}), 200

@app.route('/debug/port')
def debug_port():
    current_port = request.environ.get('SERVER_PORT')
    logger.info(f"Current server port: {current_port}")
    return jsonify({
        'port': current_port,
        'env_port': os.environ.get('PORT'),
        'server_name': request.environ.get('SERVER_NAME')
    })

if __name__ == '__main__':
    port = 5007  # Fixed port
    logger.info(f"Starting server on port {port}")
    logger.info(f"RIVA_DIR: {RIVA_DIR}")
    # logger.info(f"Script path: {os.path.join(RIVA_DIR, 'python-clients/scripts/nmt/nmt.py')}")
    logger.info(f"Script path: {os.path.join(RIVA_DIR, 'backend/nmt.py')}")
    app.run(host='0.0.0.0', port=port, debug=True)