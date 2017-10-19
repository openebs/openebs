#!/bin/bash


kubectl delete statefulset rabbitmq
kubectl delete svc rabbitmq rabbitmq-management
kubectl delete secrets rabbitmq-config
kubectl delete pvc -l app=rabbitmq
