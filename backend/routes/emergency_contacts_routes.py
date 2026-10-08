from flask import Blueprint, jsonify

try:
    from ..database import get_session
    from ..models import EmergencyContact
except ImportError:
    from database import get_session
    from models import EmergencyContact


emergency_contacts_bp = Blueprint(
    'emergency_contacts',
    __name__
)


@emergency_contacts_bp.route('', methods=['GET'])
def get_emergency_contacts():
    session = get_session()

    try:
        contacts = (
            session.query(EmergencyContact)
            .order_by(EmergencyContact.id)
            .all()
        )

        return jsonify({
            'success': True,
            'count': len(contacts),
            'contacts': [
                contact.to_dict()
                for contact in contacts
            ]
        }), 200

    except Exception as e:
        return jsonify({
            'success': False,
            'message': 'Failed to load emergency contacts',
            'error': str(e)
        }), 500

    finally:
        session.close()