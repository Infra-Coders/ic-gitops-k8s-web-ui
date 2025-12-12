#!/bin/bash

echo "Starting Kubernetes Dashboard Deployment (Helm)..."

# 1. Add Helm Repositories
echo "Adding Helm repositories..."
podman_helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
podman_helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
podman_helm repo update

# 2. Install Metrics Server (Required for graphs)
echo "Installing Metrics Server..."
podman_helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args={--kubelet-insecure-tls} \
  --wait

# 3. Install Kubernetes Dashboard
# NOTE: We are pinning chart version to 6.0.8 to use Dashboard v2.7.0.
# Newer versions (v3.0+) require more complex setup (ingress/cert-manager) not suitable for simple MVP.
echo "Installing Kubernetes Dashboard..."
podman_helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --namespace kubernetes-dashboard \
  --create-namespace \
  --version 6.0.8 \
  --set service.type=ClusterIP \
  --set extraArgs={--token-ttl=0} \
  --wait

# 4. Create Admin User (ServiceAccount)
echo "Creating Admin User..."
kubectl apply -f admin-user.yaml

# 5. Generate Token
echo "Generating Access Token..."
# Small pause to ensure SA is ready
sleep 5
TOKEN=$(podman_kubectl -n kubernetes-dashboard create token admin-user)
echo "$TOKEN" > dashboard_token.txt

echo "Deployment Complete!"
echo "---------------------------------------------------"
echo "Your token is saved in: dashboard_token.txt"
echo ""
echo "HOW TO CONNECT:"
echo "1. Run the following command:"
echo ""

# Użycie cat << 'EOF' zapobiega interpretacji zmiennych wewnątrz bloku
cat << 'EOF'
_KUBECONFIG=$(basename ${KUBECONFIG})
podman run --rm -it \
  -p 8443:8443 \
  -v ${PWD}:/podman \
  -e "KUBECONFIG=/home/${USER}/.kube/${_KUBECONFIG}" \
  -v ~/.aws:/home/${USER}/.aws \
  -v ~/.kube:/home/${USER}/.kube \
  ic-podman-runtime:latest \
  kubectl -n kubernetes-dashboard port-forward --address 0.0.0.0 svc/kubernetes-dashboard 8443:443
EOF

echo ""
echo "2. Open: https://localhost:8443"
echo "   (Accept the security warning in browser)"
echo "3. Log in with the token."
echo "---------------------------------------------------"
