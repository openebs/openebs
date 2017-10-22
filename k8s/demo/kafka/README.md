Apply the k8s podspecs mentioned in the folder.

`kubectl apply -f .`

This will create a 3 node zookeeper ensemble and a 3 node Kafka cluster which uses OpenEBS volumes.

## Verify Zookeeper
Verify the Zookeeper ensemle.  

```
kubectl exec zk-0 -- /opt/zookeeper/bin/zkCli.sh create /foo bar

WATCHER::
WatchedEvent state:SyncConnected type:None path:null
Created /foo

kubectl exec zk-2 -- /opt/zookeeper/bin/zkCli.sh get /foo

WATCHER::
WatchedEvent state:SyncConnected type:None path:null
cZxid = 0x10000004d
bar
ctime = Tue Aug 08 14:18:11 UTC 2017
mZxid = 0x10000004d
mtime = Tue Aug 08 14:18:11 UTC 2017
pZxid = 0x10000004d
cversion = 0
dataVersion = 0
aclVersion = 0
ephemeralOwner = 0x0
dataLength = 3
numChildren = 0
```

## Verify Kafka pods.

Verify kafka cluster running on your kubernetes cluster by sending messages to it

```
kubectl exec -n kafka -it kafka-0 -- bash 

bin/kafka-topics.sh --zookeeper zk-headless.kafka.svc.cluster.local:2181 --create --if-not-exists --topic openEBS.t --partitions 3 --replication-factor 3

Created topic "openEBS.t".

bin/kafka-topics.sh --list --zookeeper zk-headless.kafka.svc.cluster.local:2181
openEBS.t

bin/kafka-topics.sh --describe --zookeeper zk-headless.kafka.svc.cluster.local:2181 --topic openEBS.t

Topic:openEBS.t    PartitionCount:3        ReplicationFactor:3     Configs:
Topic: openEBS.t   Partition: 0    Leader: 0       Replicas: 0,1,2 Isr: 0,1,2
Topic: openEBS.t   Partition: 1    Leader: 1       Replicas: 1,2,0 Isr: 1,2,0
Topic: openEBS.t   Partition: 2    Leader: 2       Replicas: 2,0,1 Isr: 2,0,1

bin/kafka-console-producer.sh --broker-list kafka-0.broker.kafka.svc.cluster.local:9092,kafka-1.broker.kafka.svc.cluster.local:9092,kafka-2.broker.kafka.svc.cluster.local:9092 --topic px-kafka-topic

>Hello Kubernetes!
>This is kafka saying Hello!
```

Consume messages sent earlier. 
```
kubectl exec -n kafka -it kafka-1 -- bash 

bin/kafka-console-consumer.sh --zookeeper zk-headless.kafka.svc.cluster.local:2181 —topic px-kafka-topic --from-beginning

Hello Kubernetes!
This is kafka saying Hello!
```