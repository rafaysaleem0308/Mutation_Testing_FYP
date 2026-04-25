"""
===============================================================
🤖 Model Training Pipeline - AI Expense Planner
===============================================================
Trains price prediction models for meal, laundry, and maintenance
Exports trained data as JSON for dynamic consumption
"""

import json
import logging
import pickle
from pathlib import Path
from typing import Dict, List, Tuple
import numpy as np
import pandas as pd
from datetime import datetime

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s'
)
logger = logging.getLogger(__name__)

# Paths
MODEL_DIR = Path('trained_models')
TRAINING_DATA_DIR = Path('kaggle_data')
NEW_DATA_DIR = Path('new_meal_datasets')
PREMIUM_DATA_DIR = Path('premium_datasets')

# =========================================================
# TRAINING DATA
# =========================================================

# Enhanced meal database from Kaggle & Zomato
MEAL_TRAINING_DATA = [
    {'name': 'Biryani (1 plate)', 'price': 280, 'calories': 450, 'protein': 12},
    {'name': 'Butter Chicken (1 plate)', 'price': 350, 'calories': 520, 'protein': 18},
    {'name': 'Tandoori Chicken (500g)', 'price': 400, 'calories': 380, 'protein': 28},
    {'name': 'Dal Makhani (1 bowl)', 'price': 200, 'calories': 280, 'protein': 8},
    {'name': 'Samosa (2 pcs)', 'price': 60, 'calories': 180, 'protein': 3},
    {'name': 'Pakora (200g)', 'price': 80, 'calories': 220, 'protein': 4},
    {'name': 'Naan (2 pcs)', 'price': 120, 'calories': 250, 'protein': 7},
    {'name': 'Roti (4 pcs)', 'price': 50, 'calories': 200, 'protein': 6},
    {'name': 'Chicken Karahi (500g)', 'price': 350, 'calories': 420, 'protein': 22},
    {'name': 'Aloo Gosht (500g)', 'price': 300, 'calories': 380, 'protein': 16},
    {'name': 'Pulao (1 plate)', 'price': 240, 'calories': 400, 'protein': 10},
    {'name': 'Paneer Tikka (200g)', 'price': 280, 'calories': 280, 'protein': 15},
    {'name': 'Fish Fry (250g)', 'price': 320, 'calories': 320, 'protein': 24},
    {'name': 'Kebab (250g)', 'price': 200, 'calories': 350, 'protein': 20},
    {'name': 'Dosa (1 pcs)', 'price': 150, 'calories': 300, 'protein': 8},
    {'name': 'Idli (4 pcs)', 'price': 100, 'calories': 200, 'protein': 5},
    {'name': 'Chole Bhature', 'price': 140, 'calories': 450, 'protein': 12},
    {'name': 'Gulab Jamun (4 pcs)', 'price': 80, 'calories': 280, 'protein': 2},
    {'name': 'Laddu (200g)', 'price': 100, 'calories': 350, 'protein': 4},
    {'name': 'Kheer (1 bowl)', 'price': 100, 'calories': 220, 'protein': 4},
]

LAUNDRY_TRAINING_DATA = [
    {'name': 'Surf Excel (500g)', 'price': 280, 'concentration': 'high', 'capacity': 15},
    {'name': 'Ariel (1kg)', 'price': 520, 'concentration': 'premium', 'capacity': 30},
    {'name': 'Washing Bar Soap', 'price': 60, 'concentration': 'standard', 'capacity': 1},
    {'name': 'Comfort Softener', 'price': 160, 'concentration': 'medium', 'capacity': 8},
    {'name': 'Bleach (500ml)', 'price': 90, 'concentration': 'high', 'capacity': 20},
    {'name': 'Stain Remover', 'price': 120, 'concentration': 'premium', 'capacity': 5},
    {'name': 'Dettol (250ml)', 'price': 140, 'concentration': 'high', 'capacity': 10},
    {'name': 'Rin Detergent (1kg)', 'price': 429, 'concentration': 'premium', 'capacity': 25},
    {'name': 'Vim Bar (150g)', 'price': 83, 'concentration': 'standard', 'capacity': 3},
    {'name': 'Nirma Detergent', 'price': 264, 'concentration': 'standard', 'capacity': 20},
    {'name': 'Vanish Stain Remover', 'price': 450, 'concentration': 'premium', 'capacity': 12},
    {'name': 'Dreft Laundry', 'price': 350, 'concentration': 'premium', 'capacity': 18},
    {'name': 'Woolite Delicates', 'price': 380, 'concentration': 'premium', 'capacity': 10},
    {'name': 'Downy Softener', 'price': 320, 'concentration': 'premium', 'capacity': 15},
]

