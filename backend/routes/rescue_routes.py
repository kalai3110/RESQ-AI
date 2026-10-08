from flask import Blueprint, request, jsonify

try:
    from ..database import get_session
    from ..models import (
        RescueTeam,
        DisasterReport,
        Notification,
        User,
        RescueReportHistory,
        Shelter,
        ShelterAssignment
    )

except ImportError:
    from database import get_session
    from models import (
        RescueTeam,
        DisasterReport,
        Notification,
        User,
        RescueReportHistory,
        Shelter,
        ShelterAssignment
    )


rescue_bp = Blueprint('rescue_bp', __name__)


RESCUE_STATUSES = [
    'Available',
    'Assigned',
    'Preparing',
    'On the Way',
    'Reached',
    'Completed'
]


# ============================================================
# GET ALL RESCUE TEAMS
# ============================================================

@rescue_bp.route('/teams', methods=['GET'])
def get_rescue_teams():

    status = request.args.get('status')

    session = get_session()

    try:

        query = session.query(RescueTeam)

        if status:
            query = query.filter(
                RescueTeam.status == status
            )

        teams = query.all()

        team_list = []

        for team in teams:

            team_data = team.to_dict()

            # ====================================================
            # GET SHELTER ASSIGNMENT FOR CURRENT REPORT
            # ====================================================

            if team.assigned_report_id:

                shelter_assignment = (
                    session.query(ShelterAssignment)
                    .filter(
                        ShelterAssignment.report_id ==
                        team.assigned_report_id,

                        ShelterAssignment.team_id ==
                        team.id
                    )
                    .order_by(
                        ShelterAssignment.assigned_at.desc()
                    )
                    .first()
                )

                if shelter_assignment:

                    shelter = (
                        session.query(Shelter)
                        .filter(
                            Shelter.id ==
                            shelter_assignment.shelter_id
                        )
                        .first()
                    )

                    if shelter:

                        team_data[
                            'assigned_disaster'
                        ][
                            'shelter_assignment'
                        ] = {

                            'id':
                                shelter_assignment.id,

                            'shelter_id':
                                shelter.id,

                            'shelter_name':
                                shelter.shelter_name,

                            'address':
                                getattr(
                                    shelter,
                                    'address',
                                    None
                                ),

                            'location':
                                getattr(
                                    shelter,
                                    'location',
                                    None
                                ),

                            'district':
                                getattr(
                                    shelter,
                                    'district',
                                    None
                                ),

                            'evacuee_count':
                                shelter_assignment.evacuee_count,

                            'facilities':
                                getattr(
                                    shelter,
                                    'facilities',
                                    None
                                ),

                            'status':
                                getattr(
                                    shelter,
                                    'status',
                                    None
                                ),

                            'assigned_at':
                                shelter_assignment.assigned_at.isoformat()
                                if shelter_assignment.assigned_at
                                else None
                        }

            team_list.append(team_data)

        return jsonify({
            'success': True,
            'count': len(team_list),
            'teams': team_list
        }), 200

    finally:
        session.close()
# ============================================================
# UPDATE RESCUE TEAM STATUS
# ============================================================

