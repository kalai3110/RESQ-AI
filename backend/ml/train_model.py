import os
import json
import joblib
import numpy as np
import pandas as pd
from sklearn.tree import DecisionTreeClassifier, export_text
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score

# Disaster Types encoding
DISASTER_TYPES = ['Flood', 'Cyclone', 'Earthquake', 'Fire', 'Landslide', 'Accident', 'Other']
DAMAGE_LEVELS = {'Low': 1, 'Medium': 2, 'High': 3, 'Critical': 4}
SEVERITY_CLASSES = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
PRIORITY_MAPPING = {
    'CRITICAL': {'code': 'P1', 'title': 'Critical', 'response': 'Immediate Response Required (< 30 mins)', 'color': '#E53935'},
    'HIGH':     {'code': 'P2', 'title': 'High',     'response': 'Very Urgent Response (< 2 hours)',        'color': '#FB8C00'},
    'MEDIUM':   {'code': 'P3', 'title': 'Medium',   'response': 'Normal Response (< 6 hours)',             'color': '#FFB300'},
    'LOW':      {'code': 'P4', 'title': 'Low',      'response': 'Monitor & Routine Assistance',            'color': '#43A047'}
}

FEATURE_COLUMNS = [
    'disaster_type_code',
    'people_affected',
    'injured',
    'missing',
    'immediate_help_required',
    'damage_level_code',
    'infrastructure_damage',
    'property_damage'
]

def generate_synthetic_disaster_dataset(num_samples=3000, random_state=42):
    np.random.seed(random_state)
    records = []

    for _ in range(num_samples):
        d_type = np.random.choice(DISASTER_TYPES, p=[0.25, 0.15, 0.15, 0.20, 0.10, 0.10, 0.05])
        
        # Base scale depending on disaster type
        if d_type in ['Earthquake', 'Cyclone', 'Flood']:
            affected = int(np.random.exponential(scale=250)) + np.random.randint(5, 50)
            damage_prob = [0.1, 0.2, 0.4, 0.3]
        elif d_type in ['Fire', 'Landslide']:
            affected = int(np.random.exponential(scale=80)) + np.random.randint(2, 30)
            damage_prob = [0.15, 0.3, 0.35, 0.2]
        else:
            affected = int(np.random.exponential(scale=30)) + np.random.randint(1, 15)
            damage_prob = [0.4, 0.35, 0.2, 0.05]
            
        damage_name = np.random.choice(['Low', 'Medium', 'High', 'Critical'], p=damage_prob)
        damage_num = DAMAGE_LEVELS[damage_name]
        
        # Derived values correlated with affected population and damage level
        injured = int(np.random.binomial(affected, 0.15 * (damage_num / 2.0)))
        missing = int(np.random.binomial(affected, 0.05 * (damage_num / 2.5)))
        immediate_help = int(np.random.binomial(affected, 0.20 * (damage_num / 2.0)))
        
        infra_damage = 1 if (damage_num >= 3 or (damage_num == 2 and np.random.rand() > 0.5)) else 0
        property_damage = 1 if (damage_num >= 2 or np.random.rand() > 0.3) else 0

        # Ground truth severity logic reflecting emergency disaster response standards
              # ========================================================
        # AI SEVERITY SCORING
        # Disaster Type + Affected People + Emergency Factors
        # ========================================================

        severity_score = (
            (affected * 0.60) +
            (injured * 4.0) +
            (missing * 5.0) +
            (immediate_help * 3.0) +
            (damage_num * 15.0) +
            (infra_damage * 10.0) +
            (property_damage * 5.0)
        )

        # High-risk disaster types receive additional weight
        if d_type in ['Earthquake', 'Flood', 'Cyclone']:
            severity_score += 10

        elif d_type in ['Fire', 'Landslide']:
            severity_score += 5

        # ========================================================
        # SEVERITY CLASSIFICATION
        # ========================================================

        if (
            severity_score >= 120
            or injured >= 25
            or missing >= 8
            or immediate_help >= 35
            or damage_num == 4
        ):
            severity = 'CRITICAL'

        elif (
            severity_score >= 60
            or injured >= 8
            or missing >= 2
            or immediate_help >= 12
            or damage_num == 3
            or affected >= 50
        ):
            severity = 'HIGH'

        elif (
            severity_score >= 25
            or injured >= 2
            or immediate_help >= 3
            or damage_num == 2
            or affected >= 10
        ):
            severity = 'MEDIUM'

        else:
            severity = 'LOW'

        type_idx = DISASTER_TYPES.index(d_type)
        severity_idx = SEVERITY_CLASSES.index(severity)
        
        records.append({
            'disaster_type': d_type,
            'disaster_type_code': type_idx,
            'people_affected': affected,
            'injured': injured,
            'missing': missing,
            'immediate_help_required': immediate_help,
            'damage_level': damage_name,
            'damage_level_code': damage_num,
            'infrastructure_damage': infra_damage,
            'property_damage': property_damage,
            'severity': severity,
            'severity_code': severity_idx
        })

    df = pd.DataFrame(records)
    return df

def train_and_save_model(output_dir=None):
    if output_dir is None:
        output_dir = os.path.dirname(os.path.abspath(__file__))
    
    os.makedirs(output_dir, exist_ok=True)
    df = generate_synthetic_disaster_dataset(num_samples=3000)
    
    csv_path = os.path.join(output_dir, 'disaster_dataset.csv')
    df.to_csv(csv_path, index=False)
    print(f"[OK] Saved synthetic training dataset to {csv_path} with {len(df)} samples.")
    
    X = df[FEATURE_COLUMNS]
    y = df['severity_code']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
    
    # Train Decision Tree Classifier
    clf = DecisionTreeClassifier(
        criterion='gini',
        max_depth=6,
        min_samples_split=8,
        min_samples_leaf=4,
        random_state=42
    )
    clf.fit(X_train, y_train)
    
    y_pred = clf.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    print(f"[OK] Decision Tree Model Accuracy on Test Set: {acc * 100:.2f}%")
    
    # Save model artifact
    model_path = os.path.join(output_dir, 'disaster_model.pkl')
    joblib.dump(clf, model_path)
    print(f"[OK] Serialized model saved to {model_path}")
    
    # Save metadata
    meta = {
        'disaster_types': DISASTER_TYPES,
        'damage_levels': DAMAGE_LEVELS,
        'severity_classes': SEVERITY_CLASSES,
        'priority_mapping': PRIORITY_MAPPING,
        'feature_columns': FEATURE_COLUMNS,
        'accuracy': float(acc),
        'tree_depth': int(clf.get_depth()),
        'num_leaves': int(clf.get_n_leaves()),
        'feature_importances': {
            col: float(imp) for col, imp in zip(FEATURE_COLUMNS, clf.feature_importances_)
        }
    }
    
    meta_path = os.path.join(output_dir, 'model_meta.json')
    with open(meta_path, 'w') as f:
        json.dump(meta, f, indent=2)
    print(f"[OK] Saved model metadata to {meta_path}")

if __name__ == '__main__':
    train_and_save_model()
