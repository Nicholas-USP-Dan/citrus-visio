import datetime
import os
import re
import tkinter as tk
from decimal import Decimal, InvalidOperation
from tkinter import Event, Tk, ttk, messagebox

import psycopg2 as psy
from psycopg2.extensions import connection
from tkcalendar import DateEntry

# Definição de variáveis
DBNAME: str = "citrusvisio"
DBUSER: str = "postgres"
DBPASS: str = "postgres"


def validate_cod(s: str) -> bool:
    return re.fullmatch("\\d*", s) is not None


def validate_num(s: str) -> bool:
    if s == "":
        return True

    try:
        _ = Decimal(s)
        return True

    except InvalidOperation:
        return False


def obter_tipos(search: str, db_conn: connection) -> list[str]:
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
    def _(event: Event):  # pyright: ignore[reportUnusedParameter]
        entrada = combobox.get()
        sugestoes = obter_tipos(entrada, db_conn)
        combobox["values"] = sugestoes

    return _


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

    def salvar_insumo():
        nf = nf_entry.get().strip()
        cnpj = forn_entry.get().strip()
        tipo = tipo_entry.get().strip()
        custo_str = custo_entry.get().strip()
        data: datetime.date = aquisicao_entry.get_date()  # Retorna datetime.date
        quant_str = quant_entry.get().strip()

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

        try:
            custo = Decimal(custo_str)
            if custo < 0:
                raise ValueError
        except (InvalidOperation, ValueError):
            _ = messagebox.showwarning(
                "Custo Inválido",
                "O custo deve ser um número decimal válido e não-negativo (ex: 1250.75).",
            )
            return

        try:
            quant = int(quant_str)
            if quant <= 0:
                raise ValueError
        except ValueError:
            _ = messagebox.showwarning(
                "Quantidade Inválida",
                "A quantidade deve ser um número inteiro positivo maior que zero.",
            )
            return

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
                        cur.execute(
                            "INSERT INTO fornecedor (cnpj) VALUES (%s);", (cnpj,)
                        )
                    else:
                        _ = messagebox.showerror(
                            "Fornecedor Não Encontrado",
                            f"O CNPJ '{cnpj}' não corresponde a nenhuma pessoa jurídica cadastrada.\n"
                            + "Cadastre a pessoa jurídica no banco antes de cadastrar o insumo.",
                        )
                        db_conn.rollback()
                        return

                # Verificar se o tipo de insumo existe no banco
                cur.execute("SELECT 1 FROM tipo_insumo WHERE tipo = %s;", (tipo,))
                if not cur.fetchone():
                    confirmar = messagebox.askyesno(
                        "Tipo de Insumo Novo",
                        f"O tipo de insumo '{tipo}' não existe no banco de dados.\nDeseja cadastrá-lo automaticamente?",
                    )
                    if confirmar:
                        cur.execute(
                            "INSERT INTO tipo_insumo (tipo) VALUES (%s);", (tipo,)
                        )
                    else:
                        db_conn.rollback()
                        return

                # Inserção principal usando SQL explícito parametrizado (proteção contra SQL Injection)
                query = """
                    INSERT INTO insumo (nota_fiscal, cnpj_fornecedor, tipo_insumo, custo, data_aquisicao, quantidade)
                    VALUES (%s, %s, %s, %s, %s, %s);
                """
                cur.execute(query, (nf, cnpj, tipo, custo, data, quant))

            # Commit se tudo ocorreu bem
            db_conn.commit()
            _ = messagebox.showinfo("Sucesso", "Insumo cadastrado com sucesso!")

            # Limpar os campos após inserção bem sucedida
            nf_entry.delete(0, tk.END)
            forn_entry.delete(0, tk.END)
            tipo_entry.set("")
            custo_entry.delete(0, tk.END)
            quant_entry.delete(0, tk.END)

            # Atualizar sugestões no Combobox
            tipo_entry["values"] = obter_tipos("", db_conn)

        except psy.DatabaseError as e:
            # Em caso de qualquer erro de banco de dados, desfaz a transação para não corromper o estado da conexão
            db_conn.rollback()
            _ = messagebox.showerror(
                "Erro do SGBD",
                f"Erro na transação com o PostgreSQL:\n\n{e.pgerror or str(e)}",
            )
        except Exception as e:
            db_conn.rollback()
            _ = messagebox.showerror(
                "Erro Inesperado", f"Ocorreu um erro inesperado ao salvar:\n\n{str(e)}"
            )

    # Separador antes do botão
    sep2 = ttk.Separator(container, orient="horizontal")
    sep2.grid(row=8, column=0, columnspan=2, sticky="ew", pady=(18, 10))

    # Botão de salvar em destaque (Accent)
    btn_salvar = ttk.Button(
        container,
        text="  Salvar Insumo  ",
        command=salvar_insumo,
        style="Accent.TButton",
    )
    btn_salvar.grid(row=9, column=0, columnspan=2, pady=(0, 4))

    notebook.add(frame, text="Cadastro Insumo")

    return


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
        command=lambda: realizar_busca(),
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
    def realizar_busca():
        termo = ent_gerente.get().strip()

        # Limpa os itens atuais
        for item in tree.get_children():
            tree.delete(item)

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

    # Configura zebra stripes (cores alternadas entre linhas)
    _ = tree.tag_configure("par", background="#f7f9f7")
    _ = tree.tag_configure("impar", background="#ffffff")

    # Vincula o Enter à execução da busca
    _ = ent_gerente.bind("<Return>", lambda e: realizar_busca())

    # Preenche a busca inicial vazia (todas)
    realizar_busca()

    notebook.add(frame, text="Consulta de Ordens")

    # Retorna o widget tree para que o tema possa atualizar as cores das zebra stripes
    return tree


