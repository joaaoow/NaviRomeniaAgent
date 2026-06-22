# Testes Automatizados — `plunit`

Arquitetura de testes do projeto, usando o framework **`plunit`** (nativo do
SWI-Prolog, `library(plunit)`). Os testes são **específicos** do código: cada um
verifica um fato, uma regra ou um algoritmo de `rotas.pl` / `busca.pl`.

## Como rodar

A partir da **raiz do projeto** (a pasta acima desta):

```bash
# roda os dois suites de uma vez (sai com codigo 0 se tudo passar)
swipl run_tests.pl
```

Ou rodar um suite isolado:

```bash
swipl -g run_tests -t halt tests/test_rotas.pl   # so a base de conhecimento
swipl -g run_tests -t halt tests/test_busca.pl   # so os algoritmos de busca
```

## Estrutura

| Arquivo                 | Cobre                                                              |
|-------------------------|-------------------------------------------------------------------|
| `tests/test_rotas.pl`   | Fatos e as 8 regras de `rotas.pl` (`conectado`, `vizinho`, `cidade_fronteira`, `rota_direta`, `alcancavel`, `distancia_rota`, `melhor_rota`, `classifica_viagem`). |
| `tests/test_busca.pl`   | Algoritmos `caminho/3` (DFS), `bfs/3` (BFS), `astar/4` (A\*) + testes de **propriedade** (otimalidade do A\*, admissibilidade da heurística, comparação A\* × BFS). |
| `run_tests.pl` (raiz)   | Runner: carrega os dois suites e roda tudo, com código de saída para CI. |

## Por que estes casos?

Os testes ancoram os resultados na teoria de Russell & Norvig (cap. 3) e na própria
base de dados do projeto. Destaques:

- **Contagens exatas** — 20 cidades, 23 estradas, 20 valores de heurística.
- **Bidirecionalidade** — `forall(estrada(A,B,D))` garante que `conectado/3` vale nos dois sentidos para *todas* as estradas.
- **Becos (`cidade_fronteira/1`)** — exatamente `[eforie, giurgiu, neamt]` (grau 1).
- **Rota ótima clássica** — Arad → Bucareste = **418 km** (`melhor_rota/4` e `astar/4`).
- **A\* é ótimo** — para vários destinos, o custo do A\* é igual ao mínimo entre *todos* os caminhos (comparado via DFS + `distancia_rota/2`).
- **Heurística admissível** — `forall(cidade(C))` confirma `h(C) ≤ custo_real(C → bucareste)`, condição que garante a otimalidade do A\*.
- **A\* × BFS** — o A\* (418 km) nunca é pior em km que a BFS (450 km), porque a BFS minimiza *número de cidades*, não distância.

## Resultado esperado

```
% All 35 (+44 sub-tests) tests passed
```

> Observação: usamos `once/1` em metas que deixam ponto de escolha (ex.: `conectado/3`
> tem duas cláusulas; DFS/BFS geram várias soluções por backtracking). Isso torna o
> teste determinístico e evita o aviso `Test succeeded with choicepoint`, sem mudar o
> significado — só nos importa que exista **ao menos uma** solução.
