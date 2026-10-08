from flask import Blueprint, request, jsonify

try:
    from ..database import get_session
    from ..models import ReliefResource, Notification
except ImportError:
    from database import get_session
    from models import ReliefResource, Notification

resource_bp = Blueprint('resource_bp', __name__)

@resource_bp.route('', methods=['GET'], strict_slashes=False)
@resource_bp.route('/', methods=['GET'], strict_slashes=False)
def get_resources():
    category = request.args.get('category')
    status = request.args.get('status')

    session = get_session()
    try:
        query = session.query(ReliefResource)
        if category:
            query = query.filter(ReliefResource.category.ilike(f"%{category}%"))
        if status:
            query = query.filter(ReliefResource.status == status)

        resources = query.order_by(ReliefResource.quantity.desc()).all()
        return jsonify({
            'success': True,
            'count': len(resources),
            'resources': [r.to_dict() for r in resources]
        }), 200
    finally:
        session.close()

@resource_bp.route('/<int:resource_id>', methods=['PATCH'], strict_slashes=False)
def update_resource(resource_id):
    data = request.get_json(silent=True) or {}
    session = get_session()
    try:
        res = session.query(ReliefResource).filter(ReliefResource.id == resource_id).first()
        if not res:
            return jsonify({'success': False, 'message': 'Relief resource not found.'}), 404

        if 'quantity' in data:
            res.quantity = max(0, int(data['quantity']))
        if 'location' in data:
            res.location = data['location'].strip()

        res.calculate_status()

        notif = Notification(
            user_id=None,
            title='📦 Relief Resource Updated',
            message=f"{res.resource_name} inventory updated to {res.quantity} {res.unit}. Current Status: {res.status}.",
            notification_type='resource_update',
            report_id=None
        )
        session.add(notif)
        session.commit()

        return jsonify({
            'success': True,
            'message': 'Resource quantity and status updated.',
            'resource': res.to_dict()
        }), 200
    except Exception as e:
        session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        session.close()

@resource_bp.route('', methods=['POST'], strict_slashes=False)
@resource_bp.route('/', methods=['POST'], strict_slashes=False)
def add_resource():
    data = request.get_json(silent=True) or {}
    name = data.get('resource_name', '').strip()
    category = data.get('category', 'Supplies').strip()
    quantity = int(data.get('quantity', 100))
    unit = data.get('unit', 'units').strip()
    location = data.get('location', 'Central Depot').strip()

    if not name:
        return jsonify({'success': False, 'message': 'resource_name is required.'}), 400

    session = get_session()
    try:
        new_res = ReliefResource(
            resource_name=name,
            category=category,
            quantity=quantity,
            unit=unit,
            location=location
        )
        new_res.calculate_status()
        session.add(new_res)
        session.commit()

        return jsonify({
            'success': True,
            'message': 'Relief resource added.',
            'resource': new_res.to_dict()
        }), 201
    except Exception as e:
        session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        session.close()
