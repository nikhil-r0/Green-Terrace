import requests
import pandas as pd
from io import StringIO
from datetime import datetime
import math

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

            # Convert the price to per kg and floor to an integer
            avg_price_per_kg = math.floor(avg_price_per_100kg / 100)
            return avg_price_per_kg

        return None
    except requests.exceptions.RequestException as e:
        print(f"Error fetching market price for {crop}: {e}")
        return None
    except pd.errors.EmptyDataError:
        print(f"No data available for {crop} on {formatted_date}")
        return None

# Standalone function to get market prices for a list of crops
def get_market_prices(crop_list):
    date = datetime.now()
    prices = {}

    for crop in crop_list:
        price = get_market_price(crop, date)
        if price is not None:
            prices[crop] = price
        else:
            print(f"No market price available for {crop} on {date.strftime('%d/%m/%Y')}")
            prices[crop] = None

    return prices

# Example usage
# if __name__ == "__main__":
#      # Example input list of crops
#      crops_to_check = ['Tomato', 'Papaya', 'Onion']
#      market_prices = get_market_prices(crops_to_check)
    
#      # Print the results
#      print(market_prices)
