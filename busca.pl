% =====================================================================
%  BUSCA EM ESPACO DE ESTADOS  -  Mapa da Romenia
%  Trabalho Final de Inteligencia Artificial I  -  UCB
%  Algoritmos: DFS (profundidade), BFS (largura) e A*
% =====================================================================
%
%  Este arquivo depende da base de conhecimento em rotas.pl:
%    - conectado/3  (estradas bidirecionais com distancia)
%    - h/2          (heuristica: distancia em linha reta ate bucareste)
%
%  Como carregar (carrega rotas.pl junto, ver :- use abaixo):
%      swipl busca.pl
%
%  MODELAGEM DO PROBLEMA DE BUSCA (Russell & Norvig, cap. 3):
%    - Estado            : uma cidade (ex.: arad)
%    - Estado inicial    : cidade de partida passada na consulta
%    - Estado objetivo   : cidade de destino passada na consulta
%    - Operadores/acoes  : "ir para cidade vizinha" via conectado/3
%    - Representacao      : lista de cidades visitadas = o caminho
%    - Criterio de parada: cidade atual == cidade objetivo
%    - Custo de passo    : distancia em km da estrada (conectado/3)
% =====================================================================

% Carrega a base de conhecimento (fatos e regras) deste mesmo diretorio.
% (rotas.pl tambem faz ensure_loaded(busca); a carga mutua e segura porque
%  ensure_loaded nao recarrega arquivo ja carregado.)
:- ensure_loaded(rotas).

% Importa explicitamente library(lists) para reverse/2, member/2 e append/3.
% Garante o funcionamento mesmo com autoload desligado (portabilidade entre
% maquinas: ver doc SWI sobre autoload e 'swipl --no-autoload').
:- use_module(library(lists)).


% ---------------------------------------------------------------------
% (1) BUSCA EM PROFUNDIDADE  -  DFS  (Depth-First Search)
% ---------------------------------------------------------------------
% Estrutura de dados: a PILHA implicita da recursao do Prolog (backtracking).
% Estrategia: vai fundo em um ramo ate o objetivo ou um beco; entao volta
%             (backtrack) e tenta outro vizinho.
% A lista 'Visitadas' (em ordem reversa) evita ciclos infinitos.
%
% caminho/3 eh o predicado-chave: tambem usado por melhor_rota/4 em rotas.pl.

caminho(Inicio, Fim, Caminho) :-
    dfs(Inicio, Fim, [Inicio], CaminhoRev),
    reverse(CaminhoRev, Caminho).

% caso base: cheguei ao destino -> o caminho acumulado eh a resposta.
dfs(Fim, Fim, Visitadas, Visitadas).

% caso recursivo: vou para um vizinho 'Prox' ainda nao visitado.
dfs(Atual, Fim, Visitadas, Caminho) :-
    Atual \== Fim,
    conectado(Atual, Prox, _),
    \+ member(Prox, Visitadas),
    dfs(Prox, Fim, [Prox | Visitadas], Caminho).


% ---------------------------------------------------------------------
% (2) BUSCA EM LARGURA  -  BFS  (Breadth-First Search)
% ---------------------------------------------------------------------
% Estrutura de dados: FILA (FIFO) de caminhos parciais.
% Estrategia: expande todos os caminhos de comprimento N antes dos de N+1.
%             => encontra primeiro a rota com MENOR NUMERO DE CIDADES.
% Caminhos sao guardados em ordem reversa (cabeca = cidade atual).

bfs(Inicio, Fim, Caminho) :-
    bfs_fila([[Inicio]], Fim, CaminhoRev),
    reverse(CaminhoRev, Caminho).

% Se o primeiro caminho da fila ja termina no objetivo, achamos.
bfs_fila([[Fim | T] | _], Fim, [Fim | T]).

% Senao: retira o 1o caminho, gera as expansoes e poe no FIM da fila.
bfs_fila([[Atual | T] | Resto], Fim, Caminho) :-
    Atual \== Fim,
    findall([Prox, Atual | T],
            ( conectado(Atual, Prox, _),
              \+ member(Prox, [Atual | T]) ),
            Expansoes),
    append(Resto, Expansoes, NovaFila),   % append no fim = comportamento FIFO
    bfs_fila(NovaFila, Fim, Caminho).


% ---------------------------------------------------------------------
% (3) BUSCA INFORMADA  -  A*  (A-estrela)
% ---------------------------------------------------------------------
% Estrutura de dados: FRONTEIRA ordenada por f(n) = g(n) + h(n).
%   g(n) = custo real ja percorrido (soma das estradas em km)
%   h(n) = heuristica (linha reta ate bucareste, fato h/2 em rotas.pl)
% Estrategia: sempre expande o no de MENOR f. Com h admissivel (nunca
%             superestima), A* e COMPLETO e OTIMO: acha a rota mais curta em km.
% Cada no da fronteira: no(F, G, CaminhoReverso).

astar(Inicio, Fim, Caminho, Custo) :-
    h(Inicio, H0),
    astar_fronteira([no(H0, 0, [Inicio])], Fim, CaminhoRev, Custo),
    reverse(CaminhoRev, Caminho).

% Objetivo no topo da fronteira (menor f): o custo G eh a distancia otima.
astar_fronteira([no(_, G, [Fim | T]) | _], Fim, [Fim | T], G) :- !.

% Senao: expande o no de menor f, calcula f dos filhos e reordena a fronteira.
astar_fronteira([no(_, G, [Atual | T]) | Resto], Fim, Caminho, Custo) :-
    findall(no(F2, G2, [Prox, Atual | T]),
            ( conectado(Atual, Prox, D),
              \+ member(Prox, [Atual | T]),
              G2 is G + D,
              h(Prox, HP),
              F2 is G2 + HP ),
            Filhos),
    append(Resto, Filhos, Fronteira),
    sort(Fronteira, FronteiraOrd),   % ordena por F (1o arg de no/3) crescente
    astar_fronteira(FronteiraOrd, Fim, Caminho, Custo).
