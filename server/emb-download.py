from sentence_transformers import SentenceTransformer

# Define the model you want to download
model_name = 'sentence-transformers/all-MiniLM-L6-v2'

# Define the local path to save it
save_path = f'models/embedding'

print(f"Downloading model: {model_name}...")

# Download the model from Hugging Face
model = SentenceTransformer(model_name)

# Save the model's files to the local path
model.save(save_path)

print(f"Model saved locally to: {save_path}")
