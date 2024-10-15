import os
import time
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model
from openvino.runtime import Core
from tensorflow.keras.applications.efficientnet import preprocess_input
from PIL import Image

# Constants
IMAGE_SIZE = (224, 224)
BATCH_SIZE = 1  # Batch size for testing each image one by one

# Load the original Keras model
keras_model = load_model("plant_stages_classification_model.keras")

# Load the OpenVINO optimized model
core = Core()
ov_model = core.read_model("openvino_model/model.xml")
compiled_ov_model = core.compile_model(ov_model, "CPU")

# Function to load all images from a directory and its subdirectories
def load_images_from_directory(directory):
    images = []
    image_paths = []

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(('.jpg', '.png', '.jpeg')):
                image_path = os.path.join(root, file)
                image = Image.open(image_path).resize(IMAGE_SIZE)
                image = np.array(image)
                images.append(image)
                image_paths.append(image_path)

    return np.array(images), image_paths

# Preprocess images for both models
def preprocess_images(images):
    return preprocess_input(images)

# Benchmark function for Keras model
def benchmark_keras_model(images):
    start_time = time.time()

    for image in images:
        image = np.expand_dims(image, axis=0)  # Add batch dimension
        keras_model.predict(image)

    end_time = time.time()
    keras_duration = end_time - start_time
    print(f"Keras model inference time for {len(images)} images: {keras_duration:.4f} seconds")
    return keras_duration

# Benchmark function for OpenVINO model
def benchmark_openvino_model(images):
    input_layer = compiled_ov_model.input(0)  # Get input layer for OpenVINO model
    start_time = time.time()

    for image in images:
        image = np.expand_dims(image, axis=0)  # Add batch dimension
        image = image.astype(np.float32)       # OpenVINO expects float32
        compiled_ov_model([image])

    end_time = time.time()
    ov_duration = end_time - start_time
    print(f"OpenVINO model inference time for {len(images)} images: {ov_duration:.4f} seconds")
    return ov_duration

# Main function to run the benchmark
def run_benchmark(image_folder):
    # Load images from folder and its subfolders
    images, image_paths = load_images_from_directory(image_folder)

    # Preprocess images for both models
    images = preprocess_images(images)

    # Run benchmark for Keras model
    keras_time = benchmark_keras_model(images)

    # Run benchmark for OpenVINO model
    ov_time = benchmark_openvino_model(images)

    # Print comparison results
    print(f"Keras Model Total Time: {keras_time:.4f} seconds")
    print(f"OpenVINO Model Total Time: {ov_time:.4f} seconds")
    print(f"OpenVINO is {keras_time / ov_time:.2f}x faster than the Keras model.")

# Provide the folder containing the test images
image_folder = "datasets/plant-dataset/species"  # Adjust this path as needed
run_benchmark(image_folder)
