-- ========================================================================================
-- DADOS INICIAIS - CitrusVisio Factory
-- ----------------------------------------------------------------------------------------
-- Pre-requisito: rodar sql/esquema.sql antes (banco limpo).
-- Inserções na ordem correta das FKs. >= 2 tuplas por tabela.
--
-- IDs artificiais (GENERATED ALWAYS AS IDENTITY) NÃO são inseridos manualmente.
-- Assumindo banco recém-criado, os IDs gerados seguem a ordem de inserção:
--   ordem_producao -> 1, 2, 3
--   operacao       -> 1, 2, 3
--   lote_produto   -> 1, 2, 3
-- Esses valores esperados são referenciados nas tabelas filhas e comentados abaixo.
--
-- Formatos de domínio: cnpj=14 díg., cpf=11 díg., num_funcional=20 díg.,
-- nota fiscal (chave de acesso)=44 díg. (usamos LPAD(...,44,'0')), telefone=10-11 díg.
-- ========================================================================================


-- ========================= PESSOA JURÍDICA =========================
-- PJ1/PJ2/PJ5 atuam como fornecedores; PJ3/PJ4/PJ5 como clientes (PJ5 = sobreposição).
INSERT INTO pessoa_juridica (cnpj, nome_fantasia) VALUES
  ('11111111000111', 'Citrus Fornecedora'),   -- fornecedor com insumos alocados
  ('22222222000122', 'Embalagens Sul'),        -- fornecedor SEM insumo alocado (Consulta 3)
  ('33333333000133', 'Supermercado Bom Preço'),-- cliente que compra TODOS os tipos (Consulta 4)
  ('44444444000144', 'Lanchonete Central'),    -- cliente que compra só parte (Consulta 4)
  ('55555555000155', 'Distribuidora Mista');   -- cliente E fornecedor (sobreposição)


-- ========================= FORNECEDOR / CLIENTE =========================
INSERT INTO fornecedor (cnpj) VALUES
  ('11111111000111'),
  ('22222222000122'),
  ('55555555000155');

INSERT INTO cliente (cnpj) VALUES
  ('33333333000133'),
  ('44444444000144'),
  ('55555555000155');


-- ========================= CONTATOS (multivalorados) =========================
INSERT INTO email_fornecedor (cnpj_fornecedor, email) VALUES
  ('11111111000111', 'fiscal@citrusforn.com'),
  ('22222222000122', 'vendas@embsul.com');

INSERT INTO tel_fornecedor (cnpj_fornecedor, telefone) VALUES
  ('11111111000111', '1133334444'),
  ('22222222000122', '1144445555');

INSERT INTO email_cliente (cnpj_cliente, email) VALUES
  ('33333333000133', 'compras@bompreco.com'),
  ('44444444000144', 'contato@lanchonete.com');

INSERT INTO tel_cliente (cnpj_cliente, telefone) VALUES
  ('33333333000133', '1155556666'),
  ('44444444000144', '1166667777');


-- ========================= FUNCIONÁRIO + ESPECIALIZAÇÕES =========================
-- 2 gerentes (Consulta 5 precisa de >=2 para o ranking), 2 operadores, 2 representantes.
INSERT INTO funcionario
  (num_funcional, cpf, salario, data_contratacao, email, telefone, nome, cargo) VALUES
  ('00000000000000000001', '11111111111', 8500.00, '2024-01-15', 'carlos@citrus.com',  '11987650001', 'Carlos Gerente',      'gerente'),
  ('00000000000000000002', '22222222222', 8200.00, '2024-02-20', 'marina@citrus.com',  '11987650002', 'Marina Gerente',      'gerente'),
  ('00000000000000000003', '33333333333', 3200.00, '2024-03-10', 'joao@citrus.com',    '11987650003', 'João Operador',       'operador'),
  ('00000000000000000004', '44444444444', 3300.00, '2024-03-12', 'ana@citrus.com',     '11987650004', 'Ana Operadora',       'operador'),
  ('00000000000000000005', '55555555555', 4000.00, '2024-04-01', 'pedro@citrus.com',   '11987650005', 'Pedro Representante',  'representante'),
  ('00000000000000000006', '66666666666', 4100.00, '2024-04-05', 'lucia@citrus.com',   '11987650006', 'Lucia Representante',  'representante');

