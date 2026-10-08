import os
import json
import joblib
import pandas as pd
import numpy as np


class DisasterDecisionTreePredictor:

    def __init__(self, model_dir=None):
        if model_dir is None:
            model_dir = os.path.dirname(os.path.abspath(__file__))

        self.model_dir = model_dir
        self.model_path = os.path.join(
            model_dir,
            'disaster_model.pkl'
        )
        self.meta_path = os.path.join(
            model_dir,
            'model_meta.json'
        )

        self.model = None
        self.meta = {}

        self.disaster_types = [
            'Flood',
            'Cyclone',
            'Earthquake',
            'Fire',
            'Landslide',
            'Accident',
            'Other'
        ]

        self.damage_levels = {
            'Low': 1,
            'Medium': 2,
            'High': 3,
            'Critical': 4
        }

        self.severity_classes = [
            'LOW',
            'MEDIUM',
            'HIGH',
            'CRITICAL'
        ]

        self.priority_mapping = {
            'CRITICAL': {
                'code': 'P1',
                'title': 'Critical',
                'response': 'Immediate Response Required (< 30 mins)',
                'color': '#E53935'
            },
            'HIGH': {
                'code': 'P2',
                'title': 'High',
                'response': 'Very Urgent Response (< 2 hours)',
                'color': '#FB8C00'
            },
            'MEDIUM': {
                'code': 'P3',
                'title': 'Medium',
                'response': 'Normal Response (< 6 hours)',
                'color': '#FFB300'
            },
            'LOW': {
                'code': 'P4',
                'title': 'Low',
                'response': 'Monitor & Routine Assistance',
                'color': '#43A047'
            }
        }

        self.feature_columns = [
            'disaster_type_code',
            'people_affected',
            'injured',
            'missing',
            'immediate_help_required',
            'damage_level_code',
            'infrastructure_damage',
            'property_damage'
        ]

        self._load_model()


    # ============================================================
    # LOAD MODEL
    # ============================================================

    def _load_model(self):

        try:

            if (
                os.path.exists(self.model_path)
                and os.path.exists(self.meta_path)
            ):

                self.model = joblib.load(
                    self.model_path
                )

                with open(
                    self.meta_path,
                    'r'
                ) as f:

                    self.meta = json.load(f)

                    self.disaster_types = self.meta.get(
                        'disaster_types',
                        self.disaster_types
                    )

                    self.damage_levels = self.meta.get(
                        'damage_levels',
                        self.damage_levels
                    )

                    self.severity_classes = self.meta.get(
                        'severity_classes',
                        self.severity_classes
                    )

                    self.priority_mapping = self.meta.get(
                        'priority_mapping',
                        self.priority_mapping
                    )

                    self.feature_columns = self.meta.get(
                        'feature_columns',
                        self.feature_columns
                    )

                print(
                    "[OK] Disaster Decision Tree Model successfully loaded."
                )

            else:

                from .train_model import train_and_save_model

                train_and_save_model(
                    self.model_dir
                )

                self.model = joblib.load(
                    self.model_path
                )

        except Exception as e:

            print(
                f"[ERROR] Failed to load Decision Tree model: {e}"
            )

            self.model = None


    # ============================================================
    # ENCODE INPUTS
    # ============================================================

    def encode_inputs(
        self,
        disaster_type,
        people_affected,
        injured,
        missing,
        immediate_help,
        damage_level,
        infrastructure_damage=0,
        property_damage=0
    ):

        d_type_clean = (
            disaster_type.strip().capitalize()
            if disaster_type
            else 'Other'
        )

        if d_type_clean not in self.disaster_types:

            matches = [
                t
                for t in self.disaster_types
                if t.lower() == d_type_clean.lower()
            ]

            d_type_clean = (
                matches[0]
                if matches
                else 'Other'
            )

        d_type_code = self.disaster_types.index(
            d_type_clean
        )

        d_level_clean = (
            damage_level.strip().capitalize()
            if damage_level
            else 'Medium'
        )

        d_level_code = self.damage_levels.get(
            d_level_clean,
            2
        )

        affected_val = max(
            0,
            int(people_affected or 0)
        )

        injured_val = max(
            0,
            int(injured or 0)
        )

        missing_val = max(
            0,
            int(missing or 0)
        )

        immediate_val = max(
            0,
            int(immediate_help or 0)
        )

        infra_val = (
            1
            if infrastructure_damage in [
                1,
                True,
                '1',
                'true',
                'True'
            ]
            else 0
        )

        prop_val = (
            1
            if property_damage in [
                1,
                True,
                '1',
                'true',
                'True'
            ]
            else 0
        )

        vector = [
            d_type_code,
            affected_val,
            injured_val,
            missing_val,
            immediate_val,
            d_level_code,
            infra_val,
            prop_val
        ]

        cleaned = {
            'disaster_type': d_type_clean,
            'people_affected': affected_val,
            'injured': injured_val,
            'missing': missing_val,
            'immediate_help_required': immediate_val,
            'damage_level': d_level_clean,
            'infrastructure_damage': infra_val,
            'property_damage': prop_val
        }

        return vector, cleaned


    # ============================================================
    # PREDICT DISASTER SEVERITY
    # ============================================================

    def predict(
        self,
        disaster_type,
        people_affected,
        injured,
        missing,
        immediate_help,
        damage_level,
        infrastructure_damage=0,
        property_damage=0
    ):

        # ========================================================
        # CLEAN AND VALIDATE INPUTS
        # ========================================================

        vector, cleaned = self.encode_inputs(
            disaster_type,
            people_affected,
            injured,
            missing,
            immediate_help,
            damage_level,
            infrastructure_damage,
            property_damage
        )

        # ========================================================
        # AI DECISION TREE PREDICTION
        # ========================================================

        if self.model is not None:

            # Use the trained Decision Tree model
            X = pd.DataFrame(
                [vector],
                columns=self.feature_columns
            )

            prediction_code = int(
                self.model.predict(X)[0]
            )

            # Convert numeric class to severity name
            if 0 <= prediction_code < len(self.severity_classes):
                severity = self.severity_classes[prediction_code]
            else:
                severity = 'LOW'

            # Get probability/confidence if available
            try:

                probabilities = self.model.predict_proba(X)[0]

                prob_dict = {}

                for index, class_code in enumerate(
                    self.model.classes_
                ):

                    class_index = int(class_code)

                    if (
                        0 <= class_index
                        < len(self.severity_classes)
                    ):

                        class_name = self.severity_classes[
                            class_index
                        ]

                        prob_dict[class_name] = round(
                            float(probabilities[index]),
                            3
                        )

                confidence = round(
                    float(max(probabilities)),
                    3
                )

            except Exception:

                prob_dict = {
                    'LOW': 0.0,
                    'MEDIUM': 0.0,
                    'HIGH': 0.0,
                    'CRITICAL': 0.0
                }

                prob_dict[severity] = 1.0
                confidence = 1.0

        else:

            # Safe fallback if model is unavailable
            # This keeps the existing project working.

            affected = cleaned['people_affected']

            if affected >= 1000:

                severity = 'CRITICAL'

            elif affected >= 100:

                severity = 'HIGH'

            elif affected >= 20:

                severity = 'MEDIUM'

            else:

                severity = 'LOW'

            prob_dict = {
                'LOW': 0.0,
                'MEDIUM': 0.0,
                'HIGH': 0.0,
                'CRITICAL': 0.0
            }

            prob_dict[severity] = 1.0
            confidence = 1.0


        # ========================================================
        # PRIORITY MAPPING
        # ========================================================

        priority_info = self.priority_mapping.get(
            severity,
            self.priority_mapping['LOW']
        )

        priority_code = priority_info.get(
            'code',
            'P4'
        )

        priority_title = priority_info.get(
            'title',
            'Low'
        )

        response_time = priority_info.get(
            'response',
            'Monitor & Routine Assistance'
        )

        # ========================================================
        # CONTRIBUTING FACTORS
        # ========================================================

        contributing_factors = (
            self._get_contributing_factors(
                cleaned,
                severity
            )
        )

        # ========================================================
        # AI RECOMMENDATIONS
        # ========================================================

        recommendations = (
            self._get_recommendations(
                severity,
                cleaned
            )
        )

        # ========================================================
        # FINAL AI RESULT
        # ========================================================

        return {

            'disaster_type':
                cleaned['disaster_type'],

            'people_affected':
                cleaned['people_affected'],

            'injured':
                cleaned['injured'],

            'missing':
                cleaned['missing'],

            'immediate_help_required':
                cleaned['immediate_help_required'],

            'damage_level':
                cleaned['damage_level'],

            'infrastructure_damage':
                cleaned['infrastructure_damage'],

            'property_damage':
                cleaned['property_damage'],

            'severity':
                severity,

            'severity_display':
                f"{severity} SEVERITY",

            'priority':
                priority_code,

            'priority_title':
                priority_title,

            'priority_display':
                f"{priority_code} – {priority_title}",

            'response_timeline':
                response_time,

            'color':
                priority_info.get(
                    'color',
                    '#FFB300'
                ),

            'confidence':
                confidence,

            'class_probabilities':
                prob_dict,

            'contributing_factors':
                contributing_factors,

            'recommendations':
                recommendations,

            'algorithm':
                'AI Decision Tree Disaster Severity Classification'
        }
        # ============================================================
        # CONTRIBUTING FACTORS
        # ============================================================


    def _get_contributing_factors(
        self,
        data,
        severity
    ):

        factors = []

        if data['injured'] > 0:

            factors.append(
                f"Casualties: {data['injured']} injured "
                f"individuals requiring immediate medical triage"
            )

        if data['missing'] > 0:

            factors.append(
                f"Missing Persons: {data['missing']} people "
                f"unaccounted for requiring search & rescue"
            )

        if data['immediate_help_required'] > 0:

            factors.append(
                f"Urgent Distress: "
                f"{data['immediate_help_required']} people "
                f"in urgent danger"
            )

        if data['people_affected'] > 50:

            factors.append(
                f"Large-Scale Impact: "
                f"{data['people_affected']} people directly "
                f"affected in zone"
            )

        if data['damage_level'] in [
            'High',
            'Critical'
        ]:

            factors.append(
                f"Severe Structural Impact: "
                f"{data['damage_level']} structural damage level"
            )

        if data['infrastructure_damage'] == 1:

            factors.append(
                "Critical infrastructure "
                "(roads/power/water) compromised"
            )

        if not factors:

            factors.append(
                "Localized incident with minimal reported "
                "structural or personal damage"
            )

        return factors


    # ============================================================
    # RECOMMENDATIONS
    # ============================================================

    def _get_recommendations(
        self,
        severity,
        data
    ):

        recs = []

        if severity == 'CRITICAL':

            recs.append(
                "Deploy National/State Disaster Response "
                "Teams (NDRF/SDRF) immediately"
            )

            if data['injured'] > 0:

                recs.append(
                    "Dispatch Emergency Advanced Life Support "
                    "(ALS) Ambulances and establish field triage"
                )

            recs.append(
                "Activate emergency relief shelters and "
                "community evacuation protocols"
            )

            recs.append(
                "Mobilize heavy rescue equipment and "
                "emergency air/boat support"
            )

        elif severity == 'HIGH':

            recs.append(
                "Deploy Local Quick Response Rescue Teams "
                "to location"
            )

            if data['injured'] > 0:

                recs.append(
                    "Dispatch Basic Life Support (BLS) "
                    "Ambulances & First Aid teams"
                )

            recs.append(
                "Prepare nearby relief shelters "
                "for incoming evacuees"
            )

            recs.append(
                "Distribute emergency food packets, "
                "potable drinking water, and blankets"
            )

        elif severity == 'MEDIUM':

            recs.append(
                "Dispatch Local Municipal Assistance "
                "& Civil Defense volunteers"
            )

            recs.append(
                "Monitor shelter capacity and coordinate "
                "relief supplies distribution"
            )

            recs.append(
                "Ensure medical first-aid availability "
                "at designated safe points"
            )

        else:

            recs.append(
                "Assign local patrol unit to monitor "
                "incident status"
            )

            recs.append(
                "Provide standard municipal assistance "
                "if requested"
            )

        return recs


# ============================================================
# GLOBAL PREDICTOR INSTANCE
# ============================================================

disaster_predictor = DisasterDecisionTreePredictor()