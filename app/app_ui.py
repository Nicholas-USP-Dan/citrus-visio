import datetime
import re
import tkinter as tk
from decimal import Decimal, InvalidOperation
from tkinter import Event, ttk, messagebox

import psycopg2 as psy
from psycopg2.extensions import connection
from tkcalendar import DateEntry


# Funções de validação de entrada
def validate_cod(s: str) -> bool:
    "Validação para códigos numéricos (0123)"
    return re.fullmatch("\\d*", s) is not None


def validate_num(s: str) -> bool:
    "Validação para valores decimais (123.45)"
    if s == "":
        return True

    try:
        _ = Decimal(s)
        return True

    except InvalidOperation:
        return False


def obter_tipos(search: str, db_conn: connection) -> list[str]:
    """
    Busca por 10 tipos de insumos baseados na entrada `search`.
    """
    try:
        with db_conn.cursor() as db_cursor:
            db_cursor.execute(
                "SELECT tipo FROM tipo_insumo WHERE tipo ILIKE %s LIMIT 10;",
                (f"{search}%",),
            )
            top_tipos_rows = db_cursor.fetchall()
            return [row[0] for row in top_tipos_rows]
    except Exception:
        return []


def filter_tipos(combobox: ttk.Combobox, db_conn: connection):
    """
    Construtor de trigger de evento para ser acionado conforme
    a entrada de tipo de insumo for sendo escrita.
    """

    def f(event: Event):  # pyright: ignore[reportUnusedParameter]
        entrada = combobox.get()
        sugestoes = obter_tipos(entrada, db_conn)
        combobox["values"] = sugestoes

    return f


def salvar_insumo(
    nf: str,
    cnpj: str,
    tipo: str,
    custo_str: str,
    data: datetime.date,
    quant_str: str,
    db_conn: connection,
) -> None:
    # 1. Validações de entrada locais na interface
    if not nf or not cnpj or not tipo or not custo_str or not quant_str:
        _ = messagebox.showwarning(
            "Dados Incompletos",
            "Por favor, preencha todos os campos do formulário.",
        )
        return

    if len(nf) != 44:
        _ = messagebox.showwarning(
            "Nota Fiscal Inválida",
            "A chave de acesso da Nota Fiscal deve conter exatamente 44 dígitos.",
        )
        return

    if len(cnpj) != 14:
        _ = messagebox.showwarning(
            "CNPJ Inválido",
            "O CNPJ do fornecedor deve conter exatamente 14 dígitos.",
        )
        return

    custo = Decimal(custo_str)
    if custo < 0:
        _ = messagebox.showwarning(
            "Custo Inválido",
            "O custo deve ser um número decimal válido e não-negativo (ex: 1250.75).",
        )
        return

    quant = int(quant_str)
    if quant <= 0:
        _ = messagebox.showwarning(
            "Quantidade Inválida",
            "A quantidade deve ser um número inteiro positivo maior que zero.",
        )

    # 2. Transação no Banco de Dados com Controle de Erros
    try:
        with db_conn.cursor() as cur:
            # Verificar se o fornecedor existe no banco
            cur.execute("SELECT 1 FROM fornecedor WHERE cnpj = %s;", (cnpj,))
            if not cur.fetchone():
                # Se não for fornecedor direto, verificar se existe na pessoa_juridica
                cur.execute(
                    "SELECT nome_fantasia FROM pessoa_juridica WHERE cnpj = %s;",
                    (cnpj,),
                )
                pj_row = cur.fetchone()
                if pj_row:
                    # Promove a pessoa jurídica a fornecedor
                    cur.execute("INSERT INTO fornecedor (cnpj) VALUES (%s);", (cnpj,))
                else:
                    _ = messagebox.showerror(
                        "Fornecedor Não Encontrado",
                        f"O CNPJ '{cnpj}' não corresponde a nenhuma pessoa jurídica cadastrada.\n"
                        + "Cadastre a pessoa jurídica no banco antes de cadastrar o insumo.",
                    )
                    db_conn.rollback()
                    raise ValueError("Fornecedor não encontrado na base de dados")

            # Verificar se o tipo de insumo existe no banco
            cur.execute("SELECT 1 FROM tipo_insumo WHERE tipo = %s;", (tipo,))
            if not cur.fetchone():
                confirmar = messagebox.askyesno(
                    "Tipo de Insumo Novo",
                    f"O tipo de insumo '{tipo}' não existe no banco de dados.\nDeseja cadastrá-lo automaticamente?",
                )
                if confirmar:
                    cur.execute("INSERT INTO tipo_insumo (tipo) VALUES (%s);", (tipo,))
                else:
                    db_conn.rollback()
                    raise ValueError("Tipo de insumo não encontrado na base de dados")

            # Inserção principal usando SQL explícito parametrizado (proteção contra SQL Injection)
            query = """
                INSERT INTO insumo (nota_fiscal, cnpj_fornecedor, tipo_insumo, custo, data_aquisicao, quantidade)
                VALUES (%s, %s, %s, %s, %s, %s);
            """
            cur.execute(query, (nf, cnpj, tipo, custo, data, quant))

        # Commit se tudo ocorreu bem
        db_conn.commit()
        _ = messagebox.showinfo("Sucesso", "Insumo cadastrado com sucesso!")

    except psy.DatabaseError as e:
        # Em caso de qualquer erro de banco de dados, desfaz a transação para não corromper o estado da conexão
        db_conn.rollback()
        _ = messagebox.showerror(
            "Erro do SGBD",
            f"Erro na transação com o PostgreSQL:\n\n{e.pgerror or str(e)}",
        )
        raise e

    except Exception as e:
        db_conn.rollback()
        _ = messagebox.showerror(
            "Erro Inesperado", f"Ocorreu um erro inesperado ao salvar:\n\n{str(e)}"
        )
        raise e


