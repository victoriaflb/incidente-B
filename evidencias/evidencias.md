## Medir

RTO: : horário em que o problema começou (T0) até o serviço voltar a aceitar escrita (T1).
RTO = T1 − T0.

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

