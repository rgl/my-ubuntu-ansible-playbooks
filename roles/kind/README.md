# Applications

* [Kubernetes](#kubernetes)
* [Kubernetes Dashboard](#kubernetes-dashboard)
* [Gitea](#gitea)
* [Argo CD](#argo-cd)
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

## Argo CD

To use the Argo CD application, login with the `admin` username and the
password inside the `~/.kube/kind-argocd-admin-password.txt` file, at:

https://argocd.kind.test

If the Argo CD UI is showing these kind of errors:

> Unable to load data: permission denied
> Unable to load data: error getting cached app managed resources: NOAUTH Authentication required.
> Unable to load data: error getting cached app managed resources: cache: key is missing
> Unable to load data: error getting cached app managed resources: InvalidSpecError: Application referencing project default which does not exist

Try restarting some of the Argo CD components, and after restarting them, the
Argo CD UI should start working after a few minutes (e.g. at the next sync
interval, which defaults to 3m):

```bash
kubectl -n argocd rollout restart statefulset argocd-application-controller
kubectl -n argocd rollout status statefulset argocd-application-controller --watch
kubectl -n argocd rollout restart deployment argocd-server
kubectl -n argocd rollout status deployment argocd-server --watch
```

Configure the shell to access Argo CD:

```bash
export SSL_CERT_FILE="$HOME/.kube/kind-ingress-ca-crt.pem"
export GIT_SSL_CAINFO="$SSL_CERT_FILE"
argocd_server_fqdn="$(kubectl get -n argocd ingress/argocd-server -o json | jq -r .spec.rules[0].host)"
argocd_server_url="https://$argocd_server_fqdn"
argocd_server_admin_password="$(
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \
    | base64 --decode)"
echo "argocd_server_url: $argocd_server_url"
echo "argocd_server_admin_password: $argocd_server_admin_password"
```

Create the `example-argocd` repository:

```bash
gitea_fqdn="$(kubectl get -n gitea ingress/gitea -o json | jq -r .spec.rules[0].host)"
gitea_url="https://$gitea_fqdn"
gitea_password="$(cat ~/.kube/kind-gitea-password.txt)"
echo "gitea_url: $argocd_server_url"
echo "gitea_username: gitea"
echo "gitea_password: $gitea_password"
curl \
  --silent \
  --show-error \
  --fail-with-body \
  -u "gitea:$gitea_password" \
  -X POST \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "example-argocd",
    "private": true
  }' \
  "$gitea_url/api/v1/user/repos" \
  | jq
rm -rf tmp/example-argocd
git init tmp/example-argocd
pushd tmp/example-argocd
git branch -m main
wget -qO- https://github.com/rgl/terraform-libvirt-talos/raw/main/example.yml \
    | sed -E 's,\.example\.test,.kind.test,g' \
    > example.yml
git add .
git commit -m init
git remote add origin "$gitea_url/gitea/example-argocd.git"
git push -u origin main
popd
```

Create the `example` argocd application:

```bash
# NB we have to access gitea thru the internal cluster service because the
#    external/ingress domains does not resolve inside the cluster.
argocd_server_admin_password="$(cat ~/.kube/kind-argocd-admin-password.txt)"
argocd login \
  "$argocd_server_fqdn" \
  --grpc-web \
  --username admin \
  --password "$argocd_server_admin_password"
argocd cluster list
# NB if git repository was hosted outside of the cluster, we might have
#    needed to execute the following to trust the certificate.
#     argocd cert add-tls gitea.example.test --from "$SSL_CERT_FILE"
#     argocd cert list --cert-type https
argocd repo add \
  http://gitea-http.gitea.svc:3000/gitea/example-argocd.git \
  --grpc-web \
  --username gitea \
  --password "$gitea_password"
argocd app create \
  example \
  --dest-name in-cluster \
  --dest-namespace default \
  --project default \
  --auto-prune \
  --self-heal \
  --sync-policy automatic \
  --repo http://gitea-http.gitea.svc:3000/gitea/example-argocd.git \
  --path .
argocd app list
argocd app wait example --health --timeout 300
kubectl get crd | grep argoproj.io
kubectl -n argocd get applications
kubectl -n argocd get application/example -o yaml
```

Access the example application:

```bash
kubectl rollout status deployment/example
kubectl get ingresses,services,pods,deployments
example_fqdn="$(kubectl get ingress/example -o json | jq -r .spec.rules[0].host)"
example_url="http://$example_fqdn"
xdg-open "$example_url"
```

Modify the example application, by bumping the number of replicas:

```bash
pushd tmp/example-argocd
sed -i -E 's,(replicas:) .+,\1 3,g' example.yml
git diff
git add .
git commit -m 'bump replicas'
git push -u origin main
popd
```

Then go the Argo CD UI, and wait for it to eventually sync the example argocd
application, or click `Refresh` to sync it immediately.

Delete the example argocd application and repository:

```bash
argocd app delete \
  example \
  --yes
argocd repo rm \
  http://gitea-http.gitea.svc:3000/gitea/example-argocd.git
curl \
  --silent \
  --show-error \
  --fail-with-body \
  -u "gitea:$gitea_password" \
  -X DELETE \
  -H 'Accept: application/json' \
  "$gitea_url/api/v1/repos/gitea/example-argocd" \
  | jq
```

## pgAdmin

Use the pgAdmin application with the `admin@example.com` user and
`password` password at:

https://pgadmin.kind.test

This has access to the [PostgreSQL instance](#postgresql).

## PostgreSQL

See [PostgreSQL](postgresql.md).