def registrar_frame_cadastro_insumo(
    notebook: ttk.Notebook, db_conn: connection
) -> None:
    """
    Registra o frame com a funcionalidade 'Cadastrar Insumo'
    com parente `notebook`
    """

    # Configuração inicial
    frame = ttk.Frame(notebook)
    frame.grid(sticky="nsew")

    # Frame cresce junto com a janela
    _ = frame.columnconfigure(0, weight=1)
    _ = frame.rowconfigure(0, weight=1)

    # Container centralizado dentro do frame como um Card Fluent moderno
    container = ttk.Frame(frame, style="Card", padding=25)
    container.grid(row=0, column=0, padx=20, pady=20)
    _ = container.columnconfigure(0, weight=1)
    _ = container.columnconfigure(1, weight=1)

    # Configuração do título com fonte maior e em negrito
    header = ttk.Label(
        container, text="Cadastro de Insumos", font="-size 14 -weight bold"
    )
    header.grid(row=0, column=0, columnspan=2, pady=(0, 8))

    # Separador visual abaixo do título
    sep = ttk.Separator(container, orient="horizontal")
    sep.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(0, 16))

    # Entrada da nota fiscal (aceita somente dígitos de 0-9)
    nf_label = ttk.Label(container, text="Nota Fiscal:", font="-weight bold")
    nf_label.grid(row=2, column=0, sticky="e", padx=(0, 12), pady=7)
    nf_entry = ttk.Entry(
        container,
        width=36,
        validate="key",
        validatecommand=(frame.register(validate_cod), "%P"),
    )
    nf_entry.grid(row=2, column=1, sticky="w", pady=7)

    # Entrada para o CNPJ (aceita somente dígitos de 0-9)
    forn_label = ttk.Label(container, text="CNPJ do Fornecedor:", font="-weight bold")
    forn_label.grid(row=3, column=0, sticky="e", padx=(0, 12), pady=7)
    forn_entry = ttk.Entry(
        container,
        width=36,
        validate="key",
        validatecommand=(frame.register(validate_cod), "%P"),
    )
    forn_entry.grid(row=3, column=1, sticky="w", pady=7)

    # Entrada para o tipo do insumo
    tipo_label = ttk.Label(container, text="Tipo de Insumo:", font="-weight bold")
    tipo_label.grid(row=4, column=0, sticky="e", padx=(0, 12), pady=7)
    tipo_entry = ttk.Combobox(container, width=33)
    # Mecanismo de sugestoes dos tipos
    tipo_entry["values"] = obter_tipos("", db_conn)
    _ = tipo_entry.bind("<KeyRelease>", filter_tipos(tipo_entry, db_conn))
    tipo_entry.grid(row=4, column=1, sticky="w", pady=7)

    # Entrada para o custo do insumo
    custo_label = ttk.Label(container, text="Custo (R$):", font="-weight bold")
    custo_label.grid(row=5, column=0, sticky="e", padx=(0, 12), pady=7)
    custo_entry = ttk.Entry(
        container,
        width=36,
        validate="key",
        validatecommand=(frame.register(validate_num), "%P"),
    )
    custo_entry.grid(row=5, column=1, sticky="w", pady=7)

    # Entrada para a data de aquisição do insumo
    aquisicao_label = ttk.Label(
        container, text="Data de Aquisição:", font="-weight bold"
    )
    aquisicao_label.grid(row=6, column=0, sticky="e", padx=(0, 12), pady=7)
    aquisicao_entry = DateEntry(container, locale="pt_BR", width=33)
    aquisicao_entry.grid(row=6, column=1, sticky="w", pady=7)  # pyright: ignore[reportUnknownMemberType]

    # Entrada para a quantidade
    quant_label = ttk.Label(container, text="Quantidade:", font="-weight bold")
    quant_label.grid(row=7, column=0, sticky="e", padx=(0, 12), pady=7)
    quant_entry = ttk.Entry(
        container,
        width=36,
        validate="key",
        validatecommand=(frame.register(validate_cod), "%P"),
    )
    quant_entry.grid(row=7, column=1, sticky="w", pady=7)

    def salvar_insumo_btn():
        nf = nf_entry.get().strip()
        cnpj = forn_entry.get().strip()
        tipo = tipo_entry.get().strip()
        custo_str = custo_entry.get().strip()
        data: datetime.date = aquisicao_entry.get_date()  # Retorna datetime.date
        quant_str = quant_entry.get().strip()

        try:
            salvar_insumo(nf, cnpj, tipo, custo_str, data, quant_str, db_conn)

            # Limpar os campos após inserção bem sucedida
            nf_entry.delete(0, tk.END)
            forn_entry.delete(0, tk.END)
            tipo_entry.set("")
            custo_entry.delete(0, tk.END)
            quant_entry.delete(0, tk.END)

            # Atualizar sugestões no Combobox
            tipo_entry["values"] = obter_tipos("", db_conn)

        except Exception as _:
            pass

    # Separador antes do botão
    sep2 = ttk.Separator(container, orient="horizontal")
    sep2.grid(row=8, column=0, columnspan=2, sticky="ew", pady=(18, 10))

    # Botão de salvar em destaque (Accent)
    btn_salvar = ttk.Button(
        container,
        text="  Salvar Insumo  ",
        command=salvar_insumo_btn,
        style="Accent.TButton",
    )
    btn_salvar.grid(row=9, column=0, columnspan=2, pady=(0, 4))

    notebook.add(frame, text="Cadastro Insumo")

    return


