import requests
import json

# API endpoint URL
url = "http://127.0.0.1:5000/recommend_crops"

# Sample data for testing
test_data = {
    "terrace_size": 100,
    "latitude": 12,
    "longitude": 71,
    "savings_weight": 0.3,
    "weight_carbon_absorption": 0.7,
    "budget": 2000,
    "types": ["Fruits", "Vegetables"]
}

def test_api():
    try:
        # Send POST request to the API
        response = requests.post(url, json=test_data)
        
        # Check if the request was successful
        if response.status_code == 200:
            # Parse the JSON response
            result = response.json()
            
            # Print the results
            print("API Response:")
            print(json.dumps(result, indent=2))
            
            # You can add more specific checks here, for example:
            assert "recommended_plants" in result, "Missing 'recommended_plants' in response"
            assert "total_savings" in result, "Missing 'total_savings' in response"
            assert "total_carbon_absorbed" in result, "Missing 'total_carbon_absorbed' in response"
            
            print("\nAll checks passed. The API is working as expected.")
        else:
            print(f"Error: Received status code {response.status_code}")
            print("Response content:")
            print(response.text)
    
    except requests.exceptions.RequestException as e:
        print(f"Error connecting to the API: {e}")
    except json.JSONDecodeError:
        print("Error: Unable to parse the API response as JSON")
    except AssertionError as e:
        print(f"Test failed: {e}")

if __name__ == "__main__":
    test_api()