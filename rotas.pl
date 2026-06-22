% =====================================================================
%  Este arquivo contem:
%    (A) FATOS  -> conhecimento basico do mundo (cidades, estradas, heuristica)
%    (B) REGRAS -> conhecimento derivado por inferencia (conectividade, rotas)
%  A parte de BUSCA (BFS, DFS, A*) esta no arquivo busca.pl
%
%  Como carregar:   swipl rotas.pl   (ou swipl busca.pl - ambos funcionam)
%  Depois faca consultas, ex.:   ?- cidade(arad).
% =====================================================================

% Importa explicitamente library(lists) para member/2 (usado em alcancavel/2 e
% nas regras). Sem isto, em maquinas com autoload desligado (flag autoload=false
% ou 'swipl --no-autoload') a chamada a member/2 daria "Unknown procedure".
:- use_module(library(lists)).


% ---------------------------------------------------------------------
% (A) FATOS
% ---------------------------------------------------------------------

% --- Fato tipo 1: quais cidades existem (20 cidades) ---------------
% Forma logica:  cidade(arad) significa "arad eh uma cidade" (proposicao verdadeira).
cidade(arad).
cidade(zerind).
cidade(oradea).
cidade(sibiu).
cidade(timisoara).
cidade(lugoj).
cidade(mehadia).
cidade(drobeta).
cidade(craiova).
cidade(rimnicu).
cidade(pitesti).
cidade(fagaras).
cidade(bucareste).
cidade(giurgiu).
cidade(urziceni).
cidade(hirsova).
cidade(eforie).
cidade(vaslui).
cidade(iasi).
cidade(neamt).

% --- Fato tipo 2: estradas e suas distancias reais em km ------------
% estrada(A, B, D) significa "existe estrada direta entre A e B com D km".
% Declaramos cada estrada UMA vez; a regra 'conectado/3' cuida do sentido inverso.
estrada(arad,      zerind,    75).
estrada(arad,      sibiu,     140).
estrada(arad,      timisoara, 118).
estrada(zerind,    oradea,    71).
estrada(oradea,    sibiu,     151).
estrada(sibiu,     fagaras,   99).
estrada(sibiu,     rimnicu,   80).
estrada(timisoara, lugoj,     111).
estrada(lugoj,     mehadia,   70).
estrada(mehadia,   drobeta,   75).
estrada(drobeta,   craiova,   120).
estrada(craiova,   rimnicu,   146).
estrada(craiova,   pitesti,   138).
estrada(rimnicu,   pitesti,   97).
estrada(fagaras,   bucareste, 211).
estrada(pitesti,   bucareste, 101).
estrada(bucareste, giurgiu,   90).
estrada(bucareste, urziceni,  85).
estrada(urziceni,  hirsova,   98).
estrada(hirsova,   eforie,    86).
estrada(urziceni,  vaslui,    142).
estrada(vaslui,    iasi,      92).
estrada(iasi,      neamt,     87).

% --- Fato tipo 3: heuristica (distancia em linha reta ate bucareste) -
% h(Cidade, Valor): estimativa OTIMISTA do quanto falta ate o objetivo.
% Usada pelo A*. Nunca superestima a distancia real => heuristica ADMISSIVEL.
h(arad,      366).
h(zerind,    374).
h(oradea,    380).
h(sibiu,     253).
h(timisoara, 329).
h(lugoj,     244).
h(mehadia,   241).
h(drobeta,   242).
h(craiova,   160).
h(rimnicu,   193).
h(pitesti,   100).
h(fagaras,   176).
h(bucareste, 0).
h(giurgiu,   77).
h(urziceni,  80).
h(hirsova,   151).
h(eforie,    161).
h(vaslui,    199).
h(iasi,      226).
h(neamt,     234).


% ---------------------------------------------------------------------
% (B) REGRAS
% ---------------------------------------------------------------------

