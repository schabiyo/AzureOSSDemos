# A series of demos showcasing OSS, DevOps and Container on Azure 

Concourse is used as Pipeline to automate the deployment of the demos. If you are not familir with Concourse (http://concourse.ci), do not worry, the actual demo scripts
has little dependency with concource and can be ran using your favorite CICD pipeline tool. Some parts of these demos are based on the Skylab project by Microsoft that can be found here:
https://blogs.technet.microsoft.com/msuspartner/2017/04/13/open-source-partners-open-source-demos-microsoft-azure/

My pipelines are hosted here if you want to take look: http://ci.syolab.io/

Follow the instruction on that page for a manual deployment.


## Table of contents

* [Environment provisioning/unprovisioning pipeline](/infra-provisioning/)


![Boostrap](/docs/Utility1.PNG "Boostrap")

A second pipeline existe as well to unprovision the envionment.

![Unprovision](/docs/Utility2.PNG "Unprovision")

More details on the environment provision/unprovision HERE

* [DevOps pipeline](/devops/)



## Getting started

If you don/t already have a concourse instance, here are 2 options to get an instance up and running:

* Concourse ARM template on Azure

You can install Concourse on Azure with a on click deploy using the ARM template available here: https://azure.microsoft.com/en-us/resources/templates/concourse-ci/

* Local concourse with Vagrant

You also havethe option to use Vagrant to install Concourse localy if you wish to. follow the instruction below for that:

- **Install Vagrant/Virtual Box**


- **Start a local concourse server** 
Fetch this tutorial and start a local Concourse server:

```
vagrant box add concourse/lite --box-version $(cat VERSION)
vagrant up
```

Open http://192.168.100.5:8080/ in your browser:


Setup Concourse
----------------

In the spirit of declaring absolutely everything you do to get absolutely the same result every time, the `fly` CLI requires that you specify the target API for every `fly` request.

First, alias it with a name `ossdemos` (you can pick whatener name yopu want):

```
fly --target ossdemos login -c http://192.168.100.5:8080
fly --target ossdemos sync

```

Create a Service Principal
----------------

The pipepline requires what we call in the Azure world a Service Principalee to operate. It is basically an acccount under which the resource will be created in Azure. The service principal contains the following credentials which will need to be added to the credentials.yml file.

- **TENANT_ID**
- **CLIENT_ID**
- **CLIENT_SECRET** 

More information on service principal can be found [here](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2fazure%2fazure-resource-manager%2ftoc.json).

If you don't already have a SP, you can use the following script to create one. The script used the lastest Azure CLI 2.0.
After running the script yo will get an output similar to the following:

  Sample output:
  ```
  ==============Created Serivce Principal==============
  SUBSCRIPTION_ID: 12345678-1234-5678-1234-678912345678
  TENANT_ID:       11111111-1234-5678-1234-678912345678
  CLIEND_ID:       87654321-1234-5678-1234-678912345678
  CLIENT_SECRET:   RANDOM-STRING
  ``` 
All you have to do now if store those in the credentials.yml file under the corresponding key names.

Generate an SSH Key private and publicc keys
----------------

If you have a Linux based system, please continue with the commands below, otherwise you can simply install Bash for Windows if you are under Windows.

```
ssh-keygen -f ossdemo -t rsa -P ''
```
The above command with generate a private and public key files that you will need to add to the credentials.yml file

TODO
----------------

* Complete SP generation script
* Azure Key Vault integration
* Terraform as the IaaS provisioning tool
* Any suggestion?



If you found this guide lacking please submit an issue or PR through github. We appreciate your feedback.