def realizar_busca_ordens(termo: str, tree: ttk.Treeview, db_conn: connection):
    try:
        with db_conn.cursor() as cur:
            # Consulta SQL explícita e parametrizada (segurança contra SQL Injection)
            query = """
                SELECT
                    op.id,
                    f.nome,
                    TO_CHAR(op.data_hora_inicio, 'DD/MM/YYYY HH24:MI'),
                    COALESCE(TO_CHAR(op.data_hora_fim, 'DD/MM/YYYY HH24:MI'), 'Em andamento'),
                    COALESCE(SUM(o.gasto_energetico), 0.0),
                    COALESCE(SUM(o.gasto_hidrico), 0.0)
                FROM ordem_producao op
                JOIN funcionario f ON op.gerente = f.num_funcional
                LEFT JOIN operacao o ON o.ord_prod = op.id
                WHERE f.nome ILIKE %s
                GROUP BY op.id, f.nome
                ORDER BY op.id DESC;
            """
            cur.execute(query, (f"%{termo}%",))
            rows = cur.fetchall()

            for i, row in enumerate(rows):
                gasto_energia = f"{float(row[4]):.3f}"  # pyright: ignore[reportAny]
                gasto_agua = f"{float(row[5]):.3f}"  # pyright: ignore[reportAny]
                # Alterna o tag para criar efeito zebra (linhas pares e ímpares)
                tag = "par" if i % 2 == 0 else "impar"
                _ = tree.insert(
                    "",
                    "end",
                    values=(
                        row[0],
                        row[1],
                        row[2],
                        row[3],
                        gasto_energia,
                        gasto_agua,
                    ),
                    tags=(tag,),
                )

    except psy.DatabaseError as e:
        db_conn.rollback()
        _ = messagebox.showerror(
            "Erro de Banco de Dados",
            f"Erro ao buscar ordens de produção:\n\n{e.pgerror or str(e)}",
        )
    except Exception as e:
        db_conn.rollback()
        _ = messagebox.showerror(
            "Erro Inesperado", f"Ocorreu um erro ao pesquisar:\n\n{str(e)}"
        )


