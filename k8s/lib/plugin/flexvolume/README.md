# OpenEBS FlexVolume 

## Installation 

Step 1 : The plugin will need to be installed on all minion nodes at the volumes plugin directory location. The default location is:

```
/usr/libexec/kubernetes/kubelet-plugins/volume/exec/openebs~openebs-iscsi/openebs-iscsi
```

Step 2 : After copy the file, restart the kubelet

```
sudo systemctl restart kubelet
```

