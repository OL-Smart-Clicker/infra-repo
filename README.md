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
- [Tagging Strategy](#tagging-strategy)
- [Usage](#usage)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security](#security)
- [Diagrams & Documentation](#diagrams--documentation)
- [Contributing](#contributing)

---

## Architecture Overview
The Smart Clicker platform infrastructure provides a complete IoT-to-application pipeline on Azure:

### Core Components:
- **AKS Cluster**: Production-grade Kubernetes with Cilium networking, KEDA autoscaling, and Azure AD integration
- **Azure Container Registry**: Environment-specific SKU (Basic/Standard) with AKS integration
- **CosmosDB**: Free tier database with private endpoints, RBAC, and automated IoT data routing
- **IoT Hub**: Managed IoT ingestion with Device Provisioning Service and CosmosDB integration
- **Virtual Network**: Segregated subnets for AKS nodes, public access, and private resources
- **Key Vault**: Centralized secrets management with RBAC and automatic rotation
- **Private DNS**: Internal name resolution for private endpoints

### Data Flow:
1. **IoT Devices** → IoT Hub (with device provisioning)
2. **IoT Hub** → CosmosDB (automated routing)
3. **AKS Applications** → CosmosDB (via private endpoint, RBAC)
4. **External Users** → NGINX Ingress → AKS Services

### GitOps Integration:
- **ArgoCD**: Continuous delivery for applications
- **Helm**: Package management for applications and cluster add-ons
- **Terraform**: Infrastructure as Code with Azure DevOps pipeline

See `/docs/diags/` for detailed architecture diagrams.

---

## Prerequisites
- **Azure Subscription** with appropriate permissions
- **Terraform >= 1.11.2** (pipeline enforces this version)
- **Azure CLI** for local development and authentication
- **PowerShell** (for Windows environments)
- **Git** for version control
- **Helm** (optional, for manual chart deployments)
- **kubectl** (for cluster management)

### Required Azure Permissions:
- Contributor access to target subscription
- Ability to create service principals and role assignments
- Access to Azure DevOps for CI/CD setup

### Azure AD Requirements:
- Azure AD group for AKS administrators
- Permission to create managed identities and federated credentials

---

## Repository Structure
```
infra-repo/
├── README.md                       # This comprehensive documentation
├── TODO.md                         # Project backlog and tasks
├── pipeline/
│   └── azure-pipeline.yml         # Azure DevOps CI/CD pipeline
├── terraform/                     # Root Terraform configuration
│   ├── *.tf                      # Main infrastructure resources
│   ├── backend.tf                 # Terraform state backend
│   └── outputs.tf                 # Infrastructure outputs
├── modules/
│   └── aks-cluster/               # Reusable AKS module
│       ├── *.tf                  # AKS resources and configuration
│       ├── helm/                 # Helm charts for cluster add-ons
│       │   ├── setup/            # Custom setup chart
│       │   ├── nginx/            # NGINX Ingress values
│       │   └── argo/             # ArgoCD configuration
│       └── README.md             # Module-specific documentation
├── config/
│   └── STAGING.tfvars            # Environment-specific variables
└── docs/
    ├── diags/                    # Architecture and flow diagrams
    │   ├── *.drawio             # Draw.io diagram sources
    │   └── *.puml               # PlantUML diagrams
    └── md/                       # Detailed documentation
        ├── KUBERNETES-MODELLING.md
        └── DATAFLOW-SECURITY.md
```

---

## Terraform Modules
### AKS Cluster Module (`modules/aks-cluster`)
A comprehensive, production-ready AKS module that provisions:

**Core Features:**
- **Kubernetes Cluster**: Free tier AKS with system-assigned managed identity
- **Node Pools**: 
  - System pool (on-demand, critical addons only)
  - Spot instance pool (cost-optimized, user workloads)
  - On-demand user pool (reliable user workloads)
- **Networking**: Azure CNI with Cilium overlay and network policies
- **Security**: Azure AD integration, OIDC, workload identity, local accounts disabled

**Advanced Features:**
- **Key Vault Integration**: CSI driver with secret rotation
- **Azure Policy**: Optional OPA Gatekeeper support
- **Workload Identity**: IRSA for secure Azure resource access

**Helm Deployments:**
- **Setup Chart**: Namespace creation, secret sync, IRSA configuration
- **NGINX Ingress**: HTTP(S) load balancing and SSL termination
- **ArgoCD**: GitOps continuous delivery platform
- **App of Apps**: ArgoCD application management pattern

See [modules/aks-cluster/README.md](modules/aks-cluster/README.md) for detailed usage.

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
| cosmos_tier         | string       | Cosmos DB pricing tier (Free/Standard)           | Free         |
| common_tags         | map(string)  | Common tags applied to all resources             | See defaults |
| additional_tags     | map(string)  | Additional tags to merge with common tags        | {}           |

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
| common_tags         | map(string)  | Common tags for AKS resources                    | {}           |

---

## Resources
- `azurerm_kubernetes_cluster` (AKS with Cilium, KEDA, OIDC, Azure AD)
- `azurerm_kubernetes_cluster_node_pool` (spot/on-demand user pools)
- `azurerm_user_assigned_identity` (for IRSA - workload identity)
- `azurerm_federated_identity_credential` (OIDC federation)
- `azurerm_key_vault` (secrets management with RBAC)
- `azurerm_container_registry` (ACR with environment-based SKU)
- `azurerm_cosmosdb_account` (with free tier, private endpoint, backup)
- `azurerm_cosmosdb_sql_database` & `azurerm_cosmosdb_sql_container`
- `azurerm_iothub` (with managed identity, routing to CosmosDB)
- `azurerm_iothub_dps` (Device Provisioning Service)
- `azurerm_private_endpoint` (CosmosDB private connectivity)
- `azurerm_private_dns_zone` (CosmosDB DNS resolution)
- `azurerm_virtual_network` & `azurerm_subnet` (network segmentation)
- `azurerm_role_assignment` (RBAC for service-to-service access)
- `helm_release` (ArgoCD, NGINX Ingress, setup chart)

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
| dps_id_scope        | IoT Device Provisioning Service ID Scope    |

### AKS Module Outputs (`modules/aks-cluster/outputs.tf`)
| Name                | Description                                  |
|---------------------|----------------------------------------------|
| aks_irsa_uuid       | Principal ID of AKS IRSA                     |
| aks_irsa_clientid   | Client ID of AKS IRSA                        |
| cluster_identity    | Kubelet identity object ID                    |
| cluster_rg          | Name of the AKS resource group                |

---

## Tagging Strategy
This infrastructure implements a comprehensive tagging strategy for cost management, compliance, and operational visibility:

### Standard Tags Applied to All Resources:
- **Project**: Smart-Clicker
- **Owner**: OL-Team
- **ManagedBy**: Terraform
- **Repository**: infra-repo
- **Environment**: staging/production
- **CostCenter**: Development/Production
- **CostPolicy**: FreeTier/Production
- **CreatedDate**: Resource creation date
- **LastModified**: Dynamic timestamp (updated on changes)

### Resource-Specific Tags:
- **Service**: Resource type (Database, IoT-Hub, Container-Registry, etc.)
- **Workload**: Workload classification (Data-Storage, Data-Ingestion, Infrastructure, etc.)
- **DataClass**: Data classification for compliance (Internal, Sensor-Data, etc.)
- **Backup**: Backup requirements (Continuous, Periodic, NotRequired)
- **Compliance**: Regulatory requirements (GDPR, etc.)
- **NodeType**: AKS node type (spot, on-demand)
- **Purpose**: Resource purpose (system-workloads, user-workloads, etc.)

### Benefits:
- **Cost Tracking**: Clear allocation by environment, service, and workload
- **Compliance**: GDPR and data classification tracking
- **Operations**: Easy resource identification and management
- **Security**: Clear ownership and access control
- **Automation**: Standardized tags for automated policies

---

## Usage
### Quick Start
1. **Clone and Setup**:
   ```powershell
   git clone <repository-url>
   cd infra-repo
   ```

2. **Configure Backend**: Update `terraform/backend.tf` with your Azure Storage Account details.

3. **Set Variables**: Create `config/STAGING.tfvars` or use environment variables:
   ```hcl
   environment    = "staging"
   location       = "West Europe"
   cluster_name   = "your-cluster-name"
   cluster_admins = ["azure-ad-group-id"]
   ```

4. **Deploy Infrastructure**:
   ```powershell
   cd terraform
   terraform init
   terraform plan -var-file=../config/STAGING.tfvars
   terraform apply -var-file=../config/STAGING.tfvars
   ```

### Post-Deployment Access
1. **Connect to AKS**:
   ```powershell
   az aks get-credentials --resource-group <cluster-rg> --name <cluster-name>
   kubectl get nodes
   ```

2. **Access ArgoCD** (if deployed):
   ```powershell
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   # Access via https://localhost:8080
   # Default admin password: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
   ```

3. **Verify Helm Releases**:
   ```powershell
   helm list --all-namespaces
   ```

### Configuration Examples
See `config/STAGING.tfvars` for complete configuration examples including:
- IP whitelisting for AKS API server
- Azure AD admin groups
- IoT Hub allowed IPs
- Custom tagging

---

## CI/CD Pipeline
The Azure DevOps pipeline automates the infrastructure deployment with a secure, approval-based workflow:

### Pipeline Stages:
1. **Plan Stage**: 
   - Installs Terraform 1.11.2
   - Initializes backend state
   - Generates plan with environment-specific variables
   - Publishes plan as artifact

2. **Approval Stage**:
   - Manual validation step
   - Review Terraform plan before apply
   - Timeout policy: reject if no response

3. **Apply Stage**:
   - Downloads plan artifact
   - Re-initializes Terraform
   - Applies the approved plan

### Security Features:
- **OIDC Authentication**: Uses Azure service connection with OIDC
- **Self-hosted Runners**: Currently using self-hosted agents for security
- **Service Connections**: Secure authentication via 'tf-pipeline-sc-staging'
- **Plan Artifacts**: Immutable plans ensure consistency between plan and apply

### Trigger Configuration:
- **Branches**: Only `staging` branch
- **Paths**: Changes to `terraform/`, `config/`, `modules/`
- **PRs**: Disabled to prevent accidental runs

See [pipeline/azure-pipeline.yml](pipeline/azure-pipeline.yml) for complete configuration.

---

## Security
### Identity and Access Management:
- **Azure AD Integration**: AKS uses Entra ID for RBAC with admin group assignment
- **OIDC Workload Identity**: Secure pod-to-Azure resource access without secrets
- **IRSA (Identity and Service Account)**: Federated credentials for AKS workloads
- **Service Accounts**: Dedicated service accounts with least-privilege access
- **Local Account Disabled**: AKS relies exclusively on Azure AD authentication

### Network Security:
- **Private Endpoints**: CosmosDB accessible only via private network
- **VNet Integration**: AKS nodes deployed in dedicated subnet
- **API Server Access**: IP whitelisting for AKS API server
- **Network Policies**: Cilium-based network segmentation
- **Private DNS**: Internal DNS resolution for private endpoints

### Data Protection:
- **Key Vault Integration**: Secrets managed with RBAC and rotation
- **Encryption**: TLS 1.2 minimum, encryption at rest for CosmosDB
- **Managed Identities**: No stored credentials, Azure-managed identities
- **RBAC**: Role-based access control for all Azure and Kubernetes resources
- **Backup**: Environment-appropriate backup strategies (continuous/periodic)

### Compliance and Governance:
- **Tagging**: Comprehensive tagging for compliance tracking (GDPR)
- **Azure Policy**: Optional OPA Gatekeeper for policy enforcement
- **Audit Logging**: All changes tracked via Git and Azure logs
- **Cost Controls**: Environment-based resource sizing and free tier usage

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
