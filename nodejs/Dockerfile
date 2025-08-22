# Use Node.js 18 (lightweight Alpine version)
FROM node:18-alpine

# Set working directory inside the container
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json ./
RUN npm install

# Copy the main application file
COPY web_got.js ./

# Create ssl folder (optional, for HTTPS)
RUN mkdir ssl

# Expose HTTP and HTTPS ports
EXPOSE 3000 3443

# Create a non-root user for security
RUN adduser -S appuser
USER appuser

# Simple health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "web_got.js"]
