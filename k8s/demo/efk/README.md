Apply the specs in the efk folder.
Make sure you have applied the Storage classes for OpenEBS.

`kubectl apply -f openebs-sc.yaml`

This EFK podspec uses Elasticsearch, Fluentd and Kibana to enable you to perform k8s cluster level logging. 
The fluentd pods act as collectors, Elasticsearch as the document database and kibana as the dashboard for log visualization. 

The current podspec for Elasticsearch creates
    1) 3 master pods responsible for cluster management.
    2) 3 data pods for storing log data.
    3) 2 client pods for external access.

The current Fluentd podspec reads journal logs for `kubelet` and cluster level logging by reading from `/var/log/containers` for pods running on the kubernetes cluster. 

#### Note: Make sure you install Elasticsearch while executing this usecase. Fluentd and Kibana require the publicly accessible Elastic search endpoint. 

## Verify Elastic search installation

```
curl 'http://10.105.105.41:9200'
{
  "name" : "es-client-2155074821-nxdkt",
  "cluster_name" : "escluster",
  "cluster_uuid" : "zAYA9ERGQgCEclvYHCsOsA",
  "version" : {
    "number" : "5.5.0",
    "build_hash" : "260387d",
    "build_date" : "2017-06-30T23:16:05.735Z",
    "build_snapshot" : false,
    "lucene_version" : "6.6.0"
  },
  "tagline" : "You Know, for Search"
}

curl 'http://10.105.105.41:9200/_cat/nodes?v'
ip        heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
10.44.0.2           41          41   0    0.00    0.03     0.08 m         -      es-master-2996564765-4c56v
10.36.0.1           43          18   0    0.07    0.05     0.05 i         -      es-client-2155074821-v0w31
10.40.0.2           49          15   0    0.05    0.07     0.11 m         *      es-master-2996564765-zj0gc
10.47.0.3           43          20   0    0.13    0.11     0.13 i         -      es-client-2155074821-nxdkt
10.47.0.4           42          20   0    0.13    0.11     0.13 d         -      elasticsearch-data-2
10.47.0.2           39          20   0    0.13    0.11     0.13 m         -      es-master-2996564765-rql6m
10.42.0.2           41          13   0    0.00    0.04     0.10 d         -      elasticsearch-data-1
10.40.0.3           42          15   0    0.05    0.07     0.11 d         -      elasticsearch-data-0

curl -XPUT 'http://10.105.105.41:9200/customer?pretty&pretty'
{
  "acknowledged" : true,
  "shards_acknowledged" : true
}

curl -XGET 'http://10.105.105.41:9200/_cat/indices?v&pretty'
health status index    uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   customer -Cort549Sn6q4gmbwicOMA   5   1          0            0      1.5kb           810b

curl -XPUT 'http://10.105.105.41:9200/customer/external/1?pretty&pretty' -H 'Content-Type: application/json' -d'
{
"name": "Daenerys Targaryen"
}
'
{
  "_index" : "customer",
  "_type" : "external",
  "_id" : "1",
  "_version" : 1,
  "result" : "created",
  "_shards" : {
    "total" : 2,
    "successful" : 2,
    "failed" : 0
  },
  "created" : true
}

curl 'http://10.105.105.41:9200/customer/external/1?pretty&pretty'
{
  "_index" : "customer",
  "_type" : "external",
  "_id" : "1",
  "_version" : 1,
  "found" : true,
  "_source" : {
    "name" : "Daenerys Targaryen"
  }
}
```
