# PROMPT PARA ANALISE DE BENCHMARK

> Copie este prompt e envie para o assistente sempre que quiser analisar os resultados de um teste.
> O assistente gerará um arquivo `.md` em `analise_resultados/` com o relatório completo.

---

```
Analise os arquivos dentro dos diretórios `resultados/` e `metricas/` e gere um relatório
comparativo entre MariaDB e PostgreSQL. Siga rigorosamente o formato abaixo.

## REGRAS

1. Leia todos os CSVs em `resultados/` (stats, exceptions, failures) e `metricas/` (docker, vmstat).
2. Extraia os valores reais dos arquivos — nunca invente números.
3. Registre as condições do teste (se não encontrar, procure no README.md ou pergunte).
4. Salve o relatório em `analise_resultados/relatorio-YYYY-MM-DD-HHmmss.md`.
5. Use SEMPRE a mesma estrutura de seções abaixo.

---

## GLOSSARIO — O que cada metrica significa

> Inclua estas explicacoes **antes de cada tabela** no relatorio.

### Latencia (percentis)

| Metrica | Significado |
|---|---|
| **p50 (mediana)** | 50% das requisicoes foram respondidas ate este tempo. Representa a experiencia "tipica" do usuario. |
| **p75** | 75% das requisicoes ficaram abaixo deste valor. Mostra onde a maioria esmagadora esta. |
| **p95** | 95% das requisicoes ficaram abaixo. As 5% piores estao acima. Mede a "cauda curta" — os piores casos aceitaveis. |
| **p99** | 99% ficaram abaixo. As 1% piores estao acima. Mede a "cauda longa" — os outliers que degradam a experiencia. |
| **max** | A pior requisicao de todas. Um unico valor extremo pode puxar o max para cima. |
| **Media (avg)** | Soma de todas as latencias / total de requisicoes. **Enganadora se houver outliers** — use os percentis. |

> **Interpretacao:** Um banco com p50 baixo mas p99 altissimo entrega respostas rapidas na media, mas **inconsistente** — alguns usuarios esperam muito. Um banco com p50 mais alto mas p95/p99 proximos do p50 entrega latencia **previsivel e estavel**.

### Throughput

| Metrica | Significado |
|---|---|
| **Total de requests** | Quantas requisicoes foram completadas no periodo do teste. Quanto mais, melhor. |
| **RPS (Requests por Segundo)** | Throughput medio. Quantas requisicoes o sistema processa por segundo. |
| **Falhas** | Requisicoes que retornaram erro (HTTP 5xx, timeout, excecao). Zero falhas = sistema estavel sob carga. |

### Container (docker stats)

| Metrica | Significado |
|---|---|
| **CPU %** | Percentual de CPU alocado ao container. Pode passar de 100% se usar mais de 1 nucleo. Ex: 200% = 2 nucleos cheios. |
| **RAM %** | Percentual da RAM total do host usada pelo container. Indica consumo de memoria do banco. |

### Host (vmstat)

| Metrica | Significado |
|---|---|
| **CPU us (user)** | % de CPU gasta em codigo de usuario (processos normais, incluindo os bancos). |
| **CPU sy (system)** | % de CPU gasta em kernel (syscalls, I/O scheduling). Alto sy indica sobrecarga de chamadas de sistema. |
| **CPU id (idle)** | % de CPU ociosa. CPU total usado = 100 - idle. |
| **IO wait (wa)** | % de CPU **parada esperando disco**. Se alto (>10%), o disco e o gargalo — o banco quer ler/escrever mas o disco nao da conta. |
| **bi (blocks in)** | Blocos lidos do disco por segundo. Mede leitura de disco real. Alto bi = cache insuficiente. |
| **bo (blocks out)** | Blocos escritos no disco por segundo. Mede escrita real. Alto com baixo IO wait = escrita assincrona eficiente. |
| **Run queue (r)** | Processos na fila de CPU. Se > numero de nucleos, CPU esta sobrecarregada. |
| **Blocked (b)** | Processos bloqueados esperando I/O (disco, rede). Se > 0 constantemente, I/O e o gargalo. |
| **RAM livre (free)** | Memoria RAM nao usada pelo host. Muito baixa pode indicar que o SO esta fazendo swap. |

> **Interpretacao:** IO wait alto + bi alto + blocked > 0 = **gargalo de disco**. Run queue alta + CPU idle baixo = **gargalo de CPU**. RAM livre muito baixa + swap > 0 = **gargalo de memoria**.

---

## ESTRUTURA DO RELATORIO

### 1. Condições do Teste

Preencha com os valores reais usados. Se não souber, marque `?` e pergunte.

| Parâmetro | Valor |
|---|---|
| Data/hora do teste | (extrair do timestamp dos CSVs) |
| Duração do teste | ? |
| Usuários Locust | ? (StagesShape ou -u) |
| Spawn rate | ? (-r ou LoadTestShape) |
| Versão MariaDB | ? |
| Versão PostgreSQL | ? |
| Buffer pool MariaDB | ? |
| Shared buffers PostgreSQL | ? |
| Registros na tabela | 340.000 |
| Host | VPS |
| Endpoints testados | /dados, /dados-data, /dados-disposicao, /dados-texto, /dados-agregado, /dados-ordenado, /dados-src, /dados-contagem, /dados-inserir |

### 2. Throughput (Locust)

| Métrica | MariaDB | PostgreSQL |
|---|---|---|
| Total de requests | (valor real) | (valor real) |
| RPS médio | (valor real) | (valor real) |
| Falhas | (valor real) | (valor real) |

### 3. Latência (Locust)

| Métrica | MariaDB | PostgreSQL |
|---|---|---|
| p50 (mediana) ms | (valor real) | (valor real) |
| p75 ms | (valor real) | (valor real) |
| p95 ms | (valor real) | (valor real) |
| p99 ms | (valor real) | (valor real) |
| max ms | (valor real) | (valor real) |

### 4. Latência por Endpoint

| Endpoint | MDB p50 | PG p50 | MDB p95 | PG p95 | MDB p99 | PG p99 |
|---|---|---|---|---|---|---|
| /dados | | | | | | |
| /dados-data | | | | | | |
| /dados-disposicao | | | | | | |
| /dados-texto | | | | | | |
| /dados-agregado | | | | | | |
| /dados-ordenado | | | | | | |
| /dados-src | | | | | | |
| /dados-contagem | | | | | | |
| /dados-inserir | | | | | | |

### 5. Recursos — Container (docker stats)

| Métrica | MariaDB | PostgreSQL |
|---|---|---|
| CPU médio | | |
| CPU máximo | | |
| RAM média | | |

### 6. Recursos — Host (vmstat)

| Métrica | MariaDB | PostgreSQL |
|---|---|---|
| CPU total médio (us+sy) | | |
| CPU total máximo | | |
| IO wait médio | | |
| IO wait máximo | | |
| Blocos lidos/s (bi) | | |
| Blocos escritos/s (bo) | | |
| Run queue médio (r) | | |
| Run queue máximo (r) | | |
| Processos bloqueados médio (b) | | |
| RAM livre média (MB) | | |

### 7. Verdicto

Responda objetivamente:

- **Quem teve mais throughput?** (RPS) — cite os números
- **Quem teve menor latência mediana?** (p50) — cite os números
- **Quem teve menor latência no p95 e p99?** (cauda) — cite os números
- **Quem consumiu mais CPU?** — cite os números
- **Quem fez mais IO de disco?** (IO wait + blocos lidos) — cite os números
- **Qual foi o MAIS PERFORMÁTICO neste cenário e por quê?**
- **Se houver teste anterior, compare com ele** (evolução ou regressão)

### 8. Observações

- Qualquer anomalia, erro ou comportamento inesperado detectado nos CSVs
- Comparação com testes anteriores se disponível
```
