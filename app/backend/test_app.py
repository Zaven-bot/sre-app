# Basic test file for the Flask backend
import pytest
import json
import threading
from app import app, MetricsCollector

@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_singleton_pattern():
    """Test that MetricsCollector implements Singleton pattern correctly."""
    # Create multiple instances
    metrics1 = MetricsCollector()
    metrics2 = MetricsCollector()
    
    # They should be the same object
    assert metrics1 is metrics2
    
    # Test that data is shared
    metrics1.record_request('/test', 0.1, True)
    assert metrics2.get_metrics()['requests_total'] == 1

def test_thread_safety():
    """Test that MetricsCollector is thread-safe."""
    metrics = MetricsCollector()
    initial_count = metrics.get_metrics()['requests_total']
    
    def make_requests():
        for i in range(100):
            metrics.record_request('/test', 0.01, True)
    
    # Start multiple threads
    threads = []
    for _ in range(5):
        thread = threading.Thread(target=make_requests)
        threads.append(thread)
        thread.start()
    
    # Wait for all threads to complete
    for thread in threads:
        thread.join()
    
    # Should have 500 additional requests (5 threads × 100 requests each)
    final_count = metrics.get_metrics()['requests_total']
    assert final_count == initial_count + 500

def test_health_check(client):
    """Test the health check endpoint."""
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] in ['healthy', 'degraded']
    assert 'timestamp' in data
    assert 'uptime' in data

def test_metrics_endpoint(client):
    """Test the Prometheus metrics endpoint."""
    response = client.get('/metrics')
    assert response.status_code == 200
    assert 'requests_total' in response.data.decode()
    assert 'response_time_avg' in response.data.decode()

def test_metrics_json_endpoint(client):
    """Test the JSON metrics endpoint."""
    response = client.get('/metrics-json')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'requests_total' in data
    assert 'uptime' in data

def test_api_data_endpoint(client):
    """Test the sample API data endpoint."""
    response = client.get('/api/data')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'message' in data
    assert 'timestamp' in data
    assert 'random_number' in data

def test_load_test_endpoint(client):
    """Test the load testing endpoint."""
    response = client.get('/load-test')
    # Could be 200 or 500 (simulated errors)
    assert response.status_code in [200, 500]

def test_error_simulation(client):
    """Test the error simulation endpoint."""
    response = client.get('/simulate-error')
    # Should return various error codes
    assert response.status_code in [400, 404, 408, 500]

if __name__ == '__main__':
    pytest.main(['-v'])
