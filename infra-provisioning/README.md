# A series of demos showcasing OSS, DevOps and Container on Azure 

This section assumes the following 2 things: 

* You already have a concourse instance running. Please look at the home page of this repo on how to setup one.
This pipeline has 2 sections:
* You have an Azure subscription with a Service Principal already created. If you havent created a Service principal yet, please refer to the home page of this repo.



* Environment setup pipeline


![Boostrap](/docs/Utility1.PNG "Boostrap")

A second pipeline existe as well to unprovision the envionment.

![Unprovision](/docs/Utility2.PNG "Unprovision")

More details on the environment provision/unprovision HERE

## Getting started

git clone https://github.com/schabiyo/azure-oss-demos.git
cd azure-oss-demos

Open http://192.168.100.5:8080/ in your browser:


Deploy the infra Pipeline
----------------
You need 2 things before you can deploy the infra pipeline

* Modify the infra-provisioning/deloy-pipeline.sh file to reflect your concourse alias previously created (argument no 2)
* Modify the infra-provisioning/credentials.yml with your own information. The content is self explanatory.

```
cd infra-provisioning
./deploy-pipeline.sh

```

If you found this guide lacking please submit an issue or PR through github. We appreciate your feedback.

