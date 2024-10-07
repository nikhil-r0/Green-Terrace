import math
import json
from collections import defaultdict
import logging
from models.crp_prdct import crop_prediction_model
from models.mrkt_price import get_market_prices

# Set up logging for debugging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Define the average pot size
average_pot_size = 1

def safe_subtract(value1, value2, default=0):
    """Safely subtract two values, handling None types by substituting with a default."""
    return (value1 if value1 is not None else default) - (value2 if value2 is not None else default)


def calculate_scores(dataset, selected_categories, weight_savings, weight_carbon_absorption, max_savings, max_carb_absorption, market_prices):
    # Initialize a dictionary to store scores
    scores = defaultdict(list)

    # Logging initial values for debugging
    logger.debug(f"Dataset keys: {dataset.keys()}")
    logger.debug(f"Selected categories: {selected_categories}")
    logger.debug(f"Max savings: {max_savings}, Max carb absorption: {max_carb_absorption}")

    # Validation checks for input data
    if not dataset:
        logger.error("Empty dataset")
        return scores
    if not selected_categories:
        logger.error("No categories selected")
        return scores
    if max_savings == 0 or max_carb_absorption == 0:
        logger.error("max_savings or max_carb_absorption is zero")
        return scores

    # Loop over the selected categories and calculate scores for each plant
    for category, plants in dataset.items():
        if category in selected_categories:
            for plant in plants:
                # Get market price from API or default to the plant's own market price
                market_price = market_prices.get(plant["label"], plant.get("market_price", 0))
                if market_price is None:
                    market_price = 0  # Set a default value if no market price is found

                growing_price = int(plant["growing_price"]) if plant["growing_price"] is not None else 50  # Set a default value


                # Calculate savings as market_price - growing_price
                savings = safe_subtract(market_price, growing_price)
                score = ((savings / max_savings) * weight_savings) + (plant["carbon_absorption"] / max_carb_absorption * weight_carbon_absorption)

                # Append the plant details with its calculated score
                scores[category].append({
                    "label": plant["label"],
                    "score": score,
                    "savings": savings,
                    "carbon_absorption": plant["carbon_absorption"],
                    "growing_price": growing_price,
                    "market_price": market_price,
                    "temp_min": plant["temp_min"],
                    "temp_max": plant["temp_max"],
                    "rainfall": plant["rainfall"],
                    "sunlight_min": plant["sunlight_min"],
                    "perennial": plant["perennial"]
                })
                        
    # Sort plants by score within each category
    for category in scores:
        scores[category].sort(key=lambda x: x["score"], reverse=True)

    # Log the calculated scores for debugging
    logger.debug(f"Scores keys: {scores.keys()}")
    logger.debug(f"Number of plants per category: {[len(plants) for plants in scores.values()]}")

    return scores

