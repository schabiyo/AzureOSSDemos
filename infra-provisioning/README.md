# Infrastructure provisioning/un-provisiomning pipelines

The pipeline automatically provisions the following for you:

* A fully configured Jumpbox VM
* An OMS Workspace
* An Azure Container Registry
* 2 CentOS VMs fully configured with Docker
* One App Service Web Plan configured with 2 slots: DEV and STAGING
* A Kubernetes Cluster with 1 master and 2 nodes which are automatically registered with the previous OMS Workspace 

Under teh cover the following are happening:

* The Azure REST API is used to automatically provision an OMS Workspace
* Use of Ansible to configure Docker on the IaaS VMs
* OMS VM and COntainers monitoring agent is automatically installed on the iaas vms and well as k8s nodes


## Pre-Requisites

This section assumes the following: 

* You already have a concourse instance running. Please look at the home page of this repo on how to setup one.
* You have an Azure subscription with a Service Principal already created. If you havent created a Service principal yet, please refer to the home page of this repo.

## Getting started

* Clone the repository if it is not already done
```
git clone https://github.com/schabiyo/azure-oss-demos.git
cd azure-oss-demos
```
* Modify the infra-provisioning/deloy-pipeline.sh file to reflect your concourse alias previously created (argument no 2)
* Modify the infra-provisioning/credentials.yml with your own information. The content is self explanatory.



Deploy the infra Pipeline
----------------


```
cd infra-provisioning
./deploy-pipeline.sh

```
Open http://192.168.100.5:8080/ in your browser:

You should see something similar to the folowing in your browser:

![Boostrap](/docs/Utility1.PNG "Boostrap")


A second pipeline existe as well to unprovision the envionment. The intend here is to be able to tear down the environment with a single click. In my case I alwassy needed to remind myself to deallocate the resource, which can be painful. So if you are like me, then I'm happy to let you know that I have made used of the [Concourse Time resource](https://github.com/concourse/time-resource)  that tear down the environment everyday at midnight. You can decide to change it to what ever suit you, the documentation on the time resource is self-explanatory.

The current configuration of the "teardown-at-midnight" is as follow:

```yaml
resources:
- name: teardown-at-midnight
  type: time
  source:
    start: 12:00 AM
    stop: 1:00 AM
    location: Canada/Eastern
    days: [Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday]
```


![Unprovision](/docs/Utility2.PNG "Unprovision")

You might want to tear down only some of the provisioning resource, in that case just on the corresponding box and create a new build. In the other hand if you want to destroy the whole setup at once, juste run the "teardown-at-midnight" job, although is is a scheduled job you can still run it on demand.



If you found this guide lacking please submit an issue or PR through github. We appreciate your feedback.

