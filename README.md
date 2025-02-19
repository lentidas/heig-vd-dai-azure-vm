# heig-vd-dai-azure-vm

This repository contains the [Terraform](https://developer.hashicorp.com/terraform/docs) and [Ansible](https://docs.ansible.com) code to create a virtual machine on Microsoft Azure, using a GitOps and Infrastructure as Code (IaC) approach, in order to have working Azure VM for the HEIG-VD DAI course and/or laboratory.

> [!NOTE]
> This repository does not intend to be a complete guide on how to use Terraform, Ansible, or Azure. It is a starting point for students to have a working VM for the course.
>
> As such, the code is limited in the possible configurations and does not cover all the possible scenarios. It is up to the students to adapt the code to their needs and to learn more about Terraform, Ansible, and Azure.

# Table of Contents

- [heig-vd-dai-azure-vm](#heig-vd-dai-azure-vm)
- [Table of Contents](#table-of-contents)
  - [Concepts](#concepts)
    - [Infrastructure as Code (IaC)](#infrastructure-as-code-iac)
      - [Advantages of IaC](#advantages-of-iac)
    - [GitOps](#gitops)
    - [Terraform state](#terraform-state)
  - [Overview](#overview)
  - [Usage](#usage)
    - [Running the code locally](#running-the-code-locally)
    - [Running the code through GitHub Actions](#running-the-code-through-github-actions)
    - [Make your choice](#make-your-choice)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Concepts

### Infrastructure as Code (IaC)

Infrastructure as Code (IaC) is the practice of managing and provisioning computing infrastructure through machine-readable configuration files, rather than through interactive configuration tools (jokingly called *ClickOps* :grin:). IaC allows for the automation of infrastructure setup, reducing the risk of human error and increasing the speed and consistency of deployments.

#### Advantages of IaC

- **Consistency**: IaC ensures that the same configuration is applied every time, reducing the risk of discrepancies between environments.
- **Version Control**: By storing infrastructure configurations in version control systems like Git, teams can track changes, roll back to previous versions, and collaborate more effectively.
- **Automation**: IaC enables the automation of infrastructure provisioning and management, reducing manual effort and increasing efficiency.
- **Scalability**: IaC makes it easier to scale infrastructure up or down based on demand, as configurations can be reused and modified as needed.
- **Documentation**: IaC configurations serve as documentation for the infrastructure, making it easier to understand and manage.

### GitOps

GitOps is a set of practices that uses Git as the single source of truth for declarative infrastructure and applications. It leverages Git repositories to manage infrastructure and application configurations, enabling version control, collaboration, and automation.

> [!NOTE]
> Although GitOps concepts is more commonly associated with Kubernetes and cloud-native applications, we can apply it in this case if we are using ONLY GitHub actions to deploy the infrastructure. As soon as we start running Terraform and Ansible locally, we are not following the GitOps principles anymore and we risk having discrepancies between multiple team members (*imagine if someone forgets to commit their changes, someone else runs a `terraform apply` and overwrites their configurations!*).

### Terraform state

Terraform uses a state file to keep track of the resources it manages. The state file is used to map real-world resources to the configuration, keep track of metadata, and store the IDs and properties of the resources. Terraform uses the state file to determine what changes need to be made to the infrastructure to reach the desired state.

The state file can be stored locally or remotely. Storing the state file remotely is recommended for production environments, as it allows for collaboration, locking, and versioning of the state file ([multiple backends are supported](https://developer.hashicorp.com/terraform/language/backend)).

> [!WARNING]
> The state file can contain sensitive information about your infrastructure, so make sure to keep it secure. Also, if storing the state file locally, make sure to not commit it to version control

> [!WARNING]
> If storing the state file locally, make sure to not lose it, as Terraform will not be able to keep track of the resources it manages.

> [!NOTE]
> When doing your laboratory, you will use the Azure account of only one person. That means your colleagues will not be able to access the resources managed by your account. So you either store the state file locally and only one of you is responsible for managing the infrastructure, or you store the state file remotely and all of you manage the infrastructure through GitHub Actions.

## Overview

The [`terraform`](./terraform/) directory contains the Terraform code for provisioning the following resources on Azure:

- a resource group;
- a virtual network;
- a private subnet in that virtual network for the virtual machine;
- a public IP to attach to the virtual machine;
- a network security group that allows inbound SSH, HTTP, and HTTPS traffic;
- a network interface for the virtual machine, that connects it to the private subnet and the public IP and that is associated with the network security group created;
- finally, the virtual machine itself, running Ubuntu 20.04 LTS, with a public SSH key for authentication.

The [`ansible`](./ansible/) directory contains the Ansible playbook for configuring the virtual machine. It installs the necessary packages and sets up the environment for the HEIG-VD DAI course. The playbook performs a system update, installs some requirements and Docker and finally installs Docker and Docker Compose.

## Usage

The usage of this code depends on an important choice: whether you want to run the Terraform and Ansible code locally or through GitHub Actions.

### Running the code locally

Running the code locally requires you to have the required tools installed and to authenticate with Azure using the Azure CLI.

Only one person can manage the infrastructure, as the state file is stored locally.

### Running the code through GitHub Actions

Running the code through GitHub Actions requires you to set up a remote state backend and to authenticate with Azure using a service principal.

This allows multiple people to manage the infrastructure through GitHub Actions. The modifications to the infrastructure are done through commits to the `main` branch, followed by a manual run of the respective GitHub Actions workflows.

It is still possible to run the code locally, but **only by the person that has access to the Azure account**.

### Make your choice

I've separated the usage guides in two different files, depending on the choice you make:

- [Running the code locally](./README-local.md)
- [Running the code through GitHub Actions](./README-github-actions.md)

Please refer to the respective file for the instructions on how to use the code.

# License

This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License, similar to the license used by the [HEIG-VD DAI course](https://github.com/heig-vd-dai-course/heig-vd-dai-course).

# Acknowledgments

I would like to thank the teachers and assistants of the HEIG-VD DAI course for the amazing work they did on the course material and for the classes given.