def optimize_plants(scores, total_plants, total_budget):
    # Check for valid scores
    if not scores:
        logger.warning("No valid plant scores available.")
        return [], 0, 0, 0, 0

    optimized = []
    total_savings = 0
    total_carbon_absorbed = 0
    remaining_budget = total_budget
    remaining_plants = total_plants
    plant_counts = defaultdict(int)

    # Calculate the number of plants per category and allocate extra plants
    num_categories = len(scores.items())
    plants_per_category = math.floor(total_plants / num_categories)
    extra_plants = total_plants % num_categories

    # Iterate over each category and each plant within it
    for category, plants in scores.items():
        category_plants = plants_per_category + (1 if extra_plants > 0 else 0)
        extra_plants -= 1 if extra_plants > 0 else 0

        for plant in plants:
            # Determine how many plants to grow based on available budget and remaining plants
            if category_plants > 0 and remaining_budget >= plant["growing_price"] and plant_counts[plant["label"]] < 2:
                num_plants = min(category_plants, 
                                 math.floor(remaining_budget / plant["growing_price"]), 
                                 remaining_plants,
                                 total_plants // 10 - plant_counts[plant["label"]])

                if num_plants > 0:
                    plant_cost = num_plants * plant["growing_price"]
                    remaining_budget -= plant_cost
                    remaining_plants -= num_plants
                    category_plants -= num_plants
                    plant_counts[plant["label"]] += num_plants

                    optimized.append({
                        "label": plant["label"],
                        "carbon_absorption": plant["carbon_absorption"],
                        "savings": plant["market_price"] - plant["growing_price"],
                        "growing_price": plant["growing_price"],
                        "market_price": plant["market_price"]
                    })

                    total_savings += num_plants * plant["savings"]
                    total_carbon_absorbed += num_plants * plant["carbon_absorption"]

            # Break if no plants left to allocate in this category
            if category_plants == 0 or remaining_plants == 0 or remaining_budget < plant["growing_price"]:
                break

    return optimized, total_savings, total_carbon_absorbed, total_plants - remaining_plants, total_budget - remaining_budget

def recommend_crops(terrace_size, latitude, longitude, weight_savings, weight_carbon_absorption, total_budget, selected_categories):
    try:
        # Initial logging for debugging
        logger.info(f"Starting recommend_crops with parameters: terrace_size={terrace_size}, latitude={latitude}, "
                    f"longitude={longitude}, weight_savings={weight_savings}, weight_carbon_absorption={weight_carbon_absorption}, "
                    f"total_budget={total_budget}, selected_categories={selected_categories}")

        # Calculate total plants based on terrace size
        total_plants = terrace_size // average_pot_size
        logger.debug(f"Total plants: {total_plants}")

        # Fetch dataset and market prices
        dataset = crop_prediction_model(latitude, longitude)
        all_plant_names = [plant["label"] for category in selected_categories for plant in dataset.get(category, [])]
        market_prices = get_market_prices(all_plant_names)
        logger.debug(f"Market prices fetched: {market_prices}")

        # Determine max_savings and max_carbon_absorption
        max_savings, max_carb_absorption = 0, 0
        for category, plants in dataset.items():
            if category in selected_categories:
                for plant in plants:
                    market_price = market_prices.get(plant["label"], plant.get("market_price", 0))
                    
                    if market_price is None:
                        market_price = 0  # Set a default value if no market price is found

                    growing_price = int(plant["growing_price"]) if plant["growing_price"] is not None else 50  # Set a default value
                    # Calculate savings as market_price - growing_price
                    savings = safe_subtract(market_price, growing_price)

                    max_savings = max(max_savings, savings)
                    max_carb_absorption = max(max_carb_absorption, plant["carbon_absorption"])

        # Check for valid max values
        if max_savings == 0 or max_carb_absorption == 0:
            logger.warning("No valid plant data found for the given criteria.")
            return {"error": "No valid plant data found.", "total_savings": 0, "total_carbon_absorbed": 0, "total_plants_grown": 0, "total_budget_used": 0, "recommended_plants": []}

        # Calculate scores and optimize plant allocation
        scores = calculate_scores(dataset, selected_categories, weight_savings, weight_carbon_absorption, max_savings, max_carb_absorption, market_prices)
        recommended_plants, total_savings, total_carbon_absorbed, plants_grown, budget_used = optimize_plants(scores, total_plants, total_budget)
        logger.debug(f"Optimization results: recommended_plants={len(recommended_plants)}, total_savings={total_savings}, total_carbon_absorbed={total_carbon_absorbed}, plants_grown={plants_grown}, budget_used={budget_used}")

        # Format the output
        output = {
            "total_savings": sum(plant["savings"] for plant in recommended_plants),
            "total_carbon_absorbed": round(total_carbon_absorbed, 6),
            "total_plants_grown": plants_grown,
            "total_budget_used": budget_used,
            "recommended_plants": recommended_plants
        }
        logger.info("recommend_crops completed successfully")
        return output

    except Exception as e:
        logger.exception(f"An unexpected error occurred in recommend_crops: {str(e)}")
        return {"error": f"An unexpected error occurred: {str(e)}", "total_savings": 0, "total_carbon_absorbed": 0, "total_plants_grown": 0, "total_budget_used": 0, "recommended_plants": []}

# Main function to test recommend_crops with example parameters
if __name__ == "__main__":
    result = recommend_crops(100, 12, 71, 0.2, 0.8, 2000, ['Vegetables', 'Fruits'])
    print(json.dumps(result, indent=2))
