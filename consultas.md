# Consultas Demonstradas — Base de Conhecimento e Buscas (Prolog)

> Trabalho Final de Inteligência Artificial I — UCB, Prof. William Malvezzi
> Domínio: **planejamento de rotas no mapa da Romênia** (Russell & Norvig, cap. 3)
> Arquivos: `rotas.pl` (fatos + regras) e `busca.pl` (DFS, BFS, A\*)

Este documento atende às exigências do §7.2 e §7.4 do enunciado:
**≥ 8 consultas demonstradas**, **≥ 3 com variáveis**, com as **saídas reais** do
interpretador (os "prints" pedidos). Todas as consultas abaixo foram executadas no
**SWI-Prolog 10.0.2**.

## Como reproduzir

```bash
# a partir da pasta do projeto:
swipl busca.pl        % busca.pl já carrega rotas.pl via :- ensure_loaded(rotas).

% depois, no prompt ?-  digite qualquer consulta deste documento.
% para sair: halt.
```

Todas as saídas a seguir foram capturadas de uma execução real (não editadas).

---

## Resumo das 13 consultas

| #   | Consulta                          | Tipo                         | Usa variável? |
|-----|-----------------------------------|------------------------------|:-------------:|
| C1  | `cidade(arad).`                   | fato (verificação)           | não           |
| C2  | `estrada(arad,sibiu,D).`          | fato com variável            | **sim**       |
| C3  | `conectado(sibiu,arad,D).`        | regra (bidirecional)         | **sim**       |
| C4  | `vizinho(arad,V).`                | regra, múltiplas soluções    | **sim**       |
| C5  | `cidade_fronteira(X).`            | regra c/ várias condições    | **sim**       |
| C6  | `rota_direta(arad,bucareste).`    | regra c/ várias condições    | não           |
| C7  | `alcancavel(arad,bucareste).`     | **regra recursiva**          | não           |
| C8  | `distancia_rota([...],D).`        | **regra recursiva**          | **sim**       |
| C9  | `melhor_rota(arad,bucareste,R,D).`| regra (findall + busca)      | **sim**       |
| C10 | `classifica_viagem(arad,buc,T).`  | regra c/ várias condições    | **sim**       |
| C11 | `caminho(arad,bucareste,C).`      | busca **DFS**                | **sim**       |
| C12 | `bfs(arad,bucareste,C).`          | busca **BFS**                | **sim**       |
| C13 | `astar(arad,bucareste,C,Custo).`  | busca **A\***                | **sim**       |

> São **10 consultas com variáveis** (muito acima das 3 exigidas) e **2 regras
> recursivas** demonstradas (C7 e C8).

---

## C1 — Verificação de fato (sem variável)

**Pergunta:** "Arad é uma cidade?"

```prolog
?- cidade(arad).
true.
```

Prolog procura o fato `cidade(arad).` na base; encontra → responde `true`. É uma
consulta de **lógica proposicional** (proposição fechada, sem variáveis).

---

## C2 — Fato com variável

**Pergunta:** "Qual a distância da estrada Arad–Sibiu?"

```prolog
?- estrada(arad, sibiu, D).
D = 140.
```

`D` é uma variável. Por **unificação**, Prolog casa `estrada(arad,sibiu,D)` com o fato
`estrada(arad,sibiu,140)` e liga `D = 140`.

---

## C3 — Regra `conectado/3` (bidirecionalidade)

**Pergunta:** "Sibiu está conectada a Arad? A que distância?"

```prolog
?- conectado(sibiu, arad, D).
D = 140.
```

A base só declara `estrada(arad,sibiu,140)` (sentido Arad→Sibiu). A consulta no
sentido inverso **só funciona por causa da 2ª cláusula** da regra:
`conectado(A,B,D) :- estrada(B,A,D).` Mostra inferência, não só lookup de fato.

---

## C4 — `vizinho/2` com múltiplas soluções (variável)

**Pergunta:** "Quais são as cidades vizinhas de Arad?"

