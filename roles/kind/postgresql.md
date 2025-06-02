# PostgreSQL

Test the access from the `postgres-0` pod using `psql`:

```bash
kubectl exec -n postgresql -it postgresql-0 -- \
    env PGPASSWORD=postgres psql --host=postgresql --port=5432 --username=postgres
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
    env PGPASSWORD=postgres /usr/local/pgsql-11/psql --host=postgresql.postgresql --port=5432 --username=postgres
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

## Reference

* <https://artifacthub.io/packages/helm/bitnami/postgresql>
* <https://github.com/bitnami/charts/tree/main/bitnami/postgresql>
