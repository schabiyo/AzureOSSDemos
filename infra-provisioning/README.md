# Infrastructure provisioning/un-provisiomning pipelines

This section assumes the following: 

* You already have a concourse instance running. Please look at the home page of this repo on how to setup one.
This pipeline has 2 sections:
* You have an Azure subscription with a Service Principal already created. If you havent created a Service principal yet, please refer to the home page of this repo.

* Environment setup pipeline

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


A second pipeline existe as well to unprovision the envionment.

![Unprovision](/docs/Utility2.PNG "Unprovision")

If you found this guide lacking please submit an issue or PR through github. We appreciate your feedback.

