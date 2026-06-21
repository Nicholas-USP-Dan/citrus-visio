
-- DADOS INICIAIS 
-- ----------------------------------------------------------------------------------------
-- Pré-requisito: rodar esquema.sql antes, em uma base recém-criada.
--
-- Observação importante:
-- As tabelas ordem_producao, operacao e lote_produto usam
-- bigint GENERATED ALWAYS AS IDENTITY.
--
-- Como este script assume base vazia, os IDs esperados serão:
--   ordem_producao: 1, 2, 3, 4, 5, 6
--   operacao:       1 até 17
--   lote_produto:   1 até 12
--
-- Os IDs não são inseridos manualmente; são gerados pelo PostgreSQL.


-- ========================= PESSOA JURÍDICA =========================
INSERT INTO pessoa_juridica (cnpj, nome_fantasia) VALUES
  ('10000000000101', 'Citrus Agro Paulista'),
  ('10000000000102', 'Embalagens Sul'),
  ('10000000000103', 'Quimicos Naturais'),
  ('10000000000104', 'Recicla Bio'),
  ('10000000000105', 'Supermercado Bom Preco'),
  ('10000000000106', 'Rede Natural SP'),
  ('10000000000107', 'Distribuidora Mista'),
  ('10000000000108', 'Hotel Fazenda Sol'),
  ('10000000000109', 'Fazenda Vale Verde'),
  ('10000000000110', 'Cooperativa Sabor Local');


-- ========================= FORNECEDOR / CLIENTE =========================
-- Algumas pessoas jurídicas atuam em mais de um papel, representando a sobreposição permitida.
INSERT INTO fornecedor (cnpj) VALUES
  ('10000000000101'),
  ('10000000000102'),
  ('10000000000103'),
  ('10000000000104'),
  ('10000000000107'),
  ('10000000000109');

INSERT INTO cliente (cnpj) VALUES
  ('10000000000104'),
  ('10000000000105'),
  ('10000000000106'),
  ('10000000000107'),
  ('10000000000108'),
  ('10000000000110');


-- ========================= CONTATOS DE FORNECEDORES =========================
INSERT INTO email_fornecedor (cnpj_fornecedor, email) VALUES
  ('10000000000101', 'compras@citrusagro.com'),
  ('10000000000102', 'vendas@embalagensul.com'),
  ('10000000000103', 'contato@quimicosnaturais.com'),
  ('10000000000104', 'fornecimento@reciclabio.com'),
  ('10000000000107', 'insumos@distmista.com'),
  ('10000000000109', 'comercial@fazendaverde.com');

INSERT INTO tel_fornecedor (cnpj_fornecedor, telefone) VALUES
  ('10000000000101', '1133334001'),
  ('10000000000102', '1133334002'),
  ('10000000000103', '1133334003'),
  ('10000000000104', '1133334004'),
  ('10000000000107', '1133334007'),
  ('10000000000109', '1133334009');


-- ========================= CONTATOS DE CLIENTES =========================
INSERT INTO email_cliente (cnpj_cliente, email) VALUES
  ('10000000000104', 'compras@reciclabio.com'),
  ('10000000000105', 'compras@bompreco.com'),
  ('10000000000106', 'pedidos@redenatural.com'),
  ('10000000000107', 'vendas@distmista.com'),
  ('10000000000108', 'eventos@hotelsol.com'),
  ('10000000000110', 'compras@saborlocal.com');

INSERT INTO tel_cliente (cnpj_cliente, telefone) VALUES
  ('10000000000104', '1198888004'),
  ('10000000000105', '1198888005'),
  ('10000000000106', '1198888006'),
  ('10000000000107', '1198888007'),
  ('10000000000108', '1198888008'),
  ('10000000000110', '1198888010');


