# Kubernetes Modelling Documentation

## 1. Overview

This document details the Kubernetes implementation and deployment model for the Smart Clicker project, focusing on GitOps, application delivery, cluster add-ons, and operational strategies such as cost optimization. It highlights the use of ArgoCD, Helm, and Terraform for managing both infrastructure and workloads, including the comprehensive tagging strategy and security model implemented across all resources.

The infrastructure leverages modern Kubernetes practices including:
- **Cilium** for advanced networking and security policies
- **Azure Workload Identity** for secure pod-to-Azure resource access
- **Spot instances** for cost optimization
- **GitOps** with ArgoCD for continuous delivery

---

## 2. GitOps and ArgoCD

### a. GitOps Workflow
- The repository follows a **GitOps** approach, where the desired state of the Kubernetes cluster is defined as code and stored in Git.
- All application and infrastructure changes are made via pull requests and merged into the main branch, ensuring traceability and auditability.

### b. ArgoCD for Continuous Delivery
- **ArgoCD** is deployed as a cluster add-on using a Helm chart, managed by Terraform:

```hcl
resource "helm_release" "argocd" {
  name      = "argocd"
  namespace = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.0.1"
  values     = [file("${path.module}/helm/argo/argocd-values.yaml")]
  depends_on = [helm_release.setup]
}
```

- ArgoCD continuously monitors the Git repository and synchronizes the cluster state with the manifests and Helm charts defined in the repo.
- The **App of Apps** pattern is used (see `argocd-apps.yaml`), allowing ArgoCD to manage multiple applications and add-ons declaratively.

---

## 3. Application Deployment with Helm

### a. Helm Chart Structure
- Both **frontend** and **backend** applications are packaged as Helm charts, located in `modules/aks-cluster/helm/frontend` and `modules/aks-cluster/helm/backend`.
- Each chart includes templates for deployments, services, ingress, namespaces, and service accounts, enabling modular and repeatable deployments.

Example: `backend/templates/deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      serviceAccountName: backend-sa
      containers:
        - name: backend
          image: <image-url>
          ports:
            - containerPort: 80
```

### b. Helm Releases Managed by Terraform
- All Helm releases (including NGINX Ingress, ArgoCD, and custom setup charts) are managed declaratively in `kubernetes.tf`.
- This ensures that cluster add-ons and applications are installed in a consistent, repeatable manner as part of the infrastructure-as-code pipeline.

---

## 4. Cluster Add-ons and Automation

### a. Add-ons Deployed via Helm
- **NGINX Ingress Controller**: Provides HTTP(S) routing for services.
- **ArgoCD**: Enables GitOps-based application delivery.
- **Setup Chart**: Handles pre-requisites such as namespace creation, secret synchronization, and ArgoCD/Key Vault integration.

Example: `kubernetes.tf`
```hcl
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = "frontend"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.0"
  values     = [file("${path.module}/helm/nginx/nginx-values.yaml")]
  depends_on = [helm_release.setup]
}
```

### b. Automated Secret Sync and Namespace Management
- The **setup** Helm chart automates the creation of required namespaces and the synchronization of secrets from Azure Key Vault to Kubernetes, supporting secure and hands-off operations.

---

## 5. Cost Optimization Strategies

### a. Spot Node Pools
- The AKS cluster is configured with a dedicated **Spot node pool** for cost savings:

```hcl
resource "azurerm_kubernetes_cluster_node_pool" "spot_pool" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.vwh_aks_cluster.id
  vm_size               = "Standard_B2pls_v2"
  vnet_subnet_id        = var.subnet_id
  auto_scaling_enabled  = true
  min_count             = 0
  max_count             = 2
  mode                  = "User"
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = -1
  node_labels = {
    "nodetype" = "spot"
  }
}
```
- Workloads that are tolerant to interruptions are scheduled on Spot nodes, significantly reducing operational costs.

### b. On-Demand Node Pools
- A separate on-demand node pool is available for critical workloads that require higher availability.

---

## 6. Summary Table

| Component         | Purpose/Benefit                                      |
|-------------------|-----------------------------------------------------|
| ArgoCD            | GitOps, declarative app delivery, drift detection   |
| Helm              | Modular, repeatable app and add-on deployment       |
| Spot Node Pool    | Cost savings for non-critical workloads             |
| On-Demand Pool    | Reliability for critical workloads                  |
| Setup Chart       | Namespace, secret, and integration automation       |
| NGINX Ingress     | HTTP(S) routing for frontend/backend                |
| App Helm Charts   | Customizable, versioned deployment of services      |

---

## 7. Conclusion

This Kubernetes modelling approach leverages GitOps, Helm, and Terraform to deliver a scalable, maintainable, and cost-effective platform. By automating cluster add-ons, using Spot node pools for cost savings, and managing all deployments declaratively, the system ensures operational efficiency and rapid, reliable delivery of application updates.
