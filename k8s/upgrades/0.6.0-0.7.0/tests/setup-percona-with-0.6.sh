kubectl apply -f https://openebs.github.io/charts/openebs-operator-0.6.0.yaml
kubectl apply -f https://openebs.github.io/charts/openebs-storageclasses-0.6.0.yaml

echo "Waiting for m-apiserver to be ready"
JSONPATH='{range .items[0]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; 
until kubectl get pods -n openebs -l name=maya-apiserver -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True";
do
  echo -n "."
  sleep 2; 
done
echo ""
kubectl get pods -n openebs

echo "Launching percona"
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/v0.6/k8s/demo/percona/percona-openebs-deployment.yaml

JSONPATH='{range .items[0]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; 
until kubectl get pods -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True";
do
  echo -n "."
  sleep 2; 
done
echo ""
kubectl get pods 