-- ========================= FUNCIONÁRIOS =========================
INSERT INTO funcionario
  (num_funcional, cpf, salario, data_contratacao, email, telefone, nome, cargo) VALUES
  ('0000000001', '11111111111', 8500.00, '2024-01-15', 'carlos@citrus.com',  '11987650001', 'Carlos Almeida',    'gerente'),
  ('0000000002', '22222222222', 8200.00, '2024-02-20', 'marina@citrus.com',  '11987650002', 'Marina Costa',     'gerente'),
  ('0000000003', '33333333333', 7900.00, '2024-05-10', 'bruno@citrus.com',   '11987650003', 'Bruno Ferreira',   'gerente'),
  ('0000000004', '44444444444', 3300.00, '2024-03-12', 'joao@citrus.com',    '11987650004', 'Joao Pereira',     'operador'),
  ('0000000005', '55555555555', 3400.00, '2024-04-01', 'ana@citrus.com',     '11987650005', 'Ana Martins',      'operador'),
  ('0000000006', '66666666666', 3600.00, '2024-06-18', 'rafael@citrus.com',  '11987650006', 'Rafael Nunes',     'operador'),
  ('0000000007', '77777777777', 3500.00, '2024-08-22', 'beatriz@citrus.com', '11987650007', 'Beatriz Lima',     'operador'),
  ('0000000008', '88888888888', 4200.00, '2024-09-05', 'pedro@citrus.com',   '11987650008', 'Pedro Rocha',      'representante'),
  ('0000000009', '99999999999', 4300.00, '2024-09-18', 'lucia@citrus.com',   '11987650009', 'Lucia Barbosa',    'representante'),
  ('0000000010', '10101010101', 4100.00, '2024-10-02', 'camila@citrus.com',  '11987650010', 'Camila Araujo',    'representante');


-- ========================= ESPECIALIZAÇÕES DE FUNCIONÁRIO =========================
INSERT INTO gerente (num_funcional) VALUES
  ('0000000001'),
  ('0000000002'),
  ('0000000003');

INSERT INTO operador (num_funcional) VALUES
  ('0000000004'),
  ('0000000005'),
  ('0000000006'),
  ('0000000007');

INSERT INTO representante_comercial (num_funcional, comissao) VALUES
  ('0000000008', 0.0500),
  ('0000000009', 0.0400),
  ('0000000010', 0.0350);


-- ========================= TIPOS DE INSUMO =========================
INSERT INTO tipo_insumo (tipo) VALUES
  ('LARANJA PERA'),
  ('LARANJA LIMA'),
  ('LARANJA BAHIA'),
  ('EMBALAGEM PET'),
  ('TAMPA PLASTICA'),
  ('ACIDO CITRICO');


-- ========================= TIPOS DE RESÍDUO =========================
INSERT INTO tipo_residuo (tipo) VALUES
  ('BAGACO'),
  ('OLEO ESSENCIAL'),
  ('GAS CARBONICO'),
  ('EFLUENTE LIQUIDO'),
  ('PLASTICO CONTAMINADO');


-- ========================= TIPOS DE PRODUTO =========================
INSERT INTO tipo_produto (tipo, qtd_estoque, preco) VALUES
  ('SUCO INTEGRAL 1L',        1275, 12.000),
  ('SUCO CONCENTRADO 500ML',   920,  8.000),
  ('NECTAR DE LARANJA 1L',     990, 10.000),
  ('POLPA CONGELADA 1KG',      950, 18.000),
  ('SUCO ZERO ACUCAR 1L',      840, 14.500);


-- ========================= EQUIPAMENTOS =========================
-- A extratora 5 é importante para a Consulta 1.
INSERT INTO equipamento (numero, tipo, status, ultima_manutencao) VALUES
  (5, 'extratora',      'disponivel',    '2025-12-01'),
  (2, 'pasteurizadora', 'disponivel',    '2025-12-05'),
  (1, 'filtro',         'disponivel',    '2025-11-20'),
  (3, 'envase',         'disponivel',    '2025-12-12'),
  (4, 'tanque inox',    'disponivel',    '2025-10-25'),
  (6, 'centrifuga',     'disponivel',    '2025-11-28'),
  (7, 'rotuladora',     'em manutencao', '2025-12-15'),
  (8, 'lavadora',       'indisponivel',  '2025-09-30');


-- ========================= ORDENS DE PRODUÇÃO =========================
-- IDs esperados:
-- 1: Carlos
-- 2: Marina
-- 3: Bruno
-- 4: Carlos
-- 5: Marina, ordem em aberto e sem resíduos
-- 6: Bruno
INSERT INTO ordem_producao (gerente, data_hora_inicio, data_hora_fim) VALUES
  ('0000000001', '2026-01-10 08:00:00-03', '2026-01-10 18:00:00-03'),
  ('0000000002', '2026-01-15 08:00:00-03', '2026-01-15 17:30:00-03'),
  ('0000000003', '2026-02-01 07:30:00-03', '2026-02-01 16:30:00-03'),
  ('0000000001', '2026-02-12 08:00:00-03', '2026-02-12 15:30:00-03'),
  ('0000000002', '2026-03-01 09:00:00-03', NULL),
  ('0000000003', '2026-03-20 07:00:00-03', '2026-03-20 14:30:00-03');


-- ========================= INSUMOS =========================
-- Consulta 3:
--   Embalagens Sul e Recicla Bio aparecem porque todos os seus insumos estão sem alocação.
-- Consulta 5:
--   Laranjas alocadas às ordens permitem calcular custo médio por gerente.
INSERT INTO insumo
  (nota_fiscal, cnpj_fornecedor, tipo_insumo, custo, data_aquisicao, quantidade, ordem_producao) VALUES
  (LPAD('101', 44, '0'), '10000000000101', 'LARANJA PERA',   5500.000, '2026-01-05', 1100, 1),
  (LPAD('102', 44, '0'), '10000000000109', 'LARANJA LIMA',   4200.000, '2026-01-06',  800, 1),
  (LPAD('103', 44, '0'), '10000000000101', 'LARANJA PERA',   4800.000, '2026-01-10',  950, 2),
  (LPAD('104', 44, '0'), '10000000000107', 'LARANJA BAHIA',  6200.000, '2026-01-11', 1200, 2),
  (LPAD('105', 44, '0'), '10000000000109', 'LARANJA PERA',   5100.000, '2026-01-28', 1000, 3),
  (LPAD('106', 44, '0'), '10000000000101', 'LARANJA LIMA',   3900.000, '2026-02-08',  750, 4),
  (LPAD('107', 44, '0'), '10000000000107', 'LARANJA BAHIA',  4500.000, '2026-03-15',  850, 6),
  (LPAD('108', 44, '0'), '10000000000101', 'EMBALAGEM PET',  2000.000, '2026-01-05', 4000, 1),
  (LPAD('109', 44, '0'), '10000000000103', 'ACIDO CITRICO',   750.000, '2026-01-12',  250, 2),
  (LPAD('110', 44, '0'), '10000000000103', 'ACIDO CITRICO',   680.000, '2026-02-20',  220, NULL),
  (LPAD('111', 44, '0'), '10000000000102', 'EMBALAGEM PET',  1800.000, '2026-01-02', 5000, NULL),
  (LPAD('112', 44, '0'), '10000000000102', 'TAMPA PLASTICA',  900.000, '2026-01-03', 5000, NULL),
  (LPAD('113', 44, '0'), '10000000000104', 'TAMPA PLASTICA', 1200.000, '2026-02-01', 4500, NULL),
  (LPAD('114', 44, '0'), '10000000000104', 'EMBALAGEM PET',  1600.000, '2026-02-03', 4200, NULL);


