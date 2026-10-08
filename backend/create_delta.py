from database import get_session
from models import User
from werkzeug.security import generate_password_hash

session = get_session()

try:
    user = User(
        name="Rescue Team Delta",
        email="delta@resqai.local",
        password_hash=generate_password_hash("Delta@12345"),
        role="RESCUE_TEAM",
        rescue_team_id=4
    )

    session.add(user)
    session.commit()

    print("Delta account created successfully!")
    print("Email: delta@resqai.local")
    print("Password: Delta@12345")
    print("Team ID: 4")

except Exception as e:
    session.rollback()
    print("ERROR:", e)

finally:
    session.close()