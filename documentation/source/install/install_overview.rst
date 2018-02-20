.. _Setup:

*******
Setup
*******

Setting Up OpenEBS - Overview
================================

OpenEBS can run on various platforms: from your laptop, to VMs on a cloud provider. OpenEBS is also aimed at providing the option of using hybrid deployments where data is distributed between cloud and on-premise environments.

If you are beginner to Kubernetes and OpenEBS, OpenEBS recommends you to get started by setting up Kubernetes. The Kubernetes documentation provides you various Kubernetes installation options to choose from. See `Setup. <https://kubernetes.io/docs/setup/>`_
  
If you are already an experienced Kubernetes user and if you have Kubernetes installed you can deploy OpenEBS through either of the following:

* kubectl - you can easily setup OpenEBS on your existing Kubernetes cluster with a few simple kubectl commands. See `quick-start. <http://openebs.readthedocs.io/en/latest/intro/quick_install.html>`_
* helm


.. * running an OpenEBS cluster on your laptop using Vagrant OR 
.. * if you have access to the Cloud, you can use our custom solutions for Google and Amazon Cloud providers. 


The following flowchart helps you visualize how you can get started with OpenEBS.

.. image:: ../_static/gettingstarted.png

We are looking for help from the community in including additional platforms where OpenEBS has been successfully deployed. Please share your story through GitHub `Issues <https://github.com/openebs/openebs/issues>`_ or `Pull requests <https://github.com/openebs/openebs/pulls>`_.
