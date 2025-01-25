# Use the official Flutter image from Docker Hub
FROM cirrusci/flutter:latest

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install dependencies
RUN flutter pub get

# Expose port 8080 for web
EXPOSE 8080

# Run the Flutter web server
CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]