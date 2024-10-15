from openvino.runtime import Core
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing import image

IMAGE_SIZE = (224, 224)
CLASS_NAMES_STAGES = ['flowering', 'mature', 'seedling']  # Adjust based on actual class names
CLASS_NAMES_SPECIES = ['chickpea','rose','strawberry','tomato']
CLASS_NAMES_HEALTH = ['diseased','healthy']

def preprocess_image(image_path):
    img = image.load_img(image_path, target_size=IMAGE_SIZE)
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
    img_array /= 255.0  # Rescale to [0, 1] as done in training
    return img_array

def predict_stage(image_path):
    img_array = preprocess_image(image_path)
    predictions = model.predict(img_array)
    predicted_class = np.argmax(predictions, axis=-1)[0]  # Get the index of the highest probability
    return CLASS_NAMES_STAGES[predicted_class], predictions

# Initialize the OpenVINO runtime
core = Core()

# Load the converted model (OpenVINO IR)
model = core.read_model("openvino_model/saved_model.xml")

# Compile the model
compiled_model = core.compile_model(model, "CPU")

# Prepare input data and perform inference
test_image_path = 'datasets/plant-dataset/stages/seedling/seedling_007.jpg'
input_data = preprocess_image(test_image_path)  # Your input data (ensure preprocessing is done appropriately)
input_layer = compiled_model.input(0)  # Select input layer
output = compiled_model([input_data])  # Perform inference

# Output the results
print(output)
