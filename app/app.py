# Provavelmente tkinter já deve estar instalado

import tkinter as tk
from tkinter import ttk

# import psycopg2 as psy

root = tk.Tk()
root.title("citrusvisio")
root.option_add("*TearOff", False)  # pyright: ignore[reportUnknownMemberType]

style = ttk.Style(root)

root.tk.call("source", "./Forest-ttk-theme/forest-light.tcl")

style.theme_use("forest-light")


frm = ttk.Frame(root, padding=10)
frm.grid()
ttk.Label(frm, text="Hello World!").grid(column=0, row=0)
ttk.Button(frm, text="Quit", command=root.destroy).grid(column=1, row=0)

root.mainloop()
