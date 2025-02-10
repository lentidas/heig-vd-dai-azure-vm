# Instructions

The `infra` directory contains the infrastructure code for the project. This includes the Terraform code for creating the Microsoft Azure resources required and the Ansible code for configuring the virtual machine.

## Requirements

First, make sure you have the following tools installed:

- [Terraform](https://www.terraform.io/downloads.html)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

[Homebrew](https://brew.sh/) can be used to install these tools on macOS or Linux with the following command:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform ansible azure-cli
```

## Usage

When running locally, you will need to authenticate with Azure using the Azure CLI. More information can be found [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli).

When running in a CI/CD pipeline, you will need to authenticate with Azure using a service principal. More information can be found [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret). This guide shows you how to create a service principal and then pass it to Terraform using environment variables.

A remote state backend is required to store the Terraform state file. This was created manually on Azure and the details are stored in the `terraform.tf` file. The Azure account or Service Principal used to authenticate with Azure must have access to the storage account and container.

## Command cheatsheet

### Terraform

```bash
# Initialize the Terraform working directory.
terraform init

# Create an execution plan.
terraform plan

# Apply the changes required to reach the desired state.
terraform apply

# Destroy the Terraform-managed infrastructure.
terraform destroy
```

### Azure CLI

```bash
# Log in to Azure. A new browser window will open where you can authenticate.
az login

# List all subscriptions. You should find the `Azure for Students` subscription here.
az account list --output table

# Set the default subscription as the `Azure for Students` subscription.
az account set --subscription "SUBSCRIPTION_ID"

# List all of YOUR Service Principals.
az ad sp list --show-mine --query "[].{SP_name:displayName, SP_id:appId, tenant:appOwnerOrganizationId}" --output table

# Create a new Service Principal with Contributor role.
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID"

# Create a new Service Principal with Contributor role but with a specific name.
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID" --name "SERVICE_PRINCIPAL_NAME"

# Delete a Service Principal.
az ad sp delete --id "SERVICE_PRINCIPAL_ID"
```
