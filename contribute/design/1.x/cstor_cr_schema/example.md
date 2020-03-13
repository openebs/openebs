The proposed CSPC schema in go struct is mentioned in the apis.md file in the current directory.

Following is an example CSPC in YAML form. This YAML form of CSPC is what users intearact with and hence
YAML can help understand more what features/capabilities CSPC API has!

Following YAML is typically what one will see when `kubectl get cspc -n openebs demo-pool-cluster` is executed and 
`demo-pool-cluster` exists in the system.
Hence, it should be worth noting that few fields appearing in the CSPC are not meant to be changed/modified or entered by 
a user and it is system-generated or is for use by system.
Most system generated fields are meant ot provide a user with additional info e.g. status.

```YAML
apiVersion: cstor.openebs.io/v1
kind: CStorPoolCluster
metadata:
  name: demo-pool-cluster
  namespace: openebs
spec:
  # Following fields i.e. resources, auxResources, tolerations and priorityClassName
  # applies to pool for which these values are left unspecified at poolConfig
  # spec.pools field contains a list and an item of the list is nothing but 
  # specification of a cstor-pool.
  # poolConfig field is present in this spec.pools[i]
  resources:
    requests:
      memory: "64Mi"
      cpu: "250m"
    limits:
      memory: "128Mi"
      cpu: "500m"

  auxResources:
    requests:
      memory: "50Mi"
      cpu: "400m"
    limits:
      memory: "100Mi"
      cpu: "400m"

  tolerations:
  - key: data-plane-node
    operator: Equal
    value: true
    effect: NoSchedule

  priorityClassName: high-priority 
  # Total 3 pools are specified and hence three CStorPoolInstances CR will be created.
  # Also, total 3 cstor-pool-manager-pods are created to manage the CStorPoolInstances CRs.
  pools:
    # This is the node where cstor-pool-manager pod will get scheduled for this config. 
    - nodeSelector:
        kubernetes.io/hostname: worker-node-1

      dataRaidGroups:
      - cspiBlockDevices:
          - blockDeviceName: blockdevice-ada8ef910929513c1ad650c08fbe3f36
            # System-Generated/Used
            capacity:
            # System-Generated/Used
            devLink: /dev/iscsi-0/1
          - blockDeviceName: blockdevice-ada8ef910929513c1ad650c08fbe3f37
            # System-Generated/Used
            capacity:
            # System-Generated/Used
            devLink: /dev/iscsi-0/2

      writeCacheGroups:
      - cspiBlockDevices:
          - blockDeviceName: blockdevice-ada8ef910929513c1ad650c08fbe3f38
            # System-Generated/Used
            capacity:
            # System-Generated/Used
            devLink: /dev/iscsi-1/1

      poolConfig:
        # Possible value for dataRaidGroupType are : {stripe, mirror, raidz1, raidz2}
        dataRaidGroupType: mirror
        # Possible value for writeCacheRaidGroupType is same as that of dataRaidGroupType
        writeCacheRaidGroupType: stripe
        thickProvisioning: false
        # Possible values for compression are : {lz, off} 
        compression: lz
        # Following resources are null or empty and therefore 
        # spec.resources, spec.auxResources and spec.tolerations
        # values will be used for the cstor-pool-manager pod.
        resources: null
        auxResources: null
        tolerations: null
        priorityClassName: ""

    # This is the node where cstor-pool-manager pod will get scheduled for this config.
    - nodeSelector:
        kubernetes.io/hostname: worker-node-2

      dataRaidGroups:
      - cspiBlockDevices:
          - blockDeviceName: blockdevice-ada8ef910929513c1ad650c08fbe3f39
            # System-Generated/Used
            capacity:
            # System-Generated/Used
            devLink: /dev/iscsi-0/3
          - blockDeviceName: blockdevice-ada8ef910929513c1ad650c08fbe3f40
            # System-Generated/Used
            capacity:
            # System-Generated/Used
            devLink: /dev/iscsi-0/4

      writeCacheGroups:
      - cspiBlockDevices:
          - blockDeviceName: blockdevice-ada8ef910929513c1ad650c08fbe3f41
            # System-Generated/Used
            capacity:
            # System-Generated/Used
            devLink: /dev/iscsi-1/2

      poolConfig:
        dataRaidGroupType: mirror
        writeCacheRaidGroupType: stripe
        thickProvisioning: false
        compression: lz
        # Following resources are null or empty and therefore 
        # spec.resources, spec.auxResources and spec.tolerations
        # values will be used for the cstor-pool-manager pod.
        resources: null
        auxResources: null
        tolerations: null
        priorityClassName: ""

    - nodeSelector:
        kubernetes.io/hostname: worker-node-3

      dataRaidGroups:
      - cspiBlockDevices:
          - blockDeviceName: blockdevice-ada8ef910929513c1ad650c08fbe3f42
            # System-Generated/Used
            capacity:
            # System-Generated/Used
            devLink: /dev/iscsi-0/5
          - blockDeviceName: blockdevice-ada8ef910929513c1ad650c08fbe3f43
            # System-Generated/Used
            capacity:
            # System-Generated/Used
            devLink: /dev/iscsi-0/6

      writeCacheGroups:
      - cspiBlockDevices:
          - blockDeviceName: blockdevice-ada8ef910929513c1ad650c08fbe3f44
            # System-Generated/Used
            capacity:
            # System-Generated/Used
            devLink: /dev/iscsi-1/3

      poolConfig:
        dataRaidGroupType: stripe
        writeCacheRaidGroupType: stripe
        thickProvisioning: false
        compression: lz
        # Following resources are NOT null or empty and therefore 
        # spec.resources, spec.auxResources and spec.tolerations
        # values will be IGNORED and these values will we applied to
        # pool manager pod
        resources:
          requests:
            memory: 70Mi
            cpu: 300m
          limits:
            memory: 130Mi
            cpu: 600m

        auxResources:
          requests:
            memory: 60Mi
            cpu: 500m
          limits:
            memory: 120Mi
            cpu: 500m

        tolerations:
        - key: data-plane-node
          operator: Equal
          value: true
          effect: NoSchedule

        - key: apac-zone
          operator: Equal
          value: true
          effect: NoSchedule

        priorityClassName: utlra-priority

# System-Generated/Used
status:
  provisionedInstances: 3
  desiredInstances: 3
  healthyInstances: 3
  conditions:
  - type: PoolAvailability
    status: false
    # lastUpdateTime is the last time when CSPC was reconciled. 
    lastUpdateTime: 2020-03-13T03:56:01Z
    # lastTransitionTime is the last time when CSPC spec transitioned to a different spec 
    lastTransitionTime: 2020-03-13T03:56:49Z
    reason: CStor pool manger demo-pool-cluster-xsdfr pod is pending
    message: Cstor pool manager pod demo-pool-cluster-xsdfr not reachable
versionDetails:
  autoUpgrade: false
  desired: 1.8
  status:
    dependentsUpgraded: true
    current: 1.8
    state: Reconciled
    message: ""
    reason: ""
    lastUpdateTime: 2020-03-13T03:56:49Z

```