import os
import sys

# Ensure current directory is in sys.path
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from flask import Flask, send_from_directory, jsonify
from flask_cors import CORS

try:
    from .config import Config
    from .database import init_db
except ImportError:
    from config import Config
    from database import init_db


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Enable CORS for Flutter mobile client and web previews
    CORS(app, resources={r"/*": {"origins": "*"}})

    # Ensure uploads directory exists
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

    # Static file serving for uploaded disaster images
    @app.route('/uploads/<filename>', methods=['GET'])
    def uploaded_file(filename):
        return send_from_directory(
            app.config['UPLOAD_FOLDER'],
            filename
        )

    # Root & Health Check endpoints
    @app.route('/', methods=['GET'])
    def root():
        return jsonify({
            'project': 'AI-Based Disaster Response Assistant API',
            'version': '1.0.0',
            'status': 'Online',
            'ml_model': 'Decision Tree Classifier (Scikit-Learn)',
            'endpoints': {
                'auth': '/api/auth',
                'disaster_reports': '/api/disaster',
                'rescue_teams': '/api/rescue',
                'shelters': '/api/shelters',
                'medical_assistance': '/api/medical',
                'relief_resources': '/api/resources',
                'disaster_map': '/api/map',
                'notifications': '/api/notifications',
                'dashboard_summary': '/api/dashboard/summary',
                'emergency_contacts': '/api/emergency-contacts'
            }
        }), 200

    @app.route('/api/health', methods=['GET'])
    def health():
        return jsonify({
            'status': 'healthy',
            'service': 'AI Disaster Response Backend'
        }), 200

    # Register API Blueprints with flexible imports
    try:
        from .routes.auth_routes import auth_bp
        from .routes.disaster_routes import disaster_bp
        from .routes.rescue_routes import rescue_bp
        from .routes.shelter_routes import shelter_bp
        from .routes.medical_routes import medical_bp
        from .routes.resource_routes import resource_bp
        from .routes.map_routes import map_bp
        from .routes.notification_routes import notification_bp
        from .routes.admin_routes import admin_bp
        from .routes.emergency_contacts_routes import emergency_contacts_bp

    except ImportError:
        from routes.auth_routes import auth_bp
        from routes.disaster_routes import disaster_bp
        from routes.rescue_routes import rescue_bp
        from routes.shelter_routes import shelter_bp
        from routes.medical_routes import medical_bp
        from routes.resource_routes import resource_bp
        from routes.map_routes import map_bp
        from routes.notification_routes import notification_bp
        from routes.admin_routes import admin_bp
        from routes.emergency_contacts_routes import emergency_contacts_bp

    # Register API Blueprints
    app.register_blueprint(
        auth_bp,
        url_prefix='/api/auth'
    )

    app.register_blueprint(
        disaster_bp,
        url_prefix='/api/disaster'
    )

    app.register_blueprint(
        rescue_bp,
        url_prefix='/api/rescue'
    )

    app.register_blueprint(
        shelter_bp,
        url_prefix='/api/shelters'
    )

    app.register_blueprint(
        medical_bp,
        url_prefix='/api/medical'
    )

    app.register_blueprint(
        resource_bp,
        url_prefix='/api/resources'
    )

    app.register_blueprint(
        map_bp,
        url_prefix='/api/map'
    )

    app.register_blueprint(
        notification_bp,
        url_prefix='/api/notifications'
    )

    app.register_blueprint(
        admin_bp,
        url_prefix='/api/dashboard'
    )

    # Emergency Contacts API
    app.register_blueprint(
        emergency_contacts_bp,
        url_prefix='/api/emergency-contacts'
    )

    # Global Error Handlers
    @app.errorhandler(404)
    def not_found_error(error):
        return jsonify({
            'success': False,
            'message': 'API endpoint not found'
        }), 404

    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({
            'success': False,
            'message': 'Internal server error'
        }), 500

    # Initialize and seed database
    with app.app_context():
        init_db()

    return app


app = create_app()


if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )