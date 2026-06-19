

-- O CPF e o CNPJ tem codigos verificadores, acho que daria para usa-los na implementacao

-- Eu estou usando o formatação como na documentacao do postgres

CREATE DOMAIN cnpj_domain AS char(14)
CHECK(VALUE ~ '^\d{14}$');

CREATE DOMAIN num_funcional_domain AS char(20)
CHECK(VALUE ~ '^\d{20}$');

CREATE DOMAIN cpf_domain AS char(14)
CHECK(VALUE ~ '^\d{14}$');


CREATE DOMAIN chave_acesso_nf_domain AS CHAR(44)
CHECK(VALUE ~ '^\d{44}$');



-- Poderia ser mais rigoroso aqui, mas preguica
-- Aqui estou omitindo o codigo +55 para o Brasil
CREATE DOMAIN tel_domain AS varchar(11)
CHECK(VALUE ~ '^\d{10,11}$');

CREATE DOMAIN email_domain AS text
CHECK(VALUE LIKE '%_@__%.__%');


CREATE TABLE pessoa_juridica (
	cnpj cnpj_domain,
	nome_fantasia text NOT NULL,

	CONSTRAINT pk_juridica PRIMARY KEY(cnpj)
);

CREATE TABLE fornecedor (
  cnpj cnpj_domain,

  CONSTRAINT pk_fornecedor PRIMARY KEY(cnpj),

  CONSTRAINT fk_fornecedor FOREIGN KEY(cnpj)
  REFERENCES pessoa_juridica(cnpj)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

CREATE TABLE cliente (
  cnpj cnpj_domain,

  CONSTRAINT pk_cliente PRIMARY KEY(cnpj),
  CONSTRAINT fk_cliente FOREIGN KEY(cnpj)
  REFERENCES pessoa_juridica(cnpj)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

CREATE TABLE email_fornecedor (
	cnpj_fornecedor cnpj_domain,
	email email_domain,


	CONSTRAINT pk_email_fornc PRIMARY KEY(cnpj_fornecedor, email),

	CONSTRAINT fk_email_forn FOREIGN KEY(cnpj_fornecedor)
	REFERENCES fornecedor(cnpj) ON DELETE CASCADE ON UPDATE CASCADE

);

CREATE TABLE tel_fornecedor (
	cnpj_fornecedor cnpj_domain,
	-- Valido para telefones no brasil
	telefone tel_domain,


CONSTRAINT pk_tel_forn PRIMARY KEY(cnpj_fornecedor, telefone),

CONSTRAINT fk_tel_forn FOREIGN KEY(cnpj_fornecedor)
REFERENCES fornecedor(cnpj)
ON DELETE CASCADE
ON UPDATE CASCADE
);


CREATE TABLE email_cliente (
	cnpj_cliente cnpj_domain,
	email email_domain,


	CONSTRAINT pk_email_cliente PRIMARY KEY(cnpj_cliente, email),

	CONSTRAINT fk_email_cliente FOREIGN KEY(cnpj_cliente)
	REFERENCES cliente(cnpj)
ON DELETE CASCADE
ON UPDATE CASCADE

);


CREATE TABLE tel_cliente (
	cnpj_cliente cnpj_domain,
	telefone tel_domain,


  CONSTRAINT pk_tel_cliente PRIMARY KEY(cnpj_cliente, telefone),

  CONSTRAINT fk_tel_cliente FOREIGN KEY(cnpj_cliente)
  REFERENCES cliente(cnpj)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

CREATE TABLE funcionario (
	num_funcional num_funcional_domain,
	cpf cpf_domain NOT NULL,
	salario DECIMAL(10, 2) NOT NULL,
	data_contratacao DATE NOT NULL,
	email email_domain,
	telefone tel_domain,
	nome VARCHAR(30) NOT NULL,
	cargo VARCHAR(13) NOT NULL,

	
	CONSTRAINT pk_funcionario PRIMARY KEY(num_funcional),
	CONSTRAINT un_funcionario_cpf UNIQUE(cpf),
	CONSTRAINT ck_funcionario_cargo CHECK(cargo IN('gerente', 'operador', 'representante')),
	CONSTRAINT ck_salario_funcionario CHECK (salario >= 0)
);


CREATE TABLE gerente (
	num_funcional num_funcional_domain,


	CONSTRAINT pk_gerente PRIMARY KEY(num_funcional),

	CONSTRAINT fk_gerente FOREIGN KEY(num_funcional)
  REFERENCES funcionario(num_funcional)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

CREATE TABLE operador (
	num_funcional num_funcional_domain,


	CONSTRAINT pk_operador PRIMARY KEY(num_funcional),

	CONSTRAINT fk_operador FOREIGN KEY(num_funcional) 
  REFERENCES funcionario(num_funcional) 
  ON DELETE CASCADE 
  ON UPDATE CASCADE
);

CREATE TABLE representante_comercial (
	num_funcional num_funcional_domain,
	comissao DECIMAL(5,4),


	CONSTRAINT pk_representante PRIMARY KEY(num_funcional),

	CONSTRAINT fk_representante FOREIGN KEY(num_funcional) 
  REFERENCES funcionario(num_funcional) 
  ON DELETE CASCADE 
  ON UPDATE CASCADE
);

CREATE TABLE ordem_producao (
	id bigint GENERATED ALWAYS AS IDENTITY,
  gerente num_funcional_domain NOT NULL, 
  data_hora_inicio TIMESTAMPTZ NOT NULL,
  data_hora_fim TIMESTAMPTZ,

  CONSTRAINT pk_ordem_prod PRIMARY KEY(id),

  CONSTRAINT fk_ordem_prod FOREIGN KEY(gerente)
  REFERENCES gerente(num_funcional)
  ON DELETE RESTRICT
  ON UPDATE CASCADE,

  CONSTRAINT un_ordem_prod UNIQUE(gerente, data_hora_inicio),

  CONSTRAINT ck_ordem_prod CHECK(data_hora_fim IS NULL OR data_hora_fim > data_hora_inicio)
);

CREATE TABLE tipo_insumo (
	tipo text,

	CONSTRAINT pk_tipo_insumo PRIMARY KEY(tipo)
);


CREATE TABLE insumo (
	nota_fiscal chave_acesso_nf_domain,
	cnpj_fornecedor cnpj_domain NOT NULL,
	tipo_insumo text NOT NULL,
	custo numeric(9,3),
	data_aquisicao date NOT NULL,
	quantidade integer,
	ordem_producao bigint,


	CONSTRAINT pk_insumo PRIMARY KEY(nota_fiscal),
	
  CONSTRAINT fk_tipo_insumo FOREIGN KEY(tipo_insumo)
  REFERENCES tipo_insumo(tipo)
  ON DELETE RESTRICT
  ON UPDATE RESTRICT,

  CONSTRAINT fk_insumo_ordem FOREIGN KEY(ordem_producao)
  REFERENCES ordem_producao(id)
  ON DELETE SET NULL
  ON UPDATE CASCADE,

  CONSTRAINT custo_pos CHECK(custo >= 0),

  CONSTRAINT quant_pos CHECK(quantidade > 0)
);

CREATE TABLE tipo_residuo (
	tipo text,

	CONSTRAINT pk_tipo_residuo PRIMARY KEY(tipo)
);

CREATE TABLE geracao_residuo (
  ordem_prod bigint, 
  tipo_residuo text, 
  massa_total NUMERIC(8, 3) NOT NULL,
  destino text NOT NULL,
  intermediario text,

  CONSTRAINT pk_geracao_residuo PRIMARY KEY(ordem_prod, tipo_residuo),

  CONSTRAINT fk_geracao_residuo_op FOREIGN KEY(ordem_prod) 
  REFERENCES ordem_producao(id)
  ON DELETE CASCADE
  ON UPDATE CASCADE,

  CONSTRAINT fk_geracao_residuo_tipo FOREIGN KEY(tipo_residuo)
  REFERENCES tipo_residuo(tipo)
  ON DELETE RESTRICT
  ON UPDATE RESTRICT,

  CONSTRAINT ck_geracao_residuo CHECK(massa_total>=0)
);

CREATE TABLE tipo_produto (
	tipo text,
	qtd_estoque integer,
	preco numeric(10,3),


	CONSTRAINT pk_tipo_produto PRIMARY KEY(tipo),

	CONSTRAINT estoque_pos_tipo_prod CHECK (qtd_estoque >= 0),

	CONSTRAINT preco_pos_tipo_prod CHECK (preco > 0)
);

CREATE TABLE lote_produto (
  id bigint GENERATED ALWAYS AS IDENTITY,
  ordem_prod bigint NOT NULL,
  tipo_produto text NOT NULL,
  status text NOT NULL,
  unidades_restantes integer,
  unidades_produzidas integer NOT NULL,
  validade date,


  CONSTRAINT pk_lote_produto PRIMARY KEY(id),

  CONSTRAINT fk_ordem_lote_prod FOREIGN KEY(ordem_prod)
  REFERENCES ordem_producao(id)
  ON DELETE RESTRICT
  ON UPDATE CASCADE,

  CONSTRAINT fk_tipo_lote_prod FOREIGN KEY(tipo_produto)
  REFERENCES tipo_produto(tipo)
  ON DELETE RESTRICT
  ON UPDATE RESTRICT,

  CONSTRAINT unique_lote_prod UNIQUE(ordem_prod, tipo_produto),

  CONSTRAINT status_lote_prod CHECK (status in ('PRONTO', 'VENCIDO', 'CONTAMINADO')),

  CONSTRAINT res_less_prod_lote CHECK (unidades_restantes <= unidades_produzidas),

  CONSTRAINT un_res_pos_lote_prod CHECK (unidades_restantes >= 0),

  CONSTRAINT un_prod_pos_lote_prod CHECK (unidades_produzidas >= 0)
);

CREATE TABLE equipamento (
	numero SMALLINT,
	tipo VARCHAR(30),
	status VARCHAR(13) NOT NULL, 
	ultima_manutencao DATE,


	CONSTRAINT pk_equipamento PRIMARY KEY (numero, tipo),

	CONSTRAINT ck_equipamento CHECK(status IN ('disponivel', 'indisponivel', 'em manutencao'))
);

CREATE TABLE operacao (
	id bigint GENERATED ALWAYS AS IDENTITY,
	num_equip SMALLINT NOT NULL,
	tipo_equip VARCHAR(30) NOT NULL,
	data_hora_inicio TIMESTAMPTZ NOT NULL,
	ord_prod bigint NOT NULL,
	nome VARCHAR(30) NOT NULL,
	gasto_hidrico NUMERIC(12, 3),
	gasto_energetico NUMERIC(12, 3),
	status VARCHAR(12) NOT NULL,
	data_hora_fim TIMESTAMPTZ,

	CONSTRAINT pk_operacao PRIMARY KEY(id),

	CONSTRAINT un_operacao UNIQUE(num_equip, tipo_equip, data_hora_inicio),

	CONSTRAINT fk_operacao_equip FOREIGN KEY(num_equip, tipo_equip) 
  REFERENCES equipamento(numero, tipo) 
  ON DELETE CASCADE 
  ON UPDATE CASCADE,

	CONSTRAINT fk_operacao_ord_prod FOREIGN KEY(ord_prod) 
  REFERENCES ordem_producao(id) 
  ON DELETE CASCADE 
  ON UPDATE CASCADE,

  CONSTRAINT ck_operacao_data_hora CHECK(data_hora_fim IS NULL OR data_hora_fim > data_hora_inicio),

	CONSTRAINT ck_operacao_status CHECK(status IN('nao iniciada', 'em andamento', 'interrompida' , 'concluida'))
);

CREATE TABLE temperatura (
	operacao bigint, 
	data_hora TIMESTAMPTZ,
	graus_celsius NUMERIC(5, 2) NOT NULL,
	
	CONSTRAINT pk_temperatura PRIMARY KEY(operacao, data_hora),

	CONSTRAINT fk_temperatura FOREIGN KEY(operacao) REFERENCES operacao(id) 
  ON DELETE CASCADE 
  ON UPDATE CASCADE
); 

CREATE TABLE trabalho (
	operador num_funcional_domain,
	operacao bigint,
	data DATE,
	turno VARCHAR(10) NOT NULL,

	CONSTRAINT pk_trabalho PRIMARY KEY(operador, operacao, data),
	
  CONSTRAINT fk_trabalho_operador FOREIGN KEY(operador) 
  REFERENCES operador(num_funcional) 
  ON DELETE CASCADE 
  ON UPDATE CASCADE,
  
  CONSTRAINT fk_trabalho_operacao FOREIGN KEY(operacao) 
  REFERENCES operacao(id) 
  ON DELETE CASCADE 
  ON UPDATE CASCADE,
  
  CONSTRAINT ck_trabalho CHECK(turno IN('matutino', 'vespertino', 'noturno'))
);

CREATE TABLE venda (
	nota_fiscal chave_acesso_nf_domain,
	cliente cnpj_domain NOT NULL,
	representante num_funcional_domain NOT NULL,
	data date NOT NULL,
	valor numeric(8,3) NOT NULL,

	CONSTRAINT pk_venda PRIMARY KEY(nota_fiscal),

	CONSTRAINT fk_venda_cliente FOREIGN KEY(cliente)
	REFERENCES cliente(cnpj)
	ON DELETE CASCADE
	ON UPDATE CASCADE,

	CONSTRAINT fk_venda_rep FOREIGN KEY(representante)
	REFERENCES representante_comercial(num_funcional)
	ON DELETE CASCADE
	ON UPDATE CASCADE,

	CONSTRAINT venda_valor_pos CHECK (valor > 0)
);

CREATE TABLE eh_vendido (
	id_lote bigint,
	nf_venda chave_acesso_nf_domain,
	unidades integer NOT NULL,
	
	CONSTRAINT pk_eh_vendido PRIMARY KEY(id_lote, nf_venda),

	CONSTRAINT fk_venda_eh_vendido FOREIGN KEY(nf_venda)
	REFERENCES venda(nota_fiscal)
	ON DELETE CASCADE
	ON UPDATE CASCADE,

	CONSTRAINT fk_lote_eh_vendido FOREIGN KEY(id_lote)
	REFERENCES lote_produto(id)
	ON DELETE RESTRICT
	ON UPDATE CASCADE,

	CONSTRAINT eh_vendido_un_pos CHECK (unidades > 0)
);
