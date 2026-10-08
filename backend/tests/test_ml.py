import unittest
import os
import sys

# Ensure backend root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from ml.disaster_decision_tree import disaster_predictor

class TestDisasterDecisionTree(unittest.TestCase):

    def test_critical_severity_prediction(self):
        # Scenario: Major flood with high casualties and critical damage
        result = disaster_predictor.predict(
            disaster_type='Flood',
            people_affected=200,
            injured=40,
            missing=15,
            immediate_help=65,
            damage_level='Critical',
            infrastructure_damage=1,
            property_damage=1
        )
        self.assertEqual(result['severity'], 'CRITICAL')
        self.assertEqual(result['priority'], 'P1')
        self.assertIn('Immediate Response', result['response_timeline'])
        self.assertTrue(len(result['contributing_factors']) > 0)
        self.assertTrue(len(result['recommendations']) > 0)

    def test_high_severity_prediction(self):
        # Scenario: Industrial fire with moderate casualties
        result = disaster_predictor.predict(
            disaster_type='Fire',
            people_affected=50,
            injured=12,
            missing=0,
            immediate_help=15,
            damage_level='High',
            infrastructure_damage=0,
            property_damage=1
        )
        self.assertIn(result['severity'], ['HIGH', 'CRITICAL'])
        self.assertIn(result['priority'], ['P1', 'P2'])

    def test_medium_severity_prediction(self):
        # Scenario: Minor landslide with limited casualties
        result = disaster_predictor.predict(
            disaster_type='Landslide',
            people_affected=30,
            injured=3,
            missing=0,
            immediate_help=5,
            damage_level='Medium',
            infrastructure_damage=1,
            property_damage=1
        )
        self.assertIn(result['severity'], ['MEDIUM', 'HIGH'])
        self.assertIn(result['priority'], ['P2', 'P3'])

    def test_low_severity_prediction(self):
        # Scenario: Minor localized accident with 0 missing and low damage
        result = disaster_predictor.predict(
            disaster_type='Accident',
            people_affected=5,
            injured=0,
            missing=0,
            immediate_help=0,
            damage_level='Low',
            infrastructure_damage=0,
            property_damage=0
        )
        self.assertEqual(result['severity'], 'LOW')
        self.assertEqual(result['priority'], 'P4')
        self.assertIn('Monitor', result['response_timeline'])

if __name__ == '__main__':
    unittest.main()
