# Setting up AKS vLLM stack with one command

This script automatically configures an AKS LLM inference cluster.
Make sure your Azure CLI is set up, logged in, and the region is configured. You should have kubectl and Helm installed.

Modify fields in `production_stack_specification.yaml` and execute as:

```bash
sudo bash entry_point.sh YAML_FILE_PATH
```

Pods for the vLLM deployment should transition to Ready and the Running state.

Expected output:

```plaintext
NAME                                            READY   STATUS    RESTARTS   AGE
vllm-deployment-router-69b7f9748d-xrkvn         1/1     Running   0          75s
vllm-opt125m-deployment-vllm-696c998c6f-mvhg4   1/1     Running   0          75s
```

Clean up the service with:

```bash
bash clean_up.sh production-stack
```

