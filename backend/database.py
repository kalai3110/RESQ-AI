import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session

try:
    from .config import Config
    from .models import (
        Base,
        User,
        DisasterReport,
        RescueTeam,
        Shelter,
        MedicalRequest,
        ReliefResource,
        Notification,
        EmergencyContact
    )
except ImportError:
    from config import Config
    from models import (
        Base,
        User,
        DisasterReport,
        RescueTeam,
        Shelter,
        MedicalRequest,
        ReliefResource,
        Notification,
        EmergencyContact
    )


engine = None
SessionLocal = None


def get_engine():
    global engine

    if engine is not None:
        return engine

    db_url = Config.SQLALCHEMY_DATABASE_URI

    try:
        engine = create_engine(
            db_url,
            pool_pre_ping=True
        )

        with engine.connect() as conn:
            pass

        print(
            f"[OK] Connected to Primary Database: "
            f"{db_url.split('@')[-1] if '@' in db_url else db_url}"
        )

    except Exception as e:
        print(
            f"[WARN] Primary Database connection failed ({e}). "
            f"Falling back to SQLite for instant local execution..."
        )

        engine = create_engine(
            Config.SQLITE_URL,
            connect_args={"check_same_thread": False}
        )

        print(
            f"[OK] Connected to SQLite Database: "
            f"{Config.SQLITE_URL}"
        )

    return engine


def get_db():
    global SessionLocal

    if SessionLocal is None:
        eng = get_engine()

        SessionLocal = scoped_session(
            sessionmaker(
                autocommit=False,
                autoflush=False,
                bind=eng
            )
        )

    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


def get_session():
    global SessionLocal

    if SessionLocal is None:
        eng = get_engine()

        SessionLocal = scoped_session(
            sessionmaker(
                autocommit=False,
                autoflush=False,
                bind=eng
            )
        )

    return SessionLocal()


def init_db():
    eng = get_engine()

    # Create all database tables
    Base.metadata.create_all(bind=eng)

    print("[OK] Database tables verified / created.")

    session = get_session()

    try:
        # ============================================================
        # EXISTING INITIAL DATA
        # ============================================================

        user_count = session.query(User).count()

        if user_count == 0:
            print(
                "[INFO] Seeding initial disaster response data "
                "into database..."
            )

            seed_initial_data(session)

            session.commit()

            print(
                "[OK] Initial database seeding completed successfully."
            )

        else:
            print(
                f"[INFO] Database contains existing data "
                f"({user_count} users). Skipping seed."
            )

    except Exception as e:
        session.rollback()

        print(
            f"[ERROR] Error during database initialization: {e}"
        )

    finally:
        session.close()


    # ============================================================
    # EMERGENCY CONTACTS SEED
    # ============================================================

    contact_session = get_session()

    try:
        contact_count = (
            contact_session
            .query(EmergencyContact)
            .count()
        )

        if contact_count == 0:

            print(
                "[INFO] Adding emergency contacts..."
            )

            emergency_contacts = [

                EmergencyContact(
                    name="Police",
                    number="100",
                    category="Emergency Services",
                    description="Police emergency helpline"
                ),

                EmergencyContact(
                    name="Fire & Rescue",
                    number="101",
                    category="Emergency Services",
                    description="Fire and rescue emergency service"
                ),

                EmergencyContact(
                    name="Ambulance",
                    number="108",
                    category="Medical Emergency",
                    description="Emergency ambulance service"
                ),

                EmergencyContact(
                    name="Disaster Management",
                    number="1077",
                    category="Disaster Management",
                    description="Disaster management emergency helpline"
                ),

                EmergencyContact(
                    name="Women Helpline",
                    number="181",
                    category="Emergency Support",
                    description="Women emergency support helpline"
                )
            ]

            contact_session.add_all(
                emergency_contacts
            )

            contact_session.commit()

            print(
                "[OK] Emergency contacts seeded successfully."
            )

        else:

            print(
                f"[INFO] Emergency contacts already exist "
                f"({contact_count})."
            )

    except Exception as e:

        contact_session.rollback()

        print(
            f"[ERROR] Error while adding emergency contacts: {e}"
        )

    finally:
        contact_session.close()


