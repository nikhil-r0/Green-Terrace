import numpy as np
import onnxruntime as ort
from transformers import AutoTokenizer
import json

# Load the tokenizer
tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")  # Adjust if you're using a different model

# Load the ONNX model
model_path = "chatbot_model.onnx"  # Update this path to your model's location
session_options = ort.SessionOptions()
session_options.intra_op_num_threads = 1
session_options.inter_op_num_threads = 1
session = ort.InferenceSession(model_path, sess_options=session_options)

# Get the input name and shape
input_name = session.get_inputs()[0].name
input_shape = session.get_inputs()[0].shape
print(f"Expected input shape: {input_shape}")

# Load the JSON file with questions and answers
json_file_path = "chatbot.json"  # Update this path to your JSON file
with open(json_file_path, 'r') as file:
    qa_data = json.load(file)

def process_query(query):
    # Tokenize the input
    inputs = tokenizer(query, return_tensors="np", padding="max_length", truncation=True, max_length=input_shape[1])
    input_ids = inputs["input_ids"]

    # Ensure the input shape matches the model's expected shape
    if input_ids.shape != tuple(input_shape):
        print(f"Adjusting input shape from {input_ids.shape} to {tuple(input_shape)}")
        input_ids = np.pad(input_ids, ((0, max(0, input_shape[0] - input_ids.shape[0])), 
                                       (0, max(0, input_shape[1] - input_ids.shape[1]))),
                           mode='constant', constant_values=0)
        input_ids = input_ids[:input_shape[0], :input_shape[1]]

    # Run inference
    output = session.run(None, {input_name: input_ids})

    # Process the output
    probabilities = output[0][0]  # Assuming the output is already in probability form
    predicted_class = np.argmax(probabilities)
    confidence = np.max(probabilities)

    return predicted_class, confidence, probabilities

def find_best_match(query):
    best_match = None
    highest_similarity = 0

    for qa_pair in qa_data:
        similarity = sum(w in qa_pair['question'].lower() for w in query.lower().split()) / len(query.split())
        if similarity > highest_similarity:
            highest_similarity = similarity
            best_match = qa_pair

    return best_match, highest_similarity

def get_response(query, predicted_class, probabilities):
    # First, try to find a direct match in the JSON data
    best_match, similarity = find_best_match(query)
    
    if similarity > 0.8:  # You can adjust this threshold
        return best_match['answer']
    
    # If no good match in JSON, use the model's prediction
    responses = {
        0: "I'm not sure how to respond to that.",
        1: "Hello! How can I assist you today?",
        2: "The weather is quite nice today!",
        3: "I'm afraid I don't have personal opinions on that topic.",
        # Add more responses for each class your model can predict, up to 37
    }
    response = responses.get(predicted_class, "I'm not sure how to respond to that.")
    
    # Get the index of the class with the 3rd highest probability
    third_highest_class_index = np.argsort(probabilities)[-3]  # Get the index of the 3rd highest class
    third_highest_probability = probabilities[third_highest_class_index]

    # Include the 3rd highest class in the response
    response += f" Additionally, the class with the 3rd highest probability is class {third_highest_class_index} with a probability of {third_highest_probability:.2f}."

    # You can use the full probability distribution to provide more nuanced responses
    if np.sum(probabilities > 0.1) > 1:  # If there are multiple high-probability classes
        response += " However, I'm considering multiple possible responses."
    
    return response

def chat_loop():
    print("Chatbot: Hello! How can I help you today? (Type 'exit' to end the conversation)")
    while True:
        user_input = input("You: ")
        if user_input.lower() == 'exit':
            print("Chatbot: Goodbye! Have a great day!")
            break
        
        predicted_class, confidence, probabilities = process_query(user_input)
        response = get_response(user_input, predicted_class, probabilities)
        
        print(f"Chatbot: {response}")
        print(f"Confidence: {confidence:.2f}")
        print(f"Top 3 classes: {np.argsort(probabilities)[-3:][::-1]}")
        print(f"Top 3 probabilities: {probabilities[np.argsort(probabilities)[-3:][::-1]]}")

def answer_question(user_input):
    predicted_class, confidence, probabilities = process_query(user_input)
    response = get_response(user_input, predicted_class, probabilities)
    result = {
        "answer": response
    }
    return result

if __name__ == "__main__":
    chat_loop()
