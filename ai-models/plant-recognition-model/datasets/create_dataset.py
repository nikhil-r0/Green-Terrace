from labeler import preprocess_and_label_images
from scraper import scrape_google_images

folder_path = "plant-dataset/"
growth_stages = ["seedling","flowering","mature"]
plant_names = [{"plant" : "rose", "diseases": ["black spot", "powdery mildew"]}, {"plant" : "chickpea" , "diseases": ["fusarium wilt","ascochyta blight"]},]

def create_dataset():
    for plant in plant_names:
        plant_name = plant["plant"]
        plant_phrase = plant_name + " "
        plant_folder = folder_path + plant_name + "/"
        for disease in plant["diseases"]:
            search_phrase =  plant_phrase + disease + " leaves"
            current_folder = plant_folder +  "leaves/" + disease.replace(" ", "-") + "/"
            current_label = plant_name  + "_leaf_" + disease.replace(" ", "-")
            scrape_google_images(search_phrase,current_folder,num_images= 100)
            preprocess_and_label_images(current_folder,current_label)

        for stage in growth_stages:
            current_folder = plant_folder + stage
            search_phrase = plant_phrase + stage
            current_label = plant_name + "_healthy_" + stage
            scrape_google_images(search_phrase,current_folder,num_images= 100)
            preprocess_and_label_images(current_folder,current_label)

def label_all():
    for plant in plant_names:
        plant_name = plant["plant"]
        plant_folder = folder_path + plant_name + "/"
        for disease in plant["diseases"]:
            current_folder = plant_folder +  "leaves/" + disease.replace(" ", "-") + "/"
            current_label = plant_name  + "_leaf_" + disease.replace(" ", "-")
            preprocess_and_label_images(current_folder,current_label)

        for stage in growth_stages:
            current_folder = plant_folder + stage
            current_label = plant_name + "_healthy_" + stage
            preprocess_and_label_images(current_folder,current_label)

if __name__ == '__main__':
    label_all()