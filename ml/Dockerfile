FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Build deps for scientific Python packages.
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY ml/requirements.txt /app/ml/requirements.txt
RUN pip install --no-cache-dir -r /app/ml/requirements.txt

# Copy project (scripts rely on relative paths under /app/ml).
COPY . /app

# Railway can override this command from service settings or railway.toml.
CMD ["python", "ml/run_ml_pipeline_once.py"]
