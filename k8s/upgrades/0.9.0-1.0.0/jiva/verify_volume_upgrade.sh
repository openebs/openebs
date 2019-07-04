#!/bin/bash 

target_upgrade_version=1.0.0
is_upgrade_failed=0

function usage() {
    echo
    echo "Usage:"
    echo
    echo "$0 <pv-name>"
    echo
    echo "  <pv-name> Get the PV name using: kubectl get pv"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

pv=$1

echo "verifying jiva $pv volume upgrade"

ns=$(kubectl get pv "$pv" -o jsonpath="{.spec.claimRef.namespace}")


c_deploy_name=$(kubectl get deploy -n "$ns" \
    -l openebs.io/persistent-volume="$pv",openebs.io/controller=jiva-controller \
    -o jsonpath="{.items[*].metadata.name}" \
)

r_deploy_name=$(kubectl get deploy -n "$ns" \
    -l openebs.io/persistent-volume="$pv",openebs.io/replica=jiva-replica \
    -o jsonpath="{.items[*].metadata.name}" \
)
c_svc_name=$(kubectl get svc -n "$ns" \
    -l openebs.io/persistent-volume="$pv" \
    -o jsonpath="{.items[*].metadata.name}" \
)

#Fetch REPLICATIONFACTOR from deployment
container_name=$(echo "$pv-ctrl-con")
replication_factor=$(kubectl get deploy "$c_deploy_name" -n "$ns" \
-o jsonpath="{.spec.template.spec.containers[?(@.name=='$container_name')].env[?(@.name=='REPLICATION_FACTOR')].value}")

#Verifying the upgraded deployment versions
controller_version=$(kubectl get deployment "$c_deploy_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [ "$controller_version" != "$target_upgrade_version" ]; then
    echo "Failed validation for target deployment $c_deploy_name... "
    echo "expected version: $target_upgrade_version but got $controller_version"
    is_upgrade_failed=1
fi
replica_version=$(kubectl get deployment "$r_deploy_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [ "$replica_version" != "$target_upgrade_version" ]; then
    echo "Failed validation for replica deployment $r_deploy_name... "
    echo "expected version: $target_upgrade_version but got $replica_version"
    is_upgrade_failed=1
fi

#Verifying the upgraded service versions
controller_svc_version=$(kubectl get svc "$c_svc_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [ "$controller_svc_version" != "$target_upgrade_version" ] ; then
    echo "Failed validation for target service $c_svc_name... "
    echo "expected version: $target_upgrade_version but got $controller_svc_version"
    is_upgrade_failed=1
fi

#Verifying the upgraded deployment images
controller_images=$(kubectl get deployment "$c_deploy_name" -n "$ns" \
        -o jsonpath='{range .spec.template.spec.containers[*]}{@.image}?{end}')
for image in $(echo "$controller_images" | tr "?" " "); do
    image_version=$(echo "$image" | cut -d ':' -f 2) 
    if [ "$image_version" != "$target_upgrade_version" ] ; then
        echo "Failed validation for controller deployment $c_deploy_name..."
        echo "expected image version: $target_upgrade_version but got $image_version"
        is_upgrade_failed=1 
    fi
done

replica_images=$(kubectl get deployment "$r_deploy_name" -n "$ns" \
        -o jsonpath='{range .spec.template.spec.containers[*]}{@.image}?{end}')
for image in $(echo "$replica_images" | tr "?" " "); do 
    image_version=$(echo "$image" | cut -d ':' -f 2)
    if [ "$image_version" != "$target_upgrade_version" ] ; then
        echo "Failed validation for replica deployment $r_deploy_name..."
        echo "expected image version: $target_upgrade_version but got $image_version"
        is_upgrade_failed=1
    fi
done

#Verifying running status of controller and replica pods
running_ctrl_pod_count=$(kubectl get pods -n "$ns" \
-l openebs.io/controller=jiva-controller,openebs.io/persistent-volume="$pv" \
--no-headers | wc -l | tr -d [:blank:])
if [ "$running_ctrl_pod_count" != 1 ]; then
    echo "Failed validation for controller pod not running"
    is_upgrade_failed=1
fi

running_rep_pod_count=$(kubectl get pods -n "$ns" \
-l openebs.io/replica=jiva-replica,openebs.io/persistent-volume="$pv" \
--no-headers | wc -l | tr -d [:blank:])
if [ "$running_rep_pod_count" != "$replication_factor" ]; then
    echo "Failed validation for replica pods not running"
    is_upgrade_failed=1 
fi

#Verifying registered replica count
retry=0
replica_count=0
while [[ "$replica_count" != "$replication_factor" && $retry -lt 60 ]]
do 
    ctr_pod=$(kubectl get pod -n "$ns" \
        -l openebs.io/persistent-volume="$pv",openebs.io/controller=jiva-controller \
        -o jsonpath="{.items[*].metadata.name}" \
    )
    
    replica_count=$(kubectl exec -it "$ctr_pod" -n "$ns" --container "$container_name" \
        -- bash -c "curl -s http://localhost:9501/v1/volumes" \
        | grep -oE '("replicaCount":)[0-9]' | cut -d ':' -f 2
    )
    
    retry=$(( retry+1 ))
    sleep 5
done

if [ "$replica_count" != "$replication_factor" ]; then
    echo "Failed validation for registered replica count.. "
    echo "expected $replication_factor but only $replica_count are registered"
    is_upgrade_failed=1
fi

if [ $is_upgrade_failed == 0 ]; then
    echo "volume upgrade $pv verification is successful"
else
    echo -n "Validation steps are failed on volume $pv. This might be"
    echo "due to ongoing upgrade or errors during upgrade."
    echo -n "Please run ./verify_volume_upgrade.sh <pv_name> again after "
    echo "some time. If issue still persist, contact OpenEBS team over slack for any further help."
    exit 1
fi

exit 0
