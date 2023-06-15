#!/bin/bash

PIPELINES_INSTALLED=$(oc get csv -n openshift-operators | grep openshift-pipelines)
GITOPS_INSTALLED=$(oc get csv -n openshift-operators | grep openshift-gitops)
STREAMS_INSTALLED=$(oc get csv -n openshift-operators | grep amqstreams)
INFINISPAN_INSTALLED=$(helm list | grep infinispan)

# --- OpenShift Pipelines -----------------------------------------------------

if [[ $PIPELINES_INSTALLED == *"Succeeded"* ]]; then
  echo "OpenShift Pipelines \tis installed!"
else
  echo "OpenShift Pipelines \tis not installed."
  echo "Installing openshift pipelines..."

  read -r -d '' YAML_CONTENT <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/openshift-pipelines-operator-rh.openshift-operators: ""
  name: openshift-pipelines-operator-rh
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

  # Apply the inline YAML using 'oc apply'
  echo "$YAML_CONTENT" | oc apply -f -
  
  $(oc wait --for=condition=initialized --timeout=60s pods -l app=openshift-pipelines-operator -n openshift-operators)
fi

# --- OpenShift GitOps --------------------------------------------------------

if [[ $GITOPS_INSTALLED == *"Succeeded"* ]]; then
  echo "OpenShift GitOps \tis installed!"
else
  echo "OpenShift GitOps \tis not installed."
  echo "Installing OpenShift GitOps..."

  read -r -d '' YAML_CONTENT <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/openshift-gitops-operator.openshift-operators: ""
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: openshift-gitops-operator.v1.8.3
EOF

  # Apply the inline YAML using 'oc apply'
  echo "$YAML_CONTENT" | oc apply -f -
  
  $(oc wait --for=condition=initialized --timeout=60s pods -l app.kubernetes.io/name=openshift-gitops-server -n openshift-gitops)
  $(oc adm policy add-cluster-role-to-user cluster-admin -z openshift-gitops-argocd-application-controller -n openshift-gitops)
fi

# --- OpenShift Streams -------------------------------------------------------

if [[ $STREAMS_INSTALLED == *"Succeeded"* ]]; then
  echo "OpenShift Streams \tis installed!"
else
  echo "OpenShift streams \tis not installed."
  echo "Installing OpenShift streams..."

  read -r -d '' YAML_CONTENT <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/amq-streams.openshift-operators: ""
  name: amq-streams
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: amq-streams
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: amqstreams.v2.4.0-0
EOF
  echo "$YAML_CONTENT" | oc apply -f -
  $(oc wait --for=condition=initialized --timeout=60s pods -l name=amq-streams-cluster-operator -n openshift-operators)
fi

# --- Infinispan --------------------------------------------------------------
if [[ $INFINISPAN_INSTALLED == *"deployed"* ]]; then
  echo "Infinispan \t\tis installed!"
else
  echo "Infinispan \t\tis not installed."
  echo "Installing Infinispan..."
  $(helm repo add openshift-helm-charts https://charts.openshift.io/)

  $(helm install infinispan openshift-helm-charts/infinispan-infinispan)

  $(oc wait --for=condition=initialized --timeout=60s pods -l app=infinispan-pod)
fi

