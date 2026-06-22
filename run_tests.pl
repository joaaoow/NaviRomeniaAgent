% =====================================================================
%  RUNNER DE TESTES  -  Trabalho Final de IA I (mapa da Romenia)
%
%  Carrega os dois suites plunit e roda TODOS os testes de uma vez.
%
%  Uso (a partir da raiz do projeto):
%      swipl run_tests.pl
%
%  Sai com codigo 0 se TODOS os testes passarem; 1 se algum falhar
%  (util para integracao continua / scripts).
% =====================================================================

:- use_module(library(plunit)).

% Carrega os suites. Cada um carrega a base de conhecimento de que precisa.
:- ['tests/test_rotas'].
:- ['tests/test_busca'].

% Roda tudo e encerra com o codigo de saida apropriado.
% initialization/2 com 'main' eh a forma recomendada de ponto de entrada.
:- initialization((run_tests -> halt(0) ; halt(1)), main).
