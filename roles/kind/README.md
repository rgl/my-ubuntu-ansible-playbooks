# Applications

* [Kubernetes](#kubernetes)
* [Kubernetes Dashboard](#kubernetes-dashboard)
* [Gitea](#gitea)
* [pgAdmin](#pgadmin)
* [PostgreSQL](#postgresql)

## Kubernetes

Show information about the local Kubernetes instance:

```bash
kubectl get nodes -o wide
kubectl get l2advertisement,ipaddresspool -A
ip neighbor
sudo ip neighbor flush all
kubectl get sc,pvc,pv -A
kubectl get pods -A
kubectl get ingress -A
```

## Kubernetes Dashboard

Use the Kubernetes Dashboard application with the Token from the
`~/.kube/kind-admin-token.txt` file at:

https://kubernetes-dashboard.kind.test

## Gitea

To use the Gitea application, login with the `gitea` username and the
password inside the `~/.kube/kind-gitea-password.txt` file, at:

https://gitea.kind.test

To use Gitea inside the Kubernetes cluster, use must use the `gitea` service
endpoint at:

http://gitea-http.gitea.svc:3000

## pgAdmin

Use the pgAdmin application with the `admin@example.com` user and
`password` password at:

https://pgadmin.kind.test

This has access to the [PostgreSQL instance](#postgresql).

## PostgreSQL

See [PostgreSQL](postgresql.md).
