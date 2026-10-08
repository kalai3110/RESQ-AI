import os
import uuid

import jwt
from werkzeug.utils import secure_filename
from flask import Blueprint, request, jsonify, current_app

try:
    from ..database import get_session
    from ..models import (
        DisasterReport,
        User,
        RescueTeam,
        MedicalRequest,
        Notification,
        Shelter
    )
    from ..ml.disaster_decision_tree import disaster_predictor
    from ..config import Config
except ImportError:
    from database import get_session
    from models import (
        DisasterReport,
        User,
        RescueTeam,
        MedicalRequest,
        Notification,
        Shelter
    )
    from ml.disaster_decision_tree import disaster_predictor
    from config import Config


disaster_bp = Blueprint('disaster_bp', __name__)


# ============================================================
# DISTRICT COORDINATES
# ============================================================

DISTRICT_COORDS = {
    'madurai': (9.9252, 78.1198),
    'chennai': (13.0827, 80.2707),
    'cuddalore': (11.7480, 79.7714),
    'nilgiris': (11.4102, 76.6950),
    'salem': (11.6643, 78.1460),
    'coimbatore': (11.0168, 76.9558),
    'tiruchirappalli': (10.7905, 78.7047),
    'trichy': (10.7905, 78.7047),
    'tirunelveli': (8.7139, 77.7567),
    'kanyakumari': (8.0883, 77.5385),
    'thanjavur': (10.7870, 79.1378),
    'vellore': (12.9165, 79.1325),
    'erode': (11.3410, 77.7172),
    'dindigul': (10.3673, 77.9803)
}


# ============================================================
# APPROXIMATE COORDINATES
# ============================================================

def get_approx_coordinates(district, area=''):

    dist_key = district.strip().lower() if district else ''

    if dist_key in DISTRICT_COORDS:

        base_lat, base_lng = DISTRICT_COORDS[dist_key]

        # Area is optional now.
        # If area is empty, use district centre coordinates.
        if area and area.strip():

            area_hash = hash(area) % 100

            jitter_lat = (
                area_hash - 50
            ) * 0.0008

            jitter_lng = (
                (hash(area * 2) % 100) - 50
            ) * 0.0008

            return (
                round(base_lat + jitter_lat, 6),
                round(base_lng + jitter_lng, 6)
            )

        return (
            round(base_lat, 6),
            round(base_lng, 6)
        )

    # Default coordinates
    return (9.9252, 78.1198)


# ============================================================
# JWT SECRET
# ============================================================

def get_jwt_secret():

    try:
        secret = current_app.config.get(
            'SECRET_KEY'
        )

        if secret:
            return secret

    except Exception:
        pass

    try:
        secret = getattr(
            Config,
            'SECRET_KEY',
            None
        )

        if secret:
            return secret

    except Exception:
        pass

    secret = os.environ.get(
        'DISASTERAI_SECRET'
    )

    if secret:
        return secret

    return 'change-this-development-secret'


# ============================================================
# GET USER ID FROM JWT
# ============================================================

def get_logged_in_user_id():

    auth_header = request.headers.get(
        'Authorization',
        ''
    )

    if not auth_header:
        return None

    if not auth_header.startswith('Bearer '):
        return None

    token = auth_header.replace(
        'Bearer ',
        '',
        1
    ).strip()

    if not token:
        return None

    try:

        secret = get_jwt_secret()

        payload = jwt.decode(
            token,
            secret,
            algorithms=['HS256']
        )

        user_id = (
            payload.get('user_id')
            or payload.get('id')
            or payload.get('sub')
        )

        if user_id is None:
            return None

        return int(user_id)

    except Exception:
        return None


# ============================================================
# PREDICT DISASTER SEVERITY
# ============================================================

@disaster_bp.route(
    '/predict',
    methods=['POST']
)
def predict_disaster_severity():

    data = request.get_json(
        silent=True
    ) or {}

    disaster_type = data.get(
        'disaster_type',
        'Flood'
    )

    people_affected = data.get(
        'people_affected',
        0
    )

    injured = data.get(
        'injured',
        0
    )

    missing = data.get(
        'missing',
        0
    )

    immediate_help = data.get(
        'immediate_help_required',
        0
    )

    damage_level = data.get(
        'damage_level',
        'Medium'
    )

    infra_damage = data.get(
        'infrastructure_damage',
        0
    )

    prop_damage = data.get(
        'property_damage',
        0
    )

    prediction = disaster_predictor.predict(
        disaster_type=disaster_type,
        people_affected=people_affected,
        injured=injured,
        missing=missing,
        immediate_help=immediate_help,
        damage_level=damage_level,
        infrastructure_damage=infra_damage,
        property_damage=prop_damage
    )

    return jsonify({
        'success': True,
        'prediction': prediction
    }), 200


