import requests
import logging

logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def get_weather_data(latitude, longitude):
    """
    Fetch weather data from the Open-Meteo API for a specified location and date range.

    Args:
        latitude (float): Geographic latitude of the location.
        longitude (float): Geographic longitude of the location.
        start_date (str): Start date in YYYY-MM-DD format.
        end_date (str): End date in YYYY-MM-DD format.

    Returns:
        dict: Average temperature, rainfall, and daylight duration.
    """
    start_date = "2024-09-01"
    end_date = "2024-09-20"
    url = f"https://api.open-meteo.com/v1/forecast"
    
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "start_date": start_date,
        "end_date": end_date,
        "daily": ["temperature_2m_max", "temperature_2m_min", "rain_sum", "sunshine_duration"],
        "timezone": "auto"
    }
    
    response = requests.get(url, params=params)
    
    if response.status_code == 200:
        data = response.json()['daily']
        
        # Calculate averages
        avg_temp_max = sum(data['temperature_2m_max']) / len(data['temperature_2m_max'])
        avg_temp_min = sum(data['temperature_2m_min']) / len(data['temperature_2m_min'])
        avg_rain_sum = sum(data['rain_sum']) / len(data['rain_sum'])
        avg_daylight_duration = sum(data['sunshine_duration']) / len(data['sunshine_duration'])
        
        return {
            "temp_max": avg_temp_max,
            "temp_min": avg_temp_min,
            "rainfall": avg_rain_sum,
            "sunlight": avg_daylight_duration
        }
    else:
        raise Exception(f"Failed to fetch weather data. Status code: {response.status_code}")

# If you want to test the function independently
if __name__ == "__main__":
    latitude = 19.0760
    longitude = 72.8777
    start_date = "2024-09-01"
    end_date = "2024-09-20"
    
    weather_data = get_weather_data(latitude, longitude)
    print(weather_data)
