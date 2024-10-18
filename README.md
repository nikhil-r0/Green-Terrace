# Green Terrace

## Overview
**Green Terrace** is an application designed for terrace farmers, both beginners and experienced gardeners. Our app leverages weather data from the user's location and a custom plant dataset to provide personalized farming suggestions. Whether you're growing flowers, vegetables, or fruits, Green Terrace tailors a farming plan just for you. The app also features a marketplace for buying or selling produce and tools, and a community space for sharing knowledge, guides, and tutorials. It connects users with nurseries, markets, and researchers, fostering a supportive ecosystem for terrace farming.

The project was built for the **BuzzOnEarth India Hackathon 2024**, which focuses on leveraging AI for sustainable urban development. The hackathon’s theme is "Application of AI for sustainable development of cities," with a focus on energy, water, waste, mobility, air quality, governance, and biodiversity. Supported by Intel® Tiber Developer Cloud, participants utilize Intel’s AI Stack to create innovative solutions that address sustainability challenges on a city-wide scale.

## Key Features
- **Personalized Crop Recommendations**: Based on local weather and a custom dataset, we suggest the best crops for your terrace garden.
- **Marketplace**: A platform for buying and selling produce, plants, and gardening tools.
- **Community Space**: Access tutorials, share your gardening journey, and connect with nurseries and researchers for additional support.
- **Chatbot Integration**: Implemented using Intel’s BERT uncased model from HuggingFace, the chatbot provides personalized support for terrace gardeners.
- **Plant Stage Recognition**: A machine learning model trained to recognize the different stages of plant growth.
- **Prototype ML Model**: The recommendation model currently runs locally due to limited cloud deployment options.

## Current Development Status
- **Under Development**: Many features, such as marketplace functionalities and the crop recommendation system, are placeholders and still being built.
- **Model Deployment**: The crop recommendation system runs locally on our laptops. So the recommendation system and chatbot will not be functional from the apk.

## Future Development Plans
1. **Image-Based Recommendations**: Use terrace or garden space images for more precise crop suggestions.
2. **Chatbot Enhancements**: Further improve the chatbot for real-time, personalized advice to terrace gardeners.
3. **Plant Stage Recognition Integration**: Add the plant stage recognition model (optimized with Intel's OpenVINO) to the user interface for crop monitoring.
4. **Carbon Coin Incentives**: Reward users with Carbon Coins for sustainable gardening achievements, verified via blockchain and AI. Coins can be redeemed for discounts and rewards.
5. **Partnerships**: Collaborate with local nurseries and suppliers for exclusive deals, advertising, and incentives.
6. **Gamification & Social Media**: Introduce challenges, leaderboards, and social media campaigns to engage younger generations in terrace gardening.

## Installation Instructions
To install and run the app, follow these steps:
1. Download the APK from: `Green-Terrace/apk-release`.
2. Install the APK on your Android device.
3. Open the app and explore the available features.

## Available Functionality
- **Community Page**: Engage with fellow terrace gardeners through guides and discussions.
- **Marketplace (Placeholder)**: The marketplace is still under development, and the current features are placeholders. Real transactions are not supported.


## Hackathon Requirements & Intel® Technology Stack
Green Terrace was developed as part of the **BuzzOnEarth India Hackathon 2024**, with a focus on AI-driven solutions for sustainable urban farming.

- **Intel® AI Stack**: We leveraged Intel’s AI stack to streamline the development process, providing performance-optimized tools for model training, inference, and deployment.
- **Intel® Tiber Developer Cloud**: The hackathon supported cloud-based AI development using Intel's cutting-edge hardware.
- **OpenVINO Toolkit**: We used Intel's OpenVINO toolkit to optimize our plant stage recognition model, enhancing performance for real-time crop monitoring.

