# High Availability Web Fleet on Azure

## Project Overview
This project deploys a highly available web server architecture on Microsoft Azure using the Azure CLI. It features two Linux Virtual Machines behind a Standard Load Balancer, ensuring that if one server goes down, the traffic automatically fails over to the healthy server.

## Architecture
![Architecture Diagram](architecture.png)

## Technology Stack
- **Cloud Provider:** Microsoft Azure
- **Infrastructure as Code:** Azure CLI (Bash Script)
- **Compute:** Ubuntu Linux VMs (Standard_B1s)
- **Networking:** VNet, Subnet, NSG, Standard Load Balancer
- **Automation:** Cloud-Init for Nginx installation

## Key Features
- **Redundancy:** Dual VM deployment in an Availability Set configuration.
- **Health Checks:** Load Balancer probes port 80 every 15 seconds.
- **Automation:** Zero-touch deployment using `setup_ha_fleet.sh`.
- **Security:** Minimal port exposure (only Port 80 opened).

## Challenges & Troubleshooting

### Issue: "Resource Not Found" Error
**The Problem:**
During the automation script development, the step to connect the VMs to the Load Balancer failed with a `ResourceNotFound` error.

**The Investigation:**
I initially assumed the internal Network Interface (NIC) names were incorrect. However, running `az network nic list` confirmed the NIC names were standard. I then realized the issue was with the **IP Configuration Name**. Azure had dynamically named the IP configuration based on the VM name (e.g., `ipconfigweb-vm-1`) instead of the default `ipconfig1`.

**The Solution:**
I used the Azure CLI JMESPath query to extract the exact IP configuration name:
`az network nic show --resource-group ha-web-rg --name web-vm-1VMNic --query "ipConfigurations[0].name"`

Using this correct name in my update command resolved the issue and successfully connected the Backend Pool.

## How to Deploy
1. Clone this repository.
2. Run the setup script:
   `bash setup_ha_fleet.sh`
3. Access the Load Balancer Public IP to view the site.