@rescue_bp.route(
    '/teams/<int:team_id>/status',
    methods=['PATCH']
)
def update_team_status(team_id):

    data = request.get_json(silent=True) or {}

    new_status = data.get('status')
    current_loc = data.get('current_location')

    if (
        not new_status
        or new_status not in RESCUE_STATUSES
    ):
        return jsonify({
            'success': False,
            'message': (
                'Invalid status. Allowed statuses: '
                + ', '.join(RESCUE_STATUSES)
            )
        }), 400

    session = get_session()

    try:

        team = (
            session.query(RescueTeam)
            .filter(
                RescueTeam.id == team_id
            )
            .first()
        )

        if not team:

            return jsonify({
                'success': False,
                'message': 'Rescue team not found.'
            }), 404


        # ----------------------------------------------------
        # IMPORTANT:
        # Save the assigned report BEFORE changing
        # assigned_report_id to None.
        # ----------------------------------------------------

        assigned_report = team.assigned_report


        # Update location if provided
        if current_loc:
            team.current_location = current_loc


        # ====================================================
        # COMPLETED
        # ====================================================

        if new_status == 'Completed':

            if assigned_report:

                # Report becomes resolved
                assigned_report.status = 'Resolved'

                # Save completed rescue report in history
                completed_history = RescueReportHistory(
                    team_id=team.id,
                    report_id=assigned_report.id
                )

                session.add(completed_history)

                # Notify citizen
                citizen_notification = Notification(
                    user_id=assigned_report.user_id,
                    title=(
                        f"✅ {team.team_name} "
                        f"Response Completed"
                    ),
                    message=(
                        f"{team.team_name} has completed "
                        f"the rescue operation for "
                        f"Report #{assigned_report.id}."
                    ),
                    notification_type='rescue_status',
                    report_id=assigned_report.id
                )

                session.add(
                    citizen_notification
                )


            # Team becomes available again
            team.status = 'Available'

            # Remove current assignment
            team.assigned_report_id = None


            session.commit()


            return jsonify({
                'success': True,
                'message': (
                    'Rescue operation completed. '
                    'Report resolved and team is available.'
                ),
                'team': team.to_dict()
            }), 200


        # ====================================================
        # NORMAL STATUS UPDATE
        # ====================================================

        team.status = new_status


        # ====================================================
        # NOTIFY CITIZEN
        # ====================================================

        if assigned_report:

            msg_map = {

                'Preparing': (
                    f"{team.team_name} is preparing "
                    f"equipment and team members."
                ),

                'On the Way': (
                    f"{team.team_name} is on the way "
                    f"to the disaster location."
                ),

                'Reached': (
                    f"{team.team_name} has reached "
                    f"the disaster location."
                )
            }


            if new_status in msg_map:

                citizen_notification = Notification(

                    user_id=assigned_report.user_id,

                    title=(
                        f"🚑 {team.team_name} "
                        f"Status: {new_status}"
                    ),

                    message=msg_map[new_status],

                    notification_type='rescue_status',

                    report_id=assigned_report.id
                )

                session.add(
                    citizen_notification
                )


        session.commit()


        return jsonify({

            'success': True,

            'message': (
                f'Rescue team status updated '
                f'to {new_status}.'
            ),

            'team': team.to_dict()

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
# ASSIGN TEAM TO REPORT + NOTIFY RESPONSE TEAM
# ============================================================

@rescue_bp.route(
    '/teams/assign',
    methods=['POST']
)
def assign_team_to_report():

    data = request.get_json(silent=True) or {}

    team_id = data.get('team_id')
    report_id = data.get('report_id')

    if not team_id or not report_id:
        return jsonify({
            'success': False,
            'message': 'team_id and report_id are required.'
        }), 400

    session = get_session()

    try:

        # ====================================================
        # FIND TEAM
        # ====================================================

        team = (
            session.query(RescueTeam)
            .filter(
                RescueTeam.id == int(team_id)
            )
            .first()
        )

        if not team:
            return jsonify({
                'success': False,
                'message': 'Rescue team not found.'
            }), 404


        # ====================================================
        # FIND REPORT
        # ====================================================

        report = (
            session.query(DisasterReport)
            .filter(
                DisasterReport.id == int(report_id)
            )
            .first()
        )

        if not report:
            return jsonify({
                'success': False,
                'message': 'Disaster report not found.'
            }), 404


        # ====================================================
        # CHECK TEAM AVAILABILITY
        # ====================================================

        if team.status != 'Available':
            return jsonify({
                'success': False,
                'message': (
                    f'{team.team_name} is currently '
                    f'{team.status}.'
                )
            }), 400


        # ====================================================
        # ASSIGN TEAM
        # ====================================================

        team.assigned_report_id = report.id
        team.status = 'Assigned'

        report.status = 'Rescue in Progress'


        # ====================================================
        # FIND RESPONSE TEAM LOGIN ACCOUNT
        # ====================================================

        team_user = (
            session.query(User)
            .filter(
                User.rescue_team_id == team.id
            )
            .filter(
                User.role.in_([
                    'RESCUE_TEAM',
                    'rescue_team'
                ])
            )
            .first()
        )


        # ====================================================
        # CITIZEN NOTIFICATION
        # ====================================================

        citizen_notification = Notification(

            user_id=report.user_id,

            title=(
                f"🚑 {team.team_name} Assigned"
            ),

            message=(
                f"{team.team_name} has been assigned "
                f"to your Report #{report.id} "
                f"in {report.district}."
            ),

            notification_type='rescue_assigned',

            report_id=report.id,

            is_read=False
        )

        session.add(citizen_notification)


        # ====================================================
        # RESPONSE TEAM NOTIFICATION
        # ====================================================

        notification_created = False

        if team_user:

            team_notification = Notification(

                user_id=team_user.id,

                title=(
                    f"🚨 New Rescue Assignment"
                ),

                message=(
                    f"Report #{report.id} has been "
                    f"assigned to your team.\n\n"
                    f"Disaster: {report.disaster_type}\n"
                    f"District: {report.district}\n"
                    f"Priority: "
                    f"{getattr(report, 'priority', 'N/A')}\n\n"
                    f"Please check the report and "
                    f"start the rescue operation."
                ),

                notification_type='rescue_assigned',

                report_id=report.id,

                is_read=False
            )

            session.add(team_notification)

            notification_created = True


        # ====================================================
        # SAVE
        # ====================================================

        session.commit()


        # ====================================================
        # RESPONSE
        # ====================================================

        return jsonify({

            'success': True,

            'message': (
                f'{team.team_name} assigned '
                f'to Report #{report.id}.'
            ),

            'team': team.to_dict(),

            'report': report.to_dict(),

            'notification_created':
                notification_created,

            'team_user_id':
                team_user.id if team_user else None

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
# GET RESCUE TEAM NOTIFICATIONS WITH FULL REPORT DETAILS
# ============================================================

@rescue_bp.route('/notifications/<int:user_id>', methods=['GET'])
def get_rescue_notifications(user_id):
    session = get_session()

    try:
        notifications = (
            session.query(Notification)
            .filter(Notification.user_id == user_id)
            .filter(
                Notification.notification_type.in_([
                    'rescue_assigned',
                    'rescue_status',
                    'shelter_assigned'
                ])
            )
            .order_by(Notification.created_at.desc())
            .all()
        )

        result = []
        for n in notifications:

            report_data = None

            if n.report_id:
                report = session.get(
                    DisasterReport,
                    n.report_id
                )

                if not report:
                    continue

                # Completed / resolved reports
                # active notification list-la show panna vendam
                if report.status == 'Resolved':
                    continue

                report_data = report.to_dict()

            result.append({
                'id': n.id,
                'user_id': n.user_id,
                'title': n.title,
                'message': n.message,
                'notification_type': n.notification_type,
                'report_id': n.report_id,
                'is_read': getattr(
                    n,
                    'is_read',
                    False
                ),
                'created_at': (
                    n.created_at.isoformat()
                    if n.created_at
                    else None
                ),

                # IMPORTANT
                # Full report details
                'report': report_data,
            })

        return jsonify({
            'success': True,
            'count': len(result),
            'notifications': result
        }), 200

    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

    finally:
        session.close()

        # ============================================================
# GET COMPLETED REPORTS FOR A RESCUE TEAM
# ============================================================

@rescue_bp.route(
    '/completed-reports/<int:team_id>',
    methods=['GET']
)
def get_completed_reports(team_id):

    session = get_session()

    try:

        history = (
            session.query(RescueReportHistory)
            .filter(
                RescueReportHistory.team_id == team_id
            )
            .order_by(
                RescueReportHistory.completed_at.desc()
            )
            .all()
        )

        reports = []

        for item in history:

            report = session.get(
                DisasterReport,
                item.report_id
            )

            if not report:
                continue

            report_data = report.to_dict()

            report_data['completed_at'] = (
                item.completed_at.isoformat()
                if item.completed_at
                else None
            )

            reports.append(report_data)

        return jsonify({
            'success': True,
            'count': len(reports),
            'reports': reports
        }), 200

    except Exception as e:

        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

    finally:
        session.close()