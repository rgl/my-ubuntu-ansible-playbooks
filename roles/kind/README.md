# Applications

* [Kubernetes](#kubernetes)
* [Kubernetes Dashboard](#kubernetes-dashboard)
* [pgAdmin](#pgadmin)

## Kubernetes

Show information about the local Kubernetes instance:

```bash
kubectl get nodes -o wide
kubectl get sc,pvc,pv -A
kubectl get pods -A
kubectl get ingress -A
```

## Kubernetes Dashboard

Use the Kubernetes Dashboard application with the Token from the
`~/.kube/kind-admin-token.txt` file at:

https://kubernetes-dashboard.kind.test

## pgAdmin

Use the pgAdmin application with the `admin@example.com` user and
`password` password at:

https://pgadmin.kind.test
