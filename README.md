# checkbox.ai take home test

## Overview

This repository contains two main directories, terraform and kustomize. The `terraform` directory
[houses](houses) infrastructure definitions (e.g. vpc, iam, secretsmanager) while the `kustomize` directory
houses Kubernetes related resources that is managed by ArgoCD.

## Architecture

![image](https://user-images.githubusercontent.com/19421765/190945404-d557a4be-ee39-40e1-99b3-dc2a12a7c777.png)

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
failure-domains evenly for a high availability setup. `persistence` are also disabled as `redis`
are often treated as an in-memory storage whereas persistence are normally reserved to the
transaction database. These are not the only considerations that should be made for production
deployment; With more visibility on the application workload requirements, other Redis deployment
(e.g. Redis Cluster) mode can be considered.

On the flipside, the `shopping-cart` installation in `apps` defines the standard stream-aligned
application deployment that defines the container image, listening port and environment variables
to be injected into the container. The development team may continue to follow the 12-factor app
principles and be able to consume the environment variables in their application.

## Installation

```sh
cd terraform
terraform plan && terraform apply
```

```sh
terraform output github_public_ssh_key -> add to github
```

```sh
aws eks update-kubeconfig --name app-cluster --region ap-southeast-1
kubectl port-forward svc/argo-cd-argocd-server 8080:80 -n argocd
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

```sh
visit http://localhost:8080/
login with username: admin, password: <value from above>
```

applications from repository should appear as:

![image](https://user-images.githubusercontent.com/19421765/190952394-b3fe3cca-6d04-4d6e-a759-f38f8a80c596.png)


## Validation

Connectivity to redis cluster can be validated via:

```sh
kubectl get pods -n app-shopping-cart
kubectl exec  -n app-shopping-cart -it <shopping-cart-pod>  -- bash
```

```sh
bash-5.1# echo $REDIS_HOST
db-redis-master.db-redis.svc.cluster.local

bash-5.1# echo $REDIS_PORT
6379

bash-5.1# echo $REDIS_PASSWORD
+++++

bash-5.1# nslookup $REDIS_HOST
Server:         172.20.0.10
Address:        172.20.0.10#53

Name:   db-redis-master.db-redis.svc.cluster.local
Address: 172.20.204.205 # db-redis-master service
```

## Questions

### How would you integrate the new Redis instance with the containerised application (so that the application knows how to connect to the Redis instance)?

With the setup above, the application needs to be uploaded into a container registry, ideally after
running through code-level automated tests and static analysis ci pipeline. Then, a deployment
trigger can be setup to update the `kustomize` manifests to point to the new image version and
allow deployment to happen through ArgoCD. As environment variables are injected through the
deployment, application should have the environment variables populated and ready to be referenced
in the container during run-time.

### What other options are there for creating and deploying a production-ready Redis instance? Would any of these be preferable to the above approach?

As the `bitnami/redis` chart considered to be battle-tested and production-ready Redis
installation. It is only a matter of tweaking the configuration to meet the specific production
requirement. However, other options would be to deploy a managed AWS ElastiCache for Redis service
and supply the credentials and environment values through the deployment manifest.

In my opinion, opting for a managed service solution is a tradeoff between cost and ease of
maintainence. My guiding rule of thumb is that if the service we are considering is self-deployable
and has good support around self-maintenance, I would opt to self-host where cost overhead can be
minimized. However, in situation where the service in consideration is unique and require esoteric
expertise with minimal support for self-maintenance, I would lean to opting for the managed service
solution.

## Git log

Git logs are not used diligently here to track code changes, they're mostly experimention commits.
Given an actual project, I will be sure to follow git best practices.
