# Running the code locally

## Table of Contents

- [Running the code locally](#running-the-code-locally)
  - [Table of Contents](#table-of-contents)
  - [Get the configuration files](#get-the-configuration-files)
  - [Install the required tools](#install-the-required-tools)
  - [Azure CLI preparations](#azure-cli-preparations)
  - [Modify the Terraform backend and provider](#modify-the-terraform-backend-and-provider)
  - [Final adjustments](#final-adjustments)
  - [Provision the infrastructure](#provision-the-infrastructure)
  - [Destroy the infrastructure](#destroy-the-infrastructure)
  - [Conclusion](#conclusion)

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

## Modify the Terraform backend and provider

Instead of using the remote state backend, we will use the local state backend. This means that the state file will be stored locally in the `terraform` directory.

1. Modify the `backend.tf` file in the `terraform` directory to look like this:

    ```hcl
    terraform {
      backend "local" {}

      required_providers {
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 4"
        }
      }
    }

    # ...
    ```

2. As you are already modifying the `terraform.tf` file, you can also modify the provider block to include your subscription ID:
   
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

## Final adjustments

1. Modify the `terraform.tfvars` file in the `terraform` directory to include the values of the variables you want to use.
   - Add your SSH **public key** to the `admin_ssh_public_key` variable.
   - The `app_name` and `public_ip_label_prefix` variables are used to create a unique label for the public IP resource. This will automatically create a unique DNS name for the public IP, which is useful for accessing the virtual machine (see [here](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#domain-name-label) and [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip#domain_name_label-1)). Note that if `public_ip_label_prefix`, the domain host will be the `app_name` only.

2. Modify the `authorized_keys` file in the `ansible` directory to include any other public keys you might want to include (such as the ones from your colleagues). The keys from the teaching staff are already included.

3. Modify the hostname of the virtual machine in the `ansible.yaml` workflow file in the `.github/workflows` directory to match the DNS name you will get from concatenating the values set in the `app_name` and `public_ip_label_prefix` variables (the comma at the end is important!).

4. Save your changes, commit everything and push it to GitHub.

## Provision the infrastructure

Now, with everything in place, you can start provisioning the infrastructure.

1. Initialize Terraform:

    ```bash
    cd terraform
    terraform init
    ```

2. Perform a `plan` to check if the changes that will be made are the ones you expect:

    ```bash
    terraform plan
    ```

3. If you are satisfied with the resources that will be created, perform an `apply`:

    ```bash
    terraform apply
    ```

4. Finally, run the Ansible playbook to configure the virtual machine (Terraform should have output the public IP and the domain of the virtual machine):

    ```bash
    cd ../ansible
    ansible-playbook -i <DNS_DOMAIN_PREFIX>-<APP-NAME>.<LOCATION>.cloudapp.azure.com, ansible-playbook.yml
    ```

## Destroy the infrastructure

After the course is done, you can destroy the infrastructure by running `terraform` with the `destroy` command. This will delete all the resources created on Azure.

```bash
cd terraform
terraform destroy
```

> [!NOTE]
> If you want, a quick and dirty way to destroy the infrastructure is to delete the resource group that contains all the resources. This will delete everything in one go, however, **your Terraform state will no longer be in sync with the actual resources of your infrastructure**. You can do that through the Azure portal or using the Azure CLI: `az group delete --name <RESOURCE_GROUP_NAME> --yes`

## Conclusion

And that's it! You can now manage the infrastructure for the HEIG-VD DAI course through GitHub Actions.
