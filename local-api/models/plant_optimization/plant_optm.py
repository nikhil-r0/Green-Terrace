import pandas as pd
import numpy as np
import logging
from models.plant_optimization.get_weth_data import get_weather_data
from models.plant_optimization.growing_cost import get_plant_growing_cost
from models.plant_optimization.predict_market_data import predict_market_prices
from models.plant_optimization.get_address import fetch_state

# Set up logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Constants
PLANT_SIZE = 0.5  # Each plant takes 0.5 square meters
PERENNIAL_CARBON_WEIGHT = 1.5
PERENNIAL_SAVINGS_WEIGHT = 1.2
PLANT_DATA_CSV= 'models/datasets/plant_data.csv'  # Assume this is the correct path to your CSV file
GROWING_COST_CSV = 'models/datasets/est_growing_cost.csv'

def load_plant_data(file_path):
    """Loads plant data from CSV file."""
    try:
        logger.info(f"Loading plant data from {file_path}")
        plant_data = pd.read_csv(file_path)
        logger.debug(f"Loaded {len(plant_data)} plants from {file_path}")
        return plant_data
    except Exception as e:
        logger.error(f"Error loading plant data: {str(e)}")
        raise

def filter_plants_by_weather(plant_data, weather_data):
    """Filters plants based on compatibility with weather data."""
    try:
        logger.info("Filtering plants based on weather data")
        temp_min = weather_data['temp_min']
        temp_max = weather_data['temp_max']
        sunlight = weather_data['sunlight']

        filtered_plants = plant_data[
            (plant_data['Temp Min'] <= temp_max) & 
            (plant_data['Temp Max'] >= temp_min) & 
            (plant_data['Sunlight Min'] <= sunlight)
        ]
        logger.debug(f"Filtered plants count: {len(filtered_plants)}")
        return filtered_plants
    except Exception as e:
        logger.error(f"Error filtering plants: {str(e)}")
        raise

def calculate_savings(plant_data, state):
    """Calculates savings for each plant based on market price and growing cost."""
    try:
        logger.info("Calculating savings for plants")
        
        # Get market prices
        commodities = plant_data['Label'].tolist()
        market_prices = predict_market_prices(state, commodities)
        
        def get_savings(row):
            plant_name = row['Label']
            market_price = market_prices.get(plant_name, 0) / 100  # Convert price per quintal to price per kg
            
            if market_price == 0:
                market_price = row['Market Price']  # Use existing market price if prediction is 0
            
            growing_cost = get_plant_growing_cost(GROWING_COST_CSV, plant_name)
            
            if growing_cost == 0:
                growing_cost = row['Growing Price']  # Use existing growing cost if prediction is 0
            
            savings = market_price - growing_cost
            return max(savings, 0)  # Ensure savings are not negative
        
        plant_data['Savings'] = plant_data.apply(get_savings, axis=1)
        logger.debug(f"Calculated savings for plants: {plant_data[['Label', 'Savings']].head()}")
        return plant_data
    except Exception as e:
        logger.error(f"Error calculating savings: {str(e)}")
        raise

def score_plants(plant_data, weight_savings, weight_carbon_absorption):
    """Scores plants based on user preferences."""
    try:
        logger.info("Scoring plants based on user preferences")
        plant_data['Score'] = (
            weight_savings * plant_data['Savings'] +
            weight_carbon_absorption * plant_data['Carbon Absorption'] * 
            np.where(plant_data['Perennial'] == 'Yes', PERENNIAL_CARBON_WEIGHT, 1)
        )
        logger.debug(f"Scored plants: {plant_data[['Label', 'Score']].head()}")
        return plant_data
    except Exception as e:
        logger.error(f"Error scoring plants: {str(e)}")
        raise

