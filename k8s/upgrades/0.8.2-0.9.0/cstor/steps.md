# OpenEBS Upgrade Via CAS Templates From 0.8.2 to 0.9.0
**NOTE: Upgrade via these CAS Templates is ony supported for OpenEBS in version 0.8.2.**
**NOTE: Trying to upgrade a OpenEBS version other than 0.8.2 to 0.9.0 using these CAS templates can result in undesired behaviours.**
**NOTE: If you are having any OpenEBS version lower than 0.8.2, first upgrade it ot 0.8.2 and then these CAS templates can be used safely for 0.9.0 upgrade.**

# Steps Before Upgrade:

  - Apply cr.yaml which installs a custom resource definition for UpgradeResult custom reource. This custom resource is used to capture upgrade related information for success or failure case.
  - Apply rbac.yaml for permission stuff.
 
# Steps For OpenEBS cStor Volume Upgrade:

  - Apply cstor-pool-update-082-090.yaml
  - Open pool-upgrade-job.yaml and put the name of cstorpool resource which you want to upgrade. Some comments itself is written in the yaml for clarity.
  - After you are done editing pool-upgrade-job.yaml, save it and apply.
  - You can see logs for your upgrade in a pod which is launched by upgrade job. Do a `kubectl get pod` and hence use kubectl command to see the log of the upgrade job pod.
  - You can also do a `kubectl get upgraderesult -o yaml` to see the status of upgrade of each item. 

# Steps For OpenEBS cStor Volume Upgrade:

  - Apply cstor-volume-update-082-090.yaml
  - Open volume-upgrade-job.yaml and put the name of cstorvolume resource which you want to upgrade. Some comments itself is written in the yaml for clarity.
  - After you are done editing volume-upgrade-job.yaml, save it and apply.
  - You can see logs for your upgrade in a pod which is launched by upgrade job. Do a `kubectl get pod` and hence use kubectl command to see the log of the upgrade job pod.
  - You can also do a `kubectl get upgraderesult -o yaml` to see the status of upgrade of each item. 


