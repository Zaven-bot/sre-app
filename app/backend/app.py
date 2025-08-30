#!/usr/bin/env python3
"""
SRE/DevOps Learning App - Backend Service
A simple Flask API demonstrating:
- Health checks
- Prometheus metrics with Redis for multi-worker consistency
- Request logging
- Error handling
"""

import time
import random
import os
import json
from datetime import datetime
from collections import defaultdict
from flask import Flask, jsonify, request
from flask_cors import CORS
import psutil
import threading
import redis

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend communication


# Redis connection for shared metrics
def get_redis_client():
    """Get Redis client with error handling"""
    try:
        redis_host = os.getenv("REDIS_HOST", "localhost")
        redis_port = int(os.getenv("REDIS_PORT", 6379))
        client = redis.Redis(
            host=redis_host, port=redis_port, decode_responses=True, socket_timeout=1
        )
        client.ping()  # Test connection
        return client
    except Exception as e:
        print(f"Redis connection failed: {e}")
        return None


redis_client = get_redis_client()


class MetricsCollector:
    """
    Metrics collector using Redis for shared storage across multiple workers.
    Falls back to in-memory storage if Redis is unavailable.
    """

    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return

        self.start_time = time.time()
        self.use_redis = redis_client is not None

        if self.use_redis:
            # Initialize Redis keys if they don't exist
            if not redis_client.exists("app:start_time"):
                redis_client.set("app:start_time", self.start_time)
            print("✅ Using Redis for shared metrics storage")
        else:
            # Fallback to in-memory storage
            self.request_counter = 0
            self.error_counter = 0
            self.response_times = []
            self._metrics_lock = threading.Lock()
            print("⚠️  Using in-memory metrics (Redis unavailable)")

        self._initialized = True

    def record_request(self, endpoint, duration, success=True, status_code=200):
        """Record a request using Redis for shared storage."""
        if self.use_redis:
            try:
                # Atomic operations in Redis
                redis_client.incr("app:requests_total")
                redis_client.lpush("app:response_times", duration * 1000)  # Store in ms
                redis_client.ltrim("app:response_times", 0, 999)  # Keep last 1000

                if not success or status_code >= 400:
                    redis_client.incr("app:errors_total")
                    redis_client.incr(
                        f"app:errors_{status_code}"
                    )  # Track specific error codes

                # Store endpoint-specific metrics
                redis_client.incr(f"app:endpoint:{endpoint}:requests")
            except Exception as e:
                print(f"Redis error in record_request: {e}")
                # Could fall back to in-memory here
        else:
            # Fallback to in-memory storage
            with self._metrics_lock:
                self.request_counter += 1

                if not success or status_code >= 400:
                    self._error_counter += 1

                self.response_times.append(duration)
                if len(self.response_times) > 1000:
                    self.response_times = self.response_times[-1000:]

    def get_metrics(self):
        """Get current metrics from Redis or in-memory storage."""
        if self.use_redis:
            try:
                # Get metrics from Redis
                requests_total = int(redis_client.get("app:requests_total") or 0)
                errors_total = int(redis_client.get("app:errors_total") or 0)

                # Get error breakdown by status code
                errors_400 = int(redis_client.get("app:errors_400") or 0)
                errors_500 = int(redis_client.get("app:errors_500") or 0)

                # Get response times and calculate average
                response_times_raw = redis_client.lrange("app:response_times", 0, -1)
                response_times = [float(x) for x in response_times_raw if x]
                response_time_avg = (
                    sum(response_times) / len(response_times) if response_times else 0
                )

                # Get endpoint-specific metrics
                endpoint_metrics = {}
                for key in redis_client.keys("app:endpoint:*:requests"):
                    try:
                        endpoint = key.split(":")[2]  # Extract endpoint name
                        count = int(redis_client.get(key) or 0)
                        endpoint_metrics[endpoint] = count
                    except (IndexError, ValueError):
                        continue

                # Get app start time from Redis
                app_start_time = float(
                    redis_client.get("app:start_time") or self.start_time
                )
                uptime = time.time() - app_start_time

                return {
                    "requests_total": requests_total,
                    "errors_total": errors_total,
                    "errors_400": errors_400,
                    "errors_500": errors_500,
                    "uptime": uptime,
                    "response_time_avg": response_time_avg,
                    "memory_usage_mb": psutil.Process().memory_info().rss / 1024 / 1024,
                    "cpu_percent": psutil.cpu_percent(),
                    "storage_type": "redis",
                    "worker_id": os.getpid(),  # Show which worker responded
                    "endpoint_metrics": endpoint_metrics,
                }

            except Exception as e:
                print(f"Redis error in get_metrics: {e}")
                return {"error": "Redis unavailable", "storage_type": "error"}
        else:
            # Fallback to in-memory metrics
            with self._metrics_lock:
                uptime = time.time() - self.start_time
                response_time_avg = (
                    sum(self.response_times) / len(self.response_times)
                    if self.response_times
                    else 0
                )

                return {
                    "requests_total": self.request_counter,
                    "errors_total": self.error_counter,
                    "errors_400": 0,  # Not tracked in memory version
                    "errors_500": 0,  # Not tracked in memory version
                    "uptime": uptime,
                    "response_time_avg": response_time_avg * 1000,  # Convert to ms
                    "memory_usage_mb": psutil.Process().memory_info().rss / 1024 / 1024,
                    "cpu_percent": psutil.cpu_percent(),
                    "storage_type": "in-memory",
                    "worker_id": os.getpid(),
                    "endpoint_metrics": {},  # Not tracked in memory version
                }


