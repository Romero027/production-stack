# Deploying vLLM production-stack on Azure AKS

This guide walks you through the script that sets up a vLLM production-stack on top of AKS on Azure. It includes how the script configures Azure Files for persistent volume, setting up security configurations, and deploying a production AI inference stack using Helm.

## Installing Prerequisites

Before running this setup, ensure you have:

1. Azure CLI installed and configured with credentials and region [[Link]](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
2. Kubectl and Helm [[Link]](https://github.com/vllm-project/production-stack/blob/main/tutorials/00-install-kubernetes-env.md)

## TLDR

Disclaimer: This script requires GPU resources and will incur costs. Please make sure all resources are shut down properly.

To run the service, go into the "deployment_on_cloud/azure" folder and run:

```bash
bash entry_point.sh YOUR_AZURE_REGION EXAMPLE_YAML_PATH
```

Clean up the service (not including resource group) with:

```bash
bash clean_up.sh production-stack YOUR_AZURE_REGION
```

## Step by Step Explanation

### Step 1: Deploy the AKS Cluster

Create an Azure AKS cluster with GPU-enabled nodes.

```bash
AZURE_REGION=$1
SETUP_YAML=$2
RESOURCE_GROUP="production-stack-rg"
CLUSTER_NAME="production-stack"

az group create --name "$RESOURCE_GROUP" --location "$AZURE_REGION"

az aks create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CLUSTER_NAME" \
  --node-count 2 \
  --node-vm-size Standard_NC6s_v3 \
  --generate-ssh-keys
```

### Step 2: Set Up Azure Files for Persistent Volume

We use Azure Files as the persistent volume in AKS.

```bash
STORAGE_ACCOUNT_NAME="aksfilestorage"
SHARE_NAME="aks-share"

az storage account create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT_NAME" \
  --sku Standard_LRS

STORAGE_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT_NAME" --query "[0].value" --output tsv)

az storage share create \
  --name "$SHARE_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME"
```

### Step 3: Create a Persistent Volume (PV)

Create `azurefile-pv.yaml` with the correct storage account and share name:

```bash
cat <<EOF > azurefile-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: azurefile-pv
spec:
  capacity:
    storage: 40Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  azureFile:
    secretName: azure-secret
    shareName: $SHARE_NAME
    storageAccountName: $STORAGE_ACCOUNT_NAME
EOF
```

Apply the PV configuration:

```bash
kubectl apply -f azurefile-pv.yaml
kubectl get pv
```

### Step 4: Deploy the Production AI Stack

Add the Helm repository and deploy the AI inference stack.

```bash
helm repo add vllm https://vllm-project.github.io/production-stack
helm install vllm ./vllm-stack -f $SETUP_YAML
```

Here is an example YAML file for a cluster with two Llama-3.1-8B models:

```yaml
servingEngineSpec:
  runtimeClassName: ""
  modelSpec:
  - name: "llama8b"
    repository: "vllm/vllm-openai"
    tag: "latest"
    modelURL: "meta-llama/Llama-3.1-8B"

    replicaCount: 2

    requestCPU: 6
    requestMemory: "16Gi"
    requestGPU: 1
    hf_token: YOUR_HUGGING_FACE_TOKEN
    pvcStorage: "40Gi"
    pvcAccessMode:
      - ReadWriteMany
    storageClass: ""
```

### Step 5: Stopping the Helm Cluster

This uninstalls the production-stack and cleans PV.

```bash
helm uninstall vllm
kubectl delete pv azurefile-pv
```

If you want to start the deployment again, you can run:

```bash
kubectl apply -f azurefile-pv.yaml
helm install vllm vllm/vllm-stack -f production_stack_specification.yaml
```

### Step 6: Cleanup Azure Resources

This step cleans up the AKS cluster and associated storage:

```bash
az aks delete --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --yes --no-wait
az storage account delete --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --yes
```

You may also want to manually delete the resource group:

```bash
az group delete --name "$RESOURCE_GROUP" --yes --no-wait
```

## Summary

This tutorial covers:
✅ Creating an AKS cluster with GPU nodes
✅ Setting up Azure Files for persistent storage
✅ Creating Persistent Volumes
✅ Installing a production stack for vLLM inference with Helm

Now your Azure AKS production-stack is ready for large-scale AI model deployment 🚀!