-- ========================= OPERAÇÕES =========================
-- IDs esperados: 1 até 17.
-- Ordens 1, 2, 3, 4 e 6 usam a extratora 5, alimentando a Consulta 1.
-- Ordem 5 não usa extratora e também fica sem resíduos, servindo como caso de controle.
INSERT INTO operacao
  (num_equip, tipo_equip, data_hora_inicio, ord_prod, nome,
   gasto_hidrico, gasto_energetico, status, data_hora_fim) VALUES

  (5, 'extratora',      '2026-01-10 09:00:00-03', 1, 'Extracao',
   52.000, 125.000, 'concluida', '2026-01-10 11:00:00-03'),

  (1, 'filtro',         '2026-01-10 11:20:00-03', 1, 'Filtragem',
   28.000,  60.000, 'concluida', '2026-01-10 12:40:00-03'),

  (2, 'pasteurizadora', '2026-01-10 13:00:00-03', 1, 'Pasteurizacao',
   35.000,  95.000, 'concluida', '2026-01-10 15:00:00-03'),

  (3, 'envase',         '2026-01-10 15:20:00-03', 1, 'Envase',
   20.000,  55.000, 'concluida', '2026-01-10 17:10:00-03'),

  (5, 'extratora',      '2026-01-15 09:00:00-03', 2, 'Extracao',
   48.000, 118.000, 'concluida', '2026-01-15 11:10:00-03'),

  (6, 'centrifuga',     '2026-01-15 11:30:00-03', 2, 'Centrifugacao',
   22.000,  70.000, 'concluida', '2026-01-15 12:50:00-03'),

  (2, 'pasteurizadora', '2026-01-15 13:10:00-03', 2, 'Pasteurizacao',
   32.000,  92.000, 'concluida', '2026-01-15 15:00:00-03'),

  (3, 'envase',         '2026-01-15 15:20:00-03', 2, 'Envase',
   18.000,  50.000, 'concluida', '2026-01-15 16:50:00-03'),

  (8, 'lavadora',       '2026-02-01 08:00:00-03', 3, 'Lavagem',
   40.000,  65.000, 'concluida', '2026-02-01 09:20:00-03'),

  (5, 'extratora',      '2026-02-01 09:40:00-03', 3, 'Extracao',
   46.000, 112.000, 'concluida', '2026-02-01 11:40:00-03'),

  (1, 'filtro',         '2026-02-01 12:00:00-03', 3, 'Filtragem',
   24.000,  58.000, 'concluida', '2026-02-01 13:20:00-03'),

  (4, 'tanque inox',    '2026-02-12 08:30:00-03', 4, 'Mistura',
   25.000,  45.000, 'concluida', '2026-02-12 09:40:00-03'),

  (5, 'extratora',      '2026-02-12 10:00:00-03', 4, 'Extracao',
   44.000, 108.000, 'concluida', '2026-02-12 12:00:00-03'),

  (7, 'rotuladora',     '2026-02-12 13:00:00-03', 4, 'Rotulagem',
   10.000,  38.000, 'interrompida', '2026-02-12 13:40:00-03'),

  (2, 'pasteurizadora', '2026-03-01 10:00:00-03', 5, 'Pasteurizacao',
   30.000,  88.000, 'em andamento', NULL),

  (5, 'extratora',      '2026-03-20 08:00:00-03', 6, 'Extracao',
   42.000, 104.000, 'concluida', '2026-03-20 10:00:00-03'),

  (3, 'envase',         '2026-03-20 10:30:00-03', 6, 'Envase',
   16.000,  47.000, 'concluida', '2026-03-20 12:00:00-03');


-- ========================= TEMPERATURAS =========================
INSERT INTO temperatura (operacao, data_hora, graus_celsius) VALUES
  (1,  '2026-01-10 09:30:00-03', 25.50),
  (1,  '2026-01-10 10:30:00-03', 27.00),
  (2,  '2026-01-10 12:00:00-03', 31.20),
  (3,  '2026-01-10 14:00:00-03', 84.50),
  (4,  '2026-01-10 16:00:00-03', 24.80),
  (5,  '2026-01-15 09:40:00-03', 26.30),
  (5,  '2026-01-15 10:40:00-03', 28.10),
  (6,  '2026-01-15 12:10:00-03', 32.00),
  (7,  '2026-01-15 14:00:00-03', 85.20),
  (8,  '2026-01-15 16:00:00-03', 25.10),
  (9,  '2026-02-01 08:40:00-03', 22.80),
  (10, '2026-02-01 10:40:00-03', 27.40),
  (11, '2026-02-01 12:40:00-03', 30.90),
  (12, '2026-02-12 09:00:00-03', 23.70),
  (13, '2026-02-12 11:00:00-03', 27.80),
  (14, '2026-02-12 13:20:00-03', 24.90),
  (15, '2026-03-01 10:40:00-03', 82.60),
  (16, '2026-03-20 08:50:00-03', 26.90),
  (16, '2026-03-20 09:40:00-03', 28.20),
  (17, '2026-03-20 11:10:00-03', 24.50);


