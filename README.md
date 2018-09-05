# tf-azure-win-vm
This terraform script allows you to create a Virtual Network with two subnets, 2 VMs on Avability Set and Load Balancer.

# Create Azure Service Principal
```bash
az login

az account set --subscription="<Azure Subscription Name>"

az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<Azure Subscription ID>" -n Terraform --years 100
```
User Azure Service Principal create command output to fill value in run.sh

# Create new SSH Key
```bash
ssh-keygen -b 4096
```
Fill in demo.tfvars "key_data" with new ssh key public key

# Inizialise Terraform
```bash
terraform init
```

Check variable in demo.tfvars

# Provision infrastracture
```bash
chmod u+x run.sh 

./run.sh
```