def monta_ui(root: Tk, db_conn: connection) -> None:
    root.title("CitrusVisio Dashboard")
    root.option_add("*TearOff", False)  # pyright: ignore[reportUnknownMemberType]

    # Grid principal da janela
    _ = root.columnconfigure(0, weight=1)
    _ = root.rowconfigure(0, weight=0)  # Barra superior de controle (não estica)
    _ = root.rowconfigure(1, weight=1)  # Conteúdo principal (Notebook)

    # 1. Carrega ambos os temas do repositório Forest
    script_dir = os.path.dirname(os.path.abspath(__file__))
    theme_path_light = os.path.join(script_dir, "Forest-ttk-theme", "forest-light.tcl")
    theme_path_dark = os.path.join(script_dir, "Forest-ttk-theme", "forest-dark.tcl")

    root.tk.call("source", theme_path_light)
    root.tk.call("source", theme_path_dark)

    style = ttk.Style(root)
    style.theme_use("forest-light")
    style.configure("lefttab.TNotebook", tabposition="wn")

    # 2. Barra de Cabeçalho Superior Premium
    top_bar = ttk.Frame(root, padding=(15, 10, 15, 10))
    top_bar.grid(row=0, column=0, sticky="ew")

    # Título do Dashboard
    title_lbl = ttk.Label(top_bar, text="CitrusVisio", font="-size 16 -weight bold")
    title_lbl.pack(side="left", padx=(5, 5))

    status_lbl = ttk.Label(
        top_bar, text="• Gestão Operacional", font="-size 10", foreground="#2E7D32"
    )
    status_lbl.pack(side="left", padx=5, pady=(5, 0))

    # Callback de troca dinâmica de tema
    def toggle_theme():
        if switch_var.get():
            style.theme_use("forest-dark")
            _ = status_lbl.configure(
                foreground="#81C784"
            )  # Tom de verde claro para fundo escuro
            # Zebra stripes adaptadas para o modo escuro
            _ = ordens_tree.tag_configure("par", background="#2d2d2d")
            _ = ordens_tree.tag_configure("impar", background="#383838")
        else:
            style.theme_use("forest-light")
            _ = status_lbl.configure(
                foreground="#2E7D32"
            )  # Tom de verde escuro para fundo claro
            # Zebra stripes adaptadas para o modo claro
            _ = ordens_tree.tag_configure("par", background="#f7f9f7")
            _ = ordens_tree.tag_configure("impar", background="#ffffff")

        # Reaplica configurações de abas à esquerda
        style.configure("lefttab.TNotebook", tabposition="wn")

    # Interruptor de Tema (Switch)
    switch_var = tk.BooleanVar(value=False)
    theme_switch = ttk.Checkbutton(
        top_bar,
        text="Modo Escuro",
        style="Switch",
        variable=switch_var,
        command=toggle_theme,
    )
    theme_switch.pack(side="right", padx=10)

    # Separador horizontal abaixo da barra superior (dá profundidade visual)
    top_sep = ttk.Separator(root, orient="horizontal")
    top_sep.grid(row=0, column=0, sticky="sew")

    # 3. Painel Principal (Contendo o Notebook com Abas)
    frame = ttk.Frame(root, padding=5)
    frame.grid(row=1, column=0, sticky="nsew")
    _ = frame.columnconfigure(0, weight=1)
    _ = frame.rowconfigure(0, weight=1)

    notebook = ttk.Notebook(frame, padding=5, style="lefttab.TNotebook")
    notebook.grid(column=0, row=0, sticky="nsew")

    # Aba 1: Cadastro de Insumos
    registrar_frame_cadastro_insumo(notebook, db_conn)

    # Aba 2: Consulta de Ordens — captura o widget tree para o toggle_theme
    ordens_tree = registrar_frame_consulta_ordens(notebook, db_conn)

    # Forçar renderização geométrica
    root.update()
    root.minsize(950, 550)
    x_cordinate = int((root.winfo_screenwidth() / 2) - (950 / 2))
    y_cordinate = int((root.winfo_screenheight() / 2) - (550 / 2))
    root.geometry("950x550+{}+{}".format(x_cordinate, y_cordinate))


if __name__ == "__main__":
    db_conn = None
    try:
        db_conn = psy.connect(
            host="localhost", port=5433, dbname=DBNAME, user=DBUSER, password=DBPASS
        )
    except Exception as e:
        print(f"Erro crítico de conexão com o banco de dados PostgreSQL: {e}")
        # Se a conexão falhar, mostra o popup amigável
        root_temp = tk.Tk()
        root_temp.withdraw()
        _ = messagebox.showerror(
            "Falha de Conexão",
            f"Não foi possível conectar ao banco PostgreSQL (host=localhost, dbname={DBNAME}, port=5433).\n\n"
            f"Verifique se o container docker está ativo.\n\nDetalhes:\n{e}",
        )
        root_temp.destroy()
        exit(1)

    try:
        root = tk.Tk()
        monta_ui(root, db_conn)
        root.mainloop()
    except Exception as e:
        print(f"Erro crítico ao inicializar a interface gráfica: {e}")
    finally:
        if db_conn is not None and not db_conn.closed:
            db_conn.close()
