# PostgreSQL

Test the access from the `postgresql-cluster-1` pod using `psql`:

```bash
kubectl exec -n postgresql -it postgresql-cluster-1 -- \
    env PGPASSWORD=postgres psql --host=postgresql-cluster-rw --port=5432 --username=postgres
```

And execute some queries:

```sql
\l
select version();
show server_version;
select current_user;
select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid();
```

Test the access from the pgadmin deployment using `psql`:

```bash
kubectl exec -n pgadmin -it deployments/pgadmin-pgadmin4 -- \
    env PGPASSWORD=postgres /usr/local/pgsql-17/psql --host=postgresql-cluster-rw.postgresql --port=5432 --username=postgres
```

And execute some queries:

```sql
\l
select version();
show server_version;
select current_user;
select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid();
```

Use the pgAdmin application with the `admin@example.com` user and
`password` password at:

<https://pgadmin.kind.test>

Then, login as `postgres` with the `postgres` password into the `PostgreSQL` server.

## Reference

* <https://cloudnative-pg.io/docs/>
* <https://cloudnative-pg.io/documentation/current/supported_releases>
* <https://artifacthub.io/packages/helm/cloudnative-pg/cloudnative-pg>
* <https://github.com/cloudnative-pg/charts/tree/main/charts/cloudnative-pg>
* <https://github.com/cloudnative-pg/charts/tree/main/charts/cluster>
