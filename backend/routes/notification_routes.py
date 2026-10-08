from flask import Blueprint, request, jsonify

try:
    from ..database import get_session
    from ..models import Notification
except ImportError:
    from database import get_session
    from models import Notification

notification_bp = Blueprint('notification_bp', __name__)

@notification_bp.route('', methods=['GET'], strict_slashes=False)
@notification_bp.route('/', methods=['GET'], strict_slashes=False)
def get_notifications():
    user_id = request.args.get('user_id', type=int)
    session = get_session()
    try:
        query = session.query(Notification)
        if user_id:
            query = query.filter((Notification.user_id == user_id) | (Notification.user_id.is_(None)))
        
        notifications = query.order_by(Notification.created_at.desc()).limit(50).all()
        unread_count = sum(1 for n in notifications if not n.is_read)

        return jsonify({
            'success': True,
            'unread_count': unread_count,
            'count': len(notifications),
            'notifications': [n.to_dict() for n in notifications]
        }), 200
    finally:
        session.close()

@notification_bp.route('/<int:notif_id>/read', methods=['PATCH'], strict_slashes=False)
def mark_notification_read(notif_id):
    session = get_session()
    try:
        notif = session.query(Notification).filter(Notification.id == notif_id).first()
        if not notif:
            return jsonify({'success': False, 'message': 'Notification not found.'}), 404

        notif.is_read = True
        session.commit()
        return jsonify({'success': True, 'message': 'Notification marked as read.'}), 200
    finally:
        session.close()

@notification_bp.route('/read-all', methods=['PATCH'], strict_slashes=False)
def mark_all_read():
    user_id = request.args.get('user_id', type=int)
    session = get_session()
    try:
        query = session.query(Notification).filter(Notification.is_read == False)
        if user_id:
            query = query.filter((Notification.user_id == user_id) | (Notification.user_id.is_(None)))

        query.update({'is_read': True}, synchronize_session=False)
        session.commit()
        return jsonify({'success': True, 'message': 'All notifications marked as read.'}), 200
    finally:
        session.close()
