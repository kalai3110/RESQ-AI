from flask import Blueprint, request, jsonify

try:
    from ..database import get_session
    from ..models import (
        Shelter,
        Notification,
        ShelterAssignment,
        DisasterReport,
        RescueTeam,
        User
    )
except ImportError:
    from database import get_session
    from models import (
        Shelter,
        Notification,
        ShelterAssignment,
        DisasterReport,
        RescueTeam,
        User
    )

shelter_bp = Blueprint('shelter_bp', __name__)
@shelter_bp.route('', methods=['GET'], strict_slashes=False)
@shelter_bp.route('/', methods=['GET'], strict_slashes=False)
def get_shelters():
    district = request.args.get('district')
    status = request.args.get('status')

    session = get_session()
    try:
        query = session.query(Shelter)
        if district:
            query = query.filter(Shelter.district.ilike(f"%{district}%"))
        if status:
            query = query.filter(Shelter.status == status)

        shelters = query.order_by(Shelter.available.desc()).all()
        return jsonify({
            'success': True,
            'count': len(shelters),
            'shelters': [s.to_dict() for s in shelters]
        }), 200
    finally:
        session.close()

@shelter_bp.route('/<int:shelter_id>', methods=['GET'], strict_slashes=False)
def get_shelter_by_id(shelter_id):
    session = get_session()
    try:
        shelter = session.query(Shelter).filter(Shelter.id == shelter_id).first()
        if not shelter:
            return jsonify({'success': False, 'message': 'Shelter not found.'}), 404
        return jsonify({'success': True, 'shelter': shelter.to_dict()}), 200
    finally:
        session.close()

@shelter_bp.route('/<int:shelter_id>', methods=['PATCH'], strict_slashes=False)
def update_shelter(shelter_id):
    data = request.get_json(silent=True) or {}
    session = get_session()
    try:
        shelter = session.query(Shelter).filter(Shelter.id == shelter_id).first()
        if not shelter:
            return jsonify({'success': False, 'message': 'Shelter not found.'}), 404

        if 'capacity' in data:
            shelter.capacity = max(1, int(data['capacity']))
        if 'occupied' in data:
            shelter.occupied = min(shelter.capacity, max(0, int(data['occupied'])))
        if 'food_available' in data:
            shelter.food_available = bool(data['food_available'])
        if 'water_available' in data:
            shelter.water_available = bool(data['water_available'])
        if 'medical_available' in data:
            shelter.medical_available = bool(data['medical_available'])

        shelter.calculate_status()

        notif = Notification(
            user_id=None,
            title='🏕️ Shelter Availability Updated',
            message=f"{shelter.shelter_name} ({shelter.district}) updated: {shelter.available} available seats remaining. Status: {shelter.status}.",
            notification_type='shelter_update',
            report_id=None
        )
        session.add(notif)
        session.commit()

        return jsonify({
            'success': True,
            'message': 'Shelter information updated successfully.',
            'shelter': shelter.to_dict()
        }), 200
    except Exception as e:
        session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        session.close()

@shelter_bp.route('', methods=['POST'], strict_slashes=False)
@shelter_bp.route('/', methods=['POST'], strict_slashes=False)
def add_shelter():
    data = request.get_json(silent=True) or {}
    name = data.get('shelter_name', '').strip()
    loc = data.get('location', '').strip()
    district = data.get('district', '').strip()
    capacity = int(data.get('capacity', 200))
    occupied = int(data.get('occupied', 0))

    if not name or not loc or not district:
        return jsonify({'success': False, 'message': 'shelter_name, location, and district are required.'}), 400

    session = get_session()
    try:
        new_shelter = Shelter(
            shelter_name=name,
            location=loc,
            district=district,
            address=data.get('address', ''),
            capacity=capacity,
            occupied=occupied,
            available=max(0, capacity - occupied),
            food_available=bool(data.get('food_available', True)),
            water_available=bool(data.get('water_available', True)),
            medical_available=bool(data.get('medical_available', True)),
            contact_person=data.get('contact_person', ''),
            contact_phone=data.get('contact_phone', '')
        )
        new_shelter.calculate_status()
        session.add(new_shelter)
        session.commit()

        return jsonify({
            'success': True,
            'message': 'New relief shelter added.',
            'shelter': new_shelter.to_dict()
        }), 201
    except Exception as e:
        session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        session.close()

# ============================================================
# ASSIGN EVACUEES TO SHELTER
# ============================================================

