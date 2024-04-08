# Use Alpine Linux as the base image
FROM python:3.11.8-alpine

# Set working directory in the container
WORKDIR /app

# Install system dependencies
RUN apk --no-cache add \
    gcc \
    libc-dev \
    linux-headers \
    libffi-dev \
    openssl-dev
RUN python3 -m venv /opt/venv
# Copy the Python requirements file and install dependencies
COPY requirements.txt requirements.txt
RUN /opt/venv/bin/pip install -r requirements.txt


# Copy the Python application code into the container
COPY app.py .

# Expose port 5000 for Flask application
EXPOSE 5000

# Run the Flask application
CMD ["/opt/venv/bin/python", "app.py"]
