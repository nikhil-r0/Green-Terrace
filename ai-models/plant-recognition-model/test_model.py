import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing import image
import os

# Constants
IMAGE_SIZE = (224, 224)
CLASS_NAMES_STAGES = ['flowering', 'mature', 'seedling']  # Adjust based on actual class names
CLASS_NAMES_SPECIES = ['chickpea','rose','strawberry','tomato']
CLASS_NAMES_HEALTH = ['diseased','healthy']
# Load the trained model
model = tf.keras.models.load_model('plant_stages_classification_model.keras')

# Function to preprocess the image
def preprocess_image(image_path):
    img = image.load_img(image_path, target_size=IMAGE_SIZE)
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
    img_array /= 255.0  # Rescale to [0, 1] as done in training
    return img_array

# Function to predict the class of a given image
def predict_stage(image_path):
    img_array = preprocess_image(image_path)
    predictions = model.predict(img_array)
    predicted_class = np.argmax(predictions, axis=-1)[0]  # Get the index of the highest probability
    return CLASS_NAMES_STAGES[predicted_class], predictions

# Test the model on a single image
test_image_path = 'datasets/plant-dataset/stages/flowering/flowering_00'  # Replace with the actual image path
for i in range(1,100):
    test_image_path_current = test_image_path + str(i) + '.jpg'
    predicted_class, prediction_probs = predict_stage(test_image_path_current)

    print(f"Predicted stage: {predicted_class}")
    # print(f"Prediction probabilities: {prediction_probs}")
