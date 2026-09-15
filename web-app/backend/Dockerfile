FROM python:3.11-slim

WORKDIR /app

# Install build essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Ensure models exist (skip training if pre-generated .pkl are present)
RUN python -c "import os; os.system('python ml/train_and_vectorize.py') if not (os.path.exists('models/vectorizer.pkl') and os.path.exists('models/fashion_embeddings.pkl')) else print('✅ Pre-trained models verified in models/')"

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
