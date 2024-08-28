!/bin/bash

# Variables
resourceGroup="cloud-demo"
location="westus"
osType="Ubuntu2204"
vmssName="udacity-vmss"
adminName="udacityadmin"
storageAccount="udacitydiag$RANDOM"
bePoolName="$vmssName-bepool"
lbName="$vmssName-lb"
lbRule="$lbName-network-rule"
nsgName="$vmssName-nsg"
vnetName="$vmssName-vnet"
subnetName="$vnetName-subnet"
probeName="tcpProbe"
vmSize="Standard_B1s"
storageType="Standard_LRS"

# Create resource group. 
# This command will not work for the Cloud Lab users. 
# Cloud Lab users can comment this command and 
# use the existing Resource group name, such as, resourceGroup="cloud-demo-153430" 
# echo "STEP 0 - Creating resource group $resourceGroup..."

# az group create \
# --name $resourceGroup \
# --location $location \
# --verbose

# echo "Resource group created: $resourceGroup"

# Create Storage account
echo "STEP 1 - Creating storage account $storageAccount"

az storage account create `
--name hoaistorage `
--resource-group cloud-demo `
--location westus `
--sku Standard_LRS

echo "Storage account created: $storageAccount"

# Create Network Security Group
echo "STEP 2 - Creating network security group $nsgName"

az network nsg create `
--resource-group cloud-demo `
--name hoainsg `
--verbose

az network public-ip create `
  --resource-group cloud-demo `
  --name hoaiPublicIP

az network lb create `
  --resource-group cloud-demo `
  --name hoaiload `
  --public-ip-address hoaiPublicIP `
  --frontend-ip-name hoaifepool `
  --backend-pool-name hoaibepool

az network vnet create `
  --resource-group cloud-demo `
  --name hoaivnet `

echo "Network security group created: $nsgName"

# Create VM Scale Set
echo "STEP 3 - Creating VM scale set $vmssName"

az vmss create `
  --resource-group cloud-demo `
  --name hoaivmss `
  --image Ubuntu2204 `
  --nsg haoinsg `
  --subnet hoaisubnet `
  --vnet-name hoaivnet `
  --backend-pool-name hoaibepool `
  --storage-sku Standard_LRS `
  --load-balancer hoaiload `
  --custom-data cloud-init.txt `
  --upgrade-policy-mode automatic `
  --admin-username hoaiadmin `
  --generate-ssh-keys `
  --verbose 

echo "VM scale set created: $vmssName"

# Associate NSG with VMSS subnet
echo "STEP 4 - Associating NSG: $nsgName with subnet: $subnetName"

az network vnet create `
  --resource-group cloud-demo `
  --name hoaivnet `
  --address-prefix 10.0.0.0/16 `
  --subnet-name default `
  --subnet-prefix 10.0.1.0/24

az network vnet subnet create `
  --resource-group cloud-demo `
  --vnet-name hoaivnet `
  --name hoaisubnet `
  --address-prefix 10.0.2.0/24`
  --network-security-group hoainsg `
  --verbose

az network vnet subnet update `
--resource-group cloud-demo `
--name hoaisubnet `
--vnet-name hoaivnet `
--network-security-group hoainsg `
--verbose

echo "NSG: $nsgName associated with subnet: $subnetName"

# Create Health Probe
echo "STEP 5 - Creating health probe $probeName"

az network lb probe create `
  --resource-group cloud-demo `
  --lb-name hoaiload `
  --name hoaiprobe `
  --protocol tcp `
  --port 80 `
  --interval 5 `
  --threshold 2 `
  --verbose

echo "Health probe created: $probeName"

# Create Network Load Balancer Rule
echo "STEP 6 - Creating network load balancer rule $lbRule"

az network lb rule create `
  --resource-group cloud-demo `
  --name hoairule `
  --lb-name hoaiload `
  --probe-name hoaiprobe `
  --backend-pool-name hoaibepool `
  --backend-port 80 `
  --frontend-ip-name hoaifepool `
  --frontend-port 80 `
  --protocol tcp `
  --verbose

echo "Network load balancer rule created: $lbRule"

# Add port 80 to inbound rule NSG
echo "STEP 7 - Adding port 80 to NSG $nsgName"

az network nsg rule create `
--resource-group cloud-demo `
--nsg-name hoainsg `
--name Port_80 `
--destination-port-ranges 80 `
--direction Inbound `
--priority 100 `
--verbose

echo "Port 80 added to NSG: $nsgName"

# Add port 22 to inbound rule NSG
echo "STEP 8 - Adding port 22 to NSG $nsgName"

az network nsg rule create `
--resource-group cloud-demo `
--nsg-name hoainsg `
--name Port_22 `
--destination-port-ranges 22 `
--direction Inbound `
--priority 110 `
--verbose

echo "Port 22 added to NSG: $nsgName"

echo "VMSS script completed!"

connect VMSS
az vmss list-instance-connection-info `
--resource-group cloud-demo `
--name hoaivmss

use ssh
ssh hoaiadmin@172.178.125.150 -p 50000