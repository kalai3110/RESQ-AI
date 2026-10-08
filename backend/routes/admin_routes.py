from flask import Blueprint, jsonify

try:
    from ..database import get_session
    from ..models import (
        DisasterReport, RescueTeam, Shelter, MedicalRequest, ReliefResource, User
    )
except ImportError:
    from database import get_session
    from models import (
        DisasterReport, RescueTeam, Shelter, MedicalRequest, ReliefResource, User
    )

admin_bp = Blueprint('admin_bp', __name__)

@admin_bp.route('/summary', methods=['GET'])
def get_dashboard_summary():
    session = get_session()
    try:
        reports = session.query(DisasterReport).all()
        total_reports = len(reports)
        critical_cases = sum(1 for r in reports if r.severity == 'CRITICAL' or r.priority == 'P1')
        high_priority_cases = sum(1 for r in reports if r.severity == 'HIGH' or r.priority == 'P2')
        medium_cases = sum(1 for r in reports if r.severity == 'MEDIUM' or r.priority == 'P3')
        low_cases = sum(1 for r in reports if r.severity == 'LOW' or r.priority == 'P4')
        
        people_affected = sum(r.people_affected for r in reports)
        total_injured = sum(r.injured for r in reports)
        total_missing = sum(r.missing for r in reports)
        immediate_help_total = sum(r.immediate_help_required for r in reports)

        teams = session.query(RescueTeam).all()
        total_teams = len(teams)
        active_teams = sum(1 for t in teams if t.status in ['Assigned', 'Preparing', 'On the Way', 'Reached'])
        available_teams = sum(1 for t in teams if t.status == 'Available')

        shelters = session.query(Shelter).all()
        total_shelters = len(shelters)
        available_shelters = sum(1 for s in shelters if s.status in ['Available', 'Limited'])
        total_shelter_capacity = sum(s.capacity for s in shelters)
        total_shelter_occupied = sum(s.occupied for s in shelters)
        total_shelter_available = sum(s.available for s in shelters)

        med_requests = session.query(MedicalRequest).all()
        total_med_requests = len(med_requests)
        pending_med_requests = sum(1 for m in med_requests if m.status in ['Requested', 'Assigned', 'On the Way'])
        ambulance_requests = sum(1 for m in med_requests if m.ambulance_required)

        resources = session.query(ReliefResource).all()
        total_resource_items = len(resources)
        available_resources = sum(1 for res in resources if res.status == 'Available')
        low_resources = sum(1 for res in resources if res.status in ['Low', 'Limited', 'Out of Stock'])

        return jsonify({
            'success': True,
            'summary': {
                'total_disaster_reports': total_reports,
                'critical_cases': critical_cases,
                'high_priority_cases': high_priority_cases,
                'medium_cases': medium_cases,
                'low_cases': low_cases,
                'people_affected': people_affected,
                'total_injured': total_injured,
                'total_missing': total_missing,
                'immediate_help_total': immediate_help_total,
                'active_rescue_teams': active_teams,
                'available_rescue_teams': available_teams,
                'total_rescue_teams': total_teams,
                'available_shelters': available_shelters,
                'total_shelters': total_shelters,
                'shelter_seats_available': total_shelter_available,
                'shelter_seats_capacity': total_shelter_capacity,
                'medical_assistance_required': pending_med_requests,
                'total_medical_requests': total_med_requests,
                'ambulance_requests': ambulance_requests,
                'relief_resources_count': total_resource_items,
                'available_resources_count': available_resources,
                'low_resources_count': low_resources
            }
        }), 200
    finally:
        session.close()
