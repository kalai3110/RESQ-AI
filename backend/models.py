from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    Boolean,
    DateTime,
    ForeignKey,
    Float
)

from sqlalchemy.orm import declarative_base, relationship
import datetime

Base = declarative_base()

from werkzeug.security import(generate_password_hash, check_password_hash)


# ============================================================
# USER
# ============================================================

class User(Base):
    __tablename__ = 'users'

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    name = Column(
        String(120),
        nullable=False
    )

    email = Column(
        String(180),
        unique=True,
        nullable=False
    )

    password_hash = Column(
        String(255),
        nullable=True
    )

    role = Column(
        String(30),
        nullable=False,
        default='citizen'
    )

    phone = Column(
        String(40),
        nullable=True
    )

    rescue_team_id = Column(
        Integer, 
        nullable=True
    )

    reports = relationship(
        'DisasterReport',
        back_populates='reporter'
    )

    notifications = relationship(
        'Notification',
        back_populates='user'
    )

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(
            self.password_hash,
            password
        )

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'role': self.role,
            'phone': self.phone
        }

# ============================================================
# DISASTER REPORT
# ============================================================

class DisasterReport(Base):
    __tablename__ = 'disaster_reports'

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    user_id = Column(
        Integer,
        ForeignKey(
            'users.id',
            ondelete='CASCADE'
        ),
        nullable=False
    )

    disaster_type = Column(
        String(60),
        nullable=False
    )

    district = Column(
        String(100),
        nullable=False
    )

    area = Column(
        String(150),
        nullable=False
    )

    address = Column(
        Text,
        nullable=False
    )

    latitude = Column(
        Float,
        nullable=True
    )

    longitude = Column(
        Float,
        nullable=True
    )

    people_affected = Column(
        Integer,
        nullable=False,
        default=0
    )

    injured = Column(
        Integer,
        nullable=False,
        default=0
    )

    missing = Column(
        Integer,
        nullable=False,
        default=0
    )

    immediate_help_required = Column(
        Integer,
        nullable=False,
        default=0
    )

    property_damage = Column(
        Boolean,
        default=False
    )

    infrastructure_damage = Column(
        Boolean,
        default=False
    )

    damage_level = Column(
        String(30),
        nullable=False,
        default='Medium'
    )

    description = Column(
        Text,
        nullable=True
    )

    image_url = Column(
        String(255),
        nullable=True
    )

    severity = Column(
        String(30),
        nullable=False,
        default='MEDIUM'
    )

    priority = Column(
        String(10),
        nullable=False,
        default='P3'
    )

    status = Column(
        String(50),
        nullable=False,
        default='Reported'
    )

    created_at = Column(
        DateTime,
        default=datetime.datetime.utcnow
    )

    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow
    )

    reporter = relationship(
        'User',
        back_populates='reports'
    )

    rescue_teams = relationship(
        'RescueTeam',
        back_populates='assigned_report'
    )

    medical_requests = relationship(
        'MedicalRequest',
        back_populates='report',
        cascade='all, delete-orphan'
    )

    notifications = relationship(
        'Notification',
        back_populates='report'
    )

    def to_dict(self):
        landmark = ''

        if self.address and '| Landmark:' in self.address:
            address_parts = self.address.split(
                '| Landmark:',
                1
            )

            clean_address = address_parts[0].strip()
            landmark = address_parts[1].strip()

        else:
            clean_address = self.address

        return {
            'id': self.id,

            'report_id':
                f"DR-{self.id}",

            'user_id':
                self.user_id,

            'reporter_name':
                self.reporter.name
                if self.reporter
                else 'Anonymous',

            'disaster_type':
                self.disaster_type,

            'district':
                self.district,

            'area':
                self.area,

            'address':
                clean_address,

            'landmark':
                landmark,

            'location_display':
                f"{self.area}, {self.district}",

            'latitude':
                self.latitude,

            'longitude':
                self.longitude,

            'people_affected':
                self.people_affected,

            'injured':
                self.injured,

            'missing':
                self.missing,

            'immediate_help_required':
                self.immediate_help_required,

            'property_damage':
                bool(self.property_damage),

            'infrastructure_damage':
                bool(self.infrastructure_damage),

            'damage_level':
                self.damage_level,

            'description':
                self.description,

            'image_url':
                self.image_url,

            'severity':
                self.severity,

            'priority':
                self.priority,

            'status':
                self.status,

            'assigned_teams':
                [
                    t.team_name
                    for t in self.rescue_teams
                ]
                if self.rescue_teams
                else [],

            'created_at':
                self.created_at.isoformat()
                if self.created_at
                else None,

            'updated_at':
                self.updated_at.isoformat()
                if self.updated_at
                else None
        }



