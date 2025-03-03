#!/bin/bash
CLUSTER_NAME="production-stack"
RESOURCE_GROUP="production-stack-rg"
LOCATION="westus"

# Ensure the Azure CLI is logged in and a subscription is selected
if ! az account show > /dev/null 2>&1; then
  echo "Error: No Azure account found. Please log in with 'az login'."
  exit 1
fi

# Ensure a parameter is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <SETUP_YAML>"
  exit 1
fi

SETUP_YAML=$1

# Create the AKS cluster
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"


# TODO: check first 
az provider register --namespace Microsoft.ContainerService

az aks create \
  --resource-group "production-stack-rg" \
  --name "production-stack" \
  --node-count 1 \
  --node-vm-size Standard_NC4as_T4_v3 \
  --enable-managed-identity \
  --network-plugin azure \
  --node-osdisk-size 50 

  az quota update --scope /subscriptions/77ac8b33-96f8-46ad-8015-d618434a2fed \
  --provider Microsoft.Compute --resource standardNCASv3_T4 \
  --limit 4 --location eastus


# Get credentials
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME"

# Deploy the application using Helm
helm repo add vllm https://vllm-project.github.io/production-stack
helm install vllm vllm/vllm-stack -f "$SETUP_YAML"

