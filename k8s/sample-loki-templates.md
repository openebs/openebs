## Sample Template Specifications for Grafana Loki

```
[debug] Created tunnel using local port: '41237'

[debug] SERVER: "127.0.0.1:41237"

[debug] Fetched loki/loki-stack to /root/.helm/cache/archive/loki-stack-0.16.0.tgz

Release "loki" does not exist. Installing it now.
[debug] CHART PATH: /root/.helm/cache/archive/loki-stack-0.16.0.tgz

NAME:   loki
REVISION: 1
RELEASED: Wed Aug 21 11:52:27 2019
CHART: loki-stack-0.16.0
USER-SUPPLIED VALUES:
{}

COMPUTED VALUES:
grafana:
  enabled: false
  image:
    tag: 6.3.0-beta2
  sidecar:
    datasources:
      enabled: true
loki:
  affinity: {}
  annotations: {}
  config:
    auth_enabled: false
    chunk_store_config:
      max_look_back_period: 0
    ingester:
      chunk_block_size: 262144
      chunk_idle_period: 15m
      lifecycler:
        ring:
          kvstore:
            store: inmemory
          replication_factor: 1
    limits_config:
      enforce_metric_name: false
      reject_old_samples: true
      reject_old_samples_max_age: 168h
    schema_config:
      configs:
      - from: "2018-04-15"
        index:
          period: 168h
          prefix: index_
        object_store: filesystem
        schema: v9
        store: boltdb
    server:
      http_listen_port: 3100
    storage_config:
      boltdb:
        directory: /data/loki/index
      filesystem:
        directory: /data/loki/chunks
    table_manager:
      retention_deletes_enabled: false
      retention_period: 0
  enabled: true
  extraArgs: {}
  global: {}
  image:
    pullPolicy: IfNotPresent
    repository: grafana/loki
    tag: v0.3.0
  livenessProbe:
    httpGet:
      path: /ready
      port: http-metrics
    initialDelaySeconds: 45
  networkPolicy:
    enabled: false
  nodeSelector: {}
  persistence:
    accessModes:
    - ReadWriteOnce
    annotations: {}
    enabled: false
    size: 10Gi
    storageClassName: default
  podAnnotations:
    prometheus.io/port: http-metrics
    prometheus.io/scrape: "true"
  podDisruptionBudget: {}
  podLabels: {}
  podManagementPolicy: OrderedReady
  rbac:
    create: true
    pspEnabled: true
  readinessProbe:
    httpGet:
      path: /ready
      port: http-metrics
    initialDelaySeconds: 45
  replicas: 1
  resources: {}
  securityContext:
    fsGroup: 10001
    runAsGroup: 10001
    runAsNonRoot: true
    runAsUser: 10001
  service:
    annotations: {}
    labels: {}
    nodePort: null
    port: 3100
    type: ClusterIP
  serviceAccount:
    create: true
    name: null
  serviceMonitor:
    enabled: false
    interval: ""
  terminationGracePeriodSeconds: 30
  tolerations: []
  tracing:
    jaegerAgentHost: null
  updateStrategy:
    type: RollingUpdate
prometheus:
  enabled: false
  server:
    fullnameOverride: prometheus-server
promtail:
  affinity: {}
  annotations: {}
  config:
    client:
      backoff_config:
        maxbackoff: 5s
        maxretries: 5
        minbackoff: 100ms
      batchsize: 102400
      batchwait: 1s
      external_labels: {}
      timeout: 10s
    positions:
      filename: /run/promtail/positions.yaml
    server:
      http_listen_port: 3101
    target_config:
      sync_period: 10s
  deploymentStrategy: RollingUpdate
  enabled: true
  global: {}
  image:
    pullPolicy: IfNotPresent
    repository: grafana/promtail
    tag: v0.3.0
  livenessProbe: {}
  loki:
    serviceName: ""
    servicePort: 3100
    serviceScheme: http
  nameOverride: promtail
  nodeSelector: {}
  pipelineStages:
  - docker: {}
  podAnnotations:
    prometheus.io/port: http-metrics
    prometheus.io/scrape: "true"
  podLabels: {}
  rbac:
    create: true
    pspEnabled: true
  readinessProbe:
    failureThreshold: 5
    httpGet:
      path: /ready
      port: http-metrics
    initialDelaySeconds: 10
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 1
  resources: {}
  scrapeConfigs: []
  securityContext:
    readOnlyRootFilesystem: true
    runAsGroup: 0
    runAsUser: 0
  serviceAccount:
    create: true
    name: null
  serviceMonitor:
    enabled: false
    interval: ""
  tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
  volumeMounts:
  - mountPath: /var/lib/docker/containers
    name: docker
    readOnly: true
  - mountPath: /var/log/pods
    name: pods
    readOnly: true
  volumes:
  - hostPath:
      path: /var/lib/docker/containers
    name: docker
  - hostPath:
      path: /var/log/pods
    name: pods

HOOKS:
---
# loki-loki-stack-test
apiVersion: v1
kind: Pod
metadata:
  annotations:
    "helm.sh/hook": test-success
  labels:
    app: loki-stack
    chart: loki-stack-0.16.0
    release: loki
    heritage: Tiller
  name: loki-loki-stack-test
spec:
  containers:
  - name: test
    image: bats/bats:v1.1.0
    args:
    - /var/lib/loki/test.sh
    env:
    - name: LOKI_SERVICE
      value: loki
    - name: LOKI_PORT
      value: "3100"
    volumeMounts:
    - name: tests
      mountPath: /var/lib/loki
  restartPolicy: Never
  volumes:
  - name: tests
    configMap:
      name: loki-loki-stack-test
MANIFEST:

---
# Source: loki-stack/charts/loki/templates/podsecuritypolicy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: loki
  namespace: openebs
  labels:
    app: loki
    chart: loki-0.14.0
    heritage: Tiller
    release: loki
spec:
  privileged: false
  allowPrivilegeEscalation: false
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'persistentVolumeClaim'
    - 'secret'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
    - min: 1
      max: 65535
  fsGroup:
    rule: 'MustRunAs'
    ranges:
    - min: 1
      max: 65535
  readOnlyRootFilesystem: true
  requiredDropCapabilities:
    - ALL
---
# Source: loki-stack/charts/promtail/templates/podsecuritypolicy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: loki-promtail
  namespace: openebs
  labels:
    app: promtail
    chart: promtail-0.12.0
    heritage: Tiller
    release: loki
spec:
  privileged: false
  allowPrivilegeEscalation: false
  volumes:
    - 'secret'
    - 'configMap'
    - 'hostPath'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: 'RunAsAny'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
  readOnlyRootFilesystem: true
  requiredDropCapabilities:
    - ALL
---
# Source: loki-stack/charts/loki/templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: loki
  namespace: openebs
  labels:
    app: loki
    chart: loki-0.14.0
    release: loki
    heritage: Tiller
data:
  loki.yaml: YXV0aF9lbmFibGVkOiBmYWxzZQpjaHVua19zdG9yZV9jb25maWc6CiAgbWF4X2xvb2tfYmFja19wZXJpb2Q6IDAKaW5nZXN0ZXI6CiAgY2h1bmtfYmxvY2tfc2l6ZTogMjYyMTQ0CiAgY2h1bmtfaWRsZV9wZXJpb2Q6IDE1bQogIGxpZmVjeWNsZXI6CiAgICByaW5nOgogICAgICBrdnN0b3JlOgogICAgICAgIHN0b3JlOiBpbm1lbW9yeQogICAgICByZXBsaWNhdGlvbl9mYWN0b3I6IDEKbGltaXRzX2NvbmZpZzoKICBlbmZvcmNlX21ldHJpY19uYW1lOiBmYWxzZQogIHJlamVjdF9vbGRfc2FtcGxlczogdHJ1ZQogIHJlamVjdF9vbGRfc2FtcGxlc19tYXhfYWdlOiAxNjhoCnNjaGVtYV9jb25maWc6CiAgY29uZmlnczoKICAtIGZyb206ICIyMDE4LTA0LTE1IgogICAgaW5kZXg6CiAgICAgIHBlcmlvZDogMTY4aAogICAgICBwcmVmaXg6IGluZGV4XwogICAgb2JqZWN0X3N0b3JlOiBmaWxlc3lzdGVtCiAgICBzY2hlbWE6IHY5CiAgICBzdG9yZTogYm9sdGRiCnNlcnZlcjoKICBodHRwX2xpc3Rlbl9wb3J0OiAzMTAwCnN0b3JhZ2VfY29uZmlnOgogIGJvbHRkYjoKICAgIGRpcmVjdG9yeTogL2RhdGEvbG9raS9pbmRleAogIGZpbGVzeXN0ZW06CiAgICBkaXJlY3Rvcnk6IC9kYXRhL2xva2kvY2h1bmtzCnRhYmxlX21hbmFnZXI6CiAgcmV0ZW50aW9uX2RlbGV0ZXNfZW5hYmxlZDogZmFsc2UKICByZXRlbnRpb25fcGVyaW9kOiAwCg==
---
# Source: loki-stack/charts/promtail/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-promtail
  namespace: openebs
  labels:
    app: promtail
    chart: promtail-0.12.0
    release: loki
    heritage: Tiller
data:
  promtail.yaml: |
    client:
      backoff_config:
        maxbackoff: 5s
        maxretries: 5
        minbackoff: 100ms
      batchsize: 102400
      batchwait: 1s
      external_labels: {}
      timeout: 10s
    positions:
      filename: /run/promtail/positions.yaml
    server:
      http_listen_port: 3101
    target_config:
      sync_period: 10s
    
    scrape_configs:
    - job_name: kubernetes-pods-name
      pipeline_stages:
        - docker: {}
        
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels:
        - __meta_kubernetes_pod_label_name
        target_label: __service__
      - source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: __host__
      - action: drop
        regex: ^$
        source_labels:
        - __service__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - __meta_kubernetes_namespace
        - __service__
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: instance
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container_name
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_uid
        - __meta_kubernetes_pod_container_name
        target_label: __path__
    - job_name: kubernetes-pods-app
      pipeline_stages:
        - docker: {}
        
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: drop
        regex: .+
        source_labels:
        - __meta_kubernetes_pod_label_name
      - source_labels:
        - __meta_kubernetes_pod_label_app
        target_label: __service__
      - source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: __host__
      - action: drop
        regex: ^$
        source_labels:
        - __service__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - __meta_kubernetes_namespace
        - __service__
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: instance
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container_name
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_uid
        - __meta_kubernetes_pod_container_name
        target_label: __path__
    - job_name: kubernetes-pods-direct-controllers
      pipeline_stages:
        - docker: {}
        
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: drop
        regex: .+
        separator: ''
        source_labels:
        - __meta_kubernetes_pod_label_name
        - __meta_kubernetes_pod_label_app
      - action: drop
        regex: ^([0-9a-z-.]+)(-[0-9a-f]{8,10})$
        source_labels:
        - __meta_kubernetes_pod_controller_name
      - source_labels:
        - __meta_kubernetes_pod_controller_name
        target_label: __service__
      - source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: __host__
      - action: drop
        regex: ^$
        source_labels:
        - __service__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - __meta_kubernetes_namespace
        - __service__
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: instance
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container_name
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_uid
        - __meta_kubernetes_pod_container_name
        target_label: __path__
    - job_name: kubernetes-pods-indirect-controller
      pipeline_stages:
        - docker: {}
        
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: drop
        regex: .+
        separator: ''
        source_labels:
        - __meta_kubernetes_pod_label_name
        - __meta_kubernetes_pod_label_app
      - action: keep
        regex: ^([0-9a-z-.]+)(-[0-9a-f]{8,10})$
        source_labels:
        - __meta_kubernetes_pod_controller_name
      - action: replace
        regex: ^([0-9a-z-.]+)(-[0-9a-f]{8,10})$
        source_labels:
        - __meta_kubernetes_pod_controller_name
        target_label: __service__
      - source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: __host__
      - action: drop
        regex: ^$
        source_labels:
        - __service__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - __meta_kubernetes_namespace
        - __service__
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: instance
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container_name
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_uid
        - __meta_kubernetes_pod_container_name
        target_label: __path__
    - job_name: kubernetes-pods-static
      pipeline_stages:
        - docker: {}
        
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: drop
        regex: ^$
        source_labels:
        - __meta_kubernetes_pod_annotation_kubernetes_io_config_mirror
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_label_component
        target_label: __service__
      - source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: __host__
      - action: drop
        regex: ^$
        source_labels:
        - __service__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - __meta_kubernetes_namespace
        - __service__
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: instance
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container_name
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_annotation_kubernetes_io_config_mirror
        - __meta_kubernetes_pod_container_name
        target_label: __path__
---
# Source: loki-stack/templates/tests/loki-test-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-loki-stack-test
  labels:
    app: loki-stack
    chart: loki-stack-0.16.0
    release: loki
    heritage: Tiller
data:
  test.sh: |
    #!/usr/bin/env bash

    LOKI_URI="http://${LOKI_SERVICE}:${LOKI_PORT}"

    function setup() {
      apk add -u curl jq
      until (curl -s ${LOKI_URI}/api/prom/label/app/values | jq -e '.values[] | select(. == "loki")'); do
        sleep 1
      done
    }

    @test "Has labels" {
      curl -s ${LOKI_URI}/api/prom/label | \
      jq -e '.values[] | select(. == "app")'
    }

    @test "Query log entry" {
      curl -sG ${LOKI_URI}/api/prom/query?limit=10 --data-urlencode 'query={app="loki"}' | \
      jq -e '.streams[].entries | length >= 1'
    }

    @test "Push log entry" {
      local timestamp=$(date -Iseconds -u | sed 's/UTC/.000000000+00:00/')
      local data=$(jq -n --arg timestamp "${timestamp}" '{"streams": [{"labels": "{app=\"loki-test\"}", "entries": [{"ts": $timestamp, "line": "foobar"}]}]}')

      curl -s -X POST -H "Content-Type: application/json" ${LOKI_URI}/api/prom/push -d "${data}"

      curl -sG ${LOKI_URI}/api/prom/query?limit=1 --data-urlencode 'query={app="loki-test"}' | \
      jq -e '.streams[].entries[].line == "foobar"'
    }
---
# Source: loki-stack/charts/loki/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: loki
    chart: loki-0.14.0
    heritage: Tiller
    release: loki
  name: loki
  namespace: openebs
---
# Source: loki-stack/charts/promtail/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: promtail
    chart: promtail-0.12.0
    heritage: Tiller
    release: loki
  name: loki-promtail
  namespace: openebs
---
# Source: loki-stack/charts/promtail/templates/clusterrole.yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    app: promtail
    chart: promtail-0.12.0
    release: loki
    heritage: Tiller
  name: loki-promtail-clusterrole
  namespace: openebs
rules:
- apiGroups: [""] # "" indicates the core API group
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "watch", "list"]
---
# Source: loki-stack/charts/promtail/templates/clusterrolebinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: loki-promtail-clusterrolebinding
  labels:
    app: promtail
    chart: promtail-0.12.0
    release: loki
    heritage: Tiller
subjects:
  - kind: ServiceAccount
    name: loki-promtail
    namespace: openebs
roleRef:
  kind: ClusterRole
  name: loki-promtail-clusterrole
  apiGroup: rbac.authorization.k8s.io
---
# Source: loki-stack/charts/loki/templates/role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: loki
  namespace: openebs
  labels:
    app: loki
    chart: loki-0.14.0
    heritage: Tiller
    release: loki
rules:
- apiGroups:      ['extensions']
  resources:      ['podsecuritypolicies']
  verbs:          ['use']
  resourceNames:  [loki]
---
# Source: loki-stack/charts/promtail/templates/role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: loki-promtail
  namespace: openebs
  labels:
    app: promtail
    chart: promtail-0.12.0
    heritage: Tiller
    release: loki
rules:
- apiGroups:      ['extensions']
  resources:      ['podsecuritypolicies']
  verbs:          ['use']
  resourceNames:  [loki-promtail]
---
# Source: loki-stack/charts/loki/templates/rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: loki
  namespace: openebs
  labels:
    app: loki
    chart: loki-0.14.0
    heritage: Tiller
    release: loki
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: loki
subjects:
- kind: ServiceAccount
  name: loki
---
# Source: loki-stack/charts/promtail/templates/rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: loki-promtail
  namespace: openebs
  labels:
    app: promtail
    chart: promtail-0.12.0
    heritage: Tiller
    release: loki
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: loki-promtail
subjects:
- kind: ServiceAccount
  name: loki-promtail
---
# Source: loki-stack/charts/loki/templates/service-headless.yaml
apiVersion: v1
kind: Service
metadata:
  name: loki-headless
  namespace: openebs
  labels:
    app: loki
    chart: loki-0.14.0
    release: loki
    heritage: Tiller
spec:
  clusterIP: None
  ports:
    - port: 3100
      protocol: TCP
      name: http-metrics
      targetPort: http-metrics
  selector:
    app: loki
    release: loki
---
# Source: loki-stack/charts/loki/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: loki
  namespace: openebs
  labels:
    app: loki
    chart: loki-0.14.0
    release: loki
    heritage: Tiller
  annotations:
    {}
    
spec:
  type: ClusterIP
  ports:
    - port: 3100
      protocol: TCP
      name: http-metrics
      targetPort: http-metrics
  selector:
    app: loki
    release: loki
---
# Source: loki-stack/charts/promtail/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: loki-promtail
  namespace: openebs
  labels:
    app: promtail
    chart: promtail-0.12.0
    release: loki
    heritage: Tiller
  annotations:
    {}
    
spec:
  selector:
    matchLabels:
      app: promtail
      release: loki
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: promtail
        release: loki          
      annotations:
        checksum/config: d63942530bd9af428b5110aab9356055b1f53b133ecf32972a5d3ccb561b2df9
        prometheus.io/port: http-metrics
        prometheus.io/scrape: "true"
        
    spec:
      serviceAccountName: loki-promtail
      containers:
        - name: promtail
          image: "grafana/promtail:v0.3.0"
          imagePullPolicy: IfNotPresent
          args:
            - "-config.file=/etc/promtail/promtail.yaml"
            - "-client.url=http://loki:3100/api/prom/push"
          volumeMounts:
            - name: config
              mountPath: /etc/promtail
            - name: run
              mountPath: /run/promtail
            - mountPath: /var/lib/docker/containers
              name: docker
              readOnly: true
            - mountPath: /var/log/pods
              name: pods
              readOnly: true
            
          env:
          - name: HOSTNAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          ports:
            - containerPort: 3101
              name: http-metrics
          securityContext:
            readOnlyRootFilesystem: true
            runAsGroup: 0
            runAsUser: 0
            
          readinessProbe:
            failureThreshold: 5
            httpGet:
              path: /ready
              port: http-metrics
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
            
          resources:
            {}
            
      nodeSelector:
        {}
        
      affinity:
        {}
        
      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
        
      volumes:
        - name: config
          configMap:
            name: loki-promtail
        - name: run
          hostPath:
            path: /run/promtail
        - hostPath:
            path: /var/lib/docker/containers
          name: docker
        - hostPath:
            path: /var/log/pods
          name: pods
---
# Source: loki-stack/charts/loki/templates/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: loki
  namespace: openebs
  labels:
    app: loki
    chart: loki-0.14.0
    release: loki
    heritage: Tiller
  annotations:
    {}
    
spec:
  podManagementPolicy: OrderedReady
  replicas: 1
  selector:
    matchLabels:
      app: loki
      release: loki
  serviceName: loki-headless
  updateStrategy:
    type: RollingUpdate
    
  template:
    metadata:
      labels:
        app: loki
        name: loki
        release: loki
      annotations:
        checksum/config: 79e481cd6dd118d637642a93d50ce8ad63f19edcb04a47e06485cfc544ff7105
        prometheus.io/port: http-metrics
        prometheus.io/scrape: "true"
        
    spec:
      serviceAccountName: loki
      securityContext:
        fsGroup: 10001
        runAsGroup: 10001
        runAsNonRoot: true
        runAsUser: 10001
        
      containers:
        - name: loki
          image: "grafana/loki:v0.3.0"
          imagePullPolicy: IfNotPresent
          args:
            - "-config.file=/etc/loki/loki.yaml"
          volumeMounts:
            - name: config
              mountPath: /etc/loki
            - name: storage
              mountPath: "/data"
              subPath: 
          ports:
            - name: http-metrics
              containerPort: 3100
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /ready
              port: http-metrics
            initialDelaySeconds: 45
            
          readinessProbe:
            httpGet:
              path: /ready
              port: http-metrics
            initialDelaySeconds: 45
            
          resources:
            {}
            
          securityContext:
            readOnlyRootFilesystem: true
          env:
      nodeSelector:
        {}
        
      affinity:
        {}
        
      tolerations:
        []
        
      terminationGracePeriodSeconds: 30
      volumes:
        - name: config
          secret:
            secretName: loki
        - name: storage
          emptyDir: {}
```
