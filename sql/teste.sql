-- TESTES BÁSICOS
-- ----------------------------------------------------------------------------------------
-- Rode depois de esquema.sql e dados.sql.
--
-- Objetivo:
--   Verificar se a base foi alimentada corretamente e explorar dados simples do domínio

-- TESTE 1 - CONTAGEM DE TUPLAS POR TABELA
-- ----------------------------------------------------------------------------------------
-- Verifica se todas as tabelas receberam dados.

WITH contagens AS (
    SELECT 'pessoa_juridica' AS tabela, COUNT(*) AS total FROM pessoa_juridica
    UNION ALL SELECT 'fornecedor', COUNT(*) FROM fornecedor
    UNION ALL SELECT 'cliente', COUNT(*) FROM cliente
    UNION ALL SELECT 'email_fornecedor', COUNT(*) FROM email_fornecedor
    UNION ALL SELECT 'tel_fornecedor', COUNT(*) FROM tel_fornecedor
    UNION ALL SELECT 'email_cliente', COUNT(*) FROM email_cliente
    UNION ALL SELECT 'tel_cliente', COUNT(*) FROM tel_cliente
    UNION ALL SELECT 'funcionario', COUNT(*) FROM funcionario
    UNION ALL SELECT 'gerente', COUNT(*) FROM gerente
    UNION ALL SELECT 'operador', COUNT(*) FROM operador
    UNION ALL SELECT 'representante_comercial', COUNT(*) FROM representante_comercial
    UNION ALL SELECT 'tipo_insumo', COUNT(*) FROM tipo_insumo
    UNION ALL SELECT 'tipo_residuo', COUNT(*) FROM tipo_residuo
    UNION ALL SELECT 'tipo_produto', COUNT(*) FROM tipo_produto
    UNION ALL SELECT 'equipamento', COUNT(*) FROM equipamento
    UNION ALL SELECT 'ordem_producao', COUNT(*) FROM ordem_producao
    UNION ALL SELECT 'insumo', COUNT(*) FROM insumo
    UNION ALL SELECT 'operacao', COUNT(*) FROM operacao
    UNION ALL SELECT 'temperatura', COUNT(*) FROM temperatura
    UNION ALL SELECT 'trabalho', COUNT(*) FROM trabalho
    UNION ALL SELECT 'geracao_residuo', COUNT(*) FROM geracao_residuo
    UNION ALL SELECT 'lote_produto', COUNT(*) FROM lote_produto
    UNION ALL SELECT 'venda', COUNT(*) FROM venda
    UNION ALL SELECT 'eh_vendido', COUNT(*) FROM eh_vendido
)
SELECT
    tabela,
    total,
    CASE
        WHEN total >= 2 THEN 'OK'
        ELSE 'ATENCAO: menos de 2 tuplas'
    END AS situacao
FROM contagens
ORDER BY tabela;


-- TESTE 2 - IDS GERADOS AUTOMATICAMENTE
-- ----------------------------------------------------------------------------------------
-- Confere se as tabelas com GENERATED ALWAYS AS IDENTITY receberam IDs.

SELECT 'ordem_producao' AS tabela, MIN(id) AS menor_id, MAX(id) AS maior_id, COUNT(*) AS total
FROM ordem_producao
UNION ALL
SELECT 'operacao', MIN(id), MAX(id), COUNT(*)
FROM operacao
UNION ALL
SELECT 'lote_produto', MIN(id), MAX(id), COUNT(*)
FROM lote_produto
ORDER BY tabela;

-- TESTE 3 - PESSOAS JURÍDICAS E SEUS PAPÉIS
-- ----------------------------------------------------------------------------------------
-- Mostra quais pessoas jurídicas são fornecedores, clientes ou ambos.
-- Isso testa a ideia de sobreposição na especialização de pessoa jurídica.