@shelter_bp.route('/assign', methods=['POST'], strict_slashes=False)
def assign_evacuees_to_shelter():
    data = request.get_json(silent=True) or {}

    report_id = data.get('report_id')
    shelter_id = data.get('shelter_id')
    evacuee_count = data.get('evacuee_count')

    if not report_id or not shelter_id or evacuee_count is None:
        return jsonify({
            'success': False,
            'message': 'report_id, shelter_id and evacuee_count are required.'
        }), 400

    try:
        report_id = int(report_id)
        shelter_id = int(shelter_id)
        evacuee_count = int(evacuee_count)
    except (TypeError, ValueError):
        return jsonify({
            'success': False,
            'message': 'report_id, shelter_id and evacuee_count must be valid numbers.'
        }), 400

    if evacuee_count <= 0:
        return jsonify({
            'success': False,
            'message': 'Evacuee count must be greater than 0.'
        }), 400

    session = get_session()

    try:
        # ----------------------------------------------------
        # GET REPORT
        # ----------------------------------------------------
        report = (
            session.query(DisasterReport)
            .filter(DisasterReport.id == report_id)
            .first()
        )

        if not report:
            return jsonify({
                'success': False,
                'message': 'Disaster report not found.'
            }), 404

        # ----------------------------------------------------
        # GET SHELTER
        # ----------------------------------------------------
        shelter = (
            session.query(Shelter)
            .filter(Shelter.id == shelter_id)
            .first()
        )

        if not shelter:
            return jsonify({
                'success': False,
                'message': 'Shelter not found.'
            }), 404

        # ----------------------------------------------------
        # FIND RESCUE TEAM ASSIGNED TO THIS REPORT
        # ----------------------------------------------------
        team = (
            session.query(RescueTeam)
            .filter(
                RescueTeam.assigned_report_id == report.id
            )
            .first()
        )

        # ----------------------------------------------------
        # ALREADY SHELTERED FROM THIS REPORT
        # ----------------------------------------------------
        already_sheltered = (
            session.query(ShelterAssignment)
            .filter(
                ShelterAssignment.report_id == report.id
            )
            .all()
        )

        already_count = sum(
            assignment.evacuee_count
            for assignment in already_sheltered
        )

        remaining_people = max(
            0,
            report.people_affected - already_count
        )

        # ----------------------------------------------------
        # VALIDATE REPORT PEOPLE
        # ----------------------------------------------------
        if evacuee_count > remaining_people:
            return jsonify({
                'success': False,
                'message': (
                    f'Only {remaining_people} people remain '
                    f'available for shelter assignment.'
                )
            }), 400

        # ----------------------------------------------------
        # VALIDATE SHELTER CAPACITY
        # ----------------------------------------------------
        if evacuee_count > shelter.available:
            return jsonify({
                'success': False,
                'message': (
                    f'Shelter has only {shelter.available} '
                    f'available spaces.'
                )
            }), 400

        # ----------------------------------------------------
        # CREATE ASSIGNMENT
        # ----------------------------------------------------
        assignment = ShelterAssignment(
            report_id=report.id,
            team_id=team.id if team else None,
            shelter_id=shelter.id,
            evacuee_count=evacuee_count
        )

        session.add(assignment)

        # ----------------------------------------------------
        # UPDATE SHELTER OCCUPANCY
        # ----------------------------------------------------
        shelter.occupied += evacuee_count
        shelter.calculate_status()

        # ============================================================
        # NOTIFY RESCUE TEAM ABOUT SHELTER DESTINATION
        # ============================================================

        if team:
            team_user = (
                session.query(User)
                .filter(
                    User.rescue_team_id == team.id
                )
                .first()
            )

            if team_user:
                shelter_notification = Notification(
                    user_id=team_user.id,
                    title='Evacuation Shelter Assigned',
                    message=(
                        f'Evacuate {evacuee_count} people from '
                        f'Report #{report.id} to '
                        f'{shelter.shelter_name}. '
                        f'Address: {shelter.address or shelter.location}'
                    ),
                    notification_type='shelter_assigned',
                    report_id=report.id,
                    is_read=False
                )

                session.add(shelter_notification)

        session.commit()

        return jsonify({
            'success': True,
            'message': 'Evacuees assigned to shelter successfully.',
            'assignment': assignment.to_dict(),
            'report': {
                'id': report.id,
                'report_id': f'DR-{report.id}',
                'disaster_type': report.disaster_type,
                'district': report.district,
                'people_affected': report.people_affected
            },
            'team': (
                {
                    'id': team.id,
                    'team_name': team.team_name
                }
                if team
                else None
            ),
            'shelter': shelter.to_dict(),
            'remaining_people': remaining_people - evacuee_count
        }), 201

    except Exception as e:
        session.rollback()

        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

    finally:
        session.close()