INSERT INTO gerente (num_funcional) VALUES
  ('00000000000000000001'),
  ('00000000000000000002');

INSERT INTO operador (num_funcional) VALUES
  ('00000000000000000003'),
  ('00000000000000000004');

-- comissao como fração decimal (0.0500 = 5%)
INSERT INTO representante_comercial (num_funcional, comissao) VALUES
  ('00000000000000000005', 0.0500),
  ('00000000000000000006', 0.0300);


-- ========================= CATÁLOGOS (tipo_*) =========================
INSERT INTO tipo_insumo (tipo) VALUES
  ('LARANJA PERA'),
  ('LARANJA LIMA'),
  ('EMBALAGEM PET');

INSERT INTO tipo_residuo (tipo) VALUES
  ('BAGACO'),
  ('OLEO ESSENCIAL'),
  ('GAS CARBONICO');

-- Catálogo pequeno (2 tipos) para viabilizar a divisão relacional da Consulta 4.
INSERT INTO tipo_produto (tipo, qtd_estoque, preco) VALUES
  ('SUCO INTEGRAL 1L',        1300, 12.000),
  ('SUCO CONCENTRADO 500ML',   400,  8.000);


-- ========================= EQUIPAMENTO =========================
-- A extratora 5 é exigida pela Consulta 1.
INSERT INTO equipamento (numero, tipo, status, ultima_manutencao) VALUES
  (5, 'extratora',      'disponivel', '2025-12-01'),
  (2, 'pasteurizadora', 'disponivel', '2025-12-05');


-- ========================= ORDEM DE PRODUÇÃO (IDs gerados: 1, 2, 3) =========================
-- OP1 (id=1): gerente Carlos  -> usa extratora 5, gera 2 resíduos, usa laranjas
-- OP2 (id=2): gerente Marina  -> usa extratora 5, gera 1 resíduo,  usa laranja
-- OP3 (id=3): gerente Carlos  -> SEM resíduo (Consulta 2: ordem sem resíduo -> '-')
INSERT INTO ordem_producao (gerente, data_hora_inicio, data_hora_fim) VALUES
  ('00000000000000000001', '2026-01-10 08:00-03', '2026-01-10 18:00-03'),
  ('00000000000000000002', '2026-02-15 08:00-03', '2026-02-15 17:00-03'),
  ('00000000000000000001', '2026-03-20 08:00-03', NULL);


-- ========================= INSUMO =========================
-- nota_fiscal: 44 dígitos via LPAD. data_aquisicao anterior ao início da ordem associada.
-- Consulta 3: Embalagens Sul (PJ2) tem TODOS insumos com ordem_producao NULL.
-- Consulta 5: insumos 'LARANJA%' alocados a OP1 (Carlos) e OP2 (Marina).
INSERT INTO insumo
  (nota_fiscal, cnpj_fornecedor, tipo_insumo, custo, data_aquisicao, quantidade, ordem_producao) VALUES
  (LPAD('101',44,'0'), '11111111000111', 'LARANJA PERA',  5000.000, '2026-01-05', 1000, 1),    -- OP1
  (LPAD('102',44,'0'), '11111111000111', 'LARANJA PERA',  3000.000, '2026-01-06',  600, 1),    -- OP1
  (LPAD('103',44,'0'), '55555555000155', 'LARANJA LIMA',  4000.000, '2026-02-10',  800, 2),    -- OP2
  (LPAD('104',44,'0'), '22222222000122', 'EMBALAGEM PET', 1500.000, '2026-01-02', 5000, NULL), -- sem alocação
  (LPAD('105',44,'0'), '22222222000122', 'EMBALAGEM PET', 1200.000, '2026-01-03', 4000, NULL); -- sem alocação


-- ========================= OPERAÇÃO (IDs gerados: 1, 2, 3) =========================
-- OPER1 (id=1): extratora 5, OP1, concluída, gastos preenchidos
-- OPER2 (id=2): pasteurizadora 2, OP1, concluída
-- OPER3 (id=3): extratora 5, OP2, em andamento
INSERT INTO operacao
  (num_equip, tipo_equip, data_hora_inicio, ord_prod, nome, gasto_hidrico, gasto_energetico, status, data_hora_fim) VALUES
  (5, 'extratora',      '2026-01-10 09:00-03', 1, 'Extracao',      50.000, 120.000, 'concluida',    '2026-01-10 12:00-03'),
  (2, 'pasteurizadora', '2026-01-10 13:00-03', 1, 'Pasteurizacao', 30.000,  80.000, 'concluida',    '2026-01-10 15:00-03'),
  (5, 'extratora',      '2026-02-15 09:00-03', 2, 'Extracao',      40.000, 100.000, 'em andamento', NULL);


