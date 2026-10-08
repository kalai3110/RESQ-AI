from flask import Blueprint, jsonify

try:
    from ..database import get_session
    from ..models import DisasterReport, Shelter, RescueTeam
except ImportError:
    from database import get_session
    from models import DisasterReport, Shelter, RescueTeam

map_bp = Blueprint('map_bp', __name__)

SEVERITY_COLORS = {
    'LOW': '#43A047',
    'MEDIUM': '#FFB300',
    'HIGH': '#FB8C00',
    'CRITICAL': '#E53935'
}

@map_bp.route('/disasters', methods=['GET'])
def get_map_disasters():
    session = get_session()
    try:
        reports = session.query(DisasterReport).filter(
            DisasterReport.latitude.isnot(None),
            DisasterReport.longitude.isnot(None)
        ).all()

        shelters = session.query(Shelter).filter(
            Shelter.latitude.isnot(None),
            Shelter.longitude.isnot(None)
        ).all()

        marker_list = []
        for r in reports:
            assigned_team = r.rescue_teams[0] if r.rescue_teams else None
            team_status_str = f"{assigned_team.team_name} ({assigned_team.status})" if assigned_team else "Pending Assignment"

            district_shelters = [s for s in shelters if s.district.lower() == r.district.lower()]
            shelter_summary = f"{len(district_shelters)} shelters ({sum(s.available for s in district_shelters)} seats available)" if district_shelters else "No nearby shelters"

            marker_list.append({
                'id': r.id,
                'report_id': f"DR-{r.id}",
                'disaster_type': r.disaster_type,
                'location': f"{r.area}, {r.district}",
                'address': r.address,
                'latitude': r.latitude,
                'longitude': r.longitude,
                'people_affected': r.people_affected,
                'injured': r.injured,
                'missing': r.missing,
                'damage_level': r.damage_level,
                'severity': r.severity,
                'priority': r.priority,
                'status': r.status,
                'color': SEVERITY_COLORS.get(r.severity, '#FB8C00'),
                'rescue_team_status': team_status_str,
                'shelter_availability': shelter_summary,
                'created_at': r.created_at.isoformat() if r.created_at else None
            })

        shelter_pins = [{
            'id': s.id,
            'name': s.shelter_name,
            'location': s.location,
            'district': s.district,
            'latitude': s.latitude,
            'longitude': s.longitude,
            'capacity': s.capacity,
            'occupied': s.occupied,
            'available': s.available,
            'status': s.status,
            'food_available': bool(s.food_available),
            'water_available': bool(s.water_available),
            'medical_available': bool(s.medical_available)
        } for s in shelters]

        return jsonify({
            'success': True,
            'count': len(marker_list),
            'disaster_markers': marker_list,
            'shelter_markers': shelter_pins
        }), 200
    finally:
        session.close()