Coletando todas as soluções com `findall/3`:

```prolog
?- findall(V, vizinho(arad, V), Vs).
Vs = [zerind, sibiu, timisoara].
```

Arad tem 3 estradas. No prompt interativo, digitar `;` após cada resposta gera
`V = zerind`, depois `V = sibiu`, depois `V = timisoara` (isso é **backtracking**).

---

## C5 — `cidade_fronteira/1` (regra com várias condições + agregação)

**Pergunta:** "Quais cidades são 'becos sem saída' (têm só uma estrada)?"

```prolog
?- findall(X, cidade_fronteira(X), Fs).
Fs = [giurgiu, eforie, neamt].
```

A regra tem **3 condições**: ser cidade, coletar os vizinhos (`findall`) e ter
exatamente 1 (`length(Vs,1)`). Giurgiu, Eforie e Neamt são as três pontas do mapa.

---

## C6 — `rota_direta/2` (regra com várias condições, dá falso)

**Pergunta:** "Existe estrada direta de Arad até Bucareste?"

```prolog
?- rota_direta(arad, bucareste).
false.
```

Não há estrada direta Arad–Bucareste, então a 4ª condição (`conectado(A,B,_)`) falha
e a regra inteira falha. Exemplo de consulta que resulta em **`false`** — útil para
mostrar que o sistema não "inventa" respostas.

---

## C7 — `alcancavel/2` (REGRA RECURSIVA)

**Pergunta:** "É possível chegar de Arad a Bucareste passando por estradas?"

```prolog
?- alcancavel(arad, bucareste).
true.
```

`alcancavel/2` é a **regra recursiva** exigida pelo trabalho: o caso base é a conexão
direta; o caso recursivo viaja até um intermediário `M` ainda não visitado e chama a si
mesma. A lista de visitadas evita ciclos infinitos. Mesmo sem estrada direta (ver C6),
existe um *caminho* → `true`.

---

## C8 — `distancia_rota/2` (REGRA RECURSIVA, com variável)

**Pergunta:** "Qual a distância total da rota Arad→Sibiu→Rimnicu→Pitesti→Bucareste?"

```prolog
?- distancia_rota([arad, sibiu, rimnicu, pitesti, bucareste], D).
D = 418.
```

Soma recursiva das estradas: 140 + 80 + 97 + 101 = **418 km**. O caso base
`distancia_rota([_], 0)` para a recursão ao sobrar uma só cidade.

---

## C9 — `melhor_rota/4` (combina findall + busca, com variáveis)

**Pergunta:** "Qual a rota de menor distância entre Arad e Bucareste?"

```prolog
?- melhor_rota(arad, bucareste, R, D).
R = [arad, sibiu, rimnicu, pitesti, bucareste],
D = 418.
```

Gera **todas** as rotas (via `caminho/3`), calcula a distância de cada uma e usa
`keysort` para pegar a menor. Confirma o resultado clássico do livro: **418 km**.

---

## C10 — `classifica_viagem/3` (regra com várias condições, variável)

**Pergunta:** "A viagem Arad→Bucareste é curta, média ou longa?"

```prolog
?- classifica_viagem(arad, bucareste, T).
T = longa.
```

Como a melhor rota tem 418 km (> 300), classifica como `longa`. Demonstra regras com
condições numéricas e comparações (`<`, `>=`, `=<`, `>`).

---

## C11 — Busca em PROFUNDIDADE (DFS), com variável

**Pergunta:** "Ache *um* caminho de Arad a Bucareste (DFS)."

```prolog
?- caminho(arad, bucareste, C).
C = [arad, zerind, oradea, sibiu, fagaras, bucareste].
```

A DFS usa a **pilha implícita** do backtracking do Prolog. Acha o primeiro caminho
seguindo a ordem das estradas — **não** o mais curto.

A versão `caminho/4` devolve também o **custo em km** (soma das estradas via
`distancia_rota/2`), para comparar com a A\*:

