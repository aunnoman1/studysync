from transformers import AutoModelForVision2Seq, AutoProcessor

# Define the model you want to download
model_name = 'microsoft/kosmos-2.5'

# Define the local path to save it
save_path = 'models/ocr'

print(f"Downloading model: {model_name}...")

# Download the model and processor from Hugging Face
# trust_remote_code=True is often required for newer Microsoft models
processor = AutoProcessor.from_pretrained(model_name, trust_remote_code=True)
model = AutoModelForVision2Seq.from_pretrained(model_name, trust_remote_code=True)

# Save the model's files and processor to the local path
model.save_pretrained(save_path)
processor.save_pretrained(save_path)

print(f"Model and processor saved locally to: {save_path}")
