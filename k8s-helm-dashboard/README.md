# Kubernetes Dashboard (Helm MVP)

This directory contains the automated deployment of Kubernetes Dashboard using **Helm**.

## Changes from previous version
* **Switched to Helm:** We replaced raw YAML manifests with official Helm Charts. This aligns with our future GitOps strategy.
* **Access Method:** We switched from `kubectl proxy` (flaky URL) to `kubectl port-forward` (direct port mapping).

## Architecture Decisions (ADR)

### 1. Dashboard Versioning
**Decision:** We strictly pin the Helm Chart to version `6.0.8`.
**Reasoning:**
* Chart `6.0.8` deploys Dashboard **v2.7.0** (Stable).
* Newer Charts (7.x+) deploy Dashboard **v3.x**, which introduces mandatory dependencies (Ingress Controller, Cert-Manager) that complicate the MVP phase excessively.
* Version 2.7.0 is self-contained and sufficient for current needs.

### 2. Metrics Server
**Decision:** Deployed via `metrics-server` Helm chart.
**Reasoning:** Required for CPU/Memory visibility. EKS does not provide this by default.

## How to Run

### 1. Deploy
Run the automated script:
```bash
./deploy-helm.sh

_KUBECONFIG=$(basename ${KUBECONFIG})
podman run --rm -it \
  -p 8443:8443 \
  -v ${PWD}:/podman \
  -e "KUBECONFIG=/home/${USER}/.kube/${_KUBECONFIG}" \
  -v ~/.aws:/home/${USER}/.aws \
  -v ~/.kube:/home/${USER}/.kube \
  ic-podman-runtime:latest \
  kubectl -n kubernetes-dashboard port-forward --address 0.0.0.0 svc/kubernetes-dashboard 8443:443
