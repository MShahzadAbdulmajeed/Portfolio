# Use official Python base image (Debian-based for stability)
FROM python:3.10-slim-bullseye AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create and set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# --- Runtime Stage ---
FROM python:3.10-slim-bullseye

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy Python dependencies from builder
ENV PATH="/root/.local/bin:${PATH}"
COPY --from=builder /root/.local /root/.local

# Create non-root user
RUN useradd -m appuser && \
    mkdir -p /app/staticfiles && \
    chown appuser:appuser /app
WORKDIR /app
USER appuser

# Copy application code
COPY --chown=appuser:appuser . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Configure runtime
EXPOSE 8000
ENV DJANGO_SETTINGS_MODULE=portfolioproject.settings
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health-check/ || exit 1

# Run application
CMD ["gunicorn", \
    "--bind", "0.0.0.0:8000", \
    "--workers", "3", \
    "--threads", "2", \
    "--worker-class", "gthread", \
    "--timeout", "30", \
    "--keep-alive", "2", \
    "--access-logfile", "-", \
    "--error-logfile", "-", \
    "your_project.wsgi:application"]
