# Running the code through GitHub Actions

## Table of contents

- [Running the code through GitHub Actions](#running-the-code-through-github-actions)
  - [Table of contents](#table-of-contents)
  - [Get the configuration files](#get-the-configuration-files)
  - [Install the required tools](#install-the-required-tools)
  - [Azure CLI preparations](#azure-cli-preparations)
  - [Create an Azure storage account and container](#create-an-azure-storage-account-and-container)
  - [Create an Azure Service Principal](#create-an-azure-service-principal)
  - [Create a SSH key pair](#create-a-ssh-key-pair)
  - [Add the required secrets to your GitHub repository](#add-the-required-secrets-to-your-github-repository)
  - [Final adjustments](#final-adjustments)
  - [Provision the infrastructure](#provision-the-infrastructure)
  - [Access the virtual machine](#access-the-virtual-machine)

## Get the configuration files

The first step is to clone this repository and copy the following folders and files to your own repository:

- [`.github/workflows`](../.github/workflows)
- [`ansible`](../ansible)
- [`terraform`](../terraform)

## Install the required tools

Next, make sure you have the following tools installed:

- [Terraform](https://www.terraform.io/downloads.html)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

> [!TIP]
> Personally, I like to use [Homebrew](https://brew.sh/) to install these tools on macOS or Linux (or WSL in Windows) with the command `brew tap hashicorp/tap && brew install hashicorp/tap/terraform ansible azure-cli`.

## Azure CLI preparations


1. Log in to your Azure account (if you haven't already):

    ```bash
    az login
    ```

    A new browser window will open where you can authenticate.

2. List all subscriptions:

    ```bash
    az account list --output table
    ```

    You should find the `Azure for Students` subscription here. Copy the `id` of the subscription you want to use.

3. Set the default subscription as the `Azure for Students` subscription:

    ```bash
    az account set --subscription "<SUBSCRIPTION_ID>"
    ```

## Create an Azure storage account and container

In order to use GitHub Actions to run Terraform, you need to store the Terraform state file remotely. This is done using a remote state backend, which in this case is an Azure storage account and container.


1. Create a new resource group for the storage account:

    ```bash
    az group create --name <RESOURCE_GROUP_NAME> --location '<LOCATION>'
    ```

    Replace `<RESOURCE_GROUP_NAME>` with the name of the resource group and `<LOCATION>` with the location of the resource group (I tend to use 'West Europe' by default).

2. Create a new storage account:

    ```bash
    az storage account create --name <STORAGE_ACCOUNT_NAME> --resource-group <RESOURCE_GROUP_NAME> --location '<LOCATION>' --sku Standard_LRS
    ```

    The `Standard_LRS` SKU is the cheapest option, but you can choose another one if you prefer. Replace `<STORAGE_ACCOUNT_NAME>` with the name of the storage account. The name must be unique across Azure and cannot contain special characters or spaces (I tend to use a combination of `terraformstates` suffixed by the first part of a UUID, such as `terraformstates34asd55`).

3. Create a new container in the storage account:

    ```bash
    az storage container create --name tfstates --account-name <STORAGE_ACCOUNT_NAME> --public-access off
    ```

4. Modify the Terraform backend definition in the `terraform.tf` file accordingly:

    ```terraform
    terraform {
      backend "azurerm" {
        # This Storage Account and Container must already exist. They were created manually.
        resource_group_name   = "<RESOURCE_GROUP_NAME>"
        storage_account_name  = "<STORAGE_ACCOUNT_NAME>"
        container_name        = "tfstates"
        key                   = "<NAME_OF_THE_PROJECT>.tfstate"
      }

      required_providers {
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 4"
        }
      }
    }

    # ...
    ```

    Replace `<RESOURCE_GROUP_NAME>` and `<STORAGE_ACCOUNT_NAME>` with the names of the resource group and storage account you created. Replace `<NAME_OF_THE_PROJECT>` with the name of your project (I tend to use the name of the repository).

5. As you are already modifying the `terraform.tf` file, you can also modify the provider block to include your subscription ID:
   
    You can find your subscription ID by running the following command:

    ```bash
    az account show --query id --output tsv
    ```

    Modify the `provider` block in the `main.tf` file accordingly:

    ```terraform
    # ...

    provider "azurerm" {
      features {}
      subscription_id = "<SUBSCRIPTION_ID>"
    }
    ```

    Replace `<SUBSCRIPTION_ID>` with the ID of the subscription you want to use.

## Create an Azure Service Principal

In order to authenticate with Azure from GitHub Actions, you need to create an Azure Service Principal.

1. Create a new Service Principal with Contributor role:

    ```bash
    az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>" --name "<SERVICE_PRINCIPAL_NAME>"
    ```

    Replace `<SUBSCRIPTION_ID>` with the ID of the subscription you want to use and `<SERVICE_PRINCIPAL_NAME>` with a suitable name for your Service Principal. This command will output a JSON object with the following keys:

    - `appId`: the ID of the Service Principal.
    - `displayName`: the name given to the Service Principal.
    - `password`: the password of the Service Principal.
    - `tenant`: the ID of the tenant.

    Save this information in a secure place, as you will need it later.

2. This Service Principal has access to your entire Azure subscription, same as yourself. You probably might want to delete it after the course is done. To do so, run the following command:

    ```bash
    az ad sp delete --id "<SERVICE_PRINCIPAL_ID>"
    ```

    Replace `<SERVICE_PRINCIPAL_ID>` with the ID of the Service Principal you want to delete.

## Create a SSH key pair

You probably already have a SSH key pair for your personal use. However, I recommend creating a new one here, as this private key will be used by GitHub Actions to connect to the virtual machine and run the Ansible playbook for the first time.

It's only after this first run that you can connect to the virtual machine using your personal SSH key (*more on this later*).

1. Create a new SSH key pair without a passphrase:

    ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25529_azure_deploy_key -C 'admin@azure-for-students'
    ```

    This command will create a new SSH key pair with
    - the private key at `~/.ssh/id_ed25529_azure_deploy_key`
    - the public key at `~/.ssh/id_ed25529_azure_deploy_key.pub`
    - the comment `admin@azure-for-students`

> [!IMPORTANT]
> Do not use a passphrase for this SSH key pair, because you'll not have a way to input it when GitHub Actions tries to connect to run the Ansible playbook.

## Add the required secrets to your GitHub repository

In order to run the GitHub Actions workflows, you need to add secrets from the Azure Service Principal and the SSH key pair to your GitHub repository.

1. On your GitHub repository, go to `Settings` > `Secrets and variables` > `Actions`.

2. Add the following secrets:

    - `ARM_CLIENT_SECRET`: the password of the Azure Service Principal.
    - `SSH_PRIVATE_KEY`: the **private key** of the SSH key pair.

3. Add the following variables:
   
    - `ARM_CLIENT_ID`: the ID of the Azure Service Principal.
    - `ARM_SUBSCRIPTION_ID`: the ID of the Azure subscription.
    - `ARM_TENANT_ID`: the ID of the Azure tenant.

## Final adjustments

1. Modify the `terraform.tfvars` file in the `terraform` directory to include the values of the variables you want to use.
   - It's important to include the **public key** of the SSH key pair in the `admin_ssh_public_key` variable, as this will be the key used by the Ansible workflow that you'll run after the Terraform workflow.
   - The `app_name` and `public_ip_label_prefix` variables are used to create a unique label for the public IP resource. This will automatically create a unique DNS name for the public IP, which is useful for accessing the virtual machine (see [here](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#domain-name-label) and [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip#domain_name_label-1)). Note that if `public_ip_label_prefix`, the domain host will be the `app_name` only.

2. Modify the `authorized_keys` file in the `ansible` directory to include any other public keys you might want to include (such as your personal one and the ones from your colleagues). The keys from the teaching staff are already included.

3. Modify the working directory on the `terraform.yaml` workflow file in the `.github/workflows` directory to match the path where your Terraform code is located.

4. Modify the working directory on the `ansible.yaml` workflow file in the `.github/workflows` directory to match the path where your Ansible code is located.

5. Modify the hostname of the virtual machine in the `ansible.yaml` workflow file in the `.github/workflows` directory to match the DNS name you will get from concatenating the values set in the `app_name` and `public_ip_label_prefix` variables (the comma at the end is important!).

6. Commit everything to your repository and push it to GitHub.

## Provision the infrastructure

Now you can provision the infrastructure by running the GitHub Actions workflows.

1. Go to the `Actions` tab of your repository and run the `terraform` workflow. Select `Run workflow` and then select `plan` as the action to run. This will show you the changes that Terraform will make to your infrastructure.

2. If you are satisfied with the changes, do the same step, but with `apply` command to apply the changes to your infrastructure. This will create the resources on Azure.

3. Finally, run the `ansible` workflow to configure the virtual machine. This will install the necessary packages and set up the environment for the HEIG-VD DAI course.

## Access the virtual machine

After the `ansible` workflow has finished running, you can access the virtual machine using the public IP address that was created (check your Azure portal) or the DNS name that was created (the one you set in the `app_name` variable prefixed with the value of `public_ip_label_prefix`, if defined).

```bash
ssh ubuntu@<DNS_DOMAIN_PREFIX>-<APP-NAME>.<LOCATION>.cloudapp.azure.com

# Example:
ssh ubuntu@prefix-app-name.westeurope.cloudapp.azure.com
```
