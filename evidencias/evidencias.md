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


## Failover

- **Quem foi promovido:** a réplica `lab1-replica-1` (porta 5443).
- **Quando:** logo após a queda do primário. T0 = 11:33:54 (queda) e T1 = 11:34:09 (primeira escrita aceita no novo primário).
- **Como foi feito:** `docker compose exec replica psql -U postgres -c "SELECT pg_promote();"`, que retornou `t`.
- **Como confirmou:** `SELECT pg_is_in_recovery();` retornou `f`, ou seja, a réplica deixou o modo de recuperação e passou a aceitar escrita.
- **Verificação dos dados:** `SELECT max(id) FROM eventos;` retornou 188, igual ao último id confirmado antes da queda. Nenhuma linha foi perdida (RPO = 0).
- **Observação sobre os ids:** o primeiro INSERT no novo primário recebeu o id 199, e não 189. A sequência `bigserial` reserva ids em blocos, então o salto na numeração não indica perda de linhas.
- **Evidências:** `evidencias/02-t0-queda.png` e `evidencias/03-promocao-t1.png`.

![alt text](evidencias/03-promocao-t1.png)

![alt text](evidencias/02-t0-queda.png)

## Correção

- **O que a aplicação precisa mudar:** apontar a conexão para a porta **5443** (a réplica promovida), em vez da 5442. Em produção, isso seria feito por DNS, IP virtual ou proxy, para não depender de alterar a aplicação.
- **O que impede o servidor antigo de voltar como primário sem ser reconstruído:**
  - A promoção abriu uma nova *timeline*, e o antigo ficou na anterior: os históricos divergiram.
  - Ele pode ter confirmado linhas que a réplica nunca recebeu. Se voltasse como primário, haveria dois primários aceitando escrita (*split-brain*).
  - No cenário, o disco foi criptografado pelo ransomware e não é confiável.
  - Só volta como **réplica do novo primário**, refeito com `pg_basebackup` (ou `pg_rewind`, se o disco estivesse íntegro).

  ## Respostas

**O que o RTO medido incluiu e deixou de fora?**
Incluiu apenas o intervalo entre a queda e a primeira escrita aceita no novo primário, feito manualmente (promoção e INSERT). Ficaram de fora: a **detecção** da falha (aqui eu sabia que ia cair), a **decisão** de promover, a mudança de **DNS/endereço** e a **reconexão da aplicação**. Em um incidente real, o RTO seria maior que 15 s.

**A replicação é assíncrona: por que o RPO deu esse valor e quando seria maior?**
Na replicação assíncrona o primário confirma o commit sem esperar a réplica. O RPO deu 0 porque a carga era baixa (cerca de 10 inserts por segundo) e a rede é local, então a réplica recebeu o WAL em milissegundos. Isso não é garantia. Seria maior com atraso de replicação (rede lenta ou réplica sobrecarregada), carga de escrita alta ou cargas em lote, ou com a réplica desconectada antes da queda.