# Create metrics instance
metrics = MetricsCollector()


def track_metrics(func):
    """Decorator to track request metrics"""

    def wrapper(*args, **kwargs):
        start_time = time.time()
        success = True
        status_code = 200
        try:
            result = func(*args, **kwargs)

            # Check if result is a Flask Response object or tuple
            if hasattr(result, "status_code"):
                status_code = result.status_code
                success = 200 <= status_code < 400
            elif isinstance(result, tuple) and len(result) >= 2:
                # Handle tuple returns like (data, status_code)
                status_code = result[1] if isinstance(result[1], int) else 200
                success = 200 <= status_code < 400
            else:
                # For plain returns (like jsonify), assume success
                success = True

            return result
        except Exception as e:
            success = False
            status_code = 500
            raise
        finally:
            duration = time.time() - start_time
            metrics.record_request(request.endpoint, duration, success, status_code)

    wrapper.__name__ = func.__name__
    return wrapper


@app.route("/health")
@track_metrics
def health_check():
    """Health check endpoint for Kubernetes liveness/readiness probes"""
    health_status = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0",
        "uptime": time.time() - metrics.start_time,
        "worker_id": os.getpid(),
        "redis_connected": redis_client is not None,
        "checks": {
            "database": "ok",  # Placeholder - would check real DB
            "memory": "ok" if psutil.virtual_memory().percent < 90 else "warning",
            "disk": "ok" if psutil.disk_usage("/").percent < 90 else "warning",
            "redis": "ok" if redis_client else "disconnected",
        },
    }

    # Simulate occasional health check issues for demo
    if random.random() < 0.05:  # 5% chance of simulated issue
        health_status["status"] = "degraded"
        health_status["checks"]["external_service"] = "timeout"

    return jsonify(health_status)


