# Provavelmente tkinter já deve estar instalado

import re
import tkinter as tk
from decimal import Decimal, InvalidOperation
from tkinter import Event, Tk, ttk

import psycopg2 as psy
from psycopg2.extensions import cursor
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


def obter_tipos(search: str, db_cursor: cursor):
    db_cursor.execute(
        "SELECT * FROM tipo_insumo WHERE tipo ILIKE %s LIMIT 10;", (f"{search}%",)
    )
    top_tipos_rows = db_cursor.fetchall()
    return [row[0] for row in top_tipos_rows]


def filter_tipos(combobox: ttk.Combobox, db_cursor: cursor):
    def _(event: Event):  # pyright: ignore[reportUnusedParameter]
        entrada = combobox.get()
        sugestoes = obter_tipos(entrada, db_cursor)
        combobox["values"] = sugestoes

    return _


def registrar_frame_cadastro_insumo(notebook: ttk.Notebook, db_cursor: cursor) -> None:
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

    # Container centralizado dentro do frame
    container = ttk.Frame(frame)
    container.grid(row=0, column=0)
    _ = container.columnconfigure(0, weight=1)
    _ = container.columnconfigure(1, weight=1)

    # Configuração do título
    header = ttk.Label(container, text="Cadastro de Insumos")
    header.grid(row=0, column=0, columnspan=2, pady=(0, 10))
    _ = header.configure(font="-weight bold")

    # Entrada da nota fiscal (aceita somente dígitos de 0-9)
    nf_label = ttk.Label(container, text="Nota Fiscal: ")
    nf_label.grid(row=1, column=0, sticky="e")
    nf_entry = ttk.Entry(
        container,
        width=35,
        validate="key",
        validatecommand=(frame.register(validate_cod), "%P"),
    )
    nf_entry.grid(row=1, column=1, sticky="w", padx=(10, 0), pady=4)

    # Entrada para o CNPJ (aceita somente dígitos de 0-9)
    forn_label = ttk.Label(container, text="CNPJ do fornecedor: ")
    forn_label.grid(row=2, column=0, sticky="e")
    forn_entry = ttk.Entry(
        container,
        width=35,
        validate="key",
        validatecommand=(frame.register(validate_cod), "%P"),
    )
    forn_entry.grid(row=2, column=1, sticky="w", padx=(10, 0), pady=4)

    # Entrada para o tipo do insumo
    tipo_label = ttk.Label(container, text="Tipo de insumo: ")
    tipo_label.grid(row=3, column=0, sticky="e")
    tipo_entry = ttk.Combobox(container)
    # Mecanismo de sugestoes dos tipos
    # Caso seja inserido um tipo que nao exista,
    # o usuario e sugerido a criar
    tipo_entry["values"] = obter_tipos("", db_cursor)
    _ = tipo_entry.bind("<KeyRelease>", filter_tipos(tipo_entry, db_cursor))
    tipo_entry.grid(row=3, column=1, sticky="w", padx=(10, 0), pady=4)

    # Entrada para o custo do insumo
    custo_label = ttk.Label(container, text="Custo: ")
    custo_label.grid(row=4, column=0, sticky="e")
    custo_entry = ttk.Entry(
        container,
        width=35,
        validate="key",
        validatecommand=(frame.register(validate_num), "%P"),
    )
    custo_entry.grid(row=4, column=1, sticky="w", padx=(10, 0), pady=4)

    # Entrada para a data de aquisição do insumo
    aquisicao_label = ttk.Label(container, text="Data de aquisição: ")
    aquisicao_label.grid(row=5, column=0, sticky="e")
    aquisicao_entry = DateEntry(container, locale="pt_BR")
    aquisicao_entry.grid(row=5, column=1, sticky="w", padx=(10, 0), pady=4)  # pyright: ignore[reportUnknownMemberType]

    # Entrada para a quantidade
    quant_label = ttk.Label(container, text="Quantidade: ")
    quant_label.grid(row=6, column=0, sticky="e")
    quant_entry = ttk.Entry(
        container,
        width=35,
        validate="key",
        validatecommand=(frame.register(validate_cod), "%P"),
    )
    quant_entry.grid(row=6, column=1, sticky="w", padx=(10, 0), pady=4)

    notebook.add(frame, text="Cadastro Insumo")

    return


def monta_ui(root: Tk, db_cursor: cursor) -> None:
    root.title("CitrusVisio")
    root.option_add("*TearOff", False)  # pyright: ignore[reportUnknownMemberType]

    _ = root.columnconfigure(0, weight=1)
    _ = root.rowconfigure(0, weight=1)

    style = ttk.Style(root)
    root.tk.call("source", "./Forest-ttk-theme/forest-light.tcl")
    style.theme_use("forest-light")
    style.configure("lefttab.TNotebook", tabposition="wn")

    frame = ttk.Frame(root, padding=10)
    frame.grid(sticky="nsew")

    # Isso daqui é só pro basedpyright não dar erros
    _ = frame.columnconfigure(0, weight=1)
    _ = frame.rowconfigure(0, weight=1)

    notebook = ttk.Notebook(frame, padding=10, style="lefttab.TNotebook")
    notebook.grid(column=0, row=0, sticky="nsew")

    registrar_frame_cadastro_insumo(notebook, db_cursor)

    tab_2 = ttk.Frame(notebook)
    tk.Label(tab_2, text="teste2").pack(padx=10, pady=10)
    notebook.add(tab_2, text="Tab 2")

    # Setta o tamanho da janela como o menor possível
    root.minsize(root.winfo_width(), root.winfo_height())
    x_cordinate = int((root.winfo_screenwidth() / 2) - (root.winfo_width() / 2))
    y_cordinate = int((root.winfo_screenheight() / 2) - (root.winfo_height() / 2))
    root.geometry("+{}+{}".format(x_cordinate, y_cordinate))


if __name__ == "__main__":
    db_conn = psy.connect(host="localhost", dbname=DBNAME, user=DBUSER, password=DBPASS)

    cur = db_conn.cursor()

    root = tk.Tk()
    monta_ui(root, cur)
    # Mostra a tela para o usuário
    root.mainloop()

    # Testes com o postgres
    #
    # cur = db_conn.cursor()
    # cur.execute("SELECT tipo FROM tipo_insumo;")

    # records = cur.fetchall()
    db_conn.close()
