# Use the official NGINX image as the base image
FROM nginx:latest

# Replace the default NGINX configuration with custom configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Set the working directory to the NGINX document root
WORKDIR /usr/share/nginx/html

# Create an index.html file with the desired response
RUN echo "yo, this is nginx" > index.html
