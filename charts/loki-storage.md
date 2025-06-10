# Loki Storage Options Documentation

## Introduction

Loki provides flexible storage options depending on your deployment needs. Below is a summary of how to configure and choose the appropriate storage based on your specific deployment scenario, including filesystem volumes, object storage, and external S3-compatible solutions.

---

### 1. **Single Replica Deployment (Filesystem Volume)**

When deploying **Loki as a single replica**, you can use a **filesystem volume** for storage. This is a simple and cost-effective option for single-instance setups where high availability and scalability are not required.

- **Recommended for**: Small-scale deployments or testing environments where high availability (HA) is not a concern.

Below is an example to use a filesystem volume with single replica loki.

```yaml
  loki:
    enabled: true

    loki:
      schemaConfig:
        configs:
          - from: 2024-04-01
            store: tsdb
            object_store: filesystem
            schema: v13
            index:
              prefix: loki_index_
              period: 24h
      commonConfig:
        replication_factor: 1
      storage:
        type: filesystem

    singleBinary:
      replicas: 1
      drivesPerNode: 1
      persistence:
        enabled: true

    minio:
      enabled: false
```

---

### 2. **High Availability (HA) Deployment (Object Storage)**

For **HA (High Availability)** deployments, **object storage** is **mandatory**. This ensures that your logs are replicated and highly available across multiple nodes, reducing the risk of data loss and providing fault tolerance.

- **Recommended for**: Production environments with multiple Loki instances, where high availability and horizontal scaling are required.

By default with openebs loki is deployed in this mode, i.e with multiple replicas and with a minio distributed object storage.

---

### 3. **MinIO as the Default Object Storage**

By default, **MinIO** is used as the object storage backend for Loki. MinIO can run in both **single replica** and **HA (High Availability)** modes. However, if you are deploying Loki in an HA configuration, it is **recommended to use MinIO in HA mode** along with HA Loki for optimal performance and scalability.

- **MinIO in HA mode** is suitable for high availability, fault tolerance, and ensuring your data remains consistent across multiple Loki replicas.

---

### 4. **Migrating from Filesystem Volume to Object Storage**

If you start with **Loki as a single replica** using a filesystem volume and later decide to scale up to an HA deployment, **it is crucial to start with object storage from the beginning**. Migrating from a filesystem volume to object storage after the initial setup is **not easily possible** and could involve complex data migration steps.

- **Recommendation**: Start with object storage (such as MinIO or another S3-compatible solution) if you plan to scale your deployment in the future.

---

### 5. **Using External S3-Compatible Storage**

If you prefer not to use **MinIO** as the object storage solution for Loki, you can configure an **external S3-compatible** storage backend. You can use any S3-compatible service, such as AWS S3, Google Cloud Storage, or other object storage services that support the S3 API.

To configure Loki to use an external S3 bucket, update your Loki configuration as follows:

```yaml
# Configure these if you don't want to use MinIO and rather an external S3 bucket.
loki:
  loki:
    storage:
    type: s3
    bucketNames:
        chunks: <mybucket>  # Define your S3 bucket name for chunks storage
    s3:
        s3: s3://<my access id>:<my secret key>@<my endpoint>/<mybucket>  # S3 URL with credentials and endpoint
        endpoint: <my endpoint>  # Endpoint for your external S3-compatible service
        region: <my region>  # Region of your S3 bucket
        secretAccessKey: <my secret key>  # Access key for your S3-compatible service
        accessKeyId: <my access id>  # Secret key for your S3-compatible service
    object_store:
        type: s3
        s3:
        endpoint: s3://<my access id>:<my secret key>@<my endpoint>/<mybucket>  # S3 URL with credentials and endpoint
        region: <my region>  # Region of your external S3-compatible storage
        access_key_id: <my access id>  # Your S3 access key ID
        secret_access_key: <my secret key>  # Your S3 secret access key
```