import json
import numpy as np
from sklearnex import patch_sklearn
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer

# Patch sklearn for performance optimization
patch_sklearn()

# Load the JSON data
with open('chatbot/chatbot.json', 'r') as f:
    data = json.load(f)
    
# Extract questions and answers
questions = [item['question'] for item in data]
answers = [item['answer'] for item in data]

# Encode labels
labels = np.arange(len(answers))

# Create a pipeline for TF-IDF and Logistic Regression
model = make_pipeline(
    TfidfVectorizer(),
    LogisticRegression()
)

# Split the dataset
X_train, X_test, y_train, y_test = train_test_split(questions, labels, test_size=0.2, random_state=42)

# Train the model
model.fit(X_train, y_train)

# Evaluate the model
accuracy = model.score(X_test, y_test)
print(f"Model Accuracy: {accuracy:.2f}")

# Function to get a response from the chatbot
def chatbot_response(user_input):
    prediction = model.predict([user_input])
    return answers[prediction[0]]
    
# Example usage
if __name__ == "__main__":
    print("Welcome to the Plant Care Chatbot! Type 'exit' to quit.")
    
    while True:
        user_input = input("You: ")
        if user_input.lower() == 'exit':
            print("Goodbye!")
            break
        
        response = chatbot_response(user_input)
        print(f"Bot: {response}")