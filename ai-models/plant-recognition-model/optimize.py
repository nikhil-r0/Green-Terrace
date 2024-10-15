import tensorflow as tf

# Load your Keras model
model = tf.keras.models.load_model("plant_stages_classification_model.keras")

# Save it as SavedModel format (directory-based)
model.export("plant_stage_classification_model_saved_model")
