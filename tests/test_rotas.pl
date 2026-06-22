% =====================================================================
%  TESTES DA BASE DE CONHECIMENTO  (rotas.pl)
%  Framework: plunit (nativo do SWI-Prolog)  ->  library(plunit)
%
%  Como rodar (a partir da raiz do projeto):
%      swipl -g run_tests -t halt tests/test_rotas.pl
%  ou usar o runner:
%      swipl run_tests.pl
%
%  Cada teste abaixo verifica um FATO ou uma REGRA especifica de rotas.pl.
%  Convencoes de plunit usadas:
%    - test(nome) :- Meta.           -> passa se Meta for verdadeira
%    - test(nome, [fail]) :- Meta.   -> passa se Meta FALHAR (caso negativo)
%    - test(nome, forall(Gerador))   -> roda o corpo para CADA solucao do gerador
%
%  Nota: usamos once/1 em metas que deixam "ponto de escolha" (ex.: conectado/3
%  tem 2 clausulas). Isso torna o teste deterministico e evita o aviso
%  "Test succeeded with choicepoint" do plunit, sem mudar o significado:
%  so nos importa que EXISTA pelo menos uma solucao.
% =====================================================================

% Carrega a base sob teste. Usamos busca.pl porque as regras melhor_rota/4 e
% classifica_viagem/3 (de rotas.pl) dependem de caminho/3, definido em busca.pl.
% busca.pl ja carrega rotas.pl internamente (ensure_loaded(rotas)).
:- ensure_loaded('../busca').

% library(lists) explicito (sort/2, length/2 sao built-in; member/2 nao).
:- use_module(library(lists)).

:- begin_tests(rotas).

% ---------------------------------------------------------------------
% (A) FATOS  -  contagem e existencia
% ---------------------------------------------------------------------

% Devem existir exatamente 20 cidades (conforme declaradas em rotas.pl).
test(total_de_cidades_eh_20) :-
    findall(C, cidade(C), Cidades),
    length(Cidades, 20).

% Devem existir exatamente 23 estradas declaradas (uma direcao cada).
test(total_de_estradas_eh_23) :-
    findall(e(A,B,D), estrada(A,B,D), Estradas),
    length(Estradas, 23).

% Cidade que existe e cidade que NAO existe (caso negativo).
test(arad_eh_cidade) :- cidade(arad).
test(paris_nao_eh_cidade, [fail]) :- cidade(paris).

% A heuristica do objetivo deve ser zero (h(bucareste,0)) e haver 20 valores h/2.
test(heuristica_de_bucareste_eh_zero) :- h(bucareste, 0).
test(existe_heuristica_para_todas_cidades) :-
    findall(C, h(C, _), ComH),
    length(ComH, 20).

% ---------------------------------------------------------------------
% (B) REGRA 1: conectado/3  (bidirecional)
% ---------------------------------------------------------------------

% Existe estrada declarada arad->zerind; conectado deve valer nos DOIS sentidos.
test(conectado_sentido_declarado) :- once(conectado(arad, zerind, 75)).
test(conectado_sentido_inverso)   :- once(conectado(zerind, arad, 75)).

% Propriedade geral: para TODA estrada(A,B,D), conectado vale A->B e B->A.
test(conectado_eh_bidirecional, forall(estrada(A, B, D))) :-
    once(conectado(A, B, D)),
    once(conectado(B, A, D)).

% ---------------------------------------------------------------------
% (C) REGRA 2: vizinho/2
% ---------------------------------------------------------------------

% Vizinhos de arad sao exatamente sibiu, timisoara e zerind.
test(vizinhos_de_arad) :-
    findall(V, vizinho(arad, V), Vs),
    sort(Vs, Ordenados),
    Ordenados == [sibiu, timisoara, zerind].

% ---------------------------------------------------------------------
% (D) REGRA 3: cidade_fronteira/1  (becos = grau 1)
% ---------------------------------------------------------------------

% Apenas giurgiu, eforie e neamt tem exatamente UMA estrada (sao becos).
test(cidades_fronteira) :-
    findall(X, cidade_fronteira(X), Fronteiras),
    sort(Fronteiras, Ordenadas),
    Ordenadas == [eforie, giurgiu, neamt].

% ---------------------------------------------------------------------
% (E) REGRA 4: rota_direta/2  (mesma cidade falha; sem estrada falha)
% ---------------------------------------------------------------------

test(rota_direta_valida)            :- once(rota_direta(arad, sibiu)).
test(rota_direta_mesma_cidade_falha, [fail]) :- rota_direta(arad, arad).
test(rota_direta_sem_estrada_falha,  [fail]) :- rota_direta(arad, bucareste).

% ---------------------------------------------------------------------
% (F) REGRA 5: alcancavel/2  (recursiva, com controle de ciclo)
% ---------------------------------------------------------------------

% Tudo no grafo da Romenia eh conexo: arad alcanca destino distante (eforie).
test(alcancavel_destino_distante) :- once(alcancavel(arad, eforie)).
test(alcancavel_vizinho_direto)   :- once(alcancavel(arad, sibiu)).

% ---------------------------------------------------------------------
% (G) REGRA 6: distancia_rota/2  (recursiva, soma das estradas)
% ---------------------------------------------------------------------

test(distancia_rota_de_um_no_eh_zero) :-
    once(distancia_rota([arad], D)), D =:= 0.

test(distancia_rota_de_dois_nos) :-
    once(distancia_rota([arad, sibiu], D)), D =:= 140.

test(distancia_rota_de_tres_nos) :-
    once(distancia_rota([arad, sibiu, rimnicu], D)), D =:= 220.   % 140 + 80

% ---------------------------------------------------------------------
% (H) REGRA 7: melhor_rota/4  (depende de caminho/3 em busca.pl)
% ---------------------------------------------------------------------

% Resultado classico de Russell & Norvig: arad -> bucareste = 418 km.
test(melhor_rota_arad_bucareste) :-
    melhor_rota(arad, bucareste, Rota, Dist),
    Dist =:= 418,
    Rota == [arad, sibiu, rimnicu, pitesti, bucareste].

% ---------------------------------------------------------------------
% (I) REGRA 8: classifica_viagem/3  (curta < 150 <= media <= 300 < longa)
% ---------------------------------------------------------------------

test(viagem_curta) :- once(classifica_viagem(arad, zerind,    curta)).  % 75 km
test(viagem_media) :- once(classifica_viagem(arad, rimnicu,   media)).  % 220 km
test(viagem_longa) :- once(classifica_viagem(arad, bucareste, longa)).  % 418 km

:- end_tests(rotas).
