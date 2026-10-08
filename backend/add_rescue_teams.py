from database import get_session
from models import RescueTeam, User


teams_data = [
    {
        "team_name": "Rescue Team Foxtrot",
        "leader_name": "Arun Kumar",
        "contact": "+91 94440 22336",
        "specialization": "Earthquake & Building Collapse",
        "members_count": 12,
        "current_location": "Coimbatore Emergency Base",
        "email": "foxtrot@resqai.local",
        "password": "Foxtrot@12345",
    },
    {
        "team_name": "Rescue Team Gamma",
        "leader_name": "Karthik Raj",
        "contact": "+91 94440 22337",
        "specialization": "Flood & Medical Rescue",
        "members_count": 10,
        "current_location": "Tiruchirappalli Emergency Base",
        "email": "gamma@resqai.local",
        "password": "Gamma@12345",
    },
    {
        "team_name": "Rescue Team India",
        "leader_name": "Suresh Kumar",
        "contact": "+91 94440 22338",
        "specialization": "Multi-Hazard Emergency",
        "members_count": 14,
        "current_location": "Salem Emergency Base",
        "email": "india@resqai.local",
        "password": "India@12345",
    },
]


session = get_session()

try:
    for data in teams_data:

        # ----------------------------------------------------
        # CHECK WHETHER TEAM ALREADY EXISTS
        # ----------------------------------------------------
        existing_team = (
            session.query(RescueTeam)
            .filter(
                RescueTeam.team_name == data["team_name"]
            )
            .first()
        )

        if existing_team:
            print(
                f"Team already exists: "
                f"{existing_team.team_name} "
                f"(ID: {existing_team.id})"
            )
            continue

        # ----------------------------------------------------
        # CREATE RESCUE TEAM
        # ----------------------------------------------------
        team = RescueTeam(
            team_name=data["team_name"],
            leader_name=data["leader_name"],
            contact=data["contact"],
            specialization=data["specialization"],
            members_count=data["members_count"],
            status="Available",
            current_location=data["current_location"],
        )

        session.add(team)
        session.flush()

        # ----------------------------------------------------
        # CHECK WHETHER LOGIN ACCOUNT ALREADY EXISTS
        # ----------------------------------------------------
        existing_user = (
            session.query(User)
            .filter(
                User.email == data["email"]
            )
            .first()
        )

        if existing_user:
            existing_user.rescue_team_id = team.id

            print(
                f"Existing login linked: "
                f"{data['email']} -> Team {team.id}"
            )

        else:
            # ------------------------------------------------
            # CREATE RESCUE TEAM LOGIN
            # ------------------------------------------------
            user = User(
                name=data["team_name"],
                email=data["email"],
                role="RESCUE_TEAM",
                phone=data["contact"],
                rescue_team_id=team.id,
            )

            user.set_password(
                data["password"]
            )

            session.add(user)

            print(
                f"Created: {data['team_name']} "
                f"| Team ID: {team.id} "
                f"| Login: {data['email']}"
            )

    session.commit()

    print()
    print("========================================")
    print("RESCUE TEAM SETUP COMPLETED")
    print("========================================")

except Exception as e:
    session.rollback()
    print("ERROR:", e)

finally:
    session.close()