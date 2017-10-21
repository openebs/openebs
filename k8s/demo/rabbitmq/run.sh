#!/bin/bash

# Create Secret Cookie
kubectl create secret generic rabbitmq-config --from-literal=erlang-cookie=rabbitmq-k8s-Dem0

# Apply the StatefulSet
kubectl apply -f rabbitmq-statefulset.yaml

