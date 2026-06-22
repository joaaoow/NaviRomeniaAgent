% =====================================================================
%  TESTES DOS ALGORITMOS DE BUSCA  (busca.pl)
%  Framework: plunit (nativo do SWI-Prolog)
%
%  Como rodar (a partir da raiz do projeto):
%      swipl -g run_tests -t halt tests/test_busca.pl
%  ou usar o runner:  swipl run_tests.pl
%
%  Cobre: caminho/3 (DFS), bfs/3 (BFS) e astar/4 (A*), incluindo testes de
%  PROPRIEDADE que ligam a implementacao a teoria (Russell & Norvig, cap. 3):
%    - A* eh OTIMO  : custo encontrado == minimo sobre todos os caminhos
%    - h/2 eh ADMISSIVEL : h(C) nunca superestima o custo real ate bucareste
%
%  Nota: once/1 e usado em metas que deixam ponto de escolha (DFS/BFS geram
%  varias solucoes por backtracking) para tornar o teste deterministico.
% =====================================================================

% busca.pl carrega rotas.pl automaticamente.
:- ensure_loaded('../busca').

% library(lists) explicito: last/2, min_list/2, member/2, append/3.
:- use_module(library(lists)).

:- begin_tests(busca).

% ---------------------------------------------------------------------
% Helper de validacao: um caminho eh valido se cada par consecutivo de
% cidades estiver conectado por uma estrada (reaproveita conectado/3).
% ---------------------------------------------------------------------
caminho_valido([_]).
caminho_valido([A, B | Resto]) :-
    conectado(A, B, _),
    caminho_valido([B | Resto]).

% =====================================================================
% (1) DFS  -  caminho/3
% =====================================================================

% DFS deve achar UM caminho valido que comeca em arad e termina em bucareste.
test(dfs_encontra_caminho_valido) :-
    once(caminho(arad, bucareste, C)),
    C = [arad | _],
    last(C, bucareste),
    once(caminho_valido(C)).

% Caso trivial: caminho de uma cidade vizinha direta.
test(dfs_vizinho_direto) :-
    once(caminho(arad, zerind, C)),
    C == [arad, zerind].

% Documenta a 1a solucao do DFS (depende da ORDEM das clausulas estrada/3):
% arad -> zerind -> oradea -> sibiu -> fagaras -> bucareste.
% (Mostra o comportamento "vai fundo no 1o ramo" caracteristico da DFS.)
test(dfs_primeira_solucao_documentada) :-
    once(caminho(arad, bucareste, C)),
    C == [arad, zerind, oradea, sibiu, fagaras, bucareste].

% DFS eh COMPLETA neste grafo finito: existe ao menos uma solucao.
test(dfs_completa) :-
    once(caminho(arad, eforie, _)).

% =====================================================================
% (2) BFS  -  bfs/3   (menor numero de cidades)
% =====================================================================

% BFS retorna a rota com MENOS cidades: arad-sibiu-fagaras-bucareste (4 cidades).
test(bfs_menor_numero_de_cidades) :-
    once(bfs(arad, bucareste, C)),
    C == [arad, sibiu, fagaras, bucareste],
    length(C, 4),
    once(caminho_valido(C)).

% Vizinho direto: BFS acha o caminho de 2 cidades imediatamente.
test(bfs_vizinho_direto) :-
    once(bfs(arad, sibiu, C)),
    C == [arad, sibiu].

% =====================================================================
% (3) A*  -  astar/4   (otimo em km)
% =====================================================================

% Resultado classico de Russell & Norvig: rota OTIMA arad -> bucareste = 418 km.
test(astar_rota_otima_arad_bucareste) :-
    astar(arad, bucareste, C, Custo),
    Custo =:= 418,
    C == [arad, sibiu, rimnicu, pitesti, bucareste],
    once(caminho_valido(C)).

% A* para um destino do outro extremo do mapa (eforie): deve achar custo otimo.
test(astar_destino_distante) :-
    astar(arad, eforie, C, Custo),
    C = [arad | _],
    last(C, eforie),
    once(caminho_valido(C)),
    Custo > 0.

% =====================================================================
% (4) TESTES DE PROPRIEDADE  (ligacao com a teoria)
% =====================================================================

% PROPRIEDADE 1 - A* eh OTIMO: para varios destinos, o custo do A* deve ser
% igual ao MINIMO da distancia entre TODOS os caminhos possiveis (via DFS).
test(astar_eh_otimo, forall(member(Fim, [bucareste, eforie, neamt, craiova]))) :-
    astar(arad, Fim, _, CustoAstar),
    findall(D, ( caminho(arad, Fim, R), distancia_rota(R, D) ), Distancias),
    min_list(Distancias, Minimo),
    CustoAstar =:= Minimo.

% PROPRIEDADE 2 - heuristica ADMISSIVEL: h(C) nunca superestima o custo real
% de C ate bucareste (condicao que garante a otimalidade do A*).
test(heuristica_eh_admissivel, forall(cidade(C))) :-
    h(C, HC),
    ( astar(C, bucareste, _, CustoReal)
    -> HC =< CustoReal
    ;  true ).   % se nao ha caminho (nao ocorre aqui), nada a verificar

% PROPRIEDADE 3 - comparacao A* vs BFS: BFS minimiza NUMERO de cidades, nao km.
% Logo o custo em km do A* (otimo) deve ser <= custo em km da rota da BFS.
% (arad->bucareste: A* = 418 km;  BFS = 140+99+211 = 450 km.)
test(astar_nao_pior_que_bfs_em_km) :-
    astar(arad, bucareste, _, CustoAstar),
    once(bfs(arad, bucareste, RotaBfs)),
    once(distancia_rota(RotaBfs, CustoBfs)),
    CustoAstar =< CustoBfs.

% PROPRIEDADE 4 - consistencia entre metodos: o custo do A* deve bater com a
% distancia da melhor_rota/4 (que usa DFS + ordenacao por distancia).
test(astar_concorda_com_melhor_rota) :-
    astar(arad, bucareste, _, CustoAstar),
    melhor_rota(arad, bucareste, _, DistMelhor),
    CustoAstar =:= DistMelhor.

:- end_tests(busca).
