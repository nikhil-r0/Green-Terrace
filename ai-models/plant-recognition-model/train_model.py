import os
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau

# Define constants
IMAGE_SIZE = (224, 224)
BATCH_SIZE = 20  # Increased batch size for more stable gradient updates
NUM_CLASSES_STAGES = 3 # Seedling, Mature, Flowering

# Create a custom model
def create_model():
    base_model = tf.keras.applications.EfficientNetB0(input_shape=(224, 224, 3), include_top=False, weights='imagenet')
    
    # Unfreeze some layers of the base model for fine-tuning
    for layer in base_model.layers[-50:]:
        layer.trainable = True

    inputs = layers.Input(shape=(224, 224, 3))
    x = base_model(inputs)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.5)(x)  # Add dropout to reduce overfitting

    # Output for plant stages classification
    stages_output = layers.Dense(NUM_CLASSES_STAGES, activation='softmax', name='stages_output')(x)
    
    model = models.Model(inputs=inputs, outputs=[stages_output])
    
    return model

# Prepare data generators
def prepare_data_generators(base_dir):
    train_datagen = ImageDataGenerator(
        rescale=1.0/255.0,
        validation_split=0.2,
        rotation_range=30,         # Random rotation
        width_shift_range=0.2,     # Horizontal shifts
        height_shift_range=0.2,    # Vertical shifts
        shear_range=0.2,           # Shear transformations
        zoom_range=0.2,            # Zooming
        horizontal_flip=True,      # Random horizontal flips
        fill_mode='nearest'        # Fill strategy for shifts
    )

    train_generator = train_datagen.flow_from_directory(
        base_dir,
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='sparse',  # Sparse class labels (integers)
        subset='training'
    )

    validation_datagen = ImageDataGenerator(
        rescale=1.0/255.0,
        validation_split=0.2
    )

    validation_generator = validation_datagen.flow_from_directory(
        base_dir,
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='sparse',
        subset='validation'
    )

    return train_generator, validation_generator

# Load data
dataset_dir = 'datasets/plant-dataset/stages'
train_generator, validation_generator = prepare_data_generators(dataset_dir)

# Create the model
model = create_model()
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),  # Lower learning rate for fine-tuning
    loss={'stages_output': 'sparse_categorical_crossentropy'},
    metrics={'stages_output': 'accuracy'}
)

# Define callbacks for early stopping and reducing learning rate on plateau
callbacks = [
    EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True),
    ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=3, min_lr=1e-6)
]

# Train the model with callbacks
history = model.fit(
    train_generator,
    validation_data=validation_generator,
    epochs=30,  # Train for more epochs
    callbacks=callbacks
)

# Save the model
model.save("plant_stages_classification_model.keras")
