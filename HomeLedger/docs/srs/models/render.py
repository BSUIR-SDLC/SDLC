#!/usr/bin/env python3
"""Построение изображений по моделям SysML v2 (каталог srs/models) с помощью Graphviz.

Для каждой модели *.sysml здесь описана её графическая проекция в стиле графической
нотации SysML v2: прямоугольники со скруглением и стереотипами «...», вложенные части,
связи connect, переходы состояний и последовательности действий.
Запуск:  python render.py      (нужен Graphviz: команда dot)
Результат: PNG-файлы в каталоге ../images
"""
import html
import os
import subprocess

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "images")
FONT = "DejaVu Sans"


def esc(s):
    return html.escape(s, quote=False)


def wrap(text, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        if cur and len(cur) + 1 + len(w) > width:
            lines.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    if cur:
        lines.append(cur)
    return lines


def compartment(stereo, title, sections=(), width=40):
    """HTML-метка узла: «стереотип», имя, затем разделы (заголовок, строки)."""
    rows = []
    if stereo:
        rows.append(f'<TR><TD><FONT POINT-SIZE="10">«{esc(stereo)}»</FONT></TD></TR>')
    rows.append(f"<TR><TD>{esc(title)}</TD></TR>")
    for head, lines in sections:
        rows.append("<HR/>")
        if head:
            rows.append(f"<TR><TD>{esc(head)}</TD></TR>")
        if not head and not lines:
            rows.append('<TR><TD><FONT POINT-SIZE="4"> </FONT></TD></TR>')
        for ln in lines:
            for part in wrap(ln, width):
                rows.append(f'<TR><TD ALIGN="LEFT" BALIGN="LEFT">{esc(part)}</TD></TR>')
    return '<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="1" CELLPADDING="2">' + "".join(rows) + "</TABLE>>"


def header(**graph):
    attrs = {"fontname": FONT, "fontsize": "12", "bgcolor": "white", "pad": "0.25", "nodesep": "0.35", "ranksep": "0.5"}
    attrs.update(graph)
    g = ["digraph G {"]
    g.append("  graph [" + ", ".join(f'{k}="{v}"' for k, v in attrs.items()) + "];")
    g.append(f'  node [fontname="{FONT}", fontsize=12, shape=box, style="rounded", color="#333333", penwidth=1.3];')
    g.append(f'  edge [fontname="{FONT}", fontsize=10, color="#222222", penwidth=1.4, arrowhead=none];')
    return g


def save(name, lines, dpi=150):
    os.makedirs(OUT, exist_ok=True)
    dot = "\n".join(lines + ["}"])
    src = os.path.join(OUT, name + ".dot")
    with open(src, "w", encoding="utf-8") as f:
        f.write(dot)
    subprocess.run(["dot", "-Tpng", f"-Gdpi={dpi}", src, "-o", os.path.join(OUT, name + ".png")], check=True)
    os.remove(src)
    print("ok", name)


def cluster(lines, cid, label, body, indent="  ", just="c", style="rounded"):
    lines.append(f'{indent}subgraph cluster_{cid} {{')
    lines.append(f'{indent}  label=<{label}>; labeljust="{just}"; style="{style}"; color="#333333"; penwidth=1.4; margin=14;')
    lines.extend(indent + "  " + b for b in body)
    lines.append(f"{indent}}}")


# ───────────── 01 Системный контекст (Interconnection) ─────────────
def context():
    g = header(rankdir="TB", ranksep="0.9", nodesep="0.5")
    users = [("owner", "Владелец бюджета"), ("family", "Член семьи")]
    stores = [("data", "Файлы данных CSV (каталог data)", "Хранилище"),
              ("bak", "Резервные копии (data/backup)", "Хранилище"),
              ("rep", "Отчёт за месяц CSV", "Хранилище")]
    body = []
    for k, n in users:
        body.append(f'{k} [label=<&lt;{k}&gt; {esc(n)}: Пользователь>];')
    body.append('sys [label=<&lt;sys&gt; ПО HomeLedger<BR/>(консоль, Windows / Linux): Программное средство>, penwidth=2];')
    for k, n, t in stores:
        body.append(f'{k} [label=<&lt;{k}&gt; {esc(n)}: {t}>];')
    body.append('xls [label=<&lt;xls&gt; Табличный редактор<BR/>(Excel / Calc): Внешняя программа>];')
    body += ['owner -> sys [label="доходы, расходы,\\nлимиты, отчёты"];',
             'family -> sys [label="свои расходы,\\nпросмотр"];',
             'sys -> data [label="чтение / запись"];', 'sys -> bak [label="копия при запуске"];',
             'sys -> rep [label="экспорт"];', 'rep -> xls [label="просмотр, печать"];']
    cluster(g, "ctx", "&lt;context&gt; Контекст HomeLedger", body)
    save("02-context", g)


# ───────────── 02 Варианты использования ─────────────
def usecases():
    g = header(rankdir="LR", ranksep="1.4", nodesep="0.25", ordering="out")
    actor = lambda k, n: f'{k} [shape=none, style="", label=<<TABLE BORDER="0"><TR><TD><FONT POINT-SIZE="26">웃</FONT></TD></TR><TR><TD><FONT POINT-SIZE="10">«actor»</FONT></TD></TR><TR><TD>{esc(n)}</TD></TR></TABLE>>];'
    g.append("  " + actor("owner", "Владелец бюджета"))
    g.append("  " + actor("family", "Член семьи"))
    ucs = [("UC1", "ВИ-1 Внести расход или доход", "of"), ("UC2", "ВИ-2 Перевести между кошельками", "o"),
           ("UC3", "ВИ-3 Просмотреть и исправить журнал", "of"), ("UC4", "ВИ-4 Посмотреть баланс и статистику", "of"),
           ("UC5", "ВИ-5 Установить лимиты по категориям", "o"), ("UC6", "ВИ-6 Получить советы по организации трат", "o"),
           ("UC7", "ВИ-7 Настроить кошельки и категории", "o"), ("UC8", "ВИ-8 Экспортировать отчёт за месяц", "o")]
    body = []
    for k, n, _ in ucs:
        body.append(f'{k} [shape=ellipse, style="", label=<<FONT POINT-SIZE="10">«use case def»</FONT><BR/>&lt;{k}&gt; {esc(n)}>];')
    cluster(g, "subj", "«subject» ПО HomeLedger : Программное средство", body)
    for k, _, who in ucs:
        if "o" in who:
            g.append(f"  owner -> {k};")
    for k, _, who in ucs:  # второй субъект — справа от вариантов использования
        if "f" in who:
            g.append(f'  {k} -> family [style=dashed];')
    save("03-usecases", g)


# ───────────── 03 Бизнес-цели (requirement, Tree) ─────────────
GOALS = [("BG1", "БЦ-1 Полный учёт денег", "Записывать все доходы и расходы в одном месте вместо заметок в телефоне и памяти."),
         ("BG2", "БЦ-2 Понятная структура трат", "Видеть, на какие категории уходят деньги и как траты меняются по месяцам."),
         ("BG3", "БЦ-3 Контроль бюджета", "Не превышать месячные лимиты по категориям; узнавать о приближении к лимиту сразу."),
         ("BG4", "БЦ-4 Регулярные накопления", "Откладывать не менее 20 % дохода с помощью конкретных советов по тратам."),
         ("BG5", "БЦ-5 Быстрый ввод", "Вносить операцию не дольше 15 секунд, чтобы учёт не был заброшен.")]


def goals():
    g = header(rankdir="LR", ranksep="1.2", nodesep="0.3")
    body = ['BG [label=' + compartment("requirement", "<BG> Бизнес-цели HomeLedger", [("", [])]) + "];"]
    for k, n, d in reversed(GOALS):
        body.append(f"{k} [label=" + compartment("requirement", f"<{k}> {n}", [("doc", [d])], 38) + "];")
        body.append(f'BG -> {k} [dir=back, arrowtail=diamond, arrowsize=1.2];')
    cluster(g, "pkg", '<B>HomeLedgerBusinessGoals</B>', body, just="l", style="solid")
    save("01-business-goals", g)


# ───────────── 04 Состояния лимита (State) ─────────────
def states():
    g = header(rankdir="LR", ranksep="1.3", nodesep="0.9")
    body = ['start [shape=circle, style=filled, fillcolor="#222222", label="", width=0.22];',
            'normal [label=<<FONT POINT-SIZE="10">«state»</FONT><BR/>&lt;normal&gt; В норме (&lt; 80 %)>];',
            'near [label=<<FONT POINT-SIZE="10">«state»</FONT><BR/>&lt;near&gt; Почти исчерпан (80–100 %)>, color="#b08800"];',
            'over [label=<<FONT POINT-SIZE="10">«state»</FONT><BR/>&lt;over&gt; Превышен (&gt; 100 %)>, color="#c0392b"];',
            'start -> normal [arrowhead=normal];',
            'normal -> near [arrowhead=normal, label="t1: Расход\\n[80 ≤ usedPercent ≤ 100]"];',
            'normal -> over [arrowhead=normal, label="t2: Расход\\n[usedPercent > 100]"];',
            'near -> over [arrowhead=normal, label="t3: Расход\\n[usedPercent > 100]"];',
            'near -> normal [arrowhead=normal, style=dashed, label="t4: Изменение лимита [< 80]\\nt6: Новый месяц"];',
            'over -> near [arrowhead=normal, style=dashed, label="t5: Изменение лимита\\n[≤ 100]"];',
            'over -> normal [arrowhead=normal, style=dashed, label="t7: Новый месяц"];']
    cluster(g, "st", "&lt;BudgetStates&gt; Состояния лимита категории", body)
    save("04-budget-states", g)


# ───────────── 05 Сценарий «Внести расход» (Action) ─────────────
def action():
    g = header(rankdir="TB", ranksep="0.35", nodesep="0.5")
    A = lambda k, n: f'{k} [label=<<FONT POINT-SIZE="10">«action»</FONT><BR/>&lt;{k}&gt; {esc(n)}>];'
    body = ['start [shape=circle, style=filled, fillcolor="#222222", label="", width=0.22];',
            A("amount", "Ввести сумму"), A("category", "Выбрать категорию (по умолчанию — последняя)"),
            A("wallet", "Выбрать кошелёк (по умолчанию — последний)"),
            A("date", "Ввести дату (по умолчанию — сегодня) и комментарий"), A("validate", "Проверить данные"),
            'd1 [shape=diamond, style="", label="", width=0.4, height=0.4];',
            A("error", "Показать причину ошибки"), A("funds", "Предупредить: в кошельке недостаточно средств"),
            'd2 [shape=diamond, style="", label="", width=0.4, height=0.4];',
            A("save", "Сохранить операцию в файл"), A("limit", "Показать состояние лимита категории"),
            'done [shape=doublecircle, style=filled, fillcolor="#222222", label="", width=0.16];']
    E = lambda a, b, l="", extra="": f'{a} -> {b} [arrowhead=normal{", label=" + chr(34) + l + chr(34) if l else ""}{extra}];'
    body += [E("start", "amount"), E("amount", "category"), E("category", "wallet"), E("wallet", "date"),
             E("date", "validate"), E("validate", "d1"), E("d1", "error", "[not valid]"),
             E("d1", "funds", "[valid and not enough]"), E("d1", "save", "[else]"),
             E("error", "amount", "", ", constraint=false, style=dashed"), E("funds", "d2"),
             E("d2", "save", "[confirmed]"), E("d2", "done", "[else]"), E("save", "limit"), E("limit", "done")]
    cluster(g, "act", "&lt;AddExpense&gt; Внести расход", body)
    save("05-add-expense", g)


# ───────────── 06 Мокапы экранов и карта экранов ─────────────
def part(k, name, typ, attrs=None, width=46):
    title = f"<{k}> {name}: {typ}"
    if not attrs:
        return f'{k} [label=<{esc(title)}>];'
    inner = "".join(
        f'<TR><TD><TABLE BORDER="1" STYLE="rounded" COLOR="#555555" CELLBORDER="0" CELLSPACING="0" CELLPADDING="3">'
        f'<TR><TD><FONT POINT-SIZE="10">«attribute»</FONT></TD></TR><TR><TD>{esc(an)}</TD></TR><HR/>'
        f'<TR><TD>values</TD></TR>'
        + "".join(f'<TR><TD ALIGN="LEFT" BALIGN="LEFT">{esc(x)}</TD></TR>' for x in wrap(av, width))
        + "</TABLE></TD></TR>" for an, av in attrs)
    return (f'{k} [label=<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="6"><TR><TD>{esc(title)}</TD></TR><HR/>'
            f'{inner}</TABLE>>];')


def seq(keys, style=""):
    return [f"{a} -> {b}{' [' + style + ']' if style else ''};" for a, b in zip(keys, keys[1:])]


def mockup(name, k, title, parts, chain, rankdir="TB"):
    g = header(rankdir=rankdir, ranksep="0.3", nodesep="0.4")
    body = [part(*p) for p in parts] + seq(chain, "penwidth=2.2")
    cluster(g, k, esc(f"<{k}> {title}: Экран"), body)
    save(name, g)


def mockups():
    mockup("07-ui-main", "main", "Главный экран", [
        ("title", "Заголовок с датой", "Заголовок"),
        ("summary", "Баланс и итоги месяца", "Сводка",
         [("строки", '= ("Баланс (по кошелькам)", "Доходы · расходы · остаток месяца")')]),
        ("alerts", "Предупреждения о лимитах", "Список сообщений"),
        ("menu", "Главное меню", "Меню",
         [("пункты", '= ("1 Добавить расход", "2 Добавить доход", "3 Перевод", "4 Журнал", "5 Статистика", '
                     '"6 Бюджеты", "7 Советы", "8 Кошельки и категории", "9 Экспорт", "0 Выход")')])],
        ["title", "summary", "alerts", "menu"])
    mockup("08-ui-add", "add", "Экран «Новый расход / доход»", [
        ("sum", "Сумма, BYN", "Поле ввода"),
        ("cat", "Категория", "Список выбора", [("по умолчанию", '= "последняя выбранная"')]),
        ("wal", "Кошелёк", "Список выбора", [("по умолчанию", '= "последний выбранный"')]),
        ("dt", "Дата", "Поле ввода", [("по умолчанию", '= "сегодня"')]),
        ("cmt", "Комментарий", "Поле ввода"),
        ("res", "Результат и состояние лимита", "Список сообщений")],
        ["sum", "cat", "wal", "dt", "cmt", "res"])
    mockup("09-ui-journal", "journal", "Экран «Журнал операций»", [
        ("ops", "Операции за месяц", "Таблица",
         [("столбцы", '= ("№", "Дата", "Тип", "Категория", "Кошелёк", "Сумма", "Комментарий")')]),
        ("tot", "Итоги: операций, доходы, расходы", "Сводка"),
        ("cmd", "Команды", "Строка команд",
         [("команды", '= ("< >  месяц", "к  фильтр по категории", "и N  изменить", "у N  удалить", "0  назад")')])],
        ["ops", "tot", "cmd"])
    mockup("10-ui-stats", "stats", "Экран «Статистика»", [
        ("head", "Доходы, расходы, остаток месяца", "Сводка"),
        ("bycat", "Расходы и доходы по категориям", "Диаграмма",
         [("столбцы", '= ("Категория", "Сумма", "Доля, %", "Полоса")')]),
        ("rule", "Структура 50/30/20", "Диаграмма"),
        ("dyn", "Динамика за 6 месяцев", "Диаграмма"),
        ("cmd", "Команды", "Строка команд")],
        ["head", "bycat", "rule", "dyn", "cmd"])
    mockup("11-ui-budgets", "budgets", "Экран «Бюджеты»", [
        ("tbl", "Лимиты месяца", "Таблица",
         [("столбцы", '= ("Категория", "Лимит", "Потрачено", "Осталось", "Использовано, %")')]),
        ("cmd", "Команды", "Строка команд",
         [("команды", '= ("1  установить лимит", "2  снять лимит", "0  назад")')])],
        ["tbl", "cmd"], rankdir="LR")
    mockup("12-ui-advice", "advice", "Экран «Советы»", [
        ("list", "Советы с отметками [+] [i] [!]", "Список сообщений",
         [("правила", '= ("50/30/20", "прогноз на месяц", "дневной лимит", "топ-3 категории", '
                      '"рост к прошлому месяцу", "лимиты")')])], ["list"])


def screen_map():
    g = header(rankdir="LR", ranksep="1.0", nodesep="0.25", ordering="out")
    screens = [("a", "add", "Новый расход / доход", "1, 2"), ("t", "transfer", "Перевод между кошельками", "3"),
               ("j", "journal", "Журнал операций", "4"), ("s", "stats", "Статистика", "5"),
               ("b", "budgets", "Бюджеты", "6"), ("v", "advice", "Советы", "7"),
               ("w", "wallets", "Кошельки и категории", "8"), ("e", "export", "Экспорт отчёта", "9")]
    body = ['m [label=<&lt;main&gt; Главный экран: Экран>, penwidth=2];']
    for k, ref, name, _ in screens:
        body.append(f'{k} [label=<&lt;{ref}&gt; {esc(name)}: Экран>];')
    for k, _, _, key in reversed(screens):
        body.append(f'm -> {k} [taillabel="{key}", labeldistance=4.5, labelangle=8, arrowhead=normal];')
    body.append('j -> a [xlabel="и N", style=dashed, arrowhead=normal, constraint=false];')
    cluster(g, "map", "&lt;map&gt; Карта экранов", body)
    save("06-ui-map", g)


if __name__ == "__main__":
    goals()
    context()
    usecases()
    states()
    action()
    screen_map()
    mockups()