# ============================================================
# RESCUE TEAM
# ============================================================

class RescueTeam(Base):
    __tablename__ = 'rescue_teams'

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    team_name = Column(
        String(120),
        nullable=False
    )

    leader_name = Column(
        String(120),
        nullable=False
    )

    contact = Column(
        String(40),
        nullable=False
    )

    specialization = Column(
        String(100),
        default='General Disaster Response'
    )

    members_count = Column(
        Integer,
        default=8
    )

    assigned_report_id = Column(
        Integer,
        ForeignKey(
            'disaster_reports.id',
            ondelete='SET NULL'
        ),
        nullable=True
    )

    status = Column(
        String(50),
        nullable=False,
        default='Available'
    )

    current_location = Column(
        String(150),
        default='Central Operations Base'
    )

    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow
    )

    assigned_report = relationship(
        'DisasterReport',
        back_populates='rescue_teams'
    )

    def to_dict(self):
        report_data = None
        if self.assigned_report:
            report_data = {
                'id': self.assigned_report.id,
                'disaster_type': self.assigned_report.disaster_type,
                'district': self.assigned_report.district,
                'area': self.assigned_report.area,
                'address': self.assigned_report.address,
                'people_affected': self.assigned_report.people_affected,
                'severity': self.assigned_report.severity,
                'priority': self.assigned_report.priority,
                'status': self.assigned_report.status
            }

        return {
            'id':
                self.id,

            'team_name':
                self.team_name,

            'leader_name':
                self.leader_name,

            'contact':
                self.contact,

            'specialization':
                self.specialization,

            'members_count':
                self.members_count,

            'assigned_report_id':
                self.assigned_report_id,

            'assigned_disaster':
                report_data,

            'status':
                self.status,

            'current_location':
                self.current_location,

            'updated_at':
                self.updated_at.isoformat()
                if self.updated_at
                else None
        }

# ============================================================
# RESCUE REPORT HISTORY
# ============================================================

class RescueReportHistory(Base):
    __tablename__ = 'rescue_report_history'

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    team_id = Column(
        Integer,
        ForeignKey(
            'rescue_teams.id',
            ondelete='CASCADE'
        ),
        nullable=False
    )

    report_id = Column(
        Integer,
        ForeignKey(
            'disaster_reports.id',
            ondelete='CASCADE'
        ),
        nullable=False
    )

    completed_at = Column(
        DateTime,
        default=datetime.datetime.utcnow
    )

    team = relationship(
        'RescueTeam'
    )

    report = relationship(
        'DisasterReport'
    )

    def to_dict(self):
        return {
            'id': self.id,
            'team_id': self.team_id,
            'report_id': self.report_id,
            'completed_at':
                self.completed_at.isoformat()
                if self.completed_at
                else None
        }

# ============================================================
# SHELTER
# ============================================================

