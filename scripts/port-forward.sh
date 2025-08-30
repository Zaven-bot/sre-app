#!/bin/bash
# filepath: /Users/ianunebasami/Documents/Lite/sre-app/scripts/port-forward.sh

# Detect if running on AWS EKS or local
if kubectl cluster-info | grep -q "amazonaws.com"; then
    echo "🌩️  Detected AWS EKS cluster"
    CLUSTER_TYPE="aws"
else
    echo "🖥️  Detected local cluster"
    CLUSTER_TYPE="local"
fi

echo "Starting port-forwards for SRE Learning App..."
echo "Press Ctrl+C to stop all port-forwards"

if [ "$CLUSTER_TYPE" = "local" ]; then
    # Local: Port-forward all services
    echo "Local mode: Port-forwarding all services..."
    kubectl port-forward svc/frontend-service 8080:80 &
    PF_FRONTEND=$!
    echo "   Frontend:   http://localhost:8080"
else
    # AWS: Only port-forward monitoring (frontend has LoadBalancer)
    echo "AWS mode: Frontend available via LoadBalancer, port-forwarding monitoring..."
    FRONTEND_LB=$(kubectl get svc frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    echo "   Frontend:   http://$FRONTEND_LB (public LoadBalancer)"
fi

# Always port-forward monitoring services
kubectl port-forward svc/prometheus-service 9090:9090 &
PF_PROMETHEUS=$!

kubectl port-forward svc/grafana-service 3000:3000 &
PF_GRAFANA=$!

echo "   Prometheus: http://localhost:9090"
echo "   Grafana:    http://localhost:3000 (admin/admin)"

# Cleanup function
cleanup() {
    echo "Stopping port-forwards..."
    if [ "$CLUSTER_TYPE" = "local" ] && [ -n "$PF_FRONTEND" ]; then
        kill $PF_FRONTEND 2>/dev/null
    fi
    kill $PF_PROMETHEUS $PF_GRAFANA 2>/dev/null
    exit 0
}

trap cleanup INT
wait