def seed_initial_data(session):

    # ============================================================
    # USERS
    # ============================================================

    u1 = User(
        id=1,
        name='Commander Alex Vance',
        email='admin@disaster.org',
        role='admin',
        phone='+91 98401 11223'
    )

    u1.set_password('password123')


    u2 = User(
        id=2,
        name='Captain Rajesh Kumar (Rescue Alpha)',
        email='rescue.alpha@disaster.org',
        role='rescue',
        phone='+91 94440 22334'
    )

    u2.set_password('password123')


    u3 = User(
        id=3,
        name='Dr. Sarah Connor (Medical Unit)',
        email='medical@disaster.org',
        role='rescue',
        phone='+91 98840 33445'
    )

    u3.set_password('password123')


    u4 = User(
        id=4,
        name='Priya Sharma (Citizen)',
        email='priya@gmail.com',
        role='citizen',
        phone='+91 91760 44556'
    )

    u4.set_password('password123')


    u5 = User(
        id=5,
        name='Karthik Raja (Citizen)',
        email='karthik@gmail.com',
        role='citizen',
        phone='+91 98410 55667'
    )

    u5.set_password('password123')


    session.add_all([
        u1,
        u2,
        u3,
        u4,
        u5
    ])

    session.flush()


    # ============================================================
    # DISASTER REPORTS
    # ============================================================

    r1 = DisasterReport(
        id=1025,
        user_id=4,
        disaster_type='Flood',
        district='Madurai',
        area='Vaigai Riverbed Sector 4',
        address='Near Goripalayam Bridge & Anna Nagar Lowlands',
        latitude=9.9252,
        longitude=78.1198,
        people_affected=200,
        injured=40,
        missing=15,
        immediate_help_required=65,
        property_damage=True,
        infrastructure_damage=True,
        damage_level='High',
        description='Severe flash flooding following intense continuous rainfall. Multiple houses submerged, 15 people trapped on rooftops.',
        severity='CRITICAL',
        priority='P1',
        status='Rescue in Progress'
    )


    r2 = DisasterReport(
        id=1026,
        user_id=5,
        disaster_type='Cyclone',
        district='Cuddalore',
        area='Coastal Ward 12',
        address='Silver Beach Fishermen Colony, Block C',
        latitude=11.7480,
        longitude=79.7714,
        people_affected=150,
        injured=18,
        missing=4,
        immediate_help_required=30,
        property_damage=True,
        infrastructure_damage=True,
        damage_level='Critical',
        description='Cyclone storm surge damaged roofs and uprooted power lines. Boats damaged, several families displaced.',
        severity='HIGH',
        priority='P2',
        status='Verified'
    )


    r3 = DisasterReport(
        id=1027,
        user_id=4,
        disaster_type='Fire',
        district='Chennai',
        area='Guindy Industrial Estate',
        address='Plot 45, Phase II, Near Metro Station',
        latitude=13.0067,
        longitude=80.2026,
        people_affected=45,
        injured=12,
        missing=0,
        immediate_help_required=15,
        property_damage=True,
        infrastructure_damage=False,
        damage_level='Medium',
        description='Chemical warehouse fire breakout. Toxic smoke spreading to adjacent residential area.',
        severity='HIGH',
        priority='P2',
        status='Rescue in Progress'
    )


    r4 = DisasterReport(
        id=1028,
        user_id=5,
        disaster_type='Landslide',
        district='Nilgiris',
        area='Coonoor Ghat Road Km 14',
        address='Near Marapalam Bridge & Tea Estate',
        latitude=11.3530,
        longitude=76.7959,
        people_affected=35,
        injured=5,
        missing=2,
        immediate_help_required=8,
        property_damage=True,
        infrastructure_damage=True,
        damage_level='Medium',
        description='Debris and boulder blockage on main arterial highway. 3 vehicles trapped under earth mound.',
        severity='MEDIUM',
        priority='P3',
        status='Verified'
    )


    r5 = DisasterReport(
        id=1029,
        user_id=4,
        disaster_type='Accident',
        district='Salem',
        area='NH44 Bypass Junction',
        address='Near Kondalampatti Roundabout',
        latitude=11.6643,
        longitude=78.1460,
        people_affected=15,
        injured=8,
        missing=0,
        immediate_help_required=8,
        property_damage=True,
        infrastructure_damage=False,
        damage_level='Low',
        description='Multi-vehicle collision involving bus and cargo trucks. First responders required for extrication.',
        severity='LOW',
        priority='P4',
        status='Resolved'
    )


    session.add_all([
        r1,
        r2,
        r3,
        r4,
        r5
    ])

    session.flush()


    # ============================================================
    # RESCUE TEAMS
    # ============================================================

    t1 = RescueTeam(
        id=1,
        team_name='Rescue Team Alpha',
        leader_name='Captain Rajesh Kumar',
        contact='+91 94440 22334',
        specialization='Flood & Swift Water Rescue',
        members_count=12,
        assigned_report_id=1025,
        status='On the Way',
        current_location='En route to Goripalayam, Madurai'
    )


    t2 = RescueTeam(
        id=2,
        team_name='Rescue Team Bravo',
        leader_name='Lieutenant Vikram Rao',
        contact='+91 94440 55661',
        specialization='Urban Search & Collapse Rescue',
        members_count=10,
        assigned_report_id=1027,
        status='Reached',
        current_location='Guindy Industrial Zone, Chennai'
    )


    t3 = RescueTeam(
        id=3,
        team_name='Rescue Team Charlie',
        leader_name='Major S. Sundaram',
        contact='+91 94440 77882',
        specialization='Mountain & Landslide Extrication',
        members_count=8,
        assigned_report_id=1028,
        status='Preparing',
        current_location='Coonoor Fire & Rescue Station'
    )


    t4 = RescueTeam(
        id=4,
        team_name='Rescue Team Delta',
        leader_name='Inspector Anitha Mary',
        contact='+91 94440 99003',
        specialization='Cyclone Evacuation & Medical Escort',
        members_count=14,
        assigned_report_id=1026,
        status='Assigned',
        current_location='Cuddalore Coastal Command HQ'
    )


    t5 = RescueTeam(
        id=5,
        team_name='Rescue Team Echo (Reserve)',
        leader_name='Sub-Inspector Mohan Raj',
        contact='+91 94440 11225',
        specialization='Rapid Triage & First Response',
        members_count=8,
        assigned_report_id=None,
        status='Available',
        current_location='State Disaster Emergency Hub'
    )


    session.add_all([
        t1,
        t2,
        t3,
        t4,
        t5
    ])


    # ============================================================
    # SHELTERS
    # ============================================================

    s1 = Shelter(
        id=1,
        shelter_name='Government Relief Shelter - Central',
        location='Goripalayam Community Hall',
        district='Madurai',
        address='No 12, College Road, Goripalayam',
        latitude=9.9320,
        longitude=78.1250,
        capacity=500,
        occupied=320,
        available=180,
        food_available=True,
        water_available=True,
        medical_available=True,
        status='Available',
        contact_person='Thiru R. Murugan',
        contact_phone='+91 98421 77112'
    )


    s2 = Shelter(
        id=2,
        shelter_name='Cuddalore Coastal Cyclone Shelter #3',
        location='Silver Beach High School',
        district='Cuddalore',
        address='Main Beach Road, Devanampattinam',
        latitude=11.7510,
        longitude=79.7740,
        capacity=400,
        occupied=380,
        available=20,
        food_available=True,
        water_available=True,
        medical_available=True,
        status='Limited',
        contact_person='Mrs. K. Malathi',
        contact_phone='+91 94432 88223'
    )


    s3 = Shelter(
        id=3,
        shelter_name='Guindy Relief & Transit Camp',
        location='Alagappa School Grounds',
        district='Chennai',
        address='GST Road, Guindy, Chennai',
        latitude=13.0100,
        longitude=80.2080,
        capacity=300,
        occupied=110,
        available=190,
        food_available=True,
        water_available=True,
        medical_available=True,
        status='Available',
        contact_person='Mr. S. Ramesh',
        contact_phone='+91 98402 99334'
    )


    s4 = Shelter(
        id=4,
        shelter_name='Nilgiris Hill Relief Center',
        location='Coonoor Municipal Town Hall',
        district='Nilgiris',
        address='Upper Coonoor Market Road',
        latitude=11.3560,
        longitude=76.7990,
        capacity=150,
        occupied=150,
        available=0,
        food_available=True,
        water_available=True,
        medical_available=True,
        status='Full',
        contact_person='Mr. J. George',
        contact_phone='+91 94860 11445'
    )


    s5 = Shelter(
        id=5,
        shelter_name='Anna Nagar Disaster Refuge Hub',
        location='Madurai Corporation Indoor Stadium',
        district='Madurai',
        address='80 Feet Road, Anna Nagar, Madurai',
        latitude=9.9180,
        longitude=78.1400,
        capacity=600,
        occupied=210,
        available=390,
        food_available=True,
        water_available=True,
        medical_available=True,
        status='Available',
        contact_person='Mrs. B. Kavitha',
        contact_phone='+91 97900 55667'
    )


    session.add_all([
        s1,
        s2,
        s3,
        s4,
        s5
    ])


    # ============================================================
    # MEDICAL REQUESTS
    # ============================================================

    m1 = MedicalRequest(
        id=1,
        report_id=1025,
        injured_count=40,
        ambulance_required=True,
        first_aid_required=True,
        emergency_treatment_required=True,
        medical_required=True,
        status='On the Way',
        assigned_hospital='Madurai Government Rajaji Hospital (GRH)',
        ambulances_dispatched=4
    )


    m2 = MedicalRequest(
        id=2,
        report_id=1026,
        injured_count=18,
        ambulance_required=True,
        first_aid_required=True,
        emergency_treatment_required=False,
        medical_required=True,
        status='Assigned',
        assigned_hospital='Cuddalore District Headquarters Hospital',
        ambulances_dispatched=2
    )


    m3 = MedicalRequest(
        id=3,
        report_id=1027,
        injured_count=12,
        ambulance_required=True,
        first_aid_required=True,
        emergency_treatment_required=True,
        medical_required=True,
        status='On the Way',
        assigned_hospital='Kalaignar Centenary Super Speciality Hospital, Guindy',
        ambulances_dispatched=3
    )


    m4 = MedicalRequest(
        id=4,
        report_id=1028,
        injured_count=5,
        ambulance_required=False,
        first_aid_required=True,
        emergency_treatment_required=False,
        medical_required=True,
        status='Requested',
        assigned_hospital='Coonoor Government Lawley Hospital',
        ambulances_dispatched=1
    )


    session.add_all([
        m1,
        m2,
        m3,
        m4
    ])


    # ============================================================
    # RELIEF RESOURCES
    # ============================================================

    res1 = ReliefResource(
        id=1,
        resource_name='Food Packets',
        category='Nutrition',
        quantity=850,
        unit='packets',
        status='Available',
        location='Madurai Emergency Supply Depot'
    )

    res2 = ReliefResource(
        id=2,
        resource_name='Drinking Water Bottles (1L)',
        category='Hydration',
        quantity=1200,
        unit='bottles',
        status='Available',
        location='Madurai Emergency Supply Depot'
    )

    res3 = ReliefResource(
        id=3,
        resource_name='Medicines & First Aid Kits',
        category='Medical',
        quantity=150,
        unit='kits',
        status='Limited',
        location='State Central Medical Store'
    )

    res4 = ReliefResource(
        id=4,
        resource_name='Blankets & Warm Clothes',
        category='Shelter & Bedding',
        quantity=80,
        unit='pieces',
        status='Low',
        location='Cuddalore Relief Depot'
    )

    res5 = ReliefResource(
        id=5,
        resource_name='Inflatable Rescue Boats',
        category='Rescue Equipment',
        quantity=12,
        unit='boats',
        status='Available',
        location='State Disaster Management Depot'
    )

    res6 = ReliefResource(
        id=6,
        resource_name='Life Jackets & Buoys',
        category='Rescue Equipment',
        quantity=220,
        unit='pieces',
        status='Available',
        location='Coastal Command Base'
    )

    res7 = ReliefResource(
        id=7,
        resource_name='Emergency Power Generators',
        category='Power & Utility',
        quantity=15,
        unit='units',
        status='Available',
        location='State Electricity Board Store'
    )


    session.add_all([
        res1,
        res2,
        res3,
        res4,
        res5,
        res6,
        res7
    ])


    # ============================================================
    # NOTIFICATIONS
    # ============================================================

    n1 = Notification(
        id=1,
        user_id=None,
        title='🚨 P1 Critical Disaster Reported',
        message='Flood reported in Madurai (Vaigai Riverbed Sector 4). 200 people affected, 40 injured.',
        notification_type='disaster_report',
        report_id=1025,
        is_read=False
    )


    n2 = Notification(
        id=2,
        user_id=4,
        title='🤖 AI Severity Analysis Completed',
        message='Report #DR-1025 classified as CRITICAL SEVERITY (Priority P1 – Immediate Response Required).',
        notification_type='ai_severity',
        report_id=1025,
        is_read=False
    )


    n3 = Notification(
        id=3,
        user_id=4,
        title='🚑 Rescue Team Alpha Assigned',
        message='Rescue Team Alpha (12 members) has been dispatched and is currently On the Way to your location.',
        notification_type='rescue_assigned',
        report_id=1025,
        is_read=False
    )


    n4 = Notification(
        id=4,
        user_id=None,
        title='🏥 Medical Assistance Dispatched',
        message='4 Ambulances dispatched from GRH Madurai to Vaigai Riverbed Sector 4.',
        notification_type='medical_assigned',
        report_id=1025,
        is_read=False
    )


    n5 = Notification(
        id=5,
        user_id=None,
        title='🏕️ Relief Shelter Capacity Updated',
        message='Goripalayam Community Hall has 180 available seats with food, water and medical facilities.',
        notification_type='shelter_update',
        report_id=None,
        is_read=True
    )


    session.add_all([
        n1,
        n2,
        n3,
        n4,
        n5
    ])