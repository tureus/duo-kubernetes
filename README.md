Duo Kubernetes
=======

Duo has a IdP (the `duo access gateway`, compatible with G-Suite SAML) and a reverse proxy (the `duo networkg gateway`). They provide docker containers but it requires a little bit of work to get running in a kubernetes cluster.

I use the tool `kompose` to take a first stab at converting the office docker-compose files to kubernetes deployments/services/pvcs. I ended up needing to initialize some of the pvc storage because kube doesn't copy volume contents quite like docker would.

Assumptions
---

I put all these components in a `duo` namespace. These scripts will create two LoadBalancers, `admin` and `portal`. You can't use the nginx ingress controller because it does not support TLS-passthrough, the duo containers want to terminate all the traffic.

```
kubectl create namespace duo
```

Duo Access Gateway
----

The simplest to enable.

```
kubectl create -f duo-access-gateway-pvc.yaml
kubectl create -f duo-access-gateway-service.yaml
kubectl create -f duo-access-gateway-deployment.yaml
kubectl -n duo get all --watch # ctrl-c whenever, just so you can watch for errors
```

Duo Network Gateway
----

More complex. This is a trio of an Admin application, a Redis coordination layer, and the active component, the Portal.

Set up Redis first:

```
kubectl create -f duo-network-gateway-redis-pvc.yaml
kubectl create -f duo-network-gateway-redis-service.yaml
kubectl create -f duo-network-gateway-redis-deployment.yaml
kubectl -n duo get all --watch # ctrl-c whenever, just so you can watch for errors
```

Then the Admin app:
```
kubectl create -f duo-network-gateway-admin-service.yaml
kubectl create -f duo-network-gateway-admin-deployment.yaml
kubectl -n duo get all --watch # ctrl-c whenever, just so you can watch for errors
```

Finally, the portal:
```
kubectl create -f duo-network-gateway-redis-pvc.yaml
kubectl create -f duo-network-gateway-redis-service.yaml
kubectl create -f duo-network-gateway-redis-deployment.yaml
kubectl -n duo get all --watch # ctrl-c whenever, just so you can watch for errors
```

Once the portal is up you need to swap it out with a customized version,

```
cd duo-network-gateway-portal-image
make create-repository
make deploy
```

This will build/push/swap out the running image with a better nginx template. The root issue is the hard-coded resolver line, nginx will not be able to resolve internal services without this change, and a failure to talk to any DNS will cause it to error on requests. Not good.

Keeping things up to date
---

Unfortunately Duo doesn't have a release page. They don't named numbered versions. No semver. You can't even find a git repository showing changes. You are really at their mercy until they adopt standard best practices.

But hey, it's enterprise software!

If you do want to look for new versions:

```
curl -L https://dl.duosecurity.com/network-gateway-latest.yml
```