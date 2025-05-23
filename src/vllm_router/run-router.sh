#!/bin/bash
if [[ $# -ne 1 ]]; then
    echo "Usage $0 <router port>"
    exit 1
fi

# Use this command when testing with k8s service discovery
# python3 -m vllm_router.app --port "$1" \
#     --service-discovery k8s \
#     --k8s-label-selector release=test \
#     --k8s-namespace default \
#     --routing-logic session \
#     --session-key "x-user-id" \
#     --engine-stats-interval 10 \
#     --log-stats

# Use this command when testing with static service discovery
python3 -m vllm_router.app --port "$1" \
    --service-discovery static \
    --static-backends "http://localhost:8100,http://localhost:8200" \
    --static-models "meta-llama/Llama-3.2-1B-Instruct,meta-llama/Llama-3.2-1B-Instruct" \
    --static-model-labels "llama-prefill,llama-decode" \
    --prefill-model-labels "llama-prefill" \
    --decode-model-labels "llama-decode" \
    --log-stats \
    --log-stats-interval 10 \
    --engine-stats-interval 10 \
    --request-stats-window 10 \
    --request-stats-window 10 \
    --routing-logic disaggregated_prefill

# Use this command when testing with roundrobin routing logic
#python3 router.py --port "$1" \
#    --service-discovery k8s \
#    --k8s-label-selector release=test \
#    --routing-logic roundrobin \
#    --engine-stats-interval 10 \
#    --log-stats
#