SELECT
    pj.cnpj,
    pj.nome_fantasia,
    CASE WHEN f.cnpj IS NOT NULL THEN 'sim' ELSE 'nao' END AS eh_fornecedor,
    CASE WHEN c.cnpj IS NOT NULL THEN 'sim' ELSE 'nao' END AS eh_cliente
FROM pessoa_juridica pj
LEFT JOIN fornecedor f ON f.cnpj = pj.cnpj
LEFT JOIN cliente c ON c.cnpj = pj.cnpj
ORDER BY pj.nome_fantasia;



-- TESTE 4 - FUNCIONÁRIOS E ESPECIALIZAÇÕES
-- ----------------------------------------------------------------------------------------
-- Confere se o cargo do funcionário bate com sua tabela especializada.
-- Ajuda a verificar gerente, operador e representante comercial.

SELECT
    f.num_funcional,
    f.nome,
    f.cargo,
    CASE
        WHEN f.cargo = 'gerente'
             AND g.num_funcional IS NOT NULL
             AND o.num_funcional IS NULL
             AND r.num_funcional IS NULL
            THEN 'OK'

        WHEN f.cargo = 'operador'
             AND o.num_funcional IS NOT NULL
             AND g.num_funcional IS NULL
             AND r.num_funcional IS NULL
            THEN 'OK'

        WHEN f.cargo = 'representante'
             AND r.num_funcional IS NOT NULL
             AND g.num_funcional IS NULL
             AND o.num_funcional IS NULL
            THEN 'OK'

        ELSE 'ATENCAO: cargo nao bate com especializacao'
    END AS situacao
FROM funcionario f
LEFT JOIN gerente g ON g.num_funcional = f.num_funcional
LEFT JOIN operador o ON o.num_funcional = f.num_funcional
LEFT JOIN representante_comercial r ON r.num_funcional = f.num_funcional
ORDER BY f.num_funcional;



-- TESTE 5 - INSUMOS E RASTREABILIDADE
-- ----------------------------------------------------------------------------------------
-- Mostra a origem dos insumos e, quando houver, em qual ordem de produção foram usados.
-- Esse teste acompanha o caminho fornecedor -> insumo -> ordem -> gerente.

SELECT
    i.nota_fiscal,
    pj.nome_fantasia AS fornecedor,
    i.tipo_insumo,
    i.quantidade,
    i.custo,
    i.data_aquisicao,
    i.ordem_producao,
    f.nome AS gerente_responsavel
FROM insumo i
JOIN pessoa_juridica pj ON pj.cnpj = i.cnpj_fornecedor
LEFT JOIN ordem_producao op ON op.id = i.ordem_producao
LEFT JOIN funcionario f ON f.num_funcional = op.gerente
ORDER BY i.data_aquisicao, i.nota_fiscal;


-- TESTE 6 - INSUMOS EM ESTOQUE SEM ALOCAÇÃO
-- ----------------------------------------------------------------------------------------
-- Lista insumos comprados, mas ainda não vinculados a uma ordem de produção.
-- Útil para visualizar estoque de matéria-prima/embalagem ainda armazenado.

SELECT
    i.tipo_insumo,
    COUNT(*) AS total_notas,
    SUM(i.quantidade) AS quantidade_total,
    SUM(i.custo) AS custo_total
FROM insumo i
WHERE i.ordem_producao IS NULL
GROUP BY i.tipo_insumo
ORDER BY custo_total DESC;



-- TESTE 7 - OPERAÇÕES POR ORDEM DE PRODUÇÃO
-- ----------------------------------------------------------------------------------------
-- Mostra a sequência de operações de cada ordem.
-- Ajuda a enxergar o fluxo produtivo: extração, filtragem, pasteurização, envase etc.

SELECT
    op.id AS id_ordem,
    f.nome AS gerente,
    o.id AS id_operacao,
    o.nome AS operacao,
    o.tipo_equip,
    o.num_equip,
    o.status,
    o.data_hora_inicio,
    o.data_hora_fim
