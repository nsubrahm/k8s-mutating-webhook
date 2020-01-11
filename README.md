# Introduction

This branch demonstrates a simple example of a Kubernetes mutating webhook implemented with NodeJS. This branch accompanies the Medium articles:

1. [Kubernetes Mutating Webhook in NodeJS - Part I - Introduction](https://medium.com/@nageshblore/kubernetes-mutating-webhook-with-nodejs-part-i-introduction-ee33b2668af4).
2. [Kubernetes Mutating Webhook with NodeJS— Part II — Development](https://medium.com/@nageshblore/kubernetes-mutating-webhook-part-ii-development-bec5033c591d).

- [Introduction](#introduction)
  - [Quick start](#quick-start)
    - [Clone repository](#clone-repository)
    - [Launch kind](#launch-kind)
    - [Set-up certificate manager](#set-up-certificate-manager)
    - [Generate new certificate](#generate-new-certificate)
    - [Install helm chart](#install-helm-chart)
    - [Start a test pod](#start-a-test-pod)
    - [Testing the deployment](#testing-the-deployment)
  - [How does it work](#how-does-it-work)

## Quick start

Start with cloning the GitHub repository and change into cloned directory.

### Clone repository

```bash
git clone --branch helm https://github.com/nsubrahm/k8s-mutating-webhook.git
cd k8s-mutating-webhook
```

### Launch `kind`

The APIs that need to be enabled in `kind` will be passed via a configuration file. The `kubectl` context needs to be configured to use `kind` cluster. These steps are executed with commands as shown below.

```bash
cd yaml
kind create cluster --config kind.yaml
kubectl config use-context kind-kind
```

### Set-up certificate manager

If the Kubernetes installation has `cert-manager` already installed, then generate a new certificate as described in [next section](#generate-new-certificate).

To install certificate manager, set-up and `Issuer` as a self-signed CA and generate a certificate, use the command below.

```bash
cd ..
scripts/prereqs.sh webhook sidecars
```

With the certificate in place, the webhook can be installed with `helm` as described in the [Install `helm` chart](#install-helm-chart) section.

### Generate new certificate

Edit the YAML below such that `WEBHOOK_APP` is replaced with webhook application name (e.g. `webhook`) and `K8S_NAMESPACE` is replaced with a namespace value (e.g. `sidecars`). Save the YAML as `certificate.yaml`.

```yaml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: WEBHOOK_APP-cert
  namespace: K8S_NAMESPACE
spec:
  organization:
    - WEBHOOK_APP.K8S_NAMESPACE.com
  commonName: WEBHOOK_APP.K8S_NAMESPACE.svc
  dnsNames:
    - WEBHOOK_APP
    - WEBHOOK_APP.K8S_NAMESPACE
    - WEBHOOK_APP.K8S_NAMESPACE.svc
    - WEBHOOK_APP.K8S_NAMESPACE.svc.cluster.local
  usages:
    - server auth
  secretName: WEBHOOK_APP-cert-tls-secret
  issuerRef:
    name: WEBHOOK_APP-ca-issuer
```

Then, create the certificate with the following command.

```bash
kubectl create -f certificate.yaml
```

With the certificate in place, the webhook can be installed with `helm` as described in the following section.

### Install `helm` chart

The `MutatingWebhookConfiguration` requires `caBundle` to be configured with a string that is PEM encoded CA bundle. This string can be obtained with `kubectl get secret/secretName -n namesapce -o jsonpath='{ .data.ca\.crt }'`. Since, `helm` charts do not have an option to pass on output of [arbitrary commands in templates](https://github.com/helm/helm/issues/5145#issuecomment-453646897), the `caBundle` will have to be passed as a string from command line as shown below.

```bash
helm install webhook ./webhook --set \
webhookApp=webhook, \
caBundle=$(kubectl get secret/webhook-cert-tls-secret -n sidecars -o jsonpath='{ .data.ca\.crt }')
-n sidecars
```

Note that, the name of secret in `kubectl` command is same as `spec.secretName` in `certificate.yaml` as described in previous section. Also, the namespace is same as set when creating certificate.

### Start a test pod

Once the webhook server is deployed, you may have to wait a couple of seconds for it to come up. The status can be checked by running `kubectl get po/webhook -n sidecars`. The webhook server is ready to accept requests if the status is seen as `Running`. To start a test pod, run the command below.

```bash
cd yaml
kubectl create -f test.yaml -n sidecars
```

### Testing the deployment

The `test.yaml` is written to start a pod named `demo` having a container with the image as `tutum/curl`. The webhook server will 'mutate' this YAML such that the image name is now set to `debian`. Thus, once the pod is deployed, it can be examined for the images running in the container using the command below. It will return the image name as `debian` as defined in the mutating webhook.

```bash
kubectl get po/demo -n sidecars -o jsonpath='{.spec.containers[0].image}'
```

## How does it work

Here is a quick explanation of how the mutation happens. For details, see [Kubernetes Mutating Webhook with NodeJS— Part II — Development](https://medium.com/@nageshblore/kubernetes-mutating-webhook-part-ii-development-bec5033c591d).

1. Register a `MutatingWebhookConfiguration` as generated in `yaml/mutatingWebhookConfiguration.yaml`.
   1. The `webhooks` is an array of webhooks that need to be invoked.
   2. Only one webhook is defined where, the `clientConfig.service.name` points to a service that will mutate the request.
   3. This service is available at the `/mutate` end-point as defined in `clientConfig.service.path`.
2. Deploy the webhook application, that will mutate the request, as defined in the `webhook-deploy.yaml`.
   1. The webhook API is _always_ invoked over `https` and port `443` by default.
   2. The end-point should be configured with certificate and private key files. These files are generated in the `certs` directory and are used to create the `webhook-cert-tls-secret` object where, the string `webhook` is derived from the application name provided to the installation script.
3. When the request is submitted with `yaml/test.yaml`:
   1. `kube-apiserver` forwards this request to the registered webhook.
   2. The webhook forwards the request to the end-point and service as defined in `clientConfig.service.path` (`/mutate` in this example implementation) and `clientConfig.service.name` respectively.
   3. At the `/mutate` end-point, a response is generated where the image name in the request (i.e. `test.yaml`) is modified to hold the name `debian` - see [`mutate.js`](webhook/app/mutate.js) for details.