-- ========================= TRABALHO =========================
INSERT INTO trabalho (operador, operacao, data, turno) VALUES
  ('0000000004', 1,  '2026-01-10', 'matutino'),
  ('0000000005', 1,  '2026-01-10', 'matutino'),
  ('0000000006', 2,  '2026-01-10', 'matutino'),
  ('0000000007', 3,  '2026-01-10', 'vespertino'),
  ('0000000004', 4,  '2026-01-10', 'vespertino'),
  ('0000000005', 5,  '2026-01-15', 'matutino'),
  ('0000000006', 6,  '2026-01-15', 'matutino'),
  ('0000000007', 7,  '2026-01-15', 'vespertino'),
  ('0000000004', 8,  '2026-01-15', 'vespertino'),
  ('0000000005', 9,  '2026-02-01', 'matutino'),
  ('0000000006', 10, '2026-02-01', 'matutino'),
  ('0000000007', 11, '2026-02-01', 'vespertino'),
  ('0000000004', 12, '2026-02-12', 'matutino'),
  ('0000000005', 13, '2026-02-12', 'matutino'),
  ('0000000006', 14, '2026-02-12', 'vespertino'),
  ('0000000007', 15, '2026-03-01', 'matutino'),
  ('0000000004', 16, '2026-03-20', 'matutino'),
  ('0000000005', 17, '2026-03-20', 'vespertino');


-- ========================= GERAÇÃO DE RESÍDUOS =========================
-- Consulta 2:
--   usa massa_total para escolher o resíduo predominante por ordem.
--   ordem 5 não tem resíduo, então aparece com '-' e massa 0.
INSERT INTO geracao_residuo (ordem_prod, tipo_residuo, massa_total, destino, intermediario) VALUES
  (1, 'BAGACO',                620.250, 'compostagem',        'Empresa Verde'),
  (1, 'OLEO ESSENCIAL',         90.500, 'reuso industrial',   'Aroma Citrus'),
  (1, 'EFLUENTE LIQUIDO',      150.000, 'tratamento',         'EcoTrat'),
  (2, 'BAGACO',                510.700, 'compostagem',        'Empresa Verde'),
  (2, 'GAS CARBONICO',         140.000, 'captura controlada', 'Carbon Control'),
  (3, 'BAGACO',                430.000, 'racao animal',       'AgroRacao'),
  (3, 'PLASTICO CONTAMINADO',   20.000, 'coprocessamento',    'Recicla Bio'),
  (4, 'BAGACO',                300.300, 'compostagem',        'Empresa Verde'),
  (4, 'OLEO ESSENCIAL',        130.200, 'reuso industrial',   'Aroma Citrus'),
  (6, 'GAS CARBONICO',         160.000, 'captura controlada', 'Carbon Control'),
  (6, 'EFLUENTE LIQUIDO',      210.600, 'tratamento',         'EcoTrat');