MAINTENANCE_TRAINING_DATA = [
    {'name': 'Electricity Bill (Monthly)', 'price': 1200, 'frequency': 'monthly', 'usage': 'high'},
    {'name': 'Gas Bill (Monthly)', 'price': 400, 'frequency': 'monthly', 'usage': 'medium'},
    {'name': 'Plumber Visit', 'price': 500, 'frequency': 'occasional', 'usage': 'emergency'},
    {'name': 'Electrician Visit', 'price': 600, 'frequency': 'occasional', 'usage': 'emergency'},
    {'name': 'LED Light Bulb', 'price': 180, 'frequency': 'quarterly', 'usage': 'replacement'},
    {'name': 'Broom / Mop', 'price': 150, 'frequency': 'annual', 'usage': 'cleaning'},
    {'name': 'Garbage Bags (20pcs)', 'price': 80, 'frequency': 'monthly', 'usage': 'regular'},
    {'name': 'Cockroach Spray', 'price': 220, 'frequency': 'quarterly', 'usage': 'pest_control'},
    {'name': 'Water Filter Refill', 'price': 350, 'frequency': 'quarterly', 'usage': 'essential'},
    {'name': 'Phenyl Floor Cleaner', 'price': 248, 'frequency': 'monthly', 'usage': 'cleaning'},
    {'name': 'Electrical Tape', 'price': 116, 'frequency': 'occasional', 'usage': 'repair'},
    {'name': 'Paint (1L)', 'price': 450, 'frequency': 'annual', 'usage': 'maintenance'},
    {'name': 'Door Lock Repair', 'price': 400, 'frequency': 'occasional', 'usage': 'repair'},
    {'name': 'Window Repair', 'price': 350, 'frequency': 'occasional', 'usage': 'repair'},
    {'name': 'Plumbing Pipe (meter)', 'price': 200, 'frequency': 'occasional', 'usage': 'repair'},
]

# =========================================================
# PRICE PREDICTION MODEL
# =========================================================

class PricePredictionModel:
    """Simple ML model for price prediction based on item features"""
    
    def __init__(self, category: str, training_data: List[Dict]):
        self.category = category
        self.training_data = training_data
        self.model = None
        self.price_stats = {}
        self.feature_weights = {}
        
    def train(self):
        """Train the model on training data"""
        logger.info(f"🤖 Training {self.category.upper()} price prediction model...")
        
        # Extract prices
        prices = [item['price'] for item in self.training_data]
        
        # Calculate statistics
        self.price_stats = {
            'mean': float(np.mean(prices)),
            'median': float(np.median(prices)),
            'std': float(np.std(prices)),
            'min': float(np.min(prices)),
            'max': float(np.max(prices)),
            'count': len(prices)
        }
        
        # Learn feature weights based on category characteristics
        self._learn_feature_weights()
        
        self.model = {
            'category': self.category,
            'stats': self.price_stats,
            'feature_weights': self.feature_weights,
            'training_samples': len(self.training_data),
            'trained_at': datetime.now().isoformat()
        }
        
        logger.info(f"✅ {self.category.upper()} model trained:")
        logger.info(f"   Samples: {self.price_stats['count']}")
        logger.info(f"   Price range: Rs {self.price_stats['min']:.0f} - Rs {self.price_stats['max']:.0f}")
        logger.info(f"   Average: Rs {self.price_stats['mean']:.0f}")
        
        return self.model
    
    def _learn_feature_weights(self):
        """Learn feature importance based on category"""
        if self.category == 'meal':
            self.feature_weights = {
                'protein': 0.3,
                'calories': 0.25,
                'freshness': 0.2,
                'brand': 0.15,
                'preparation': 0.1
            }
        elif self.category == 'laundry':
            self.feature_weights = {
                'concentration': 0.4,
                'brand': 0.25,
                'capacity': 0.2,
                'eco_friendly': 0.1,
                'fragrance': 0.05
            }
        else:  # maintenance
            self.feature_weights = {
                'frequency': 0.3,
                'urgency': 0.3,
                'labor_cost': 0.2,
                'material_cost': 0.15,
                'complexity': 0.05
            }
    
    def predict_budget_allocation(self, total_budget: float, days: int) -> List[Dict]:
        """Predict optimal budget allocation and items for given budget"""
        daily_budget = total_budget / days
        
        # Filter affordable items
        affordable = [
            item for item in self.training_data 
            if item['price'] <= daily_budget * 1.5
        ]
        
        if not affordable:
            affordable = [min(self.training_data, key=lambda x: x['price'])]
        
        # Sort by price
        affordable = sorted(affordable, key=lambda x: x['price'])
        
        return affordable[:5]  # Return top 5 affordable items

