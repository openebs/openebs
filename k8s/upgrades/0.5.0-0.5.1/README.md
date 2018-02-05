# UPGRADE FROM OPENEBS 0.5.0 TO 0.5.1

Follow the steps suggested in [README](https://github.com/ksatchit/openebs/blob/master/k8s/upgrades/0.4.0-0.5.0/README.md) 
for upgrade from 0.4.0 to 0.5.0 with the following minor changes in the following steps: 

- Step #2 : Obtain the specifications from https://github.com/openebs/openebs/releases/tag/v0.5.1
- Step #4 : Monitoring is supported from 0.5.0 onwards. Either they be running aleady or they can be created on a need basis
- Step #5 : The script oebs_update.sh to update the volume deployments should be: 
  - Copied into the 0.5.0-0.5.1 folder OR updated with appropriate relative paths 
  - Upadted by commenting the step to delete stale controller replicaset as this issue is N/A in the upgrade from 0.5 to 0.5.1
- Step:4 : Refer Step #4




