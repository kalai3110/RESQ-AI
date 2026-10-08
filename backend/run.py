import os
import sys

# Ensure backend root is in Python module search path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import app

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print("=" * 60)
    print("🚀 Starting AI-Based Disaster Response Assistant Backend")
    print(f"📡 API Server: http://localhost:{port} / http://0.0.0.0:{port}")
    print("=" * 60)
    app.run(host='0.0.0.0', port=port, debug=False)
