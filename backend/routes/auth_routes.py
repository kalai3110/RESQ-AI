import datetime
from flask import Blueprint, request, jsonify

try:
    from ..database import get_session
    from ..models import User
except ImportError:
    from database import get_session
    from models import User

auth_bp = Blueprint('auth_bp', __name__)

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json(silent=True) or {}

    email = data.get('email', '').strip().lower()
    password = data.get('password', '')

    if not email or not password:
        return jsonify({
            'success': False,
            'message': 'Email and password are required.'
        }), 400

    session = get_session()

    try:
        user = session.query(User).filter(
            User.email == email
        ).first()

        if not user:
            return jsonify({
                'success': False,
                'message': 'Invalid email or password.'
            }), 401

        if not user.check_password(password):
            return jsonify({
                'success': False,
                'message': 'Invalid email or password.'
            }), 401

        # Create user response
        user_dict = user.to_dict()

        # Debug
        print("========== LOGIN DEBUG ==========")
        print("USER ID:", user.id)
        print("USER EMAIL:", user.email)
        print("USER ROLE:", user.role)
        print("RESCUE TEAM ID:", user.rescue_team_id)
        print("=================================")

        return jsonify({
            'success': True,
            'message': 'Login successful.',
            'user': user_dict,
            'rescue_team_id': user.rescue_team_id,
            'token': f"token-{user.id}-{datetime.datetime.utcnow().timestamp()}"
        }), 200

    finally:
        session.close()

@auth_bp.route('/google-login', methods=['POST'])
def google_login():
    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip().lower()
    name = data.get('name', '').strip() or 'Google User'
    firebase_uid = data.get('firebase_uid', '')
    role = data.get('role', 'citizen')

    if not email:
        return jsonify({
            'success': False,
            'message': 'Google email is required.'
        }), 400

    session = get_session()
    try:
        user = session.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                name=name,
                email=email,
                role=role,
                firebase_uid=firebase_uid
            )
            user.set_password(f"google-oauth-{email}")
            session.add(user)
            session.commit()
        else:
            if firebase_uid and not user.firebase_uid:
                user.firebase_uid = firebase_uid
                session.commit()

        user_dict = user.to_dict()
        return jsonify({
            'success': True,
            'message': 'Google authentication successful.',
            'user': user_dict,
            'token': f"google-token-{user.id}-{datetime.datetime.utcnow().timestamp()}"
        }), 200
    except Exception as e:
        session.rollback()
        return jsonify({
            'success': False,
            'message': f'Google Sign-In failed: {str(e)}'
        }), 500
    finally:
        session.close()

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json(silent=True) or {}
    name = data.get('name', '').strip()
    email = data.get('email', '').strip().lower()
    password = data.get('password', '')
    role = data.get('role', 'citizen').strip().lower()
    phone = data.get('phone', '').strip()

    if not name or not email or not password:
        return jsonify({
            'success': False,
            'message': 'Name, email, and password are required.'
        }), 400

    if len(password) < 6:
        return jsonify({
            'success': False,
            'message': 'Password must be at least 6 characters.'
        }), 400

    if role not in ['citizen', 'rescue', 'admin']:
        role = 'citizen'

    session = get_session()
    try:
        existing = session.query(User).filter(User.email == email).first()
        if existing:
            return jsonify({
                'success': False,
                'message': 'An account with this email already exists.'
            }), 409

        new_user = User(
            name=name,
            email=email,
            role=role,
            phone=phone
        )
        new_user.set_password(password)
        session.add(new_user)
        session.commit()

        return jsonify({
            'success': True,
            'message': 'Account registered successfully.',
            'user': new_user.to_dict(),
            'token': f"token-{new_user.id}-{datetime.datetime.utcnow().timestamp()}"
        }), 201
    except Exception as e:
        session.rollback()
        return jsonify({
            'success': False,
            'message': f'Registration failed: {str(e)}'
        }), 500
    finally:
        session.close()

@auth_bp.route('/profile', methods=['GET'])
def get_profile():
    user_id = request.args.get('user_id', type=int)
    if not user_id:
        return jsonify({'success': False, 'message': 'user_id is required.'}), 400

    session = get_session()
    try:
        user = session.query(User).filter(User.id == user_id).first()
        if not user:
            return jsonify({'success': False, 'message': 'User not found.'}), 404
        return jsonify({'success': True, 'user': user.to_dict()}), 200
    finally:
        session.close()
