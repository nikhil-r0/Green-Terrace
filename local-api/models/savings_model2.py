import json
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import requests
from io import StringIO

# Function to get market price for a specific crop
def get_market_price(crop, date):
    base_url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    api_key = "579b464db66ec23bdd000001c0a290a221ac4a1e7f41626aaf9ee723"  # Replace with your actual API key

    formatted_date = date.strftime("%d/%m/%Y")

    params = {
        "api-key": api_key,
        "format": "csv",
        "filters[commodity]": crop,
        "filters[arrival_date]": formatted_date,
        "limit": 1000
    }

    try:
        response = requests.get(base_url, params=params)
        response.raise_for_status()

        df = pd.read_csv(StringIO(response.text))

        if not df.empty:
            df.columns = ['State', 'District', 'Market', 'Commodity', 'Variety', 'Grade', 'Arrival_Date', 'Min_Price', 'Max_Price', 'Modal_Price']
            avg_price_per_100kg = df['Modal_Price'].mean()

            # Convert the price to per kg
            avg_price_per_kg = avg_price_per_100kg / 100
            return avg_price_per_kg

        return None
    except requests.exceptions.RequestException as e:
        print(f"Error fetching market price: {e}")
        return None
    except pd.errors.EmptyDataError:
        print(f"No data available for {crop} on {formatted_date}")
        return None

# Function to collect two days' worth of market price data
def collect_two_day_data(crop):
    data = []
    end_date = datetime.now()
    start_date = end_date - timedelta(days=2)  # This will give us 2 days of data including today
    current_date = start_date
    while current_date <= end_date:
        price = get_market_price(crop, current_date)
        if price is not None:
            data.append({'date': current_date, 'price': price})
        current_date += timedelta(days=1)
    return pd.DataFrame(data)


# Function to estimate savings
# Function to estimate savings per plant (assuming each plant yields 1 kg)
# Function to estimate savings for a given crop type
def estimate_savings_per_crop(crop, quantity, growing_cost):
    df = collect_two_day_data(crop)
    if df.empty:
        print(f"No data available for {crop} in the past two days.")
        return None

    current_price = df['price'].iloc[-1]
    estimated_future_price = current_price  # Simplified: using current price as future price estimate

    # Assuming one plant yields 1 kg
    market_cost_per_plant = estimated_future_price  # Market cost per kg (for one plant)
    growing_total_cost_per_plant = growing_cost     # Growing cost per kg (for one plant)
    savings_per_plant = market_cost_per_plant - growing_total_cost_per_plant

    # Calculate total savings for the entire quantity
    total_savings = savings_per_plant * quantity

    # Create a string summary for this crop
    result_str = f"--- {crop} ---\n"
    result_str += f"Current market price: ₹{current_price:.2f} per kg\n"
    result_str += f"Estimated future market price: ₹{estimated_future_price:.2f} per kg\n"
    result_str += f"Growing cost per plant: ₹{growing_total_cost_per_plant:.2f}\n"
    result_str += f"Estimated savings per plant: ₹{savings_per_plant:.2f}\n"

    return result_str, total_savings


# Example usage
crop = "Wheat"       # Example crop name
quantity = 10        # Example number of plants (assumed to be 1 kg per plant)
growing_cost = 15.0  # Example growing cost per kg

result = estimate_savings_per_crop(crop, quantity, growing_cost)
print(result)



# Function to load plant data from the JSON file
def load_plant_data(crop_name, file_path):
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)

        if 'plants' in data and isinstance(data['plants'], list):
            for plant in data['plants']:
                if plant['name'].lower() == crop_name.lower():
                    return plant
        else:
            print(f"JSON structure is not as expected. Here's what we found:")
            print(json.dumps(data, indent=2))
            return None
    except json.JSONDecodeError:
        print(f"Error: The file at {file_path} is not a valid JSON file.")
        return None
    except FileNotFoundError:
        print(f"Error: The file at {file_path} was not found.")
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")
        return None

    print(f"No data found for the crop '{crop_name}'.")
    return None

    return res

# Example usage
crop = "Wheat"       # Example crop name
quantity = 10        # Example number of plants (assumed to be 1 kg per plant)
growing_cost = 15.0  # Example growing cost per kg

result = estimate_savings_per_crop(crop, quantity, growing_cost)
print(result)



# Function to load plant data from the JSON file
def load_plant_data(crop_name, file_path):
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)

        if 'plants' in data and isinstance(data['plants'], list):
            for plant in data['plants']:
                if plant['name'].lower() == crop_name.lower():
                    return plant
        else:
            print(f"JSON structure is not as expected. Here's what we found:")
            print(json.dumps(data, indent=2))
            return None
    except json.JSONDecodeError:
        print(f"Error: The file at {file_path} is not a valid JSON file.")
        return None
    except FileNotFoundError:
        print(f"Error: The file at {file_path} was not found.")
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")
        return None

    print(f"No data found for the crop '{crop_name}'.")
    return None