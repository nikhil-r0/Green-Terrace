import pandas as pd
import joblib


def predict_market_prices(state, commodities):
    results = {}
    model = joblib.load('models/plant_optimization/market_price_model3.pkl')
    print("Model loaded from 'market_price_model.pkl'")
    # Prepare input data
    for commodity in commodities:
        input_data = pd.DataFrame({
            'state': [state],
            'commodity': [commodity],
            'variety': [""]  # Placeholder for the variety
        })
        
        try:
            predicted_price = model.predict(input_data)
            # Check if the prediction is valid
            results[commodity] = round(predicted_price[0], 2) if predicted_price[0] > 0 else 0
        except Exception as e:
            results[commodity] = 0  # Return 0 if an error occurs or price is not found
    
    return results

if __name__ == '__main__':
    state_input = "Karnataka"  # Change this as needed
    commodities_input = ["Brinjal"]  # Change this as needed
    predicted_prices = predict_market_prices(state_input, commodities_input)
    print(predicted_prices)