def registrar_frame_consulta_ordens(
    notebook: ttk.Notebook, db_conn: connection
) -> ttk.Treeview:
    """
    Registra o frame com a funcionalidade 'Consulta de Ordens por Gerente'
    com parente `notebook`
    """
    # Configuração inicial do Frame com padding
    frame = ttk.Frame(notebook, padding=15)
    frame.grid(sticky="nsew")

    # Layout responsivo
    _ = frame.columnconfigure(0, weight=1)
    _ = frame.rowconfigure(1, weight=1)  # A tabela crescerá verticalmente

    # 1. Painel de Filtro de Busca (Estilizado como Card Fluent)
    search_frame = ttk.Frame(frame, style="Card", padding=15)
    search_frame.grid(row=0, column=0, sticky="ew", pady=(0, 15))
    _ = search_frame.columnconfigure(1, weight=1)

    lbl_gerente = ttk.Label(search_frame, text="Nome do Gerente: ", font="-weight bold")
    lbl_gerente.grid(row=0, column=0, sticky="w", padx=(0, 10))

    ent_gerente = ttk.Entry(search_frame)
    ent_gerente.grid(row=0, column=1, sticky="ew", padx=(0, 15))

    # Botão de busca estilizado com Accent
    btn_buscar = ttk.Button(
        search_frame,
        text="Buscar",
        command=lambda: realizar_busca_btn(),
        style="Accent.TButton",
    )
    btn_buscar.grid(row=0, column=2, sticky="e")

    # 2. Tabela de Resultados (Treeview)
    table_frame = ttk.Frame(frame)
    table_frame.grid(row=1, column=0, sticky="nsew")
    _ = table_frame.columnconfigure(0, weight=1)
    _ = table_frame.rowconfigure(0, weight=1)

    # Definir colunas da Treeview
    columns = ("id_ordem", "gerente", "inicio", "fim", "gasto_energia", "gasto_agua")
    tree = ttk.Treeview(
        table_frame, columns=columns, show="headings", selectmode="browse"
    )

    # Configurar cabeçalhos
    tree.heading("id_ordem", text="ID Ordem")
    tree.heading("gerente", text="Gerente Responsável")
    tree.heading("inicio", text="Data/Hora Início")
    tree.heading("fim", text="Data/Hora Fim")
    tree.heading("gasto_energia", text="Energia (kWh)")
    tree.heading("gasto_agua", text="Água (L)")

    # Configurar dimensões e alinhamentos
    _ = tree.column("id_ordem", width=90, anchor="center")
    _ = tree.column("gerente", width=220, anchor="w")
    _ = tree.column("inicio", width=160, anchor="center")
    _ = tree.column("fim", width=160, anchor="center")
    _ = tree.column("gasto_energia", width=130, anchor="e")
    _ = tree.column("gasto_agua", width=130, anchor="e")

    # Barras de rolagem
    vsb = ttk.Scrollbar(table_frame, orient="vertical", command=tree.yview)
    hsb = ttk.Scrollbar(table_frame, orient="horizontal", command=tree.xview)
    _ = tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

    tree.grid(row=0, column=0, sticky="nsew")
    vsb.grid(row=0, column=1, sticky="ns")
    hsb.grid(row=1, column=0, sticky="ew")

    # Lógica de Busca parametrizada
    def realizar_busca_btn():
        termo = ent_gerente.get().strip()

        # Limpa os itens atuais
        for item in tree.get_children():
            tree.delete(item)

        realizar_busca_ordens(termo, tree, db_conn)

    # Configura zebra stripes (cores alternadas entre linhas)
    _ = tree.tag_configure("par", background="#f7f9f7")
    _ = tree.tag_configure("impar", background="#ffffff")

    # Vincula o Enter à execução da busca
    _ = ent_gerente.bind("<Return>", lambda e: realizar_busca_btn())

    # Preenche a busca inicial vazia (todas)
    realizar_busca_btn()

    notebook.add(frame, text="Consulta de Ordens")

    # Retorna o widget tree para que o tema possa atualizar as cores das zebra stripes
    return tree


