from flask import Blueprint, request, jsonify

try:
    from ..database import get_session
    from ..models import MedicalRequest, DisasterReport, Notification
except ImportError:
    from database import get_session
    from models import MedicalRequest, DisasterReport, Notification

medical_bp = Blueprint('medical_bp', __name__)

MED_STATUSES = ['Requested', 'Assigned', 'On the Way', 'Completed']

@medical_bp.route('/requests', methods=['GET'])
def get_medical_requests():
    status = request.args.get('status')
    session = get_session()
    try:
        query = session.query(MedicalRequest).order_by(MedicalRequest.updated_at.desc())
        if status:
            query = query.filter(MedicalRequest.status == status)

        requests = query.all()
        return jsonify({
            'success': True,
            'count': len(requests),
            'medical_requests': [m.to_dict() for m in requests]
        }), 200
    finally:
        session.close()

@medical_bp.route('/requests', methods=['POST'])
def create_medical_request():
    data = request.get_json(silent=True) or {}
    report_id = data.get('report_id')
    injured_count = int(data.get('injured_count', 1))

    if not report_id:
        return jsonify({'success': False, 'message': 'report_id is required.'}), 400

    session = get_session()
    try:
        report = session.query(DisasterReport).filter(DisasterReport.id == report_id).first()
        if not report:
            return jsonify({'success': False, 'message': 'Associated disaster report not found.'}), 404

        med_req = MedicalRequest(
            report_id=report_id,
            injured_count=injured_count,
            emergency_treatment_required=bool(data.get('emergency_treatment_required', True)),
            ambulance_required=bool(data.get('ambulance_required', True)),
            first_aid_required=bool(data.get('first_aid_required', True)),
            medical_required=True,
            status='Requested',
            assigned_hospital=data.get('assigned_hospital', 'District HQ Emergency Hospital'),
            ambulances_dispatched=int(data.get('ambulances_dispatched', 1))
        )
        session.add(med_req)

        notif = Notification(
            user_id=report.user_id,
            title='🏥 Medical Assistance Requested',
            message=f"Emergency medical request logged for {injured_count} injured individuals at {report.area}.",
            notification_type='medical_assigned',
            report_id=report_id
        )
        session.add(notif)
        session.commit()

        return jsonify({
            'success': True,
            'message': 'Medical assistance request created.',
            'medical_request': med_req.to_dict()
        }), 201
    except Exception as e:
        session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        session.close()

@medical_bp.route('/requests/<int:req_id>/status', methods=['PATCH'])
def update_medical_status(req_id):
    data = request.get_json(silent=True) or {}
    new_status = data.get('status')
    hospital = data.get('assigned_hospital')
    ambulances = data.get('ambulances_dispatched')

    if not new_status or new_status not in MED_STATUSES:
        return jsonify({'success': False, 'message': f'Valid statuses: {", ".join(MED_STATUSES)}'}), 400

    session = get_session()
    try:
        med_req = session.query(MedicalRequest).filter(MedicalRequest.id == req_id).first()
        if not med_req:
            return jsonify({'success': False, 'message': 'Medical request not found.'}), 404

        med_req.status = new_status
        if hospital:
            med_req.assigned_hospital = hospital
        if ambulances is not None:
            med_req.ambulances_dispatched = int(ambulances)

        if med_req.report:
            notif = Notification(
                user_id=med_req.report.user_id,
                title=f"🏥 Medical Assistance Status: {new_status}",
                message=f"Medical unit dispatch status updated to '{new_status}' (Hospital: {med_req.assigned_hospital or 'Dispatched Unit'}).",
                notification_type='medical_status',
                report_id=med_req.report_id
            )
            session.add(notif)

        session.commit()
        return jsonify({
            'success': True,
            'message': 'Medical assistance status updated.',
            'medical_request': med_req.to_dict()
        }), 200
    except Exception as e:
        session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        session.close()
