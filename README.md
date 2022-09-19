# checkbox.ai take home test

## Overview

This repository contains two main directories, terraform and kustomize. The `terraform` directory
[houses](houses) infrastructure definitions (e.g. vpc, iam, secretsmanager) while the `kustomize` directory
houses Kubernetes related resources that is managed by ArgoCD.

## Architecture

![image](https://user-images.githubusercontent.com/19421765/190936458-2e34a229-b252-4637-acc0-e22f4316213e.png)

### Network

As a standard reference design, this network owns the 10.0.0.0/20 CIDR block with 4 subnet groups
defined, namely: `ingress`, `apps`, `databases` and `platform`. They each own 24 netmask length
that translates to 256 available IP addresses in each range.

### Compute

Compute resources are managed by AWS EKS. AWS EKS installation are done via the
`terraform-aws-eks-blueprints` module that defines the EKS cluster, managed node groups and cluster
add-ons configurations.

The cluster attaches three nodegroups: `apps`, `dbs`, and `platform` that are assigned to its
respective subnets for resource isolation.

The cluster additionally contains EKS and Kubernetes related add-ons via the
`terraform-aws-eks-blueprints//modules/kubernetes-addons` module that defines EKS plugins (e.g.
vpc_cni, coredns, kubeproxy) and Kubernetes plugins (e.g. argocd).

Following the ArgoCD `app of apps` pattern, two meta-application are defined, namely `platform` and
`apps`. `platform` aims to concern with platform related installations that are typically managed
by devops (`redis` installation for example) while `apps` aims to concern with stream-aligned
applications that are managed by developers

In this example, `argocd` installation is also customized to include `argocd-vault-plugin` to
retrieve sensitive credentials from `awssecretsmanager`.

## Kubernetes

`redis` installation in `platform` takes the `bitnami/redis` helm chart as the base installation to
customize from. Although there are no specific customization done aside for configuring the helm
chart for now, but this sets up for future overlays when needed.

`redis` is configured as a standard master-replica setup with `node-selection` selector and
`podAntiAffinityPreset: hard` to ensure that pods are spread across the `dbs` nodegroup and
failure-domains evenly for a high availability setup. `persistence` are also disabled for now as
`redis` are often treated as an in-memory storage where persistence are normally reserved to the
transaction database.

on the flipside, the `shopping-cart` installation in `apps` defines the standard stream-aligned
application deployment that defines the container image, listening port and environment variables
to be injected into the container. The development team may continue to follow the 12-factor app
principles and be able to consume the environment variables in their application.
