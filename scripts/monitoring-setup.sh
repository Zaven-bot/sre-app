#!/bin/bash
# Monitoring setup script for SRE learning

set -e

echo "📊 Setting up Monitoring Stack"
echo "=============================="

# Function to install Prometheus on Kubernetes
install_prometheus_k8s() {
    echo "🎯 Installing Prometheus on Kubernetes..."
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply Prometheus configuration
    kubectl create configmap prometheus-config \
        --from-file=monitoring/prometheus-config.yaml \
        --namespace=monitoring \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create Prometheus deployment
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config-volume
          mountPath: /etc/prometheus
        args:
          - '--config.file=/etc/prometheus/prometheus-config.yaml'
          - '--storage.tsdb.path=/prometheus'
          - '--web.console.libraries=/etc/prometheus/console_libraries'
          - '--web.console.templates=/etc/prometheus/consoles'
          - '--web.enable-lifecycle'
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: config-volume
        configMap:
          name: prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: ClusterIP
EOF

    echo "✅ Prometheus installed"
}

# Function to install Grafana on Kubernetes
install_grafana_k8s() {
    echo "📈 Installing Grafana on Kubernetes..."
    
    # Create Grafana deployment
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "100m"
      volumes:
      - name: grafana-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
EOF

    echo "✅ Grafana installed"
}

# Function to setup port forwarding for local access
setup_port_forwarding() {
    echo "🌐 Setting up port forwarding..."
    
    # Check if pods are ready
    kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=120s
    kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=120s
    
    echo "🎯 Starting port forwarding (run in background)..."
    echo "   Prometheus: http://localhost:9090"
    echo "   Grafana: http://localhost:3000 (admin/admin)"
    
    # Create port forwarding script
    cat << 'EOF' > scripts/port-forward.sh
#!/bin/bash
echo "Starting port forwarding for monitoring..."
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000"
echo "Press Ctrl+C to stop"

kubectl port-forward service/prometheus-service 9090:9090 -n monitoring &
PROM_PID=$!

kubectl port-forward service/grafana-service 3000:3000 -n monitoring &
GRAFANA_PID=$!

# Wait for interrupt
trap "kill $PROM_PID $GRAFANA_PID; exit" INT
wait
EOF

    chmod +x scripts/port-forward.sh
    echo "📝 Created scripts/port-forward.sh for easy access"
}

# Function to configure Grafana datasource and dashboard
configure_grafana() {
    echo "⚙️  Configuring Grafana (you'll need to do this manually)..."
    echo ""
    echo "🎯 Manual Grafana Setup Steps:"
    echo "1. Go to http://localhost:3000"
    echo "2. Login with admin/admin"
    echo "3. Add Prometheus datasource:"
    echo "   - URL: http://prometheus-service.monitoring.svc.cluster.local:9090"
    echo "   - Or if using port-forward: http://localhost:9090"
    echo "4. Import dashboard from monitoring/grafana-dashboard.json"
    echo ""
}

# Function to install Node Exporter (system metrics)
install_node_exporter() {
    echo "🖥️  Installing Node Exporter for system metrics..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:latest
        ports:
        - containerPort: 9100
        args:
          - '--path.procfs=/host/proc'
          - '--path.sysfs=/host/sys'
          - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)(\$|/)'
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        resources:
          requests:
            memory: "32Mi"
            cpu: "10m"
          limits:
            memory: "64Mi"
            cpu: "20m"
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      tolerations:
      - operator: Exists
---
apiVersion: v1
kind: Service
metadata:
  name: node-exporter-service
  namespace: monitoring
  labels:
    prometheus: "true"
spec:
  selector:
    app: node-exporter
  ports:
  - port: 9100
    targetPort: 9100
    name: metrics
EOF

    echo "✅ Node Exporter installed"
}

# Function to create alert rules (basic examples)
create_alert_rules() {
    echo "🚨 Creating basic alert rules..."
    
    cat << 'EOF' > monitoring/alert-rules.yaml
groups:
- name: application-alerts
  rules:
  - alert: HighErrorRate
    expr: rate(errors_total[5m]) > 0.1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value }} errors per second"

  - alert: HighResponseTime
    expr: response_time_avg > 1000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High response time detected"
      description: "Average response time is {{ $value }}ms"

  - alert: ServiceDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Service is down"
      description: "{{ $labels.instance }} has been down for more than 1 minute"

- name: infrastructure-alerts
  rules:
  - alert: HighMemoryUsage
    expr: (memory_usage_mb / 1024) > 0.8
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage"
      description: "Memory usage is {{ $value }}GB"

  - alert: HighCPUUsage
    expr: cpu_percent > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage"
      description: "CPU usage is {{ $value }}%"
EOF

    echo "✅ Alert rules created (monitoring/alert-rules.yaml)"
    echo "📝 To enable alerts, add Alertmanager to your setup"
}

# Function to verify monitoring setup
verify_monitoring() {
    echo "🔍 Verifying monitoring setup..."
    
    # Check if services are running
    echo "📊 Checking Prometheus..."
    if kubectl get pods -n monitoring -l app=prometheus | grep -q Running; then
        echo "✅ Prometheus is running"
    else
        echo "❌ Prometheus is not running"
    fi
    
    echo "📈 Checking Grafana..."
    if kubectl get pods -n monitoring -l app=grafana | grep -q Running; then
        echo "✅ Grafana is running"
    else
        echo "❌ Grafana is not running"
    fi
    
    echo "🖥️  Checking Node Exporter..."
    if kubectl get pods -n monitoring -l app=node-exporter | grep -q Running; then
        echo "✅ Node Exporter is running"
    else
        echo "❌ Node Exporter is not running"
    fi
    
    echo ""
    echo "🎯 Next steps:"
    echo "1. Run: ./scripts/port-forward.sh"
    echo "2. Access Prometheus: http://localhost:9090"
    echo "3. Access Grafana: http://localhost:3000 (admin/admin)"
    echo "4. Configure Grafana datasource and import dashboard"
}

# Main execution
case "${1:-all}" in
    "prometheus")
        install_prometheus_k8s
        ;;
    "grafana")
        install_grafana_k8s
        ;;
    "node-exporter")
        install_node_exporter
        ;;
    "alerts")
        create_alert_rules
        ;;
    "verify")
        verify_monitoring
        ;;
    "all")
        install_prometheus_k8s
        install_grafana_k8s
        install_node_exporter
        create_alert_rules
        setup_port_forwarding
        configure_grafana
        verify_monitoring
        ;;
    *)
        echo "Usage: $0 [prometheus|grafana|node-exporter|alerts|verify|all]"
        echo ""
        echo "Commands:"
        echo "  prometheus    - Install Prometheus only"
        echo "  grafana      - Install Grafana only"
        echo "  node-exporter - Install Node Exporter only"
        echo "  alerts       - Create alert rules"
        echo "  verify       - Verify monitoring setup"
        echo "  all          - Install everything (default)"
        exit 1
        ;;
esac

echo ""
echo "✅ Monitoring setup complete!"
