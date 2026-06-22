# Planejamento de Rotas no Mapa da Romênia — Sistema Inteligente em Prolog

Trabalho Final de **Inteligência Artificial I** — Universidade Católica de Brasília (UCB)
Prof. William Malvezzi

Protótipo de sistema inteligente que combina os três pilares exigidos:
**(1)** um agente inteligente modelado (PEAS + ambiente), **(2)** representação explícita
de conhecimento em Prolog (fatos + regras) e **(3)** busca em espaço de estados
(DFS, BFS e A\*), aplicados ao clássico **mapa da Romênia** de Russell & Norvig (cap. 3).

---

## Integrantes

> Matrículas a preencher.
>
> - João Pedro Silva — _(matrícula)_
> - Arthur Lima Gomes — _(matrícula)_
> - Tiago Alexsander — _(matrícula)_
> - Caio Victor Veras — _(matrícula)_
> - Guilherme do Couto — _(matrícula)_

---

## Domínio do problema

Dado o mapa rodoviário da Romênia (20 cidades, 23 estradas com distâncias reais em km),
o sistema responde a perguntas como *"existe caminho de Arad até Bucareste?"* e calcula
a **melhor rota** entre duas cidades, comparando três estratégias de busca. É um problema
clássico de IA: encontrar o caminho de menor custo num grafo, com heurística admissível.

---

## Estrutura do projeto

| Arquivo          | Conteúdo                                                                 |
|------------------|--------------------------------------------------------------------------|
| `rotas.pl`       | **Base de conhecimento**: 20 fatos `cidade/1`, 23 `estrada/3`, 20 `h/2` (heurística) e 8 regras (incl. 2 recursivas). |
| `busca.pl`       | **Algoritmos de busca**: DFS (`caminho/3`), BFS (`bfs/3`) e A\* (`astar/4`). Carrega `rotas.pl` automaticamente (e vice-versa). |
| `agente.md`      | **Modelagem do agente** "NaviRomênia": PEAS, classificação do ambiente e tipo de agente. |
| `consultas.md`   | **13 consultas demonstradas** com as saídas reais do interpretador + explicação de unificação/backtracking. |
| `tests/`         | **Testes automatizados** (`plunit`): `test_rotas.pl`, `test_busca.pl` e `tests/README.md`. |
| `run_tests.pl`   | **Runner de testes**: carrega os dois suites e roda todos de uma vez.    |
| `CLAUDE.md`      | Resumo das exigências do enunciado (contexto do projeto).                |
| `README.md`      | Este arquivo.                                                            |

---

## Pré-requisitos

- **SWI-Prolog** (testado na versão **10.0.2**).
  - Windows: `winget install SWI.SWI-Prolog`
  - Linux (Debian/Ubuntu): `sudo apt install swi-prolog`
  - macOS: `brew install swi-prolog`
- Verifique a instalação:
  ```bash
  swipl --version
  ```

---

## Como executar

### Modo interativo (recomendado)

A partir da pasta do projeto:

```bash
swipl busca.pl
```

> `busca.pl` já carrega `rotas.pl` (via `:- ensure_loaded(rotas).`), então **toda** a
> base de conhecimento e os três algoritmos ficam disponíveis de uma vez.
>
> **Tanto faz qual arquivo você abre:** `swipl rotas.pl` também funciona, pois os dois
> se carregam mutuamente. (Antes, abrir só `rotas.pl` dava `Unknown procedure: caminho/3`
> — isso foi corrigido.) Os arquivos também importam `library(lists)` explicitamente,
> para rodar mesmo em máquinas com *autoload* desativado.

No prompt `?-`, experimente:

```prolog
?- cidade(arad).                              % é uma cidade?           -> true
?- estrada(arad, sibiu, D).                   % distância da estrada    -> D = 140
?- vizinho(arad, V).                          % vizinhos (use ; p/ mais)
?- alcancavel(arad, bucareste).               % existe caminho?         -> true
?- melhor_rota(arad, bucareste, R, D).        % melhor rota e distância

?- caminho(arad, bucareste, C).               % DFS  -> primeiro caminho
?- bfs(arad, bucareste, C).                   % BFS  -> menos cidades
?- astar(arad, bucareste, C, Custo).          % A*   -> rota ÓTIMA (418 km)
```

Para sair do interpretador:

```prolog
?- halt.
```

> Dica: no modo interativo, depois de uma resposta digite `;` para pedir a **próxima**
> solução (isso dispara o *backtracking*) ou `Enter` para encerrar a consulta.

### Modo "uma consulta só" (linha de comando)

Útil para scripts ou para capturar uma saída específica:

```bash
swipl -q -g "astar(arad,bucareste,C,Custo), write(C-Custo), nl" -t halt busca.pl
```

Saída esperada:

```
[arad,sibiu,rimnicu,pitesti,bucareste]-418
```

---

## Resultado de referência (validação)

Para a viagem **Arad → Bucareste**, os três algoritmos produzem:

| Algoritmo | Rota                                          | Cidades | Distância  |
|-----------|-----------------------------------------------|:-------:|:----------:|
| DFS       | arad→zerind→oradea→sibiu→fagaras→bucareste     | 6       | 607 km     |
| BFS       | arad→sibiu→fagaras→bucareste                   | 4       | 450 km     |
| **A\***   | arad→sibiu→rimnicu→pitesti→bucareste           | 5       | **418 km** |

O valor **418 km** do A\* coincide com o resultado clássico de Russell & Norvig,
confirmando que a heurística é admissível e a busca é ótima. Veja `consultas.md` para
as 13 consultas completas com saídas reais.

---

## Testes automatizados

O projeto inclui uma suíte de testes em **`plunit`** (framework nativo do SWI-Prolog),
com **35 testes** (44 com sub-testes) que validam fatos, regras e os três algoritmos
de busca — incluindo provas de **otimalidade do A\*** e **admissibilidade da heurística**.

```bash
swipl run_tests.pl
```

Saída esperada:

```
% All 35 (+44 sub-tests) tests passed
```

Detalhes de cada caso em [`tests/README.md`](tests/README.md).

---

## Referência

RUSSELL, Stuart; NORVIG, Peter. *Inteligência Artificial*. 3. ed.
Rio de Janeiro: Elsevier, 2013. (cap. 2 — agentes; cap. 3 — busca)