class Shelter(Base):
    __tablename__ = 'shelters'

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    shelter_name = Column(
        String(180),
        nullable=False
    )

    location = Column(
        String(180),
        nullable=False
    )

    district = Column(
        String(100),
        nullable=False
    )

    address = Column(
        Text,
        nullable=True
    )

    latitude = Column(
        Float,
        nullable=True
    )

    longitude = Column(
        Float,
        nullable=True
    )

    capacity = Column(
        Integer,
        nullable=False,
        default=100
    )

    occupied = Column(
        Integer,
        nullable=False,
        default=0
    )

    available = Column(
        Integer,
        nullable=False,
        default=100
    )

    food_available = Column(
        Boolean,
        default=True
    )

    water_available = Column(
        Boolean,
        default=True
    )

    medical_available = Column(
        Boolean,
        default=True
    )

    status = Column(
        String(40),
        nullable=False,
        default='Available'
    )

    contact_person = Column(
        String(120),
        nullable=True
    )

    contact_phone = Column(
        String(40),
        nullable=True
    )

    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow
    )

    def calculate_status(self):
        self.available = max(
            0,
            self.capacity - self.occupied
        )

        if self.available == 0:
            self.status = 'Full'

        elif self.available < (
            self.capacity * 0.2
        ):
            self.status = 'Limited'

        else:
            self.status = 'Available'

    def to_dict(self):
        return {
            'id':
                self.id,

            'shelter_name':
                self.shelter_name,

            'location':
                self.location,

            'district':
                self.district,

            'address':
                self.address,

            'latitude':
                self.latitude,

            'longitude':
                self.longitude,

            'capacity':
                self.capacity,

            'occupied':
                self.occupied,

            'available':
                self.available,

            'food_available':
                bool(self.food_available),

            'water_available':
                bool(self.water_available),

            'medical_available':
                bool(self.medical_available),

            'status':
                self.status,

            'contact_person':
                self.contact_person,

            'contact_phone':
                self.contact_phone,

            'occupancy_percentage':
                round(
                    (
                        self.occupied /
                        self.capacity *
                        100
                    ),
                    1
                )
                if self.capacity > 0
                else 0,

            'updated_at':
                self.updated_at.isoformat()
                if self.updated_at
                else None
        }


# ============================================================
# MEDICAL REQUEST
# ============================================================

class MedicalRequest(Base):
    __tablename__ = 'medical_requests'

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    report_id = Column(
        Integer,
        ForeignKey(
            'disaster_reports.id',
            ondelete='CASCADE'
        ),
        nullable=False
    )

    injured_count = Column(
        Integer,
        nullable=False,
        default=0
    )

    emergency_treatment_required = Column(
        Boolean,
        default=False
    )

    ambulance_required = Column(
        Boolean,
        default=False
    )

    first_aid_required = Column(
        Boolean,
        default=True
    )

    medical_required = Column(
        Boolean,
        default=True
    )

    status = Column(
        String(50),
        nullable=False,
        default='Requested'
    )

    assigned_hospital = Column(
        String(150),
        nullable=True
    )

    ambulances_dispatched = Column(
        Integer,
        default=0
    )

    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow
    )

    report = relationship(
        'DisasterReport',
        back_populates='medical_requests'
    )

    def to_dict(self):
        return {
            'id':
                self.id,

            'report_id':
                self.report_id,

            'disaster_type':
                self.report.disaster_type
                if self.report
                else 'Unknown',

            'location':
                f"{self.report.area}, "
                f"{self.report.district}"
                if self.report
                else 'Unknown',

            'severity':
                self.report.severity
                if self.report
                else 'MEDIUM',

            'priority':
                self.report.priority
                if self.report
                else 'P3',

            'injured_count':
                self.injured_count,

            'emergency_treatment_required':
                bool(
                    self.emergency_treatment_required
                ),

            'ambulance_required':
                bool(
                    self.ambulance_required
                ),

            'first_aid_required':
                bool(
                    self.first_aid_required
                ),

            'medical_required':
                bool(
                    self.medical_required
                ),

            'status':
                self.status,

            'assigned_hospital':
                self.assigned_hospital,

            'ambulances_dispatched':
                self.ambulances_dispatched,

            'updated_at':
                self.updated_at.isoformat()
                if self.updated_at
                else None
        }


# ============================================================
# RELIEF RESOURCE
# ============================================================

