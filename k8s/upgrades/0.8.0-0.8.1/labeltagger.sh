#!/bin/bash
#####################################################################
# NOTES: This script finds unlabeled volume resources of openebs   #
#####################################################################

function usage() {
    echo 
    echo "Usage: This script adds openebs.io/version label to unlabeled volume resources of openebs"
    echo 
    echo "$0 <current openebs version>"
    echo 
    echo "Example: $0 0.8.0"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

currentVersion=$1
echo $currentVersion

echo "#!/bin/bash" > label.sh
echo "set -e" >> label.sh

echo "##### Creating the tag script #####"
# Adding cstor resources
kubectl get cstorvolume --all-namespaces -l 'openebs.io/version notin (0.8.1), openebs.io/version notin (0.8.0)' -o jsonpath="{range .items[*]}kubectl label {@.kind} {@.metadata.name} openebs.io/version=$currentVersion -n {@.metadata.namespace} --overwrite=true;{end}" | tr ";" "\n" >> label.sh
kubectl get cstorvolumereplicas --all-namespaces -l 'openebs.io/version notin (0.8.1), openebs.io/version notin (0.8.0)' -o jsonpath="{range .items[*]}kubectl label {@.kind} {@.metadata.name} openebs.io/version=$currentVersion -n {@.metadata.namespace} --overwrite=true;{end}" | tr ";" "\n" >> label.sh
kubectl get service --all-namespaces -l 'openebs.io/version notin (0.8.1), openebs.io/version notin (0.8.0), openebs.io/target-service in (cstor-target-svc)' -o jsonpath="{range .items[*]}kubectl label {@.kind} {@.metadata.name} openebs.io/version=$currentVersion -n {@.metadata.namespace} --overwrite=true;{end}" | tr ";" "\n" >> label.sh
kubectl get deployment --all-namespaces -l 'openebs.io/version notin (0.8.1), openebs.io/version notin (0.8.0), openebs.io/target in (cstor-target)' -o jsonpath="{range .items[*]}kubectl label {@.kind} {@.metadata.name} openebs.io/version=$currentVersion -n {@.metadata.namespace} --overwrite=true;{end}" | tr ";" "\n" >> label.sh

# Adding jiva resources
kubectl get service --all-namespaces -l 'openebs.io/version notin (0.8.1), openebs.io/version notin (0.8.0), openebs.io/controller-service in (jiva-controller-svc)' -o jsonpath="{range .items[*]}kubectl label {@.kind} {@.metadata.name} openebs.io/version=$currentVersion -n {@.metadata.namespace} --overwrite=true;{end}" | tr ";" "\n" >> label.sh
kubectl get deployment --all-namespaces -l 'openebs.io/version notin (0.8.1), openebs.io/version notin (0.8.0), openebs.io/replica in (replica)' -o jsonpath="{range .items[*]}kubectl label {@.kind} {@.metadata.name} openebs.io/version=$currentVersion -n {@.metadata.namespace} --overwrite=true;{end}" | tr ";" "\n" >> label.sh
kubectl get deployment --all-namespaces -l 'openebs.io/version notin (0.8.1), openebs.io/version notin (0.8.0), openebs.io/controller in (jiva-controller)' -o jsonpath="{range .items[*]}kubectl label {@.kind} {@.metadata.name} openebs.io/version=$currentVersion -n {@.metadata.namespace} --overwrite=true;{end}" | tr ";" "\n" >> label.sh

# Adding pool resources
kubectl get csp -l 'openebs.io/version notin (0.8.1), openebs.io/version notin (0.8.0)' -o jsonpath="{range .items[*]}kubectl label {@.kind} {@.metadata.name} openebs.io/version=$currentVersion --overwrite=true;{end}" | tr ";" "\n" >> label.sh
kubectl get deployment --all-namespaces -l 'openebs.io/version notin (0.8.1), openebs.io/version notin (0.8.0), app in (cstor-pool)' -o jsonpath="{range .items[*]}kubectl label {@.kind} {@.metadata.name} openebs.io/version=$currentVersion -n {@.metadata.namespace} --overwrite=true;{end}" | tr ";" "\n" >> label.sh
kubectl get sp -l 'openebs.io/version notin (0.8.1), openebs.io/version notin (0.8.0), openebs.io/cas-type in (cstor)' -o jsonpath="{range .items[*]}kubectl label {@.kind} {@.metadata.name} openebs.io/version=$currentVersion --overwrite=true;{end}" | tr ";" "\n" >> label.sh

# Running the label.sh
chmod +x ./label.sh
./label.sh

# Removing the generated script
rm label.sh