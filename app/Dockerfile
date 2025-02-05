# Use the official lightweight Python image.
FROM python:3.9-slim

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages
RUN pip install --no-cache-dir flask

# Generate self-signed SSL certificates (Optional, use your own)
RUN apt-get update && apt-get install -y openssl && \
    openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=localhost"

# Make port 443 available to the world outside this container
EXPOSE 443

# Run app.py with SSL
CMD ["python3", "app.py"]