# Cenário B — Servidor principal fora do ar (ransomware) Situação. 

Um ransomware criptografa o disco do banco principal em pleno horário de pico. Existe uma réplica. 

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

| Medida | Valor |
|---|---|
| T0 (queda do primário) | 11:33:54 |
| T1 (primeira escrita no novo primário) | 11:34:09 |
| RTO | 15 s |
| Último id confirmado | 188 |
| max(id) no novo primário | 188 |
| RPO | 0 linhas |

## Failover

- **Quem foi promovido:** a réplica `lab1-replica-1` (porta 5443).
- **Quando:** logo após a queda do primário. T0 = 11:33:54 (queda) e T1 = 11:34:09 (primeira escrita aceita no novo primário).
- **Como foi feito:** `docker compose exec replica psql -U postgres -c "SELECT pg_promote();"`, que retornou `t`.
- **Como confirmou:** `SELECT pg_is_in_recovery();` retornou `f`, ou seja, a réplica deixou o modo de recuperação e passou a aceitar escrita.
- **Verificação dos dados:** `SELECT max(id) FROM eventos;` retornou 188, igual ao último id confirmado antes da queda. Nenhuma linha foi perdida (RPO = 0).
- **Observação sobre os ids:** o primeiro INSERT no novo primário recebeu o id 199, e não 189. A sequência `bigserial` reserva ids em blocos, então o salto na numeração não indica perda de linhas.
- **Evidências:** `evidencias/02-t0-queda.png` e `evidencias/03-promocao-t1.png`.

![alt text](evidencias/03-promocao-t1.png)