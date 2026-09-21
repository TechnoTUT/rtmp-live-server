# Kubernetes Deployment Guide

## Overview
This directory contains the production-ready Kubernetes manifests for deploying:
1. **Live Server**: RTMP server with Intel iGPU (VA-API) hardware-accelerated snapshot generation.
2. **Dashboard**: Nuxt 3 BFF dashboard with low-latency live preview.

## Architecture & Network
```
[OBS / Streamer] ──> Service: LoadBalancer (:1935) ──> Pod: live-server
                                                            │ (Internal ClusterIP :8080)
[Browser / User] ──> Ingress (:80/:443) ──> Pod: live-dashboard
```

## Prerequisites
- Kubernetes cluster with Intel iGPU on nodes (nodes must have `/dev/dri`).
- Ingress controller (e.g. Ingress-Nginx, Traefik).
- LoadBalancer controller for bare-metal (e.g. MetalLB) if on-premises.

## Deployment Steps

1. **Adjust Ingress Host**
   Edit `k8s/deployment.yaml` and update `rtmp-dashboard.example.com` to your domain.

2. **Verify Node GIDs for `/dev/dri`**
   Ensure `supplementalGroups: [44, 105]` in the manifest matches your node's `video` and `render` group IDs (can be verified with `getent group video render` on the node).

3. **Apply Manifest**
   ```bash
   kubectl apply -f k8s/deployment.yaml
   ```

4. **Verify Pods & Services**
   ```bash
   kubectl get pods,svc,ingress -n rtmp-live
   ```
