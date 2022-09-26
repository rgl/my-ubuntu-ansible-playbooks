# YugabyteDB

Test the access from the tserver pod using `ysqlsh`:

```bash
kubectl exec -n yugabytedb -it yb-tserver-0 -- ysqlsh
```

And execute some queries:

```sql
\l
select version();
show server_version;
select current_user;
select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid();
```

## Reference

* https://artifacthub.io/packages/helm/yugabyte/yugabyte
* https://github.com/yugabyte/yugabyte-db/tree/master/cloud/kubernetes
* https://download.yugabyte.com/#kubernetes
* https://docs.yugabyte.com/stable/deploy/kubernetes/
* https://docs.yugabyte.com/stable/architecture/
* https://docs.yugabyte.com/stable/architecture/concepts/universe/
* https://docs.yugabyte.com/stable/architecture/concepts/yb-master/
* https://docs.yugabyte.com/stable/architecture/concepts/yb-tserver/
* https://docs.yugabyte.com/preview/reference/configuration/default-ports/#client-apis
* https://docs.yugabyte.com/preview/tools/#connection-parameters
* https://docs.yugabyte.com/preview/explore/ysql-language-features/postgresql-compatibility/