% --- Regra 1: conectividade bidirecional (2 condicoes, com OR) -------
% Linguagem natural: "A esta conectada a B (com distancia D) se existe
%                     estrada de A para B OU de B para A".
% Logica:  conectado(A,B,D) <- estrada(A,B,D) v estrada(B,A,D)
conectado(A, B, D) :- estrada(A, B, D).
conectado(A, B, D) :- estrada(B, A, D).

% --- Regra 2: vizinho (esconde a distancia; util para a busca) -------
% "B eh vizinho de A se ha conexao direta entre eles".
vizinho(A, B) :- conectado(A, B, _).

% --- Regra 3: cidade de fronteira (mais de uma condicao) -------------
% "X eh cidade-fronteira se eh uma cidade E tem so UMA estrada (beco)".
% Demonstra regra com varias condicoes e uso de agregacao (findall/length).
cidade_fronteira(X) :-
    cidade(X),
    findall(V, vizinho(X, V), Vizinhos),
    length(Vizinhos, 1).

% --- Regra 4: rota direta possivel (mais de uma condicao) ------------
% "Da para ir direto de A para B se sao cidades diferentes e ha conexao".
rota_direta(A, B) :-
    cidade(A),
    cidade(B),
    A \== B,
    conectado(A, B, _).

% --- Regra 5: ALCANCAVEL (RECURSIVA) --------------------------------
% Linguagem natural: "B eh alcancavel a partir de A se ha estrada direta,
%                     OU se da para chegar a um intermediario M e de M a B".
% Esta eh a regra recursiva exigida pelo trabalho. O 4o argumento (Visitadas)
% evita ciclos infinitos (nao revisitar cidade ja passada).
alcancavel(A, B) :- alcancavel(A, B, [A]).

% caso base: existe conexao direta
alcancavel(A, B, _) :-
    conectado(A, B, _).

% caso recursivo: vai ate um intermediario M ainda nao visitado
alcancavel(A, B, Visitadas) :-
    conectado(A, M, _),
    M \== B,
    \+ member(M, Visitadas),
    alcancavel(M, B, [M | Visitadas]).

% --- Regra 6: distancia de uma rota completa (RECURSIVA) ------------
% "A distancia de uma rota [a,b,c,...] eh a soma das estradas no caminho".
distancia_rota([_], 0).
distancia_rota([A, B | Resto], D) :-
    conectado(A, B, D1),
    distancia_rota([B | Resto], D2),
    D is D1 + D2.

% --- Regra 7: rota mais curta entre A e B (usa findall + busca) ------
% "A melhor rota de A para B eh a de menor distancia entre todas as rotas".
% (depende de caminho/3 definido em busca.pl)
melhor_rota(A, B, Rota, Dist) :-
    findall(D-R, (caminho(A, B, R), distancia_rota(R, D)), Pares),
    keysort(Pares, [Dist-Rota | _]).

% --- Regra 8: classificar tamanho de uma viagem (mais de uma condicao)
% "Uma viagem eh curta (<150km), media (<=300km) ou longa (>300km)".
classifica_viagem(A, B, curta) :- melhor_rota(A, B, _, D), D < 150.
classifica_viagem(A, B, media) :- melhor_rota(A, B, _, D), D >= 150, D =< 300.
classifica_viagem(A, B, longa) :- melhor_rota(A, B, _, D), D > 300.


% ---------------------------------------------------------------------
% CARGA DA BUSCA (robustez de carregamento)
% ---------------------------------------------------------------------
% As regras melhor_rota/4 e classifica_viagem/3 acima dependem de caminho/3,
% que e definido em busca.pl. Carregamos busca.pl aqui para que o projeto
% funcione AO CARREGAR QUALQUER UM DOS DOIS ARQUIVOS (swipl rotas.pl OU
% swipl busca.pl). Isto corrige o erro "Unknown procedure: caminho/3" que
% ocorria quando alguem carregava so o rotas.pl.
%
% ensure_loaded/1 equivale a load_files(_, [if(not_loaded)]): nao recarrega
% arquivo ja carregado. Por isso a dependencia mutua com o ':- ensure_loaded(rotas).'
% no topo de busca.pl NAO causa laco infinito (carrega cada arquivo uma unica vez).
:- ensure_loaded(busca).
