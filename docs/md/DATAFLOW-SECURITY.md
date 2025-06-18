# Data Flow and Security Documentation

## 1. High-Level Architecture

- **Azure Kubernetes Service (AKS)** orchestrates containerized workloads.
- **Azure Cosmos DB** is the main data store, accessed by backend services and IoT Hub.
- **Azure IoT Hub** ingests device telemetry and routes data to Cosmos DB.
- **Azure Container Registry (ACR)** stores container images for AKS deployments.
- **Azure Key Vault** manages secrets, certificates, and sensitive configuration.
- **NGINX Ingress Controller** manages secure external access to services.
- **Helm** is used for templating and deploying Kubernetes resources.

---

## 2. Data Flow Between Components

### a. IoT Data Ingestion
- Devices send telemetry to **Azure IoT Hub**.
- IoT Hub routes data to **Cosmos DB** using a Cosmos DB endpoint.
- Backend services in AKS may also consume data from IoT Hub or Cosmos DB.

### b. Application Data Flow
- **Frontend** communicates with **backend** services via HTTP(S) through the NGINX ingress.
- **Backend** services interact with **Cosmos DB** for data persistence.
- **Backend** may also interact with **IoT Hub** for device management or telemetry.

### c. Image Deployment
- CI/CD pipelines build and push images to **ACR**.
- AKS pulls images from ACR for deployment.

---

## 3. Security Features

### a. Role-Based Access Control (RBAC)
- **Kubernetes RBAC** is enabled and configured via Helm charts (`service-account.yaml`), restricting access to resources based on roles.
- **Azure RBAC** is used for resource access (e.g., AKS, Cosmos DB, IoT Hub) via managed identities and service principals.

### b. Secure Authentication Mechanisms
- **Managed Identities**: AKS nodes and workloads use Azure Managed Identities to securely access Azure resources (e.g., Key Vault, ACR, Cosmos DB) without hardcoded credentials.
- **Service Principals**: Used for Terraform and CI/CD pipelines to authenticate with Azure.

### c. Private Connections and Network Security
- **Virtual Networks (VNets)**: All major resources (AKS, Cosmos DB, IoT Hub) are deployed within or connected to VNets, restricting access to internal traffic.
- **Subnet Rules**: Cosmos DB and IoT Hub restrict access to specific subnets using `virtual_network_rule` blocks in Terraform.
- **Public Network Access**: Disabled or tightly controlled for Cosmos DB and other sensitive resources.
- **IP Whitelisting**: Only specific IP ranges or Azure services are allowed to access certain resources.

### d. Network Policies
- **Kubernetes Network Policies** (if present in Helm charts) restrict pod-to-pod and pod-to-service communication, enforcing least privilege at the network layer.
- **Azure NSGs**: Network Security Groups further restrict traffic at the subnet level.

### e. Certificates and Secure Ingress
- **TLS/SSL**: NGINX ingress is configured to terminate TLS, ensuring encrypted traffic between clients and services.
- **Certificate Management**: Certificates are managed via Azure Key Vault and synced to Kubernetes using secure mechanisms (e.g., cert-manager, secret sync jobs).
- **Helm Charts**: Ingress resources reference TLS secrets for secure endpoints.

### f. Secret Management
- **Azure Key Vault**: Stores sensitive secrets, connection strings, and certificates.
- **Kubernetes Secrets**: Synced from Key Vault or managed via Helm, used for application configuration.
- **No Hardcoded Secrets**: Credentials and sensitive data are not stored in code or configuration files.

### g. Secure Image Handling
- **ACR Authentication**: AKS uses managed identities or service principals to pull images securely from ACR.
- **Image Scanning**: CI/CD pipelines include security scanning (e.g., Trivy) to detect vulnerabilities in container images.

### h. Auditing and Monitoring
- **Azure Monitor and Log Analytics**: Collect logs and metrics from AKS, Cosmos DB, and IoT Hub.
- **Diagnostic Settings**: Enabled for key resources to ensure audit trails and security event logging.

---

## 4. Example Security Configurations

### Terraform (Cosmos DB)
```hcl
public_network_access_enabled = false
is_virtual_network_filter_enabled = true
virtual_network_rule {
  id = azurerm_subnet.aks_subnet.id
}
network_acl_bypass_for_azure_services = true
```

### Helm (Kubernetes RBAC)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
# ... role rules ...
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
# ... role binding ...
```

### Helm (Ingress with TLS)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-ingress
spec:
  tls:
    - hosts:
        - backend.example.com
      secretName: backend-tls
```

---

## 5. Summary Table

| Component         | Security Feature(s)                                                                 |
|-------------------|------------------------------------------------------------------------------------|
| AKS               | RBAC, Managed Identity, Network Policies, TLS Ingress                              |
| Cosmos DB         | VNet Integration, Private Endpoints, Firewall Rules, Key Vault Integration         |
| IoT Hub           | VNet Integration, Private Endpoints, Access Policies                               |
| ACR               | Private Access, Managed Identity Authentication                                    |
| Key Vault         | Access Policies, Secret Sync, Certificate Management                               |
| NGINX Ingress     | TLS Termination, Secure Secret Reference                                           |
| Helm Deployments  | RBAC, Secret Management, Network Policy Templates                                  |

---

## 6. Security Best Practices Followed

- Principle of least privilege for all access (RBAC, network, secrets).
- All sensitive data and secrets are managed outside of code.
- All external traffic is encrypted and authenticated.
- Internal traffic is restricted to only necessary components.
- Regular vulnerability scanning and monitoring are in place.

---

This document provides a clear overview of the data flow and security posture of the infrastructure. For diagrams or more detailed breakdowns, refer to the `diags/` folder.
