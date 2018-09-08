
kubectl apply -f https://openebs.github.io/charts/openebs-operator-0.7.0.yaml

echo "Waiting for default jiva pool to be ready"
until kubectl get sp -l openebs.io/version 2>&1 | grep -q "default";
do
  echo -n "."
  sleep 2; 
done
echo ""
kubectl get pods -n openebs