# ============================================================
# SUBMIT DISASTER REPORT
# ============================================================

@disaster_bp.route(
    '/report',
    methods=['POST']
)
def submit_disaster_report():

    image_filename = None

    # --------------------------------------------------------
    # MULTIPART FORM DATA
    # --------------------------------------------------------

    if (
        request.content_type
        and
        'multipart/form-data'
        in request.content_type
    ):

        form_data = request.form.to_dict()

        # Keep original working behavior
        user_id = form_data.get(
            'user_id',
            4
        )

        disaster_type = form_data.get(
            'disaster_type',
            'Flood'
        )

        district = form_data.get(
            'district',
            ''
        ).strip()

        # ====================================================
        # AREA IS NOW OPTIONAL
        # ====================================================

        area = form_data.get(
            'area',
            ''
        ).strip()

        address = form_data.get(
            'address',
            ''
        ).strip()

        landmark = form_data.get(
            'landmark',
            ''
        ).strip()

        # ====================================================
        # ADDRESS + LANDMARK
        # ====================================================

        if address and landmark:

            location_address = (
                f"{address} | Landmark: {landmark}"
            )

        elif address:

            location_address = address

        else:

            location_address = landmark

        people_affected = int(
            form_data.get(
                'people_affected',
                form_data.get(
                    'affected_people',
                    0
                )
            ) or 0
        )
        injured = int(
            form_data.get(
                'injured',
                0
            ) or 0
        )

        missing = int(
            form_data.get(
                'missing',
                0
            ) or 0
        )

        immediate_help = int(
            form_data.get(
                'immediate_help_required',
                0
            ) or 0
        )

        property_damage = (
            form_data.get(
                'property_damage',
                'false'
            ).lower()
            in ['true', '1']
        )

        infrastructure_damage = (
            form_data.get(
                'infrastructure_damage',
                'false'
            ).lower()
            in ['true', '1']
        )

        damage_level = form_data.get(
            'damage_level',
            'Medium'
        )

        description = form_data.get(
            'description',
            ''
        )

        # ----------------------------------------------------
        # IMAGE
        # ----------------------------------------------------

        if 'image' in request.files:

            file = request.files['image']

            if file and file.filename != '':

                ext = (
                    file.filename
                    .rsplit('.', 1)[-1]
                    .lower()
                )

                if ext in Config.ALLOWED_EXTENSIONS:

                    image_filename = (
                        f"disaster_"
                        f"{uuid.uuid4().hex[:10]}."
                        f"{ext}"
                    )

                    os.makedirs(
                        Config.UPLOAD_FOLDER,
                        exist_ok=True
                    )

                    file.save(
                        os.path.join(
                            Config.UPLOAD_FOLDER,
                            image_filename
                        )
                    )

    # --------------------------------------------------------
    # JSON DATA
    # --------------------------------------------------------

    else:

        json_data = (
            request.get_json(
                silent=True
            )
            or {}
        )

        # Keep original working behavior
        user_id = json_data.get(
            'user_id',
            4
        )

        disaster_type = json_data.get(
            'disaster_type',
            'Flood'
        )

        district = json_data.get(
            'district',
            ''
        ).strip()

        # ====================================================
        # AREA IS NOW OPTIONAL
        # ====================================================

        area = json_data.get(
            'area',
            ''
        ).strip()

        address = json_data.get(
            'address',
            ''
        ).strip()

        landmark = json_data.get(
            'landmark',
            ''
        ).strip()

        # ====================================================
        # ADDRESS + LANDMARK
        # ====================================================

        if address and landmark:

            location_address = (
                f"{address} | Landmark: {landmark}"
            )

        elif address:

            location_address = address

        else:

            location_address = landmark

        people_affected = int(
            json_data.get(
                'people_affected',
                json_data.get(
                    'affected_people',
                    0
                )
            ) or 0
        )

        injured = int(
            json_data.get(
                'injured',
                0
            ) or 0
        )

        missing = int(
            json_data.get(
                'missing',
                0
            ) or 0
        )

        immediate_help = int(
            json_data.get(
                'immediate_help_required',
                0
            ) or 0
        )

        property_damage = bool(
            json_data.get(
                'property_damage',
                False
            )
        )

        infrastructure_damage = bool(
            json_data.get(
                'infrastructure_damage',
                False
            )
        )

        damage_level = json_data.get(
            'damage_level',
            'Medium'
        )

        description = json_data.get(
            'description',
            ''
        )

        image_filename = json_data.get(
            'image_url',
            None
        )

    # ========================================================
    # LOCATION VALIDATION
    #
    # AREA IS NOT REQUIRED ANYMORE
    #
    # Required:
    #   1. District
    #   2. Address OR Landmark
    # ========================================================

    if not district or not location_address:

        return jsonify({

            'success': False,

            'message': (
                'Disaster Location '
                '(District and Address / Landmark) '
                'is required.'
            )

        }), 400

    # ========================================================
    # AI PREDICTION
    # ========================================================

    prediction = disaster_predictor.predict(

        disaster_type=disaster_type,

        people_affected=people_affected,

        injured=injured,

        missing=missing,

        immediate_help=immediate_help,

        damage_level=damage_level,

        infrastructure_damage=(
            infrastructure_damage
        ),

        property_damage=(
            property_damage
        )
    )

    predicted_severity = prediction[
        'severity'
    ]

    predicted_priority = prediction[
        'priority'
    ]

    # ========================================================
    # COORDINATES
    # ========================================================

    lat, lng = get_approx_coordinates(
        district,
        area
    )

    # ========================================================
    # DATABASE
    # ========================================================

    session = get_session()

    try:

        report = DisasterReport(

            user_id=int(user_id),

            disaster_type=disaster_type,

            district=district,

            # Area is kept as an empty string when not provided.
            # This preserves compatibility with the existing DB model.
            area=area,

            address=location_address,

            latitude=lat,

            longitude=lng,

            people_affected=people_affected,

            injured=injured,

            missing=missing,

            immediate_help_required=(
                immediate_help
            ),

            property_damage=(
                property_damage
            ),

            infrastructure_damage=(
                infrastructure_damage
            ),

            damage_level=damage_level,

            description=description,

            image_url=image_filename,

            severity=predicted_severity,

            priority=predicted_priority,

            status='Reported'
        )

        session.add(report)

        session.flush()

        # ====================================================
        # MEDICAL REQUEST
        # ====================================================

        if injured > 0:

            med_req = MedicalRequest(

                report_id=report.id,

                injured_count=injured,

                ambulance_required=(
                    True
                    if (
                        injured >= 5
                        or predicted_severity
                        in ['CRITICAL', 'HIGH']
                    )
                    else False
                ),

                first_aid_required=True,

                emergency_treatment_required=(
                    True
                    if predicted_severity
                    == 'CRITICAL'
                    else False
                ),

                medical_required=True,

                status='Requested',

                ambulances_dispatched=(
                    max(1, injured // 8)
                    if predicted_severity
                    in ['CRITICAL', 'HIGH']
                    else 0
                )
            )

            session.add(med_req)

        # ====================================================
        # RESCUE TEAM
        # ====================================================

        assigned_team_name = None


        # ====================================================
        # USER NOTIFICATION
        # ====================================================

        user_notif = Notification(

            user_id=int(user_id),

            title=(
                'Disaster Report '
                'Submitted Successfully'
            ),

            message=(
                f"Report #DR-{report.id} "
                f"({disaster_type}) has been "
                f"registered with AI Severity: "
                f"{predicted_severity} and "
                f"Priority: "
                f"{predicted_priority}."
            ),

            notification_type=(
                'disaster_report'
            ),

            report_id=report.id,

            is_read=False
        )

        session.add(user_notif)

        # ====================================================
        # ADMIN NOTIFICATION
        # ====================================================

        admin_notif = Notification(

            user_id=None,

            title=(
                f"🚨 {predicted_priority} "
                f"Disaster: "
                f"{disaster_type} "
                f"at {district}"
            ),

            message=(
                f"New report in "
                f"{location_address}, "
                f"{district}. "
                f"{people_affected} affected, "
                f"{injured} injured. "
                f"Priority: "
                f"{predicted_priority}."
            ),

            notification_type='admin_alert',

            report_id=report.id,

            is_read=False
        )

        session.add(admin_notif)

        # ====================================================
        # COMMIT
        # ====================================================

        session.commit()

        return jsonify({

            'success': True,

            'message': (
                'Disaster report successfully '
                'registered and analyzed by AI.'
            ),

            'report': report.to_dict(),

            'ai_analysis': prediction,

            'assigned_team': (
                assigned_team_name
            )

        }), 201

    except Exception as e:

        session.rollback()

        return jsonify({

            'success': False,

            'message': (
                'Failed to submit disaster '
                f'report: {str(e)}'
            )

        }), 500

    finally:

        session.close()


# ============================================================
# GET ALL DISASTER REPORTS
# ============================================================

@disaster_bp.route(
    '/reports',
    methods=['GET']
)
def get_disaster_reports():

    district = request.args.get(
        'district'
    )

    severity = request.args.get(
        'severity'
    )

    priority = request.args.get(
        'priority'
    )

    status = request.args.get(
        'status'
    )

    disaster_type = request.args.get(
        'type'
    )

    session = get_session()

    try:

        # ----------------------------------------------------
        # GET ACTIVE REPORTS
        # ----------------------------------------------------

        query = (
            session.query(
                DisasterReport
            )
            .filter(
                DisasterReport.status != 'Resolved'
            )
            .order_by(
                DisasterReport.created_at.desc()
            )
        )

        # ----------------------------------------------------
        # FILTERS
        # ----------------------------------------------------

        if district:

            query = query.filter(
                DisasterReport.district.ilike(
                    f"%{district}%"
                )
            )

        if severity:

            query = query.filter(
                DisasterReport.severity
                == severity.upper()
            )

        if priority:

            query = query.filter(
                DisasterReport.priority
                == priority.upper()
            )

        if status:

            query = query.filter(
                DisasterReport.status
                == status
            )

        if disaster_type:

            query = query.filter(
                DisasterReport.disaster_type.ilike(
                    f"%{disaster_type}%"
                )
            )

        # ----------------------------------------------------
        # GET REPORTS
        # ----------------------------------------------------

        reports = query.all()

        # ====================================================
        # PRIORITY-BASED SORTING
        #
        # P1 = CRITICAL
        # P2 = HIGH
        # P3 = MEDIUM
        # P4 = LOW
        #
        # Same priority:
        # Newest report appears first
        # ====================================================

        priority_order = {
            'P1': 1,
            'P2': 2,
            'P3': 3,
            'P4': 4
        }

        reports = sorted(
            reports,
            key=lambda r: priority_order.get(
                (r.priority or '').upper(),
                99
            )
        )

        # ----------------------------------------------------
        # RESPONSE
        # ----------------------------------------------------

        return jsonify({

            'success': True,

            'count': len(reports),

            'reports': [
                r.to_dict()
                for r in reports
            ]

        }), 200

    finally:

        session.close()

# ============================================================
# GET REPORT DETAIL
# ============================================================

@disaster_bp.route(
    '/reports/<int:report_id>',
    methods=['GET']
)
def get_report_detail(report_id):

    session = get_session()

    try:

        report = (
            session.query(
                DisasterReport
            )
            .filter(
                DisasterReport.id
                == report_id
            )
            .first()
        )

        if not report:

            return jsonify({

                'success': False,

                'message': (
                    'Disaster report '
                    'not found.'
                )

            }), 404

        report_data = report.to_dict()

        shelters = (
            session.query(Shelter)
            .filter(
                Shelter.district.ilike(
                    f"%{report.district}%"
                )
            )
            .all()
        )

        report_data[
            'district_shelters'
        ] = [
            s.to_dict()
            for s in shelters
        ]

        med_reqs = (
            session.query(
                MedicalRequest
            )
            .filter(
                MedicalRequest.report_id
                == report_id
            )
            .all()
        )

        report_data[
            'medical_requests'
        ] = [
            m.to_dict()
            for m in med_reqs
        ]

        teams = (
            session.query(
                RescueTeam
            )
            .filter(
                RescueTeam.assigned_report_id
                == report_id
            )
            .all()
        )

        report_data[
            'rescue_teams'
        ] = [
            t.to_dict()
            for t in teams
        ]

        return jsonify({

            'success': True,

            'report': report_data

        }), 200

    finally:

        session.close()


# ============================================================
# GET MY REPORTS
# ============================================================

@disaster_bp.route(
    '/my-reports',
    methods=['GET']
)
def get_my_reports():

    # First try JWT token
    user_id = get_logged_in_user_id()

    # If JWT is not available,
    # allow query parameter
    if user_id is None:

        user_id = request.args.get(
            'user_id',
            type=int
        )

    if user_id is None:

        return jsonify({

            'success': False,

            'message': (
                'User authentication '
                'is required.'
            )

        }), 401

    session = get_session()

    try:

        reports = (
            session.query(
                DisasterReport
            )
            .filter(
                DisasterReport.user_id
                == user_id
            )
            .order_by(
                DisasterReport.created_at.desc()
            )
            .all()
        )

        return jsonify({

            'success': True,

            'count': len(reports),

            'reports': [
                r.to_dict()
                for r in reports
            ]

        }), 200

    except Exception as e:

        return jsonify({

            'success': False,

            'message': (
                'Failed to load reports: '
                f'{str(e)}'
            )

        }), 500

    finally:

        session.close()


# ============================================================
# UPDATE REPORT STATUS
# ============================================================

@disaster_bp.route(
    '/reports/<int:report_id>/status',
    methods=['PATCH']
)
def update_report_status(report_id):

    data = request.get_json(
        silent=True
    ) or {}

    new_status = data.get(
        'status'
    )

    if not new_status:

        return jsonify({

            'success': False,

            'message': (
                'New status is required.'
            )

        }), 400

    session = get_session()

    try:

        report = (
            session.query(
                DisasterReport
            )
            .filter(
                DisasterReport.id
                == report_id
            )
            .first()
        )

        if not report:

            return jsonify({

                'success': False,

                'message': (
                    'Report not found.'
                )

            }), 404

        report.status = new_status

        notif = Notification(

            user_id=report.user_id,

            title=(
                f"Report #DR-{report.id} "
                f"Status Updated"
            ),

            message=(
                f"The status of your report "
                f"for {report.disaster_type} "
                f"in {report.district} "
                f"is now '{new_status}'."
            ),

            notification_type=(
                'status_update'
            ),

            report_id=report_id
        )

        session.add(notif)

        session.commit()

        return jsonify({

            'success': True,

            'message': (
                'Report status updated '
                'successfully.'
            ),

            'report': report.to_dict()

        }), 200

    except Exception as e:

        session.rollback()

        return jsonify({

            'success': False,

            'message': str(e)

        }), 500

    finally:

        session.close()


# ============================================================
# OVERRIDE REPORT SEVERITY
# ============================================================

@disaster_bp.route(
    '/reports/<int:report_id>/severity',
    methods=['PATCH']
)
def override_report_severity(report_id):

    data = request.get_json(
        silent=True
    ) or {}

    new_severity = (
        data.get(
            'severity',
            ''
        )
        .upper()
    )

    new_priority = (
        data.get(
            'priority',
            ''
        )
        .upper()
    )

    if new_severity not in [
        'LOW',
        'MEDIUM',
        'HIGH',
        'CRITICAL'
    ]:

        return jsonify({

            'success': False,

            'message': (
                'Invalid severity level.'
            )

        }), 400

    priority_map = {

        'CRITICAL': 'P1',

        'HIGH': 'P2',

        'MEDIUM': 'P3',

        'LOW': 'P4'
    }

    if not new_priority:

        new_priority = (
            priority_map[new_severity]
        )

    session = get_session()

    try:

        report = (
            session.query(
                DisasterReport
            )
            .filter(
                DisasterReport.id
                == report_id
            )
            .first()
        )

        if not report:

            return jsonify({

                'success': False,

                'message': (
                    'Report not found.'
                )

            }), 404

        report.severity = (
            new_severity
        )

        report.priority = (
            new_priority
        )

        session.commit()

        return jsonify({

            'success': True,

            'message': (
                'Severity and Priority '
                'updated.'
            ),

            'report': report.to_dict()

        }), 200

    except Exception as e:

        session.rollback()

        return jsonify({

            'success': False,

            'message': str(e)

        }), 500

    finally:

        session.close()