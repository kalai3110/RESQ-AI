from database import get_session
from models import DisasterReport, Notification, MedicalRequest

session = get_session()

try:
    session.query(MedicalRequest).delete(
        synchronize_session=False
    )

    session.query(Notification).delete(
        synchronize_session=False
    )

    deleted = session.query(DisasterReport).delete(
        synchronize_session=False
    )

    session.commit()

    print(f"Deleted {deleted} disaster reports successfully.")

except Exception as e:
    session.rollback()
    print("ERROR:", e)

finally:
    session.close()