```prolog
?- caminho(arad, bucareste, C, Custo).
C = [arad, zerind, oradea, sibiu, fagaras, bucareste],
Custo = 607.
```

---

## C12 — Busca em LARGURA (BFS), com variável

**Pergunta:** "Ache o caminho com MENOS cidades de Arad a Bucareste (BFS)."

```prolog
?- bfs(arad, bucareste, C).
C = [arad, sibiu, fagaras, bucareste].
```

A BFS usa uma **fila (FIFO)** e expande por níveis → encontra a rota com **menor número
de saltos** (3 estradas). A versão `bfs/4` mostra o **custo em km** dessa rota:

```prolog
?- bfs(arad, bucareste, C, Custo).
C = [arad, sibiu, fagaras, bucareste],
Custo = 450.
```

Menos cidades, mas **não** a mais curta em km (450 > 418 da A\*): a BFS minimiza
número de saltos, não distância.

---

## C13 — Busca A\* (informada, ótima), com variáveis

**Pergunta:** "Ache a rota de MENOR DISTÂNCIA em km de Arad a Bucareste (A\*)."

```prolog
?- astar(arad, bucareste, C, Custo).
C = [arad, sibiu, rimnicu, pitesti, bucareste],
Custo = 418.
```

A\* ordena a fronteira por `f(n) = g(n) + h(n)`. Com a heurística admissível `h/2`
(linha reta até Bucareste), é **completa e ótima**: devolve a rota mais curta, **418 km** —
exatamente o resultado de Russell & Norvig.

---

## Comparação dos três algoritmos (mesma origem e destino)

| Algoritmo | Rota encontrada                                   | Cidades | Distância | Característica            |
|-----------|---------------------------------------------------|:-------:|:---------:|--------------------------|
| **DFS**   | arad→zerind→oradea→sibiu→fagaras→bucareste         | 6       | 607 km    | rápida, **não ótima**    |
| **BFS**   | arad→sibiu→fagaras→bucareste                       | 4       | 450 km    | **menos saltos**         |
| **A\***   | arad→sibiu→rimnicu→pitesti→bucareste               | 5       | **418 km**| **ótima** (menor km)     |

> Conclusão prática: a rota mais curta em km (A\*) **não** é a com menos cidades (BFS),
> e a DFS pode achar uma rota bem pior. Isso justifica usar busca informada (A\*) quando
> o custo importa — discussão central do cap. 3 do Russell & Norvig.

---

## Unificação e Backtracking (exigência §7.4)

**Unificação** é o mecanismo que casa dois termos, ligando variáveis a valores. Na
consulta C2, `estrada(arad,sibiu,D)` unifica com o fato `estrada(arad,sibiu,140)`:
os átomos `arad` e `sibiu` casam diretamente e a variável `D` se liga a `140`.

**Backtracking** é a volta automática do Prolog quando uma escolha não leva à solução
(ou quando pedimos *mais* soluções com `;`). Exemplo concreto em C4:

```prolog
?- vizinho(arad, V).
V = zerind ;     % 1ª solução  (estrada arad–zerind)
V = sibiu ;      % backtrack -> tenta a próxima estrada
V = timisoara.   % backtrack -> última estrada; não há mais → fim
```

Na busca DFS (C11) o backtracking é o coração do algoritmo: ao chegar num beco sem
saída, o Prolog **desfaz** a última cidade escolhida e tenta outra estrada — exatamente
o comportamento de "voltar e tentar outro ramo" da busca em profundidade.

Um exemplo de **Modus Ponens** (inferência) aparece em C3: temos a regra
`conectado(A,B,D) :- estrada(B,A,D)` e o fato `estrada(arad,sibiu,140)`. Unificando
`B=sibiu, A=arad, D=140`, a premissa da regra é satisfeita, logo Prolog **deduz** a
conclusão `conectado(sibiu,arad,140)` — uma proposição que não estava escrita
explicitamente na base.
