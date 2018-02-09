# UPGRADE FROM OPENEBS 0.5.0 TO 0.5.1

Follow the steps suggested in [README](https://github.com/ksatchit/openebs/blob/master/k8s/upgrades/0.4.0-0.5.0/README.md) 
for upgrading OpenEBS from 0.4.0 to 0.5.0 with the following minor changes: 

- Step #2 : Obtain the specifications from https://github.com/openebs/openebs/releases/tag/v0.5.1

- Step #4 : Monitoring is supported from 0.5.0 onwards. These pods may be created on a need basis if not running already

- Step #5 : The script oebs_update.sh to update the volume deployments should be: 

  - Copied into the 0.5.0-0.5.1 folder OR updated with relative paths to point to the appropriate patch files 
  - Updated by commenting the step to delete stale controller replicaset as this issue is N/A while upgrading from 0.5.0 to 0.5.1
  
- Step #7 : Refer Step #4




