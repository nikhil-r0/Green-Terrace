from flask import Flask, request, jsonify
from models.plant_optimization import recommend_crops
import logging

# Set up logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/recommend_crops', methods=['POST'])
def api_recommend_crops():
    try:
        logger.info("Received request for /recommend_crops")
        data = request.json

        result = recommend_crops(
            terrace_size=data['terrace_size'],
            latitude=data['latitude'],
            longitude=data['longitude'],
            weight_savings=data['savings_weight'],
            weight_carbon_absorption=data['weight_carbon_absorption'],
            total_budget=data['budget'],
            selected_categories=data['types']
        )
        logger.info("recomend_crops function completed")
        logger.debug(f"Result: {result}")

        return jsonify(result)
    except Exception as e:
        logger.exception(f"An error occurred in api_recommend_crops: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host =  '0.0.0.0',port = 5000,debug=True)