@app.route("/metrics")
def prometheus_metrics():
    """Prometheus metrics endpoint in the expected format"""
    current_metrics = metrics.get_metrics()

    # Prometheus format metrics
    metrics_output = f"""# HELP requests_total Total number of requests
# TYPE requests_total counter
requests_total {current_metrics.get('requests_total', 0)}

# HELP errors_total Total number of errors
# TYPE errors_total counter
errors_total {current_metrics.get('errors_total', 0)}

# HELP errors_by_status_code Error count by HTTP status code
# TYPE errors_by_status_code counter
errors_by_status_code{{code="400"}} {current_metrics.get('errors_400', 0)}
errors_by_status_code{{code="500"}} {current_metrics.get('errors_500', 0)}

# HELP response_time_avg Average response time in milliseconds
# TYPE response_time_avg gauge
response_time_avg {current_metrics.get('response_time_avg', 0)}

# HELP memory_usage_mb Memory usage in megabytes
# TYPE memory_usage_mb gauge
memory_usage_mb {current_metrics.get('memory_usage_mb', 0)}

# HELP cpu_percent CPU usage percentage
# TYPE cpu_percent gauge
cpu_percent {current_metrics.get('cpu_percent', 0)}

# HELP uptime_seconds Application uptime in seconds
# TYPE uptime_seconds gauge
uptime_seconds {current_metrics.get('uptime', 0)}

# HELP app_info Application information
# TYPE app_info gauge
app_info{{worker_id="{current_metrics.get('worker_id', 'unknown')}", storage="{current_metrics.get('storage_type', 'unknown')}"}} 1
"""

    # Add endpoint-specific metrics if available
    endpoint_metrics = current_metrics.get("endpoint_metrics", {})
    if endpoint_metrics:
        metrics_output += "\n\n# HELP requests_by_endpoint Requests per endpoint\n"
        metrics_output += "# TYPE requests_by_endpoint counter\n"
        for endpoint, count in endpoint_metrics.items():
            metrics_output += f'requests_by_endpoint{{endpoint="{endpoint}"}} {count}\n'

    return metrics_output, 200, {"Content-Type": "text/plain; charset=utf-8"}


@app.route("/metrics-json")
def metrics_json():
    """JSON metrics endpoint for frontend consumption"""
    return jsonify(metrics.get_metrics())


@app.route("/api/data")
@track_metrics
def get_data():
    """Sample API endpoint that returns some data"""
    # Simulate some processing time
    time.sleep(random.uniform(0.01, 0.1))

    return jsonify(
        {
            "message": "Hello from the backend!",
            "timestamp": datetime.utcnow().isoformat(),
            "random_number": random.randint(1, 1000),
            "server_info": {
                "python_version": "3.x",
                "framework": "Flask",
                "environment": "development",  # Could be loaded from env vars
            },
        }
    )


@app.route("/load-test")
@track_metrics
def load_test():
    """Endpoint for generating test load"""
    # Simulate variable processing time
    delay = random.uniform(0.1, 2.0)
    time.sleep(delay)

    # Simulate different outcomes
    outcome = random.random()

    if outcome < 0.7:  # 70% success
        return (
            jsonify(
                {
                    "status": "success",
                    "delay": delay,
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ),
            200,
        )
    elif outcome < 0.85:  # 15% client error
        return (
            jsonify(
                {
                    "error": "Simulated client error",
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ),
            400,
        )
    else:  # 15% server error
        return (
            jsonify(
                {
                    "error": "Simulated server error",
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ),
            500,
        )


@app.errorhandler(Exception)
def handle_exception(e):
    """Global error handler"""
    metrics.record_request(
        request.endpoint if request.endpoint else "unknown", 0, False
    )
    return (
        jsonify(
            {
                "error": "Internal server error",
                "timestamp": datetime.utcnow().isoformat(),
                "type": type(e).__name__,
            }
        ),
        500,
    )


@app.before_request
def before_request():
    """Log all incoming requests"""
    request.start_time = time.time()


@app.after_request
def after_request(response):
    """Log response details"""
    if hasattr(request, "start_time"):
        duration = time.time() - request.start_time
        print(
            f"{datetime.utcnow().isoformat()} - {request.method} {request.path} - {response.status_code} - {duration:.3f}s"
        )
    return response


if __name__ == "__main__":
    print("🚀 Starting SRE/DevOps Learning App Backend")
    print("📊 Metrics available at: http://localhost:6000/metrics")
    print("🏥 Health check at: http://localhost:6000/health")
    print("🌐 CORS enabled for frontend communication")

    # Start the Flask app
    app.run(host="0.0.0.0", port=6000, debug=True)
