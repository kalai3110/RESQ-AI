import os
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'disaster-ai-response-secret-key-2026')
    JWT_SECRET = os.environ.get('JWT_SECRET', 'jwt-disaster-mgmt-super-secure-key-9988')
    
    # Database configuration
    # MySQL default connection string: mysql+pymysql://username:password@host:port/database_name
    MYSQL_USER = os.environ.get('MYSQL_USER', 'root')
    MYSQL_PASSWORD = os.environ.get('MYSQL_PASSWORD', '')
    MYSQL_HOST = os.environ.get('MYSQL_HOST', 'localhost')
    MYSQL_PORT = os.environ.get('MYSQL_PORT', '3306')
    MYSQL_DB = os.environ.get('MYSQL_DB', 'disaster_response_db')
    
    MYSQL_URL = f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}?charset=utf8mb4"
    SQLITE_URL = f"sqlite:///{os.path.join(BASE_DIR, 'disaster_response.db')}"
    
    # Priority: explicitly set DATABASE_URL, else try MySQL, and if unavailable database.py falls back cleanly to SQLite
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', MYSQL_URL)
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
UPLOAD_FOLDER = '/tmp/uploads'
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16 MB max image size
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp', 'gif'}
