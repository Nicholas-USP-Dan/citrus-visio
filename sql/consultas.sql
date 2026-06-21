-- ========================================================================================
-- CONSULTA 1 (COMPLEXIDADE MÉDIA): SUBQUERY CORRELACIONADA
-- OBJETIVO: Identificar ordens de produção que utilizaram a extratora 5, retornando
--           o gerente responsável, os gastos energéticos e hídricos totais, e operações concluídas
-- ========================================================================================
SELECT
    op.id                                                    AS id_ordem,
    f.nome                                                   AS nome_gerente,
    op.data_hora_inicio,
    SUM(o.gasto_energetico)                                  AS total_gasto_energetico_kwh,
    SUM(o.gasto_hidrico)                                     AS total_gasto_hidrico,
    COUNT(o.id) FILTER (WHERE o.status = 'concluida')        AS operacoes_concluidas
FROM
    ordem_producao op
JOIN funcionario f ON op.gerente = f.num_funcional
JOIN operacao    o ON o.ord_prod  = op.id
WHERE
    EXISTS (
        SELECT 1 FROM operacao o2
        WHERE  o2.ord_prod        = op.id
          AND  (o2.num_equip = 5 AND o2.tipo_equip = 'extratora')
    )
GROUP BY op.id, f.nome, op.data_hora_inicio
ORDER BY total_gasto_energetico_kwh DESC;


-- ========================================================================================
-- CONSULTA 2 (COMPLEXIDADE MÉDIA): JUNÇÃO EXTERNA
-- OBJETIVO: Consultar o tipo de resíduo predominante (de maior massa total) em cada
--           ordem de produção. Inclui ordens sem nenhum resíduo registrado, que aparecem
--           com tipo '-' e massa 0.
-- OBS.: a chave de geracao_residuo é (ordem_prod, tipo_residuo), logo cada tipo aparece
--       no máximo uma vez por ordem. Por isso não faz sentido medir o "mais gerado" por
--       contagem; usa-se massa_total como critério, e DISTINCT ON para pegar o maior por ordem.
-- ========================================================================================
SELECT DISTINCT ON (op.id)
    f.nome                            AS nome_gerente,
    op.id                             AS id_ordem,
    COALESCE(gr.tipo_residuo, '-')    AS tipo_residuo_predominante,
    COALESCE(gr.massa_total, 0)       AS massa_total
FROM
    ordem_producao op
JOIN      funcionario     f  ON f.num_funcional = op.gerente
LEFT JOIN geracao_residuo gr ON gr.ordem_prod   = op.id
ORDER BY op.id, gr.massa_total DESC NULLS LAST;


-- ========================================================================================
-- CONSULTA 3 (COMPLEXIDADE MÉDIA): FILTRAGEM E ANTI-JUNÇÃO
-- OBJETIVO: Listar fornecedores cujos insumos estão todos sem alocação —
--           nenhum insumo seu foi vinculado a qualquer ordem de produção.
-- ========================================================================================
SELECT
    pj.cnpj,
    pj.nome_fantasia,
    COUNT(i.nota_fiscal) AS total_insumos_sem_alocacao
FROM
    pessoa_juridica pj
JOIN fornecedor f ON pj.cnpj          = f.cnpj
JOIN insumo     i ON f.cnpj           = i.cnpj_fornecedor
WHERE
    NOT EXISTS (
        SELECT 1 FROM insumo i2
        WHERE  i2.cnpj_fornecedor  = f.cnpj
          AND  i2.ordem_producao  IS NOT NULL
    )
GROUP BY pj.cnpj, pj.nome_fantasia
ORDER BY total_insumos_sem_alocacao DESC;


-- ========================================================================================
-- CONSULTA 4 (COMPLEXIDADE EXTREMA): DIVISÃO RELACIONAL + GENERALIZAÇÃO
-- OBJETIVO: Identificar clientes que compraram TODOS os tipos de produto do catálogo,
--           retornando faixa de valor gasto e volume de compras.
-- Divisão relacional implementada com NOT EXISTS + EXCEPT: um cliente é selecionado
-- quando o conjunto (todos os tipos de produto) MENOS (tipos que ele comprou) é vazio.
-- ========================================================================================
WITH clientes_com_cobertura AS (
    SELECT DISTINCT c.cnpj AS cnpj_cliente
    FROM cliente c
    WHERE NOT EXISTS (
        (
            SELECT tipo
            FROM tipo_produto
        )
        EXCEPT
        (
            SELECT lp.tipo_produto
            FROM venda v
            JOIN eh_vendido   ev ON ev.nf_venda = v.nota_fiscal
            JOIN lote_produto lp ON lp.id       = ev.id_lote
            WHERE v.cliente = c.cnpj
        )
    )
)

SELECT
    CASE
        WHEN SUM(v.valor) <  10000  THEN 'Até R$ 10.000'
        WHEN SUM(v.valor) <  50000  THEN 'R$ 10.001 – R$ 50.000'
        WHEN SUM(v.valor) < 200000  THEN 'R$ 50.001 – R$ 200.000'
        ELSE                             'Acima de R$ 200.000'
    END                              AS faixa_valor_total_gasto,
    pj.cnpj,
    pj.nome_fantasia,
    COUNT(DISTINCT v.nota_fiscal)    AS total_compras
FROM clientes_com_cobertura cc
JOIN pessoa_juridica pj ON cc.cnpj_cliente = pj.cnpj
JOIN venda           v  ON v.cliente      = cl.cnpj
GROUP BY pj.cnpj, pj.nome_fantasia
ORDER BY faixa_valor_total_gasto, total_compras DESC;


-- ========================================================================================
-- CONSULTA 5 (COMPLEXIDADE ALTA): SUBQUERIES ANINHADAS NÃO CORRELACIONADAS
-- OBJETIVO: Custo médio de matéria-prima (laranjas) por gerente em três níveis de agregação:
--           insumo → ordem de produção → gerente.
-- ========================================================================================
WITH custos_insumo_laranjas AS (
    -- Nível 1: custo unitário de cada insumo matéria-prima
    SELECT nota_fiscal, ordem_producao, custo AS custo_insumo
    FROM   insumo i
    WHERE  UPPER(i.tipo_insumo) LIKE 'LARANJA%'
),
custos_ordem_laranjas AS (
    -- Nível 2: custo de matéria-prima de cada ordem de produção
    SELECT
        op.id      AS id_ordem,
        op.gerente,
        SUM(cil.custo_insumo) AS custo_ordem
    FROM       ordem_producao op
    JOIN custos_insumo_laranjas cil ON cil.ordem_producao = op.id
    GROUP BY op.id, op.gerente
)
SELECT
    f.nome                          AS nome_gerente,
    ROUND(AVG(col.custo_ordem), 3)   AS custo_medio_gerente
FROM       funcionario f
JOIN custos_ordem_laranjas col ON col.gerente = f.num_funcional
GROUP BY f.nome
ORDER BY custo_medio_gerente DESC;
