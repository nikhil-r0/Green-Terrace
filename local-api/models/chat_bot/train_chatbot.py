import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, Trainer, TrainingArguments
from datasets import load_dataset

# Check if GPU is available
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Running on: {device}")

# Step 2: Load the model and tokenizer from Hugging Face
model_name = "Intel/neural-chat-7b-v3-3"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name).to(device)

# Step 3: Load and preprocess the JSON dataset
# Assume the JSON file is uploaded to Colab's filesystem with format like:
# [{"question": "What is a green terrace?", "answer": "A green terrace is ..."}]

# Replace 'your_json_file.json' with the path to your uploaded JSON dataset
dataset = load_dataset('json', data_files='chatbot.json')

# Tokenization function for the dataset
def tokenize_function(examples):
    return tokenizer(examples["question"], padding="max_length", truncation=True, max_length=256)

# Apply tokenization to the dataset
tokenized_dataset = dataset.map(tokenize_function, batched=True)

# Step 4: Set up training arguments
training_args = TrainingArguments(
    output_dir="./results",
    per_device_train_batch_size=1,  # You can adjust this based on available memory
    num_train_epochs=3,
    logging_dir="./logs",
    logging_steps=100,
    evaluation_strategy="steps",  # Evaluate after each logging step
    eval_steps=100,
    save_total_limit=2,
    fp16=torch.cuda.is_available(),  # Enable FP16 training if on GPU
)

# Step 5: Set up the Trainer for fine-tuning
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=tokenized_dataset["train"],
    eval_dataset=tokenized_dataset["train"],  # Optionally, split into train and validation
)

# Step 6: Train the model
trainer.train()

# Step 7: Save the fine-tuned model and tokenizer
model.save_pretrained("./fine_tuned_model")
tokenizer.save_pretrained("./fine_tuned_model")
print("Model and tokenizer saved!")

# Step 8: Run a test with the fine-tuned model (optional)
def generate_response(prompt):
    inputs = tokenizer(prompt, return_tensors="pt").to(device)
    outputs = model.generate(inputs['input_ids'], max_length=50)
    return tokenizer.decode(outputs[0], skip_special_tokens=True)

# Example usage of the chatbot
response = generate_response("What is a green terrace?")
print(f"Chatbot response: {response}")
