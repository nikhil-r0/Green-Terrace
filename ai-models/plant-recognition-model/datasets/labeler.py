import os
import hashlib
from PIL import Image

def resize_image(image, size=(224, 224)):
    """Resize the image to the specified size."""
    return image.resize(size)

def calculate_image_hash(image_path):
    """Calculate the hash of an image to identify duplicates."""
    with open(image_path, 'rb') as f:
        img_hash = hashlib.md5(f.read()).hexdigest()
    return img_hash

def preprocess_and_save_images_with_hashes(folder_path, size=(224, 224)):
    """Preprocess images: resizing, removing duplicates, and saving with hashes as filenames."""
    image_hashes = {}
    images_to_rename = []

    # First pass: resize images, check for duplicates, and save with hash as filename
    for root, dirs, files in os.walk(folder_path):
        for filename in files:
            if filename.endswith(('.jpg', '.jpeg', '.png')):
                image_path = os.path.join(root, filename)

                # Check for duplicates using hash
                img_hash = calculate_image_hash(image_path)
                if img_hash in image_hashes:
                    os.remove(image_path)  # Remove duplicate image
                    continue  # Skip processing this image

                # Process and resize image if no duplicate
                with Image.open(image_path) as img:
                    resized_img = resize_image(img, size)
                    
                    # Save the image with its hash as the new filename
                    new_filename = f"{img_hash}.jpg"
                    new_path = os.path.join(folder_path, new_filename)
                    resized_img.save(new_path, format='JPEG')

                    # Keep track of the saved image for renaming in the next phase
                    images_to_rename.append(new_path)

                # Add hash to the dictionary to track duplicates
                image_hashes[img_hash] = new_path

                # Remove the original image after processing and saving with a hash name
                os.remove(image_path)

    return images_to_rename

def get_available_filename(folder_path, category_name, count):
    """Generate an available filename by checking for existing files and incrementing the number if needed."""
    while True:
        new_filename = f"{category_name}_{str(count).zfill(3)}.jpg"
        new_path = os.path.join(folder_path, new_filename)
        if not os.path.exists(new_path):
            return new_path, count
        count += 1

def rename_images_with_labels(folder_path, images_to_rename, category_name):
    """Rename images with appropriate labels."""
    count = 1

    for image_path in images_to_rename:
        # Generate a new filename with category_name and sequential numbering
        new_path, count = get_available_filename(folder_path, category_name, count)

        # Rename the image
        os.rename(image_path, new_path)

        count += 1

def preprocess_and_label_images(folder_path, category_name, size=(224, 224)):
    """Complete pipeline: resize images, remove duplicates, save with hashes, then rename with labels."""
    # First phase: Resize and save images with hashes as filenames, removing the originals
    images_to_rename = preprocess_and_save_images_with_hashes(folder_path, size)

    # Second phase: Rename images with category labels
    rename_images_with_labels(folder_path, images_to_rename, category_name)

# Example usage
if __name__ == '__main__':
    folder_path = "plant-dataset/stages/mature"  # Update with your images folder path
    category_name = "mature"     # Update with your category name
    preprocess_and_label_images(folder_path, category_name)
