import json
import numpy as np
from sklearn.model_selection import train_test_split
from weather_data import get_weather_data

# Import and patch scikit-learn with Intel optimizations
from sklearnex import patch_sklearn
patch_sklearn()

# Now import the RandomForestClassifier from the patched sklearn
from sklearn.ensemble import RandomForestClassifier

def load_plant_data(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

def prepare_data(plant_data, climate_data):
    X = []
    y = []
    
    for types in plant_data:
        for plants in types.items():
            for plant in plants[1]:
                temp_min = plant['temp_min']
                temp_max = plant['temp_max']
                rainfall = plant['rainfall']
                sunlight_min = plant['sunlight_min']
                
                if (climate_data['avg_temp_min'] >= temp_min and 
                    climate_data['avg_temp_max'] <= temp_max and
                    climate_data['avg_daylight_duration']/3600 >= sunlight_min):
                    suitability = 1
                else:
                    suitability = 0
                
                X.append([temp_min, temp_max, rainfall, sunlight_min])
                y.append(suitability)
    
    return np.array(X), np.array(y)

def train_model(X_train, y_train):
    # Using the Intel-optimized RandomForestClassifier
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    return model

def predict_suitability(plant, model):
    features = [
        plant['temp_min'],
        plant['temp_max'],
        plant['rainfall'],
        plant['sunlight_min']
    ]
    return model.predict([features])[0]

def categorize_predicted_plants(plant_data, model):
    count=0
    predicted_plants = {}

    for category in plant_data:
        for plants in category.items():
            predicted_plants[plants[0]] = []
            for plant in plants[1]:
                if predict_suitability(plant, model):
                    predicted_plants[plants[0]].append(plant)
                    count=count+1
    print(count)
    
    return predicted_plants


def crop_prediction_model(latitude, longitude):
    # Load plant data
    plant_data = load_plant_data('plant_data.json')
    
    # Fetch weather data
    weather_data = get_weather_data(latitude, longitude, "2024-09-01", "2024-09-20")
    weather_data = {key: round(value, 3) for key, value in weather_data.items()}
    
    # Prepare data for training
    X, y = prepare_data(plant_data, weather_data)
    
    # Split the data into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Train the model using Intel-optimized RandomForestClassifier
    model = train_model(X_train, y_train)
    
    # Predict and categorize plants
    predicted_plants = categorize_predicted_plants(plant_data, model)
    
    return predicted_plants

# If you want to test the function independently
# if __name__ == "__main__":
#     result = crop_prediction_model(12,72)
#     print(json.dumps(result, indent=2))