class ReliefResource(Base):
    __tablename__ = 'relief_resources'

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    resource_name = Column(
        String(120),
        nullable=False
    )

    category = Column(
        String(80),
        nullable=False
    )

    quantity = Column(
        Integer,
        nullable=False,
        default=0
    )

    unit = Column(
        String(40),
        nullable=False,
        default='units'
    )

    status = Column(
        String(40),
        nullable=False,
        default='Available'
    )

    location = Column(
        String(150),
        default='Main Emergency Depot'
    )

    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow
    )

    def calculate_status(self):
        if self.quantity <= 0:
            self.status = 'Out of Stock'

        elif self.quantity < 100:
            self.status = 'Low'

        elif self.quantity < 300:
            self.status = 'Limited'

        else:
            self.status = 'Available'

    def to_dict(self):
        return {
            'id':
                self.id,

            'resource_name':
                self.resource_name,

            'category':
                self.category,

            'quantity':
                self.quantity,

            'unit':
                self.unit,

            'display_quantity':
                f"{self.quantity} {self.unit}",

            'status':
                self.status,

            'location':
                self.location,

            'updated_at':
                self.updated_at.isoformat()
                if self.updated_at
                else None
        }


# ============================================================
# NOTIFICATION
# ============================================================

class Notification(Base):
    __tablename__ = 'notifications'

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    user_id = Column(
        Integer,
        ForeignKey(
            'users.id',
            ondelete='CASCADE'
        ),
        nullable=True
    )

    title = Column(
        String(180),
        nullable=False
    )

    message = Column(
        Text,
        nullable=False
    )

    notification_type = Column(
        String(60),
        nullable=False
    )

    report_id = Column(
        Integer,
        ForeignKey(
            'disaster_reports.id',
            ondelete='SET NULL'
        ),
        nullable=True
    )

    is_read = Column(
        Boolean,
        default=False
    )

    created_at = Column(
        DateTime,
        default=datetime.datetime.utcnow
    )

    user = relationship(
        'User',
        back_populates='notifications'
    )

    report = relationship(
        'DisasterReport',
        back_populates='notifications'
    )

    def to_dict(self):
        return {
            'id':
                self.id,

            'user_id':
                self.user_id,

            'title':
                self.title,

            'message':
                self.message,

            'notification_type':
                self.notification_type,

            'report_id':
                self.report_id,

            'is_read':
                bool(self.is_read),

            'created_at':
                self.created_at.isoformat()
                if self.created_at
                else None
        }


# ============================================================
# EMERGENCY CONTACTS
# ============================================================

class EmergencyContact(Base):
    __tablename__ = 'emergency_contacts'

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    name = Column(
        String(120),
        nullable=False
    )

    number = Column(
        String(30),
        nullable=False
    )

    category = Column(
        String(80),
        nullable=False
    )

    description = Column(
        String(255),
        nullable=True
    )

    def to_dict(self):
        return {
            'id':
                self.id,

            'name':
                self.name,

            'number':
                self.number,

            'category':
                self.category,

            'description':
                self.description
        }
# ============================================================
# SHELTER ASSIGNMENT
# ============================================================

class ShelterAssignment(Base):
    __tablename__ = 'shelter_assignments'

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    report_id = Column(
        Integer,
        ForeignKey(
            'disaster_reports.id',
            ondelete='CASCADE'
        ),
        nullable=False
    )

    team_id = Column(
        Integer,
        ForeignKey(
            'rescue_teams.id',
            ondelete='SET NULL'
        ),
        nullable=True
    )

    shelter_id = Column(
        Integer,
        ForeignKey(
            'shelters.id',
            ondelete='CASCADE'
        ),
        nullable=False
    )

    evacuee_count = Column(
        Integer,
        nullable=False,
        default=0
    )

    assigned_at = Column(
        DateTime,
        default=datetime.datetime.utcnow
    )

    def to_dict(self):
        return {
            'id': self.id,
            'report_id': self.report_id,
            'team_id': self.team_id,
            'shelter_id': self.shelter_id,
            'evacuee_count': self.evacuee_count,
            'assigned_at':
                self.assigned_at.isoformat()
                if self.assigned_at
                else None
        }