FROM ordem_producao op
JOIN funcionario f ON f.num_funcional = op.gerente
JOIN operacao o ON o.ord_prod = op.id
ORDER BY op.id, o.data_hora_inicio;



-- TESTE 8 - RESUMO DE GASTO POR ORDEM
-- ----------------------------------------------------------------------------------------
-- Soma gasto hídrico e energético de cada ordem.
-- É uma visão simples para verificar os dados de produção.

SELECT
    op.id AS id_ordem,
    f.nome AS gerente,
    COUNT(o.id) AS total_operacoes,
    SUM(o.gasto_hidrico) AS gasto_hidrico_total,
    SUM(o.gasto_energetico) AS gasto_energetico_total
FROM ordem_producao op
JOIN funcionario f ON f.num_funcional = op.gerente
LEFT JOIN operacao o ON o.ord_prod = op.id
GROUP BY op.id, f.nome
ORDER BY op.id;



-- TESTE 9 - TEMPERATURA POR OPERAÇÃO
-- ----------------------------------------------------------------------------------------
-- Verifica se há medições de temperatura associadas às operações.


SELECT
    o.id AS id_operacao,
    o.nome AS operacao,
    o.tipo_equip,
    o.num_equip,
    COUNT(t.data_hora) AS total_medicoes,
    MIN(t.graus_celsius) AS menor_temperatura,
    ROUND(AVG(t.graus_celsius), 2) AS temperatura_media,
    MAX(t.graus_celsius) AS maior_temperatura
FROM operacao o
LEFT JOIN temperatura t ON t.operacao = o.id
GROUP BY o.id, o.nome, o.tipo_equip, o.num_equip
ORDER BY o.id;



-- TESTE 10 - OPERADORES POR OPERAÇÃO
-- ----------------------------------------------------------------------------------------
-- Mostra quais operadores trabalharam em cada operação e em qual turno.

SELECT
    o.id AS id_operacao,
    o.nome AS operacao,
    COUNT(t.operador) AS total_operadores,
    COALESCE(
        STRING_AGG(f.nome || ' (' || t.turno || ')', ', ' ORDER BY f.nome),
        '-'
    ) AS operadores
FROM operacao o
LEFT JOIN trabalho t ON t.operacao = o.id
LEFT JOIN funcionario f ON f.num_funcional = t.operador
GROUP BY o.id, o.nome
ORDER BY o.id;



-- TESTE 11 - RESÍDUOS GERADOS POR ORDEM
-- ----------------------------------------------------------------------------------------
-- Lista os resíduos registrados por ordem de produção.
-- É uma visão simples para controle ambiental/sustentabilidade.

SELECT
    op.id AS id_ordem,
    f.nome AS gerente,
    gr.tipo_residuo,
    gr.massa_total,
    gr.destino,
    COALESCE(gr.intermediario, '-') AS intermediario
FROM ordem_producao op
JOIN funcionario f ON f.num_funcional = op.gerente
LEFT JOIN geracao_residuo gr ON gr.ordem_prod = op.id
ORDER BY op.id, gr.massa_total DESC NULLS LAST;



-- TESTE 12 - ESTOQUE DE LOTES POR TIPO DE PRODUTO
-- ----------------------------------------------------------------------------------------
-- Compara o catálogo de tipo_produto com os lotes produzidos.
-- Ajuda a visualizar unidades prontas, vencidas e contaminadas.

SELECT
    tp.tipo AS tipo_produto,
    tp.qtd_estoque AS estoque_no_catalogo,
    COALESCE(SUM(lp.unidades_restantes) FILTER (WHERE lp.status = 'PRONTO'), 0) AS unidades_prontas,
    COALESCE(SUM(lp.unidades_restantes) FILTER (WHERE lp.status = 'VENCIDO'), 0) AS unidades_vencidas,
    COALESCE(SUM(lp.unidades_restantes) FILTER (WHERE lp.status = 'CONTAMINADO'), 0) AS unidades_contaminadas,
    COUNT(lp.id) AS total_lotes
