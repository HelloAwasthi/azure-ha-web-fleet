#!/bin/bash
# Project: High Availability Web Fleet
# Description: Deploys 2 Nginx VMs behind a Standard Load Balancer using Azure CLI.

# Variables
RG_NAME="ha-web-rg"
LOCATION="centralindia"
VNET_NAME="ha-vnet"
SUBNET_NAME="web-subnet"

# 1. Create Resource Group
echo "Creating Resource Group..."
az group create --name $RG_NAME --location $LOCATION

# 2. Create Network Infrastructure
echo "Creating VNet and Subnet..."
az network vnet create \
  --resource-group $RG_NAME \
  --name $VNET_NAME \
  --address-prefix 10.0.0.0/24 \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix 10.0.0.0/25

# 3. Create Cloud-Init Script
cat <<EOF > cloud-init.txt
#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx
echo "Hello from \$(hostname)" > /var/www/html/index.html
EOF

# 4. Create Virtual Machines
echo "Creating Web Server 1..."
az vm create \
  --resource-group $RG_NAME \
  --name web-vm-1 \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --admin-username azureuser \
  --custom-data cloud-init.txt \
  --generate-ssh-keys

echo "Creating Web Server 2..."
az vm create \
  --resource-group $RG_NAME \
  --name web-vm-2 \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --admin-username azureuser \
  --custom-data cloud-init.txt \
  --generate-ssh-keys

# 5. Open Firewall (Port 80)
echo "Opening Port 80..."
az vm open-port --resource-group $RG_NAME --name web-vm-1 --port 80
az vm open-port --resource-group $RG_NAME --name web-vm-2 --port 80

# 6. Create Load Balancer Resources
echo "Creating Load Balancer..."
az network public-ip create \
  --resource-group $RG_NAME \
  --name web-lb-ip \
  --sku Standard

az network lb create \
  --resource-group $RG_NAME \
  --name web-lb \
  --sku Standard \
  --public-ip-address web-lb-ip \
  --frontend-ip-name FrontEndPool \
  --backend-pool-name BackEndPool

# 7. Create Health Probe & Rules
az network lb probe create \
  --resource-group $RG_NAME \
  --lb-name web-lb \
  --name web-health-probe \
  --protocol Tcp \
  --port 80

az network lb rule create \
  --resource-group $RG_NAME \
  --lb-name web-lb \
  --name web-rule \
  --protocol Tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name FrontEndPool \
  --backend-pool-name BackEndPool \
  --probe-name web-health-probe

# 8. Connect VMs to Load Balancer
# Note: Using the specific IP Config names we discovered during troubleshooting.

echo "Connecting VM 1 to LB..."
az network nic ip-config update \
  --resource-group $RG_NAME \
  --name ipconfigweb-vm-1 \
  --nic-name web-vm-1VMNic \
  --lb-name web-lb \
  --lb-address-pools BackEndPool

echo "Connecting VM 2 to LB..."
az network nic ip-config update \
  --resource-group $RG_NAME \
  --name ipconfigweb-vm-2 \
  --nic-name web-vm-2VMNic \
  --lb-name web-lb \
  --lb-address-pools BackEndPool

echo "Deployment Complete!"
