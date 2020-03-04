#!/usr/bin/env bash
#####################################################################
# NOTES: This script finds unlabeled volume resources of openebs   #
#####################################################################

# Search of CStor Resources
printf "############## Unlabeled CStor Volumes Resources ##############\n\n"

printf "CStor Volumes:\n"
echo "--------------"
printf "\n"
# Search for CStor Volumes
kubectl get cstorvolume --all-namespaces -l 'openebs.io/version notin (0.8.2), openebs.io/version notin (0.8.1)'

printf "\nCStor Volumes Replicas:\n"
echo "-----------------------"
printf "\n"
# Search for CStor Volume Replicas
kubectl get cstorvolumereplicas --all-namespaces -l 'openebs.io/version notin (0.8.2), openebs.io/version notin (0.8.1)'

printf "\nCStor Target service:\n"
echo "---------------------"
printf "\n"
# Search for CStor Target Service
kubectl get service --all-namespaces -l 'openebs.io/version notin (0.8.2), openebs.io/version notin (0.8.1), openebs.io/target-service in (cstor-target-svc)'

printf "\nCStor Target Deployment:\n"
echo "---------------------"
printf "\n"
# Search for CStor Target Deployment
kubectl get deployment --all-namespaces -l 'openebs.io/version notin (0.8.2), openebs.io/version notin (0.8.1), openebs.io/target in (cstor-target)'


printf "\n\n############## unlabeled Jiva Volumes Resources ##############\n\n"

printf "\nJiva Controller service:\n"
echo "------------------------"
printf "\n"
# Search for Jiva Controller Services
kubectl get service --all-namespaces -l 'openebs.io/version notin (0.8.2), openebs.io/version notin (0.8.1), openebs.io/controller-service in (jiva-controller-svc)'

printf "\nJiva Replica Deployment:\n"
echo "------------------------"
printf "\n"
# Search for Jiva Replica Deployment
kubectl get deployment --all-namespaces -l 'openebs.io/version notin (0.8.2), openebs.io/version notin (0.8.1), openebs.io/replica in (jiva-replica)'

printf "\nJiva Controller Deployment:\n"
echo "------------------------"
printf "\n"
# Search for Jiva Controller Deployment
kubectl get deployment --all-namespaces -l 'openebs.io/version notin (0.8.2), openebs.io/version notin (0.8.1), openebs.io/controller in (jiva-controller)'

printf "\n\n############## Storage Pool Resources ##############\n\n"

printf "\nCStor Pool:\n"
echo "-----------"
printf "\n"
kubectl get csp -l 'openebs.io/version notin (0.8.2), openebs.io/version notin (0.8.1)'

printf "\nCStor Pool Deployments:\n"
echo "-----------------------"
printf "\n"
kubectl get deployment --all-namespaces -l 'openebs.io/version notin (0.8.2), openebs.io/version notin (0.8.1), app in (cstor-pool)'

printf "\nStorge Pool:\n"
echo "------------"
printf "\n"
kubectl get sp -l 'openebs.io/version notin (0.8.2), openebs.io/version notin (0.8.1), openebs.io/cas-type in (cstor)'

printf "Note: The unlabeled resources can be tagged with correct version of openebs using labeltagger.sh.\n Example: ./labeltagger.sh 0.8.1"
