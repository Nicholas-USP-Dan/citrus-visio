from app_ui import registrar_frame_cadastro_insumo, registrar_frame_consulta_ordens, registrar_frame_consulta_vendas # pyright: ignore[reportImplicitRelativeImport]

import os
import tkinter as tk
from tkinter import Tk, ttk, messagebox

import psycopg2 as psy
from psycopg2.extensions import connection

# Definição de variáveis
DBNAME: str = "citrusvisio"
DBUSER: str = "postgres"
DBPASS: str = "postgres"


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
            _ = vendas_tree.tag_configure("par",   background="#2d2d2d")
            _ = vendas_tree.tag_configure("impar", background="#383838")
            
        else:
            style.theme_use("forest-light")
            _ = status_lbl.configure(
                foreground="#2E7D32"
            )  # Tom de verde escuro para fundo claro
            # Zebra stripes adaptadas para o modo claro
            _ = ordens_tree.tag_configure("par", background="#f7f9f7")
            _ = ordens_tree.tag_configure("impar", background="#ffffff")
            _ = vendas_tree.tag_configure("par",   background="#f7f9f7")
            _ = vendas_tree.tag_configure("par",   background="#ffffff")
            

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

    # Aba 3: Consulta de vendas — captura o widget tree para o toggle_theme
    vendas_tree = registrar_frame_consulta_vendas(notebook, db_conn)


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
