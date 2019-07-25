---
apiVersion: batch/v1
kind: Job
metadata:
  name: jvupg-100111-<@pv-name>
spec:
  backoffLimit: 0
  template:
    spec:
      serviceAccountName: <@openebs-service-account>
      containers:
      - name:  upgrade
        image: openebs/m-upgrade:ci-1.1.x-072501
        args: 
        - "<@from-version>"
        - "<@to-version>"
        - "jivaVolume"
        - "<@pv-name>"
        - "<@openebs-namespace>"
        tty: true 
      restartPolicy: Never
