from datetime import date
from decimal import Decimal

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import StyleSheet1, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle

CINZA = colors.HexColor("#CCCCCC")
styles: StyleSheet1 = getSampleStyleSheet()


def _fmt(value: Decimal | None) -> str:
    if value is None:
        return "—"
    return f"{value:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


def _tabela(cabecalho: list, linhas: list, col_widths: list) -> Table:
    t = Table([cabecalho] + linhas, colWidths=col_widths, repeatRows=1)
    t.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("BACKGROUND", (0, 0), (-1, 0), colors.lightgrey),
                ("GRID", (0, 0), (-1, -1), 0.5, CINZA),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return t


def montar_pdf(
    inicio: date,
    fim: date,
    total_hidrico: Decimal | None,
    total_energetico: Decimal | None,
    total_residuos: Decimal | None,
    gastos_por_mes: list[tuple],  # (gasto_hidrico, gasto_energetico, mes_ano)
    residuos_por_tipo: list[tuple],  # (massa_total, tipo_residuo, mes_ano)
    caminho_saida: str = "relatorio_producao.pdf",
) -> None:
    doc = SimpleDocTemplate(
        caminho_saida,
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )
    story = []

    periodo = f"{inicio.strftime('%d/%m/%Y')} – {fim.strftime('%d/%m/%Y')}"
    story.append(Paragraph("Relatório de Produção", styles["Title"]))
    story.append(Paragraph(f"CitrusVisio Factory · {periodo}", styles["Normal"]))
    story.append(Spacer(1, 0.5 * cm))

    story.append(Paragraph("Totais do período", styles["Heading2"]))
    story.append(
        _tabela(
            ["", "Valor", "Unidade"],
            [
                ["Gasto hídrico", _fmt(total_hidrico), "m³"],
                ["Gasto energético", _fmt(total_energetico), "kWh"],
                ["Resíduos gerados", _fmt(total_residuos), "kg"],
            ],
            [6 * cm, 4 * cm, 3 * cm],
        )
    )
    story.append(Spacer(1, 0.5 * cm))

    story.append(Paragraph("Gastos por mês", styles["Heading2"]))
    story.append(
        _tabela(
            ["Ano/Mês", "Hídrico (m³)", "Energético (kWh)"],
            [[mes, _fmt(h), _fmt(e)] for h, e, mes in gastos_por_mes],
            [5 * cm, 5 * cm, 5 * cm],
        )
    )
    story.append(Spacer(1, 0.5 * cm))

    story.append(Paragraph("Resíduos por tipo e mês", styles["Heading2"]))
    story.append(
        _tabela(
            ["Ano/Mês", "Tipo", "Massa (kg)"],
            [[mes, tipo, _fmt(massa)] for massa, tipo, mes in residuos_por_tipo],
            [5 * cm, 5 * cm, 5 * cm],
        )
    )

    doc.build(story)