def realizar_busca_vendas(
    termo_representante: str,
    termo_cliente: str,
    tree: ttk.Treeview,
    db_conn: connection,
):
    """
    Executa a consulta de vendas por representante comercial,
    filtrada por nome do representante e/ou nome fantasia do cliente,
    incluindo o valor de comissão gerado por cada venda.
    """
    try:
        with db_conn.cursor() as cur:
            # Consulta SQL explícita e parametrizada (segurança contra SQL Injection)
            query = """
                SELECT
                    v.nota_fiscal,
                    f.nome                                      AS nome_representante,
                    pj.nome_fantasia                            AS cliente,
                    TO_CHAR(v.data, 'DD/MM/YYYY')              AS data_venda,
                    v.valor,
                    ROUND(v.valor * rc.comissao, 2)            AS comissao_gerada
                FROM
                    venda v
                JOIN representante_comercial rc ON rc.num_funcional = v.representante
                JOIN funcionario f              ON f.num_funcional   = rc.num_funcional
                JOIN cliente cl                 ON cl.cnpj           = v.cliente
                JOIN pessoa_juridica pj         ON pj.cnpj           = cl.cnpj
                WHERE
                    f.nome              ILIKE %s
                    AND pj.nome_fantasia ILIKE %s
                ORDER BY v.data DESC, v.valor DESC;
            """
            cur.execute(query, (f"%{termo_representante}%", f"%{termo_cliente}%"))
            rows = cur.fetchall()
 
            for i, row in enumerate(rows):
                # Trunca a nota fiscal (44 dígitos) para caber na coluna:
                # exibe primeiros 10 + "..." + últimos 6
                nf_raw: str = row[0]
                nf_display = f"{nf_raw[:10]}...{nf_raw[-6:]}" if len(nf_raw) > 20 else nf_raw
                valor    = f"R$ {float(row[4]):.2f}"  # pyright: ignore[reportAny]
                comissao = f"R$ {float(row[5]):.2f}"  # pyright: ignore[reportAny]
                # Alterna o tag para criar efeito zebra (linhas pares e ímpares)
                tag = "par" if i % 2 == 0 else "impar"
                _ = tree.insert(
                    "",
                    "end",
                    values=(nf_display, row[1], row[2], row[3], valor, comissao),
                    tags=(tag,),
                )
 
    except psy.DatabaseError as e:
        db_conn.rollback()
        _ = messagebox.showerror(
            "Erro de Banco de Dados",
            f"Erro ao buscar vendas:\n\n{e.pgerror or str(e)}",
        )
    except Exception as e:
        db_conn.rollback()
        _ = messagebox.showerror(
            "Erro Inesperado", f"Ocorreu um erro ao pesquisar:\n\n{str(e)}"
        )
 
 
