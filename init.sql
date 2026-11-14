CREATE TABLE clientes (id serial PRIMARY KEY, nome text, email text);
INSERT INTO clientes (nome, email)
SELECT 'cliente ' || g, 'c' || g || '@loja.com' FROM generate_series(1, 1000) g;
CREATE TABLE eventos (id bigserial PRIMARY KEY, ts timestamptz DEFAULT now());
CREATE ROLE app LOGIN PASSWORD 'app';
GRANT SELECT, INSERT, UPDATE ON clientes TO app;
GRANT USAGE ON SEQUENCE clientes_id_seq TO app;