-- ========================= LOTES DE PRODUTO =========================
-- IDs esperados:
-- 1  OP1 SUCO INTEGRAL
-- 2  OP1 SUCO CONCENTRADO
-- 3  OP1 NECTAR
-- 4  OP2 POLPA
-- 5  OP2 SUCO ZERO
-- 6  OP3 SUCO INTEGRAL
-- 7  OP3 POLPA VENCIDO
-- 8  OP4 SUCO CONCENTRADO
-- 9  OP4 NECTAR CONTAMINADO
-- 10 OP5 SUCO ZERO
-- 11 OP6 POLPA
-- 12 OP6 NECTAR
INSERT INTO lote_produto
  (ordem_prod, tipo_produto, status, unidades_restantes, unidades_produzidas, validade) VALUES
  (1, 'SUCO INTEGRAL 1L',        'PRONTO',       795, 1000, '2026-12-31'),
  (1, 'SUCO CONCENTRADO 500ML',  'PRONTO',       570,  700, '2026-12-31'),
  (1, 'NECTAR DE LARANJA 1L',    'PRONTO',       600,  900, '2026-12-31'),
  (2, 'POLPA CONGELADA 1KG',     'PRONTO',       520,  600, '2026-11-30'),
  (2, 'SUCO ZERO ACUCAR 1L',     'PRONTO',       500,  650, '2026-11-30'),
  (3, 'SUCO INTEGRAL 1L',        'PRONTO',       480,  800, '2026-10-31'),
  (3, 'POLPA CONGELADA 1KG',     'VENCIDO',      300,  300, '2026-03-01'),
  (4, 'SUCO CONCENTRADO 500ML',  'PRONTO',       350,  700, '2026-12-15'),
  (4, 'NECTAR DE LARANJA 1L',    'CONTAMINADO',  400,  400, '2026-12-15'),
  (5, 'SUCO ZERO ACUCAR 1L',     'PRONTO',       340,  500, '2026-12-20'),
  (6, 'POLPA CONGELADA 1KG',     'PRONTO',       430,  650, '2026-12-20'),
  (6, 'NECTAR DE LARANJA 1L',    'PRONTO',       390,  600, '2026-12-20');


-- ========================= VENDAS =========================
-- Consulta 4:
--   Supermercado Bom Preco compra todos os 5 tipos de produto.
--   Cooperativa Sabor Local também compra todos os 5 tipos de produto.
--   Os demais clientes compram apenas parte do catálogo.
INSERT INTO venda (nota_fiscal, cliente, representante, data, valor) VALUES
  (LPAD('501', 44, '0'), '10000000000105', '0000000008', '2026-05-01', 2740.000),
  (LPAD('502', 44, '0'), '10000000000105', '0000000008', '2026-05-10', 3230.000),
  (LPAD('503', 44, '0'), '10000000000105', '0000000008', '2026-05-15', 1485.000),
  (LPAD('504', 44, '0'), '10000000000110', '0000000009', '2026-05-20', 7000.000),
  (LPAD('505', 44, '0'), '10000000000110', '0000000009', '2026-05-22', 5020.000),
  (LPAD('506', 44, '0'), '10000000000106', '0000000010', '2026-05-25', 1080.000),
  (LPAD('507', 44, '0'), '10000000000106', '0000000010', '2026-05-28',  580.000),
  (LPAD('508', 44, '0'), '10000000000107', '0000000009', '2026-06-01', 2200.000),
  (LPAD('509', 44, '0'), '10000000000108', '0000000010', '2026-06-05', 1380.000),
  (LPAD('510', 44, '0'), '10000000000104', '0000000008', '2026-06-10',  420.000);


-- ========================= LOTES VENDIDOS =========================
INSERT INTO eh_vendido (id_lote, nf_venda, unidades) VALUES
  (1,  LPAD('501', 44, '0'), 120),
  (2,  LPAD('501', 44, '0'), 100),
  (3,  LPAD('501', 44, '0'),  50),

  (3,  LPAD('502', 44, '0'), 150),
  (4,  LPAD('502', 44, '0'),  80),
  (5,  LPAD('502', 44, '0'),  20),

  (5,  LPAD('503', 44, '0'),  90),
  (11, LPAD('503', 44, '0'),  10),

  (6,  LPAD('504', 44, '0'), 300),
  (8,  LPAD('504', 44, '0'), 200),
  (12, LPAD('504', 44, '0'), 180),

  (11, LPAD('505', 44, '0'), 150),
  (10, LPAD('505', 44, '0'), 160),

  (1,  LPAD('506', 44, '0'),  70),
  (2,  LPAD('506', 44, '0'),  30),

  (5,  LPAD('507', 44, '0'),  40),

  (8,  LPAD('508', 44, '0'), 150),
  (3,  LPAD('508', 44, '0'), 100),

  (11, LPAD('509', 44, '0'),  60),
  (12, LPAD('509', 44, '0'),  30),

  (6,  LPAD('510', 44, '0'),  20),
  (1,  LPAD('510', 44, '0'),  15);

