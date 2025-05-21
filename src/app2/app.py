# File: src/app1/app.py
from flask import Flask, jsonify
import os
import socket
import prometheus_client
from prometheus_client import Counter, Histogram
import time

# Create metrics
REQUEST_COUNT = Counter(
    'app_request_count', 
    'Application Request Count',
    ['method', 'endpoint', 'http_status']
)
REQUEST_LATENCY = Histogram(
    'app_request_latency_seconds', 
    'Application Request Latency', 
    ['method', 'endpoint']
)

app = Flask(__name__)

# Expose metrics endpoint
@app.route('/metrics')
def metrics():
    return prometheus_client.generate_latest()

# Define handlers
@app.route('/')
def home():
    start_time = time.time()
    host_name = socket.gethostname()
    host_ip = socket.gethostbyname(host_name)
    environment = os.environ.get('ENVIRONMENT', 'unknown')
    
    response = {
        'message': 'Hello from App1!',
        'hostname': host_name,
        'hostip': host_ip,
        'environment': environment,
        'version': os.environ.get('VERSION', '1.0.0')
    }
    
    request_latency = time.time() - start_time
    REQUEST_LATENCY.labels('GET', '/').observe(request_latency)
    REQUEST_COUNT.labels('GET', '/', 200).inc()
    
    return jsonify(response)

@app.route('/health')
def health():
    REQUEST_COUNT.labels('GET', '/health', 200).inc()
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)