FROM tipo_produto tp
LEFT JOIN lote_produto lp ON lp.tipo_produto = tp.tipo
GROUP BY tp.tipo, tp.qtd_estoque
ORDER BY tp.tipo;



-- TESTE 13 - DETALHAMENTO DAS VENDAS
-- ----------------------------------------------------------------------------------------
-- Mostra cliente, representante, valor da venda e total de unidades vendidas.

SELECT
    v.data,
    v.nota_fiscal,
    pj.nome_fantasia AS cliente,
    f.nome AS representante,
    v.valor,
    SUM(ev.unidades) AS unidades_vendidas,
    COUNT(DISTINCT lp.tipo_produto) AS tipos_de_produto_na_venda
FROM venda v
JOIN pessoa_juridica pj ON pj.cnpj = v.cliente
JOIN funcionario f ON f.num_funcional = v.representante
JOIN eh_vendido ev ON ev.nf_venda = v.nota_fiscal
JOIN lote_produto lp ON lp.id = ev.id_lote
GROUP BY v.data, v.nota_fiscal, pj.nome_fantasia, f.nome, v.valor
ORDER BY v.data, v.nota_fiscal;


-- TESTE 14 - CONFERÊNCIA DO VALOR DAS VENDAS
-- ----------------------------------------------------------------------------------------
-- Calcula o valor esperado da venda com base em:
--   unidades vendidas * preço do tipo de produto.
--
-- A diferença deve ser 0 se os dados estiverem coerentes.

SELECT
    v.nota_fiscal,
    pj.nome_fantasia AS cliente,
    v.valor AS valor_registrado,
    SUM(ev.unidades * tp.preco) AS valor_calculado,
    ROUND(v.valor - SUM(ev.unidades * tp.preco), 3) AS diferenca
FROM venda v
JOIN pessoa_juridica pj ON pj.cnpj = v.cliente
JOIN eh_vendido ev ON ev.nf_venda = v.nota_fiscal
JOIN lote_produto lp ON lp.id = ev.id_lote
JOIN tipo_produto tp ON tp.tipo = lp.tipo_produto
GROUP BY v.nota_fiscal, pj.nome_fantasia, v.valor
ORDER BY v.nota_fiscal;


-- TESTE 15 - LOTES VENDIDOS COM STATUS NÃO PRONTO
-- ----------------------------------------------------------------------------------------
-- Pela regra de negócio, só lotes PRONTO deveriam ser vendidos.
-- O ideal é esta consulta retornar 0 linhas.

SELECT
    lp.id AS id_lote,
    lp.tipo_produto,
    lp.status,
    ev.nf_venda,
    ev.unidades
FROM lote_produto lp
JOIN eh_vendido ev ON ev.id_lote = lp.id
WHERE lp.status <> 'PRONTO'
ORDER BY lp.id;


-- TESTE 16 - CONFERÊNCIA DE UNIDADES RESTANTES
-- ----------------------------------------------------------------------------------------
-- Verifica se:
--   unidades_restantes = unidades_produzidas - unidades_vendidas
--
-- Com os dados atuais, isso deve bater.
-- Em um sistema real, poderia haver perdas, vencimento ou contaminação alterando esse cálculo.

SELECT
    lp.id AS id_lote,
    lp.tipo_produto,
    lp.status,
    lp.unidades_produzidas,
    COALESCE(SUM(ev.unidades), 0) AS unidades_vendidas,
    lp.unidades_restantes,
    lp.unidades_produzidas - COALESCE(SUM(ev.unidades), 0) AS unidades_restantes_calculadas,
    CASE
        WHEN lp.unidades_restantes = lp.unidades_produzidas - COALESCE(SUM(ev.unidades), 0)
            THEN 'OK'
        ELSE 'ATENCAO: unidades restantes divergentes'
    END AS situacao
