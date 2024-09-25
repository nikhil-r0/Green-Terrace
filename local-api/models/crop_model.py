import numpy as np
import requests
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
import tensorflow as tf
from sklearn.preprocessing import LabelEncoder
import pandas as pd
from datetime import datetime, timedelta
import json

# Load the crop data from the JSON file
with open('crop_data.json', 'r') as file:
    crop_data = json.load(file)

# Convert the list of dictionaries to a DataFrame
crop_df = pd.DataFrame(crop_data)
label_encoder = LabelEncoder()
label_encoder.fit(crop_df['label'])

# Process humidity range
# Convert humidity to string before applying split
crop_df['humidity'] = crop_df['humidity'].astype(str)

# Process humidity range
crop_df['humidity_min'] = crop_df['humidity'].apply(lambda x: float(x.split('-')[0]) if '-' in x else float(x))
crop_df['humidity_max'] = crop_df['humidity'].apply(lambda x: float(x.split('-')[1]) if '-' in x else float(x))


# Round off the crop data
crop_df = crop_df.round({
    'temp_min': 1,
    'temp_max': 1,
    'rainfall_min': 1,
    'rainfall_max': 1,
    'humidity_min': 1,
    'humidity_max': 1,
    'sunlight_min': 1,
    'sunlight_max': 1,
    'space_per_plant': 2
})

# Define features (X) and target (y)
X = crop_df[['temp_min', 'temp_max', 'rainfall_min', 'rainfall_max', 'humidity_min', 'humidity_max']]
y = crop_df['label']

# Split data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train a Random Forest Classifier
model = RandomForestClassifier()
model.fit(X_train, y_train)

def fetch_monthly_weather_data(latitude, longitude, start_date, end_date):
    """
    Fetches weather data for each day in the given date range and returns monthly averages.
    """
    url_template = "https://api.open-meteo.com/v1/forecast?latitude={}&longitude={}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,relative_humidity_2m_max,relative_humidity_2m_min&start_date={}&end_date={}"

    try:
        url = url_template.format(latitude, longitude, start_date, end_date)
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()

        daily_data = data['daily']

        # Calculate monthly averages
        avg_temp_max = round(sum(daily_data['temperature_2m_max']) / len(daily_data['temperature_2m_max']), 1)
        avg_temp_min = round(sum(daily_data['temperature_2m_min']) / len(daily_data['temperature_2m_min']), 1)
        avg_rainfall = round(sum(daily_data['precipitation_sum']) / len(daily_data['precipitation_sum']), 1)
        avg_humidity_max = round(sum(daily_data['relative_humidity_2m_max']) / len(daily_data['relative_humidity_2m_max']), 1)
        avg_humidity_min = round(sum(daily_data['relative_humidity_2m_min']) / len(daily_data['relative_humidity_2m_min']), 1)

        return {
            'temp_max': avg_temp_max,
            'temp_min': avg_temp_min,
            'humidity_max': avg_humidity_max,
            'humidity_min': avg_humidity_min,
            'rainfall': avg_rainfall
        }

    except requests.exceptions.HTTPError as http_err:
        print(f"HTTP error occurred: {http_err}")
    except Exception as err:
        print(f"An error occurred: {err}")
    return None

def predict_top_crops(weather_data, sunlight, area, top_n=5):
    """
    Predicts top N suitable crops based on weather data, sunlight, and area.
    Returns a string in the format 'Crop1:Quantity1, Crop2:Quantity2, ...'
    """
    import numpy as np

    # Load the TFLite model and allocate tensors
    interpreter = tf.lite.Interpreter(model_path='crop_model.tflite')
    interpreter.allocate_tensors()

    # Get input and output tensors
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Prepare input data
    avg_temp = (weather_data['temp_max'] + weather_data['temp_min']) / 2
    avg_humidity = (weather_data['humidity_max'] + weather_data['humidity_min']) / 2
    rainfall = weather_data['rainfall']

    input_data = np.array([[avg_temp, avg_humidity, rainfall, sunlight]], dtype=np.float32)

    # Set the tensor to point to the input data
    interpreter.set_tensor(input_details[0]['index'], input_data)

    # Run the inference
    interpreter.invoke()

    # Retrieve the output and get probabilities
    output_data = interpreter.get_tensor(output_details[0]['index'])
    probabilities = output_data[0]

    # Get top N crops
    top_indices = np.argsort(probabilities)[-top_n:][::-1]
    top_crops = [(label_encoder.inverse_transform([i])[0], probabilities[i]) for i in top_indices]

    # Map crop labels to space per plant
    crop_space_mapping = dict(zip(crop_df['label'], crop_df['space_per_plant']))

    suitable_crops = []
    for crop_label, probability in top_crops:
        space_per_plant = crop_space_mapping.get(crop_label, 1)  # default to 1 if not found
        num_plants = int(area // space_per_plant)
        suitable_crops.append((crop_label, num_plants))

    # Format the result as a string
    result = ", ".join([f"{crop}:{quantity}" for crop, quantity in suitable_crops])
    return result

def crop_detect(LAT, LON, SUN, ARE):
    # Prompt user for location
    latitude = float(LAT)
    longitude = float(LON)

    # Define the start and end dates for the month
    today = datetime.now()
    first_day_of_month = today.replace(day=1).strftime('%Y-%m-%d')
    last_day_of_month = (today.replace(day=28) + timedelta(days=4)).replace(day=1).strftime('%Y-%m-%d')

    print("Fetching monthly weather data...")
    current_weather_data = fetch_monthly_weather_data(latitude, longitude, first_day_of_month, last_day_of_month)

    if current_weather_data:
        print("Weather data retrieved successfully.")
        print(f"Current weather conditions: {current_weather_data}")

        # Prompt user for sunlight hours and area
        sunlight = float(SUN)
        area = float(ARE)

        # print("\nPredicting suitable crops...")
        # Predict suitable crops based on weather data, sunlight, and area
        predicted_crops = predict_top_crops(current_weather_data, sunlight, area)
        return (predicted_crops)
        # Display the results
        """if predicted_crops:
            # print("\nSuitable crops for the current conditions:")
            # print(predicted_crops)
        else:
            print("No suitable crops found for the current conditions.")
    else:
        print("Failed to fetch weather data. Please check your latitude and longitude values.")
"""