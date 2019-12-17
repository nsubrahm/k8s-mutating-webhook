# Introduction

This project demonstrates the use of sidecar pattern when developing applications for OpenShift or Kubernetes in general. In the sidecar pattern, there is a main application that implements the core business function. Often, the main application is supported by a 'helper' application. This helper application is referred to as the sidecar because, it is deployed as a container, different from the container for the main application, in the _same_ pod.

- [Introduction](#introduction)
  - [Quick start](#quick-start)
    - [Pre-requisites](#pre-requisites)
    - [Steps](#steps)
  - [Description](#description)
    - [Main application](#main-application)
    - [Localization application](#localization-application)
    - [Deployment](#deployment)

## Quick start

### Pre-requisites

- Running instance of OpenShift
- `oc` CLI

### Steps

1. Clone this repository and run the following command after logging in to the OpenShift instance. While the first command creates the necessary objects for this demo, the second command will display the host to access the demo.

```bash
oc create -f pod/sidecar-demo.yaml
oc get route sidecar
```

2. To see the demo in action, use `curl` as shown in below.

```bash
curl https://<host>/demo/<lang>
```

where _<host>_ is derived from the route definition and _<lang>_ is one of `en`, `hi` or `kn`.

## Description

This project exposes a REST API endpoint at `/demo/<lang>` where _<lang>_ is one of `en`, `hi` or `kn`. The aim is to respond with message around the status of an imaginary database in a language of choice of the user. To do this, the main application simulates the enquiry of status of the imaginary database status. Whereas, the helper application would localize the status message.

### Main application

The main application is defined in `main-app` folder of this project. It can be built into a Docker image using the provided `Dockerfile`. This application listens at port `3000` and invokes the localization application for getting the localized message. For example, the main application will send a message code corresponding to the status of the database and a parameter for language code along with some parameters relevant to that particular message. Finally, this localized message is returned as a JSON document.

### Localization application

The localization application is defined in the `localize-app` folder of this project. It can be built into a Docker image using the provided `Dockerfile`. This application listens at port `3001` to apply the correct localization, with `node-localize` module, and responds back to the main application.  In response to the query from the main application, the message code with text as applicable for the required language is returned.

### Deployment

To deploy the project in the sidecar pattern, a single pod will be deployed with each application deployed as an individual container. Further, a service and a route object will be created to expose the main application over internet. The definition of these objects are available in `pod/sidecar-demo.yaml`.

Notes:

1. This project assumes that the sidecar is reachable as a REST end-point over `http`. It is definitely possible to communicate over other protocols e.g. `tcp`, etc.
2. The sidecar container is accessed by the main application as `localhost` since the containers are in the same pod.
