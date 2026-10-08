import unittest
import os
import sys
import json

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app
from database import get_session
from models import User, DisasterReport, RescueTeam, Shelter, ReliefResource

class TestDisasterResponseAPI(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.app = create_app()
        cls.client = cls.app.test_client()

    def test_root_endpoint(self):
        res = self.client.get('/')
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data['status'], 'Online')
        self.assertIn('ml_model', data)

    def test_dashboard_summary(self):
        res = self.client.get('/api/dashboard/summary')
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertTrue(data['success'])
        summary = data['summary']
        self.assertIn('total_disaster_reports', summary)
        self.assertIn('critical_cases', summary)
        self.assertIn('active_rescue_teams', summary)
        self.assertIn('available_shelters', summary)

    def test_auth_login_valid(self):
        res = self.client.post('/api/auth/login', json={
            'email': 'admin@disaster.org',
            'password': 'password123'
        })
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertTrue(data['success'])
        self.assertEqual(data['user']['role'], 'admin')

    def test_auth_login_invalid(self):
        res = self.client.post('/api/auth/login', json={
            'email': 'admin@disaster.org',
            'password': 'wrongpassword'
        })
        self.assertEqual(res.status_code, 401)
        data = json.loads(res.data)
        self.assertFalse(data['success'])
        self.assertIn('Invalid email or password', data['message'])

    def test_ai_predict_endpoint(self):
        res = self.client.post('/api/disaster/predict', json={
            'disaster_type': 'Flood',
            'people_affected': 250,
            'injured': 45,
            'missing': 10,
            'immediate_help_required': 50,
            'damage_level': 'High',
            'infrastructure_damage': 1,
            'property_damage': 1
        })
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertTrue(data['success'])
        self.assertEqual(data['prediction']['severity'], 'CRITICAL')
        self.assertEqual(data['prediction']['priority'], 'P1')

    def test_report_submission_lifecycle(self):
        # Submit new disaster report
        report_payload = {
            'user_id': 4,
            'disaster_type': 'Cyclone',
            'district': 'Cuddalore',
            'area': 'Port Blair Road Sector 2',
            'address': 'Near Lighthouse & Coastal Fishery Dock',
            'people_affected': 180,
            'injured': 25,
            'missing': 5,
            'immediate_help_required': 35,
            'property_damage': True,
            'infrastructure_damage': True,
            'damage_level': 'High',
            'description': 'Storm surge causing massive sea water ingress and roof blow-offs.'
        }
        res = self.client.post('/api/disaster/report', json=report_payload)
        self.assertEqual(res.status_code, 201)
        data = json.loads(res.data)
        self.assertTrue(data['success'])
        report_id = data['report']['id']
        self.assertEqual(data['report']['severity'], 'CRITICAL')
        self.assertEqual(data['report']['priority'], 'P1')

        # Retrieve report by ID
        get_res = self.client.get(f'/api/disaster/reports/{report_id}')
        self.assertEqual(get_res.status_code, 200)
        get_data = json.loads(get_res.data)
        self.assertEqual(get_data['report']['district'], 'Cuddalore')

    def test_rescue_teams_lifecycle(self):
        res = self.client.get('/api/rescue/teams')
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertTrue(data['success'])
        self.assertTrue(len(data['teams']) > 0)

        # Update status
        team_id = data['teams'][0]['id']
        patch_res = self.client.patch(f'/api/rescue/teams/{team_id}/status', json={
            'status': 'Reached',
            'current_location': 'On-site command center'
        })
        self.assertEqual(patch_res.status_code, 200)
        patch_data = json.loads(patch_res.data)
        self.assertEqual(patch_data['team']['status'], 'Reached')

    def test_shelters_endpoint(self):
        res = self.client.get('/api/shelters')
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertTrue(data['success'])
        self.assertTrue(len(data['shelters']) > 0)

    def test_relief_resources_endpoint(self):
        res = self.client.get('/api/resources')
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertTrue(data['success'])
        self.assertTrue(len(data['resources']) > 0)

    def test_map_disasters_endpoint(self):
        res = self.client.get('/api/map/disasters')
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertTrue(data['success'])
        self.assertIn('disaster_markers', data)
        self.assertIn('shelter_markers', data)

    def test_notifications_endpoint(self):
        res = self.client.get('/api/notifications')
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertTrue(data['success'])

if __name__ == '__main__':
    unittest.main()