def allocate_plants(plant_data, terrace_size, budget, selected_categories, weight_savings, weight_carbon_absorption):
    """Allocates plants based on terrace size, budget, and preferences."""
    try:
        logger.info("Allocating plants based on constraints")

        max_plants = int(terrace_size / PLANT_SIZE)
        logger.debug(f"Max plants to allocate: {max_plants}")

        selected_plants = plant_data[plant_data['Category'].isin(selected_categories)]
        selected_plants = score_plants(selected_plants, weight_savings, weight_carbon_absorption)
        sorted_plants = selected_plants.sort_values(by='Score', ascending=False)

        total_cost = 0
        allocated_plants = []
        plant_counts = {category: 0 for category in selected_categories}

        for index, row in sorted_plants.iterrows():
            if total_cost + row['Growing Price'] > budget or len(allocated_plants) >= max_plants:
                break
            if plant_counts[row['Category']] < max_plants / len(selected_categories):

                allocated_plants.append(row)
                plant_counts[row['Category']] += 1
                total_cost += row['Growing Price']
                
        total_savings = sum([plant['Savings'] for plant in allocated_plants])
        total_carbon_absorption = sum([plant['Carbon Absorption'] for plant in allocated_plants])

        logger.info(f"Total plants allocated: {len(allocated_plants)}")
        logger.debug(f"Total savings: {total_savings}, Total carbon absorption: {total_carbon_absorption}")

        return allocated_plants, total_savings, total_carbon_absorption
    except Exception as e:
        logger.error(f"Error allocating plants: {str(e)}")
        raise

def recommend_crops(terrace_size, latitude, longitude, weight_savings, weight_carbon_absorption, total_budget, selected_categories):
    """Main function to recommend crops."""
    state = fetch_state(latitude,longitude)
    logger.info(state)
    try:
        logger.info("Starting recommend_crops function")

        # Load plant data (including carbon absorption)
        plant_data = load_plant_data(PLANT_DATA_CSV)

        # Get weather data
        weather_data = get_weather_data(latitude, longitude)
        logger.info(weather_data)

        # Filter plants based on weather compatibility
        filtered_plants = filter_plants_by_weather(plant_data, weather_data)

        # Calculate savings for filtered plants
        filtered_plants = calculate_savings(filtered_plants, state)

        # Allocate plants based on the constraints
        allocated_plants, total_savings, total_carbon_absorption = allocate_plants(
            filtered_plants, 
            terrace_size, 
            total_budget, 
            selected_categories, 
            weight_savings, 
            weight_carbon_absorption
        )

        # Prepare response
        plant_list = [{
            "label": plant["Label"],
            "category": plant["Category"],
            "savings": plant["Savings"],
            "growing_price": plant["Growing Price"],
            "carbon_absorption": plant["Carbon Absorption"]
            } for plant in allocated_plants]

        result = {
            "recommended_plants": plant_list,
            "total_savings": total_savings,
            "total_carbon_absorption": total_carbon_absorption
        }

        logger.info("Crops recommendation completed successfully")
        return result
    except Exception as e:
        logger.error(f"Error in recommend_crops: {str(e)}")
        raise


def main():
    # Set up logging
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    logger = logging.getLogger(__name__)

    # Test parameters
    terrace_size = 20  # square meters
    latitude = 28.6139  # Delhi latitude
    longitude = 77.2090  # Delhi longitude
    weight_savings = 0.6
    weight_carbon_absorption = 0.2
    total_budget = 5000  # rupees
    selected_categories = ["Vegetables", "Fruits", "Herbs"]


    try:
        logger.info("Starting crop recommendation test")
        
        # Call the recommend_crops function
        result = recommend_crops(
            terrace_size, 
            latitude, 
            longitude, 
            weight_savings, 
            weight_carbon_absorption, 
            total_budget, 
            selected_categories, 
        )

        # Check the result
        logger.info("Crop recommendation completed. Checking results...")

        # Print allocated plants
        logger.info("Allocated plants:")
        for plant in result["allocated_plants"]:
            logger.info(f"- {plant['Label']} ({plant['Category']}): Savings = {plant['Savings']:.2f}, Carbon Absorption = {plant['Carbon Absorption']}")

        # Print total savings and carbon absorption
        logger.info(f"Total Savings: {result['total_savings']:.2f}")
        logger.info(f"Total Carbon Absorption: {result['total_carbon_absorption']:.2f}")

        # Perform some basic checks
        assert len(result["allocated_plants"]) > 0, "No plants were allocated"
        assert result["total_savings"] >= 0, "Total savings should not be negative"
        assert result["total_carbon_absorption"] >= 0, "Total carbon absorption should not be negative"

        # Check if all selected categories are represented
        allocated_categories = set(plant["Category"] for plant in result["allocated_plants"])
        assert allocated_categories.issubset(set(selected_categories)), "Allocated plants include categories not in selected_categories"

        logger.info("All checks passed successfully!")

    except Exception as e:
        logger.error(f"An error occurred during the test: {str(e)}")
        raise

if __name__ == "__main__":
    main()