def registrar_frame_consulta_vendas(
    notebook: ttk.Notebook, db_conn: connection
)-> ttk.Treeview:
    """
    Registra o frame com a funcionalidade 'Consulta de Vendas por Representante'
    com parente `notebook`.
    """
    frame = ttk.Frame(notebook, padding=15)
    frame.grid(sticky="nsew")
 
    # Layout responsivo
    _ = frame.columnconfigure(0, weight=1)
    _ = frame.rowconfigure(1, weight=1)  # A tabela crescerá verticalmente
 
    # 1. Painel de Filtro de Busca (Estilizado como Card Fluent)
    search_frame = ttk.Frame(frame, style="Card", padding=15)
    search_frame.grid(row=0, column=0, sticky="ew", pady=(0, 15))
    _ = search_frame.columnconfigure(1, weight=1)
    _ = search_frame.columnconfigure(3, weight=1)
 
    lbl_rep = ttk.Label(search_frame, text="Representante:", font="-weight bold")
    lbl_rep.grid(row=0, column=0, sticky="w", padx=(0, 8))
 
    ent_representante = ttk.Entry(search_frame)
    ent_representante.grid(row=0, column=1, sticky="ew", padx=(0, 20))
 
    lbl_cli = ttk.Label(search_frame, text="Cliente:", font="-weight bold")
    lbl_cli.grid(row=0, column=2, sticky="w", padx=(0, 8))
 
    ent_cliente = ttk.Entry(search_frame)
    ent_cliente.grid(row=0, column=3, sticky="ew", padx=(0, 15))
 
    # Botão de busca estilizado com Accent
    btn_buscar = ttk.Button(
        search_frame,
        text="Buscar",
        style="Accent.TButton",
        command=lambda: realizar_busca_btn(),
    )
    btn_buscar.grid(row=0, column=4, sticky="e")
 
    # 2. Tabela de Resultados (Treeview)
    table_frame = ttk.Frame(frame)
    table_frame.grid(row=1, column=0, sticky="nsew")
    _ = table_frame.columnconfigure(0, weight=1)
    _ = table_frame.rowconfigure(0, weight=1)
 
    # Definir colunas da Treeview
    columns = ("nota_fiscal", "representante", "cliente", "data", "valor", "comissao")
    tree = ttk.Treeview(
        table_frame, columns=columns, show="headings", selectmode="browse"
    )
 
    # Configurar cabeçalhos
    tree.heading("nota_fiscal",   text="Nota Fiscal")
    tree.heading("representante", text="Representante")
    tree.heading("cliente",       text="Cliente")
    tree.heading("data",          text="Data")
    tree.heading("valor",         text="Valor")
    tree.heading("comissao",      text="Comissão Gerada")
 
    # Configurar dimensões e alinhamentos
    _ = tree.column("nota_fiscal",   width=160, anchor="center")
    _ = tree.column("representante", width=180, anchor="w")
    _ = tree.column("cliente",       width=180, anchor="w")
    _ = tree.column("data",          width=100, anchor="center")
    _ = tree.column("valor",         width=110, anchor="e")
    _ = tree.column("comissao",      width=120, anchor="e")
 
    # Barras de rolagem
    vsb = ttk.Scrollbar(table_frame, orient="vertical",   command=tree.yview)
    hsb = ttk.Scrollbar(table_frame, orient="horizontal", command=tree.xview)
    _ = tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)
 
    tree.grid(row=0, column=0, sticky="nsew")
    vsb.grid(row=0, column=1, sticky="ns")
    hsb.grid(row=1, column=0, sticky="ew")
 
    # Lógica de Busca parametrizada
    def realizar_busca_btn():
        termo_rep = ent_representante.get().strip()
        termo_cli = ent_cliente.get().strip()
 
        # Limpa os itens atuais
        for item in tree.get_children():
            tree.delete(item)
 
        realizar_busca_vendas(termo_rep, termo_cli, tree, db_conn)
 
    # Configura zebra stripes (cores alternadas entre linhas)
    _ = tree.tag_configure("par",   background="#f7f9f7")
    _ = tree.tag_configure("impar", background="#ffffff")
 
    # Vincula o Enter à execução da busca em ambos os campos
    _ = ent_representante.bind("<Return>", lambda e: realizar_busca_btn())
    _ = ent_cliente.bind("<Return>",       lambda e: realizar_busca_btn())
 
    # Preenche a busca inicial vazia (todas)
    realizar_busca_btn()
 
    notebook.add(frame, text="Vendas por Representante")
 
    # Retorna o widget tree para que o tema possa atualizar as cores das zebra stripes
    return tree


 

