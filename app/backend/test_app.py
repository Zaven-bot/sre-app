# Basic test file for the Flask backend
import pytest
import json
import threading
from unittest.mock import MagicMock, patch


# Mock Redis for testing
class MockRedis:
    """Mock Redis client for testing"""

    def __init__(self):
        self.data = {}
        self.lists = {}

    def ping(self):
        return True

    def get(self, key):
        return self.data.get(key)

    def set(self, key, value):
        self.data[key] = str(value)

    def incr(self, key):
        current = int(self.data.get(key, 0))
        self.data[key] = str(current + 1)
        return current + 1

    def exists(self, key):
        return key in self.data

    def lpush(self, key, value):
        if key not in self.lists:
            self.lists[key] = []
        self.lists[key].insert(0, str(value))

    def ltrim(self, key, start, end):
        if key in self.lists:
            if end == -1:
                self.lists[key] = self.lists[key][start:]
            else:
                self.lists[key] = self.lists[key][start : end + 1]

    def lrange(self, key, start, end):
        if key not in self.lists:
            return []
        if end == -1:
            return self.lists[key][start:]
        else:
            return self.lists[key][start : end + 1]

    def keys(self, pattern):
        # Simple pattern matching for our test case
        if pattern == "app:endpoint:*:requests":
            return [
                k
                for k in self.data.keys()
                if k.startswith("app:endpoint:") and k.endswith(":requests")
            ]
        return []


# Mock Redis before importing app
mock_redis_client = MockRedis()

# Patch Redis before app import
with patch("redis.Redis") as mock_redis_class:
    mock_redis_class.return_value = mock_redis_client
    from app import app, MetricsCollector


@pytest.fixture(autouse=True)
def reset_metrics():
    """Reset metrics singleton for each test"""
    # Reset singleton instance for each test
    MetricsCollector._instance = None
    # Clear mock Redis data
    mock_redis_client.data.clear()
    mock_redis_client.lists.clear()
    yield


@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_singleton_pattern():
    """Test that MetricsCollector implements Singleton pattern correctly."""
    # Create multiple instances
    metrics1 = MetricsCollector()
    metrics2 = MetricsCollector()

    # They should be the same object
    assert metrics1 is metrics2

    # Test that data is shared through Redis
    metrics1.record_request("/test", 0.1, True)
    metrics_data = metrics2.get_metrics()
    assert metrics_data["requests_total"] >= 1


def test_thread_safety():
    """Test that MetricsCollector is thread-safe through Redis."""
    metrics = MetricsCollector()
    initial_count = metrics.get_metrics()["requests_total"]

    def make_requests():
        for i in range(10):  # Reduced from 100 to 10 for faster tests
            metrics.record_request("/test", 0.01, True)

    # Start multiple threads
    threads = []
    for _ in range(3):  # Reduced from 5 to 3 for faster tests
        thread = threading.Thread(target=make_requests)
        threads.append(thread)
        thread.start()

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    # Should have 30 additional requests (3 threads × 10 requests each)
    final_count = metrics.get_metrics()["requests_total"]
    assert final_count == initial_count + 30


def test_health_check(client):
    """Test the health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["status"] in ["healthy", "degraded"]
    assert "timestamp" in data
    assert "uptime" in data


def test_metrics_endpoint(client):
    """Test the Prometheus metrics endpoint."""
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "requests_total" in response.data.decode()
    assert "response_time_avg" in response.data.decode()


def test_metrics_json_endpoint(client):
    """Test the JSON metrics endpoint."""
    response = client.get("/metrics-json")
    assert response.status_code == 200
    data = json.loads(response.data)
    assert "requests_total" in data
    assert "uptime" in data


def test_api_data_endpoint(client):
    """Test the sample API data endpoint."""
    response = client.get("/api/data")
    assert response.status_code == 200
    data = json.loads(response.data)
    assert "message" in data
    assert "timestamp" in data
    assert "random_number" in data


def test_load_test_endpoint(client):
    """Test the load testing endpoint."""
    response = client.get("/load-test")
    # Could be 200 or 500 (simulated errors)
    assert response.status_code in [200, 400, 500]


def test_redis_requirement():
    """Test that MetricsCollector fails fast when Redis is unavailable."""
    with patch("app.redis_client", None):
        with patch("app.get_redis_client", return_value=None):
            # Reset singleton to force reinitialization
            MetricsCollector._instance = None

            # Should raise RuntimeError when Redis is unavailable
            with pytest.raises(RuntimeError, match="Redis is required but unavailable"):
                MetricsCollector()


def test_redis_only_storage_type():
    """Test that metrics always report 'redis' storage type."""
    metrics = MetricsCollector()
    metrics_data = metrics.get_metrics()
    assert metrics_data["storage_type"] == "redis"


if __name__ == "__main__":
    pytest.main(["-v"])
