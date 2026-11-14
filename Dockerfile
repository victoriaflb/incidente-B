FROM postgres:16
LABEL description="Primario do Incidente B (DBaaS): tabelas clientes/eventos e usuario app"
COPY init.sql /docker-entrypoint-initdb.d/init.sql
