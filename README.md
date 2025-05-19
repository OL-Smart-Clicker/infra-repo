# infra-iac

This repository contains Infrastructure as Code (IaC) for deploying and managing the Smart Clicker platform on Microsoft Azure using Terraform. It provisions a secure, production-grade environment with AKS, Azure Container Registry, CosmosDB, IoT Hub, and supporting network and IAM resources.

---

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Terraform Modules](#terraform-modules)
- [Variables](#variables)
- [Resources](#resources)
- [Outputs](#outputs)
- [Usage](#usage)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security](#security)
- [Diagrams & Documentation](#diagrams--documentation)
- [Contributing](#contributing)

---

## Architecture Overview
The infrastructure provisions:
- **AKS Cluster** (with OIDC, Azure AD, KEDA, Cilium, Gatekeeper, Key Vault integration)
- **Azure Container Registry** (for container images)
- **CosmosDB** (with private endpoint, RBAC, and IoT Hub integration)
- **IoT Hub** (with managed identity, CosmosDB routing)
- **Virtual Network & Subnets** (segregated for AKS, public, and private workloads)
- **Private DNS** (for CosmosDB private endpoint)
- **Key Vault** (for secrets, with RBAC)
- **Role Assignments** (for secure access between services)
- **Helm Deployments** (ArgoCD, NGINX Ingress, cluster setup)

See `/docs/diags/` for detailed diagrams.

---

## Prerequisites
- Azure Subscription
- [Terraform >= 1.1.0](https://www.terraform.io/downloads.html)
- Azure CLI
- Permissions to create resources in the target subscription
- (For CI/CD) Azure DevOps or GitHub Actions with appropriate service connections

---

## Repository Structure
```
infra-repo/
  README.md
  pipeline/azure-pipeline.yml
  terraform/           # Root Terraform configuration
  modules/aks-cluster/ # AKS reusable module
  config/              # Environment-specific tfvars
  docs/                # Architecture, security, and flow diagrams
```

---

## Terraform Modules
### AKS Cluster Module (`modules/aks-cluster`)
- Provisions AKS with:
  - System and user node pools (spot/on-demand)
  - Azure AD integration
  - OIDC and workload identity
  - KEDA, Cilium, Gatekeeper, Key Vault
  - Helm releases for ArgoCD, NGINX, setup
- See [modules/aks-cluster/README.md](modules/aks-cluster/README.md) for advanced usage.

---

## Variables
### Root Variables (`terraform/variables.tf`)
| Name                | Type         | Description                                      | Default      |
|---------------------|--------------|--------------------------------------------------|--------------|
| environment         | string       | Deployment environment (staging/production)       |              |
| location            | string       | Azure region for resources                       | westeurope   |
| cluster_name        | string       | The name of the AKS cluster                      |              |
| cluster_admins      | list(string) | Azure AD group IDs for cluster admin access       | []           |
| cluster_access_ips  | list(string) | IP CIDRs allowed to access AKS API               | []           |
| cluster_lb_sku      | string       | AKS Load Balancer SKU                            | standard     |
| iot_allowed_ips     | list(string) | Allowed IPs for IoT Hub                          | []           |
| cosmos_tier         | string       | Cosmos DB pricing tier (Free/Standard)           | Free         |

### AKS Module Variables (`modules/aks-cluster/variables.tf`)
| Name                | Type         | Description                                      | Default      |
|---------------------|--------------|--------------------------------------------------|--------------|
| environment         | string       | The Azure tenant environment                     | staging      |
| location            | string       | The location of the resources                    | West Europe  |
| cluster_name        | string       | The name of the AKS cluster                      |              |
| auto_upgrade        | string       | Automatic upgrade channel                        | none         |
| api_access_cidrs    | list(string) | IPs allowed to access AKS API                    | []           |
| cluster_admin_groups| list(string) | Azure AD group IDs for cluster admin access       | []           |
| subnet_id           | string       | Subnet ID for AKS nodes                          |              |
| enable_gatekeeper   | bool         | Enable OPA Gatekeeper                            | false        |
| k8s_version         | string       | Kubernetes version                               | 1.31.6       |
| lb_sku              | string       | Load Balancer SKU                                | standard     |

---

## Resources
- `azurerm_kubernetes_cluster` (AKS)
- `azurerm_kubernetes_cluster_node_pool` (spot/on-demand)
- `azurerm_user_assigned_identity` (for IRSA)
- `azurerm_federated_identity_credential` (OIDC)
- `azurerm_key_vault` (secrets)
- `azurerm_container_registry` (ACR)
- `azurerm_cosmosdb_account` (CosmosDB)
- `azurerm_iothub` (IoT Hub)
- `azurerm_private_endpoint` (CosmosDB)
- `azurerm_private_dns_zone` (CosmosDB DNS)
- `azurerm_role_assignment` (RBAC)
- `helm_release` (ArgoCD, NGINX, setup)

---

## Outputs
### Root Outputs (`terraform/outputs.tf`)
| Name                | Description                                  |
|---------------------|----------------------------------------------|
| iothub_hostname     | IoT Hub hostname                             |
| cosmos_endpoint     | CosmosDB endpoint                            |
| private_endpoint_fqdn| CosmosDB private endpoint FQDN              |
| aks_irsa_clientid   | AKS IRSA client ID                           |
| acr_username        | ACR admin username                           |
| acr_login_server    | ACR login server URL                         |

### AKS Module Outputs (`modules/aks-cluster/outputs.tf`)
| Name                | Description                                  |
|---------------------|----------------------------------------------|
| aks_irsa_uuid       | Principal ID of AKS IRSA                     |
| aks_irsa_clientid   | Client ID of AKS IRSA                        |
| cluster_identity    | Kubelet identity object ID                    |
| cluster_rg          | Name of the AKS resource group                |

---

## Usage
1. Clone the repository and configure your backend (see `terraform/backend.tf`).
2. Set your environment variables or create a `config/STAGING.tfvars` file.
3. Initialize and apply Terraform:
   ```powershell
   cd terraform
   terraform init
   terraform plan -var-file=../config/STAGING.tfvars
   terraform apply -var-file=../config/STAGING.tfvars
   ```
4. For CI/CD, see [pipeline/azure-pipeline.yml](pipeline/azure-pipeline.yml).

---

## CI/CD Pipeline
- Azure Pipeline automates plan, approval, and apply stages.
- Uses service connection for secure authentication.
- Publishes Terraform plan as an artifact for manual approval.
- See [pipeline/azure-pipeline.yml](pipeline/azure-pipeline.yml) for details.

---

## Security
- AKS uses Azure AD (Entra ID) for RBAC.
- OIDC and workload identity for secure pod access to Azure resources.
- Key Vault with RBAC for secrets.
- CosmosDB and IoT Hub use managed identities and private endpoints.
- Network is segmented with private subnets and DNS.

---

## Diagrams & Documentation
- See `/docs/diags/` for architecture, security, and flow diagrams.
- See `/docs/md/` for detailed documentation on Kubernetes modeling and dataflow security.

---

## Contributing
1. Fork the repository and create a feature branch.
2. Follow the established code style and naming conventions.
3. Document your changes.
4. Submit a pull request for review.

---

## License
MIT License
