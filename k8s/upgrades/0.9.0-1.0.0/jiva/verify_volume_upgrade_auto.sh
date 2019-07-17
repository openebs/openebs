#!/bin/bash 

is_upgrade_failed=0

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )/../" && pwd )"
source $DIR/util.sh

#Fetch REPLICATIONFACTOR from deployment
container_name=$(echo "$pv-ctrl-con")
replication_factor=$(kubectl get deploy "$c_deploy_name" -n "$ns" \
-o jsonpath="{.spec.template.spec.containers[?(@.name=='$container_name')].env[?(@.name=='REPLICATION_FACTOR')].value}")

#Verifying the upgraded deployment versions
version=$(verify_openebs_version "deployment" $c_deploy_name $ns)
if [ "$version" != "$upgrade_version" ]; then
    echo "Failed validation for target deployment $c_deploy_name "
    echo "expected version $upgrade_version but got $version."
    is_upgrade_failed=1
fi

version=$(verify_openebs_version "deployment" $r_deploy_name $ns)
if [ "$version" != "$upgrade_version" ]; then
    echo "Failed validation for replica deployment $r_deploy_name "
    echo "expected version $upgrade_version but got $version."
    is_upgrade_failed=1
fi

#Verifying the upgraded service versions
version=$(verify_openebs_version "svc" $c_svc_name $ns)
if [ "$version" != "$upgrade_version" ] ; then
    echo "Failed validation for target service $c_svc_name "
    echo "expected version $upgrade_version but got $version."
    is_upgrade_failed=1
fi

#Verifying the upgraded deployment images
controller_images=$(kubectl get deployment "$c_deploy_name" -n "$ns" \
        -o jsonpath='{range .spec.template.spec.containers[*]}{@.image}?{end}')
for image in $(echo "$controller_images" | tr "?" " "); do
    image_version=$(echo "$image" | cut -d ':' -f 2) 
    if [ "$image_version" != "$upgrade_version" ] ; then
        echo "Failed validation for controller deployment $c_deploy_name "
        echo "expected image version $upgrade_version but got $image_version."
        is_upgrade_failed=1 
    fi
done

replica_images=$(kubectl get deployment "$r_deploy_name" -n "$ns" \
        -o jsonpath='{range .spec.template.spec.containers[*]}{@.image}?{end}')
for image in $(echo "$replica_images" | tr "?" " "); do 
    image_version=$(echo "$image" | cut -d ':' -f 2)
    if [ "$image_version" != "$upgrade_version" ] ; then
        echo "Failed validation for replica deployment $r_deploy_name "
        echo "expected image version $upgrade_version but got $image_version."
        is_upgrade_failed=1
    fi
done

#Verifying running status of controller and replica pods
running_ctrl_pod_count=$(kubectl get pods -n "$ns" \
-l openebs.io/controller=jiva-controller,openebs.io/persistent-volume="$pv" \
--no-headers | wc -l | tr -d [:blank:])
if [ "$running_ctrl_pod_count" != 1 ]; then
    echo "Failed validation for controller pod not running."
    is_upgrade_failed=1
fi

running_rep_pod_count=$(kubectl get pods -n "$ns" \
-l openebs.io/replica=jiva-replica,openebs.io/persistent-volume="$pv" \
--no-headers | wc -l | tr -d [:blank:])
if [ "$running_rep_pod_count" != "$replication_factor" ]; then
    echo "Failed validation for replica pods not running."
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
    echo "Failed validation for registered replica count "
    echo "expected $replication_factor but only $replica_count are registered."
    is_upgrade_failed=1
fi

#Checking node stickiness
after_node_names=$(kubectl get pods -n "$ns" \
    -l openebs.io/replica=jiva-replica,openebs.io/persistent-volume="$pv" \
    -o jsonpath='{range .items[*]}{@.spec.nodeName}:{end}')

for after_node in $(echo "$after_node_names" | tr ":" " "); do 
    count=0
    for before_node in $(echo "$before_node_names" | tr ":" " "); do
        if [ "$after_node" == "$before_node" ]; then
            count=$(( count+1 )) 
        fi
    done
    if [ $count != 1 ]; then
        echo "Node stickiness failed after upgrade."
        is_upgrade_failed=1
    fi 
done

if [ $is_upgrade_failed == 0 ]; then
    echo "volume upgrade $pv verification is successful."
else
    exit 1
fi

exit 0
