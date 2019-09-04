#!/bin/bash

echo "Running pre-installation steps"

x=$(kubectl get crd cstorpoolclusters.openebs.io -o jsonpath="{.spec.scope}" 2>&1 )

if [[ $x == 'Cluster' ]]; then
    kubectl delete crd cstorpoolclusters.openebs.io
fi

echo "Installing cspc operator"

kubectl apply -f cspc-operator.yaml