-- ========================= TEMPERATURA (histórico por operação) =========================
INSERT INTO temperatura (operacao, data_hora, graus_celsius) VALUES
  (1, '2026-01-10 10:00-03', 25.50),
  (1, '2026-01-10 11:00-03', 28.00),
  (2, '2026-01-10 14:00-03', 85.00);


-- ========================= TRABALHO (operadores nas operações) =========================
INSERT INTO trabalho (operador, operacao, data, turno) VALUES
  ('00000000000000000003', 1, '2026-01-10', 'matutino'),
  ('00000000000000000004', 2, '2026-01-10', 'vespertino'),
  ('00000000000000000003', 3, '2026-02-15', 'matutino');


-- ========================= GERAÇÃO DE RESÍDUO =========================
-- OP1: 2 tipos com massas diferentes -> predominante = BAGACO (572.260 > 120.500)
-- OP2: 1 tipo -> predominante = GAS CARBONICO
-- OP3: nenhum -> Consulta 2 mostra '-'
INSERT INTO geracao_residuo (ordem_prod, tipo_residuo, massa_total, destino, intermediario) VALUES
  (1, 'BAGACO',         572.260, 'compostagem', 'Empresa B'),
  (1, 'OLEO ESSENCIAL', 120.500, 'reuso',       'Empresa C'),
  (2, 'GAS CARBONICO',   90.000, 'tratamento',  'Empresa D');


-- ========================= LOTE DE PRODUTO (IDs gerados: 1, 2, 3) =========================
-- LOTE1 (id=1): OP1, SUCO INTEGRAL 1L
-- LOTE2 (id=2): OP1, SUCO CONCENTRADO 500ML
-- LOTE3 (id=3): OP2, SUCO INTEGRAL 1L
INSERT INTO lote_produto
  (ordem_prod, tipo_produto, status, unidades_restantes, unidades_produzidas, validade) VALUES
  (1, 'SUCO INTEGRAL 1L',        'PRONTO', 500, 1000, '2026-12-31'),
  (1, 'SUCO CONCENTRADO 500ML',  'PRONTO', 400,  800, '2026-12-31'),
  (2, 'SUCO INTEGRAL 1L',        'PRONTO', 300,  600, '2026-11-30');


-- ========================= VENDA =========================
-- valor coerente com unidades vendidas x preço do tipo de produto.
-- PJ3 (Bom Preço) compra os 2 tipos -> cobre o catálogo (Consulta 4).
-- PJ4 e PJ5 compram só SUCO INTEGRAL -> não cobrem o catálogo.
INSERT INTO venda (nota_fiscal, cliente, representante, data, valor) VALUES
  (LPAD('201',44,'0'), '33333333000133', '00000000000000000005', '2026-05-01', 1200.000), -- 100 x 12 (integral)
  (LPAD('202',44,'0'), '33333333000133', '00000000000000000005', '2026-05-10',  400.000), --  50 x 8  (concentrado)
  (LPAD('203',44,'0'), '44444444000144', '00000000000000000006', '2026-05-05',  960.000), --  80 x 12 (integral)
  (LPAD('204',44,'0'), '55555555000155', '00000000000000000006', '2026-05-08',  360.000); --  30 x 12 (integral)


-- ========================= EH_VENDIDO (lotes vendidos em cada venda) =========================
INSERT INTO eh_vendido (id_lote, nf_venda, unidades) VALUES
  (1, LPAD('201',44,'0'), 100),  -- Bom Preço: SUCO INTEGRAL
  (2, LPAD('202',44,'0'),  50),  -- Bom Preço: SUCO CONCENTRADO -> cobre os 2 tipos
  (1, LPAD('203',44,'0'),  80),  -- Lanchonete: só SUCO INTEGRAL
  (3, LPAD('204',44,'0'),  30);  -- Distribuidora: só SUCO INTEGRAL
