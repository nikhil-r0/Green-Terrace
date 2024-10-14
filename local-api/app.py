from flask import Flask, request, jsonify
from models.plant_optimization.plant_optm import recommend_crops
from models.chat_bot.chatbot import answer_question
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
        logger.debug(f"Request data: {data}")

        result = recommend_crops(
            terrace_size=data['terrace_size'],
            latitude=data['latitude'],
            longitude=data['longitude'],
            weight_savings=data['savings_weight'],
            weight_carbon_absorption=data['weight_carbon_absorption'],
            total_budget=data['budget'],
            selected_categories=data['types'],
        )

        logger.info("Crops recommendation API completed successfully")
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error in /recommend_crops API: {str(e)}")
        return jsonify({"error": str(e)}), 500
    
@app.route('/chatbot', methods=['POST'])
def api_chatbot():
    try:
        logger.info("Received request for /chatbot")
        data = request.json
        logger.debug(f"Request data: {data}")

        result = answer_question(data['question'])

        logger.info("Query answered successfully.")
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error in /chatbot API: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host = '0.0.0.0', port=4000)