FROM lote_produto lp
LEFT JOIN eh_vendido ev ON ev.id_lote = lp.id
GROUP BY lp.id, lp.tipo_produto, lp.status, lp.unidades_produzidas, lp.unidades_restantes
ORDER BY lp.id;


-- TESTE 17 - EQUIPAMENTOS E USO EM OPERAÇÕES
-- ----------------------------------------------------------------------------------------
-- Mostra quantas vezes cada equipamento foi usado.
-- Ajuda a validar se os equipamentos aparecem nas operações.

SELECT
    e.tipo,
    e.numero,
    e.status,
    e.ultima_manutencao,
    COUNT(o.id) AS total_operacoes
FROM equipamento e
LEFT JOIN operacao o
       ON o.tipo_equip = e.tipo
      AND o.num_equip = e.numero
GROUP BY e.tipo, e.numero, e.status, e.ultima_manutencao
ORDER BY total_operacoes DESC, e.tipo, e.numero;


-- TESTE 18 - DIAGNÓSTICO: OPERAÇÕES COM EQUIPAMENTO NÃO DISPONÍVEL
-- ----------------------------------------------------------------------------------------
-- Este teste identifica operações associadas a equipamentos que, no cadastro atual,
-- estão como 'indisponivel' ou 'em manutencao'.
--
-- Atenção:
--   O esquema atual não guarda histórico de status do equipamento.
--   Então esse teste é apenas diagnóstico, não necessariamente erro absoluto.

SELECT
    o.id AS id_operacao,
    o.nome AS operacao,
    o.tipo_equip,
    o.num_equip,
    e.status AS status_atual_equipamento,
    o.data_hora_inicio,
    o.data_hora_fim
FROM operacao o
JOIN equipamento e
  ON e.tipo = o.tipo_equip
 AND e.numero = o.num_equip
WHERE e.status <> 'disponivel'
ORDER BY o.id;


-- TESTE 19 - ORDENS DE PRODUÇÃO COM STATUS GERAL
-- ----------------------------------------------------------------------------------------
-- Resume cada ordem com datas, gerente, total de operações, lotes e resíduos.
-- Boa visão geral da cadeia produtiva.

SELECT
    op.id AS id_ordem,
    f.nome AS gerente,
    op.data_hora_inicio,
    op.data_hora_fim,
    COUNT(DISTINCT o.id) AS total_operacoes,
    COUNT(DISTINCT lp.id) AS total_lotes,
    COUNT(DISTINCT gr.tipo_residuo) AS tipos_residuo_gerados
FROM ordem_producao op
JOIN funcionario f ON f.num_funcional = op.gerente
LEFT JOIN operacao o ON o.ord_prod = op.id
LEFT JOIN lote_produto lp ON lp.ordem_prod = op.id
LEFT JOIN geracao_residuo gr ON gr.ordem_prod = op.id
GROUP BY op.id, f.nome, op.data_hora_inicio, op.data_hora_fim
ORDER BY op.id;


-- TESTE 20 - VISÃO COMPLETA: PRODUTO VENDIDO E SUA ORIGEM
-- ----------------------------------------------------------------------------------------
-- Rastreia venda -> lote -> ordem de produção -> gerente.
-- Esse é um teste simples, mas mostra bem a ideia de rastreabilidade pós-venda.

SELECT
    v.nota_fiscal AS nf_venda,
    v.data AS data_venda,
    cliente.nome_fantasia AS cliente,
    lp.id AS id_lote,
    lp.tipo_produto,
    ev.unidades,
    op.id AS id_ordem_origem,
    gerente.nome AS gerente_da_ordem
FROM venda v
JOIN pessoa_juridica cliente ON cliente.cnpj = v.cliente
JOIN eh_vendido ev ON ev.nf_venda = v.nota_fiscal
JOIN lote_produto lp ON lp.id = ev.id_lote
JOIN ordem_producao op ON op.id = lp.ordem_prod
JOIN funcionario gerente ON gerente.num_funcional = op.gerente
ORDER BY v.data, v.nota_fiscal, lp.id;
