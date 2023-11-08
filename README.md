# Wind Turbine GitOps repo

The main file here is the `wind-turbine-app.yaml` - file which contains an Application using 
- the `helm` chart folder for templates and 
- the `config/config.js` files for parameters.

For easy install there is a shell script which does all kinds of installations that are needed.

## Installation

1. fork this repo
2. `0-github-secret-tmpl.yaml`: fill credentials for github from user settings -> Developer settings -> Personal access tokens -> Fine-grained tokens
3. `0-quay-secret-tmpl.yaml`: fill credentials for quay from Robot Accounts -> Create Robot Account -> Kubernetes Secret

## Webhooks

1. Get routes from your stage and dev deployments
2. Create json webhooks in your GitHub application project forks to push to your Event Listener Routes
3. Profit

## Used stuff

This application uses multiple tools which are installed via script on a clean environment. The tools are installed via operator or helm charts. Here's the list:
- operators:
  - AMQ Streams
  - OpenShift Pipelines
  - OpenShift GitOps
- helm packages:
  - Reloader
  - Sealed Secrets

The applications can be installed manually via helm install as well. Change the values file according to your needs and install.

## Bugfixing:

#### PVC stuck - delete pvc

The pvcs are configured to be not deleted at helm uninstall. You should always delete them manually.

If some pvc gets stuck you can fix this via
```sh
oc patch pvc <pvc-name> -p '{"metadata":{"finalizers": []}}' --type=merge
```
