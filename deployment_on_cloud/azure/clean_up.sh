#!/bin/bash

# Set variables
CLUSTER_NAME=$1
RESOURCE_GROUP="production-stack-rg"
LOCATION="eastus"

# Ensure the Azure CLI is logged in and a subscription is selected
if ! az account show > /dev/null 2>&1; then
  echo "Error: No Azure account found. Please log in with 'az login'."
  exit 1
fi

if [ -z "$CLUSTER_NAME" ]; then
  echo "Usage: $0 <CLUSTER_NAME>"
  exit 1
fi

# Check if the cluster exists
CLUSTER_STATUS=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "provisioningState" --output tsv 2>/dev/null)

if [ "$CLUSTER_STATUS" != "Succeeded" ]; then
  echo "Cluster $CLUSTER_NAME not found or not in a running state."
  exit 1
fi

echo "Starting cleanup for AKS cluster: $CLUSTER_NAME"

# Delete all namespaces except for default, kube-system, and kube-public
echo "Deleting all custom namespaces..."
kubectl get ns --no-headers | awk '{print $1}' | grep -vE '^(default|kube-system|kube-public)' | xargs -r kubectl delete ns

# Delete all workloads
echo "Deleting all workloads..."
kubectl delete deployments,statefulsets,daemonsets,services,ingresses,configmaps,secrets,persistentvolumeclaims,jobs,cronjobs --all --all-namespaces
kubectl delete persistentvolumes --all

# Delete Load Balancers
echo "Deleting Load Balancers..."
LB_NAMES=$(kubectl get services --all-namespaces -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].metadata.name}')
for LB_NAME in $LB_NAMES; do
  kubectl delete service "$LB_NAME" --all-namespaces
done

# Delete the AKS cluster
echo "Deleting AKS cluster..."
az aks delete --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --yes --no-wait

# Wait for cluster deletion
echo "Waiting for cluster $CLUSTER_NAME to be deleted..."
while az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "provisioningState" --output tsv 2>/dev/null; do
  sleep 10
done

echo "Cluster $CLUSTER_NAME deleted."

# Delete associated persistent storage
echo "Deleting persistent storage..."
DISK_NAMES=$(az disk list --resource-group "$RESOURCE_GROUP" --query "[].name" --output tsv)
for DISK_NAME in $DISK_NAMES; do
  az disk delete --name "$DISK_NAME" --resource-group "$RESOURCE_GROUP" --yes --no-wait
done

echo "AKS cluster $CLUSTER_NAME cleanup completed successfully!"

