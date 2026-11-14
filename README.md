# Cenário B — Servidor principalfora do ar (ransomware) Situação. Um ransomware criptografa o disco do banco principal em pleno horário de pico. Existe uma réplica. 

Reproduza. 

1. No psql interativo do primário, simule pedidos chegando: 

INSERT INTO eventos DEFAULT VALUES RETURNING id;
\watch 0.1

2. Em outro terminal, anote T0 e derrube o primário. Anote o último id impresso antes do erro. 

3. Promova a réplica e confirme pg_is_in_recovery() = false. 

4. Grave uma linha no novo primário e anote T1. 

**Meça**. RTO = T1 − T0. RPO = (último id confirmado) − ( SELECT max(id) FROM eventos; no novo primário), se positivo. 

**Corrija**. Registre o que a aplicação precisa mudar para voltar (apontar para a porta 5443) e o que impediria o servidor antigo de voltar como primário sem ser reconstruído. 

**Responda**. O que o RTO medido incluiu e deixou de fora (detecção, DNS, reconexão)? A replicação é assíncrona: por que o RPO deu esse valor e quando seria maior?