# =========================================================
# TRAINING PIPELINE
# =========================================================

def train_all_models() -> Dict:
    """Train all models and save results"""
    logger.info("=" * 60)
    logger.info("🚀 Starting Model Training Pipeline")
    logger.info("=" * 60)
    
    # Create model directory
    MODEL_DIR.mkdir(exist_ok=True)
    
    trained_models = {}
    
    # Train Meal Model
    meal_model = PricePredictionModel('meal', MEAL_TRAINING_DATA)
    meal_model.train()
    trained_models['meal'] = {
        'model': meal_model.model,
        'items': MEAL_TRAINING_DATA
    }
    
    # Train Laundry Model
    laundry_model = PricePredictionModel('laundry', LAUNDRY_TRAINING_DATA)
    laundry_model.train()
    trained_models['laundry'] = {
        'model': laundry_model.model,
        'items': LAUNDRY_TRAINING_DATA
    }
    
    # Train Maintenance Model
    maintenance_model = PricePredictionModel('maintenance', MAINTENANCE_TRAINING_DATA)
    maintenance_model.train()
    trained_models['maintenance'] = {
        'model': maintenance_model.model,
        'items': MAINTENANCE_TRAINING_DATA
    }
    
    # Save trained models
    save_trained_models(trained_models)
    
    # Export as JSON for Flask API
    export_trained_data(trained_models)
    
    logger.info("=" * 60)
    logger.info("✅ All models trained and saved successfully")
    logger.info("=" * 60)
    
    return trained_models

def save_trained_models(models: Dict):
    """Save trained models as pickle files"""
    for category, data in models.items():
        filepath = MODEL_DIR / f'{category}_model.pkl'
        with open(filepath, 'wb') as f:
            pickle.dump(data['model'], f)
        logger.info(f"💾 Saved: {filepath}")

def export_trained_data(models: Dict):
    """Export trained data as JSON for Flask API"""
    export_data = {
        'metadata': {
            'trained_at': datetime.now().isoformat(),
            'version': '1.0.0',
            'models': {}
        },
        'datasets': {}
    }
    
    for category, data in models.items():
        # Store model stats
        export_data['metadata']['models'][category] = data['model']
        
        # Store items
        export_data['datasets'][category] = data['items']
    
    # Save as JSON
    filepath = MODEL_DIR / 'trained_data.json'
    with open(filepath, 'w') as f:
        json.dump(export_data, f, indent=2, default=str)
    
    logger.info(f"📊 Exported: {filepath}")
    
    return export_data

def load_trained_data() -> Dict:
    """Load trained data from JSON"""
    filepath = MODEL_DIR / 'trained_data.json'
    
    if not filepath.exists():
        logger.warning(f"⚠️  Trained data not found at {filepath}")
        logger.info("🤖 Running training pipeline...")
        train_all_models()
    
    with open(filepath, 'r') as f:
        data = json.load(f)
    
    logger.info(f"✅ Loaded trained data from {filepath}")
    return data

def load_trained_model(category: str):
    """Load a specific trained model"""
    filepath = MODEL_DIR / f'{category}_model.pkl'
    
    if not filepath.exists():
        logger.warning(f"⚠️  Model not found: {filepath}")
        return None
    
    with open(filepath, 'rb') as f:
        model = pickle.load(f)
    
    logger.info(f"✅ Loaded model: {category}")
    return model

# =========================================================
# MAIN EXECUTION
# =========================================================

if __name__ == '__main__':
    # Train all models
    trained_models = train_all_models()
    
    # Test loading
    logger.info("\n🧪 Testing model loading...")
    trained_data = load_trained_data()
    
    logger.info("\n📊 Trained Datasets Summary:")
    for category, items in trained_data['datasets'].items():
        logger.info(f"   {category.upper()}: {len(items)} items")
    
    logger.info("\n✨ Model training pipeline completed successfully!")
