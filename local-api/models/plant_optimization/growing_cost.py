import pandas as pd
import json

# Function to calculate growing costs for a list of plants
def calculate_growing_costs_for_plants(csv_file, plant_list):
    # Load the CSV file into a DataFrame
    df = pd.read_csv(csv_file)

    # Constants: amount of fertilizer and pesticide used (in kg)
    fert_amount = 0.5  # kg
    pest_amount = 0.2  # kg

    # Function to calculate growing cost for each row
    def calculate_growing_cost(row):
        seed_cost = row['seed_cost']
        fert_cost = row['fert_cost'] * fert_amount if row['fert_req'] else 0
        pest_cost = row['pest_cost'] * pest_amount if row['pest_req'] else 0
        return seed_cost + fert_cost + pest_cost

    # Filter the DataFrame to include only the specified plants
    filtered_df = df[df['Label'].isin(plant_list)]

    # Apply the growing cost calculation function to the filtered DataFrame
    filtered_df['growing_cost'] = filtered_df.apply(calculate_growing_cost, axis=1)

    # Prepare the result in the specified format
    result = filtered_df[['Category', 'Label', 'growing_cost', 'fert_name', 'pest_name']].rename(columns={
        'Label': 'plant_name'
    })

    # Convert the result DataFrame to JSON format
    result_json = result.to_json(orient='records')

    # Return the JSON data
    return result_json

def get_plant_growing_cost(csv_file, plant_name):
    # Get the JSON output for all plants
    all_plants_json = calculate_growing_costs_for_plants(csv_file, [plant_name])
    
    # Parse the JSON string into a Python object
    plants_data = json.loads(all_plants_json)
    
    # Check if the plant was found
    if not plants_data:
        return None  # Plant not found
    
    # Extract the growing cost for the specified plant
    plant_data = plants_data[0]
    growing_cost = plant_data['growing_cost']
    
    return growing_cost

# Example usage:
if __name__ == '__main__':
    plant_list = ["Strawberry", "Lemon","Guava"]
    json_output = calculate_growing_costs_for_plants('est_growing_cost.csv', plant_list)
    print(json_output)
