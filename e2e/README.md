# Overview

The primary objectives of the e2e tests are to ensure a consistent and reliable behavior of OpenEBS Storage for various persistent workloads, and to catch hard-to-test bugs before users do, when unit and integration tests are insufficient.

The e2e tests range from automating the initial setup and configuration to successfully deploying and running persistent workloads under various conditions/failure simulations. 

# Notes
- The workloads are simulated either using standard images like (percona, mysql, etc.,) or using custom images that are built under the project [openebs/test-storage](https://github.com/openebs/test-storage)
