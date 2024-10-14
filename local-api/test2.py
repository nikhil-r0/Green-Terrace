import requests
import json

# API endpoint URL
url = "http://127.0.0.1:4000/chatbot"

# Sample data for testing
test_data = {
    "question": "roses"
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
    except requests.exceptions.RequestException as e:
        print(f"Error connecting to the API: {e}")
    except json.JSONDecodeError:
        print("Error: Unable to parse the API response as JSON")
    except AssertionError as e:
        print(f"Test failed: {e}")

if __name__ == "__main__":
    test_api()