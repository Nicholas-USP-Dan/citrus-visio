-- ========================================================================================
-- TESTE / VALIDAÇÃO - CitrusVisio Factory
-- ----------------------------------------------------------------------------------------
-- Script auxiliar para conferir, num banco limpo, que esquema + dados foram carregados
-- corretamente e que as 5 consultas retornam os resultados esperados.
--
-- Ordem de execução (banco limpo):
--   1) sql/esquema.sql
--   2) sql/dados.sql
--   3) sql/teste.sql   (este arquivo)
-- ========================================================================================

-- 1) Contagem de tuplas por tabela. Requisito do projeto: >= 2 tuplas por tabela.
SELECT relname AS tabela, n_live_tup AS qtd_tuplas
FROM   pg_stat_user_tables
ORDER  BY relname;

-- 2) Confirma que os IDs gerados (IDENTITY) seguem a ordem esperada (banco limpo):
--    ordem_producao -> 1,2,3 | operacao -> 1,2,3 | lote_produto -> 1,2,3
SELECT 'ordem_producao' AS tabela, array_agg(id ORDER BY id) AS ids FROM ordem_producao
UNION ALL
SELECT 'operacao',       array_agg(id ORDER BY id) FROM operacao
UNION ALL
SELECT 'lote_produto',   array_agg(id ORDER BY id) FROM lote_produto;

-- ----------------------------------------------------------------------------------------
-- Resultados esperados das consultas (conferir contra sql/consultas.sql):
--
-- Consulta 1 (extratora 5): 2 linhas
--   Ordem 1 (Carlos)  -> energético 200.000 | hídrico 80.000 | concluídas 2
--   Ordem 2 (Marina)  -> energético 100.000 | hídrico 40.000 | concluídas 0
--
-- Consulta 2 (resíduo predominante por ordem): 3 linhas
--   Ordem 1 -> BAGACO 572.260   (maior massa)
--   Ordem 2 -> GAS CARBONICO 90.000
--   Ordem 3 -> '-' 0            (ordem sem resíduo registrado)
--
-- Consulta 3 (fornecedores sem alocação): 1 linha
--   Embalagens Sul (22222222000122) -> 2 insumos sem alocação
--
-- Consulta 4 (divisão relacional - comprou todos os tipos): 1 linha
--   Supermercado Bom Preço (33333333000133) -> 'Até R$ 10.000' | 2 compras
--
-- Consulta 5 (custo médio de laranja por gerente): 2 linhas
--   Carlos Gerente -> 8000.000
--   Marina Gerente -> 4000.000
-- ----------------------------------------------------------------------------------------
