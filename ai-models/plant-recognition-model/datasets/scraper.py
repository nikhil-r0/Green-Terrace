import os
import time
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.keys import Keys
from io import BytesIO
from PIL import Image  # For image format conversion

# Function to download images from Google Images
def scrape_google_images(search_query, download_path, num_images=10):
    # Create download folder if it doesn't exist
    if not os.path.exists(download_path):
        os.makedirs(download_path)
        print("Created download folder:", download_path)

    # Set up Selenium WebDriver (Assumes ChromeDriver is in your PATH)
    options = Options()
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    print("WebDriver initialized")

    # Navigate to Google Images
    search_url = f"https://www.google.com/search?q={search_query}&tbm=isch"
    driver.get(search_url)
    print("Navigated to URL:", search_url)

    # Scroll to load more images
    for _ in range(5):
        driver.find_element(By.TAG_NAME, 'body').send_keys(Keys.END)
        time.sleep(5)  # Pause to allow images to load
        print("Scrolled to end of page")

    # Find image elements with full-size URL
    images = driver.find_elements(By.CSS_SELECTOR, ".YQ4gaf")  # Use the same selector for thumbnails
    print("Found", len(images), "image elements")
    img_urls = set()
    img_count = 0

    # Extract the image URLs directly
    for img in images:
        try:
            src = img.get_attribute("src")  # Try to get the URL from the thumbnail itself
            if "http" in src and src not in img_urls:
                img_urls.add(src)
                img_count += 1
                print("Added image URL:", src)
            else:
                # If not available, try a different selector for full-size image (replace with a selector that points to the full-size image on Google Images)
                full_img = img.find_element(By.CSS_SELECTOR, ".RKks6d img")  # Replace with appropriate selector
                full_src = full_img.get_attribute("src")
                if "http" in full_src and full_src not in img_urls:
                    img_urls.add(full_src)
                    img_count += 1
                    print("Added full-size image URL:", full_src)
            if img_count >= num_images:
                break
        except Exception as e:
            print(f"Error getting image URL: {e}")
        if img_count >= num_images:
            break

    # Download each image with error handling and format conversion
    for i, img_url in enumerate(img_urls):
        try:
            response = requests.get(img_url, timeout=10)  # Add timeout
            response.raise_for_status()  # Raise an exception for HTTP errors

            img_data = response.content
            img_name = os.path.join(download_path, f"{search_query}_{str(i+1).zfill(2)}.jpg")

            # Convert image to JPEG if necessary (adjust format as needed)
            img = Image.open(BytesIO(img_data))
            img.save(img_name, format="JPEG")

            print(f"Downloaded {img_name}")
        except requests.exceptions.RequestException as e:
            print(f"Error downloading {img_url}: {e}")
        except Exception as e:
            print(f"Error processing image: {e}")

    driver.quit()


# Usage Example:
# Specify the search term and download folder
if __name__ == '__main__':
    search_term = "fully grown vegetables with plant"
    download_folder = "plant-dataset/stages/mature"

    # Scrape Google Images and download them
    scrape_google_images(search_term, download_folder, num_images=2000)