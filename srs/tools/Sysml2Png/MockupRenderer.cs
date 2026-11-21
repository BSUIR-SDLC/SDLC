using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;

namespace Sysml2Png;

/// <summary>
/// Рисует экран (часть типа UiKit::Screen) по дереву вложенных частей.
/// Размеры задаются в логических пикселях, изображение сохраняется с масштабом 2.
/// </summary>
static class MockupRenderer
{
    const float Scale = 2f;
    const int TitleBar = 32, TabBarH = 46, Pad = 14, Gap = 10, FieldH = 30, ButtonH = 32, LabelH = 18;

    static readonly Color Accent = Color.FromArgb(0x2F, 0x6F, 0xDE);
    static readonly Color Text = Color.FromArgb(0x1F, 0x29, 0x37);
    static readonly Color Muted = Color.FromArgb(0x6B, 0x72, 0x80);
    static readonly Color Border = Color.FromArgb(0xC9, 0xCE, 0xD6);
    static readonly Color Light = Color.FromArgb(0xF3, 0xF5, 0xF8);
    static readonly Color Dark = Color.FromArgb(0x26, 0x3A, 0x4F);

    static readonly Font FNormal = new("Segoe UI", 10f, GraphicsUnit.Point);
    static readonly Font FSmall = new("Segoe UI", 9f, GraphicsUnit.Point);
    static readonly Font FBold = new("Segoe UI Semibold", 10f, GraphicsUnit.Point);
    static readonly Font FTitle = new("Segoe UI Semibold", 11f, GraphicsUnit.Point);
    static readonly Font FHeading = new("Segoe UI Semibold", 13f, GraphicsUnit.Point);
    static readonly Font FValue = new("Segoe UI Semibold", 15f, GraphicsUnit.Point);
    static readonly Font FApp = new("Segoe UI Semibold", 12.5f, GraphicsUnit.Point);

    static readonly Graphics Measure = Graphics.FromImage(new Bitmap(1, 1));

    static Color ToneColor(string tone) => tone switch
    {
        "success" => Color.FromArgb(0x1E, 0x9E, 0x5A),
        "warning" => Color.FromArgb(0xE0, 0x8A, 0x00),
        "danger" => Color.FromArgb(0xD6, 0x3B, 0x3B),
        _ => Accent
    };

    public static void Render(Node screen, string pngPath)
    {
        int w = screen.Int("width", 1200);
        int h = ScreenHeight(screen, w);
        using var bmp = new Bitmap((int)(w * Scale), (int)(h * Scale), PixelFormat.Format24bppRgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.ScaleTransform(Scale, Scale);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            g.Clear(Color.White);
            DrawScreen(g, screen, w, h);
        }
        bmp.Save(pngPath, ImageFormat.Png);
    }

    // ---------------- Экран ----------------

    static int ScreenHeight(Node s, int w)
    {
        int y = TitleBar;
        bool content = false;
        foreach (var c in s.Children)
        {
            if (c.Type == "TabBar") { y += TabBarH; continue; }
            y += content ? Gap + 2 : Pad;
            y += Height(c, w - 2 * Pad);
            content = true;
        }
        return y + Pad + 1;
    }

    static void DrawScreen(Graphics g, Node s, int w, int h)
    {
        // Заголовок окна Windows.
        using (var b = new SolidBrush(Color.FromArgb(0xEE, 0xF0, 0xF3))) g.FillRectangle(b, 0, 0, w, TitleBar);
        DrawPill(g, 10, 9, 22, 14);
        g.DrawString(s.Str("title", ""), FSmall, new SolidBrush(Text), 40, 8);
        using (var p = new Pen(Text, 1f))
        {
            float cy = TitleBar / 2f;
            float x = w - 46 * 3 + 23;
            g.DrawLine(p, x - 5, cy, x + 5, cy);
            x += 46;
            g.DrawRectangle(p, x - 5, cy - 5, 10, 10);
            x += 46;
            g.DrawLine(p, x - 5, cy - 5, x + 5, cy + 5);
            g.DrawLine(p, x + 5, cy - 5, x - 5, cy + 5);
        }

        int y = TitleBar;
        bool content = false;
        foreach (var c in s.Children)
        {
            if (c.Type == "TabBar") { DrawTabBar(g, c, new Rectangle(0, y, w, TabBarH)); y += TabBarH; continue; }
            y += content ? Gap + 2 : Pad;
            int ch = Height(c, w - 2 * Pad);
            Draw(g, c, new Rectangle(Pad, y, w - 2 * Pad, ch));
            y += ch;
            content = true;
        }
        using (var p = new Pen(Color.FromArgb(0x8A, 0x92, 0x9C))) g.DrawRectangle(p, 0, 0, w - 1, h - 1);
    }

    static void DrawPill(Graphics g, float x, float y, float w, float h)
    {
        using var left = new SolidBrush(Accent);
        using var right = new SolidBrush(Color.FromArgb(0xF2, 0x8C, 0x8C));
        var st = g.Save();
        g.TranslateTransform(x + w / 2, y + h / 2);
        g.RotateTransform(-30);
        using var path = Rounded(new RectangleF(-w / 2, -h / 2 + 2, w, h - 4), (h - 4) / 2);
        g.SetClip(path);
        g.FillRectangle(left, -w / 2, -h / 2, w / 2, h);
        g.FillRectangle(right, 0, -h / 2, w / 2, h);
        g.ResetClip();
        g.Restore(st);
    }

    static void DrawTabBar(Graphics g, Node n, Rectangle r)
    {
        using (var b = new SolidBrush(Dark)) g.FillRectangle(b, r);
        float x = r.X + Pad;
        float midY = r.Y + r.Height / 2f;
        string app = n.Str("text", "");
        var sz = g.MeasureString(app, FApp);
        g.DrawString(app, FApp, Brushes.White, x, midY - sz.Height / 2);
        x += sz.Width + 30;
        string active = n.Str("active");
        foreach (var item in n.List("items"))
        {
            bool on = item == active;
            var f = on ? FBold : FNormal;
            var isz = g.MeasureString(item, f);
            using var b = new SolidBrush(on ? Color.White : Color.FromArgb(0xC5, 0xD0, 0xDC));
            g.DrawString(item, f, b, x, midY - isz.Height / 2);
            if (on)
                using (var ab = new SolidBrush(Color.FromArgb(0x7F, 0xB2, 0xFF)))
                    g.FillRectangle(ab, x + 2, r.Bottom - 4, isz.Width - 4, 3);
            x += isz.Width + 22;
        }
        string user = n.Str("user");
        if (user != null)
        {
            var usz = g.MeasureString(user, FNormal);
            using var b = new SolidBrush(Color.FromArgb(0xE0, 0xE6, 0xEE));
            g.DrawString(user, FNormal, b, r.Right - Pad - usz.Width, midY - usz.Height / 2);
        }
    }

    // ---------------- Измерение ----------------

    static bool Stretches(Node n) => n.Type is "Panel" or "Column" or "Table" or "Chart" or "StatCard" or "Banner";

    static int Height(Node n, int w)
    {
        switch (n.Type)
        {
            case "Row":
            {
                var widths = RowWidths(n, w);
                int h = 0;
                for (int i = 0; i < n.Children.Count; i++) h = Math.Max(h, Height(n.Children[i], widths[i]));
                return h;
            }
            case "Column":
                return Stack(n.Children, w);
            case "Panel":
            {
                int h = Pad;
                if (n.Str("text") != null) h += 22 + 6;
                h += Stack(n.Children, w - 2 * Pad);
                return h + Pad;
            }
            case "Label":
            {
                var f = LabelFont(n);
                return (int)Math.Ceiling(Measure.MeasureString(n.Str("text", ""), f, w).Height) + 2;
            }
            case "Link": return FieldH;
            case "Banner":
                return (int)Math.Ceiling(Measure.MeasureString(n.Str("text", ""), FNormal, w - 34).Height) + 20;
            case "TextField" or "DateField" or "TimeField" or "NumberField" or "Select":
                return (n.Str("label") != null ? LabelH + 4 : 0) + FieldH;
            case "Checkbox": return 24;
            case "Button": return ButtonH;
            case "StatCard": return 72;
            case "Table": return 30 + 28 * n.Children.Count + 1;
            case "Chart": return n.Str("kind") == "pie" ? 190 : 210;
            default: return 0;
        }
    }

    static int Stack(List<Node> children, int w)
    {
        int h = 0;
        for (int i = 0; i < children.Count; i++) h += (i > 0 ? Gap : 0) + Height(children[i], w);
        return h;
    }

    static int[] RowWidths(Node row, int w)
    {
        var ch = row.Children;
        int total = ch.Sum(c => c.Int("weight", 1));
        int avail = w - Gap * (ch.Count - 1);
        var res = new int[ch.Count];
        int used = 0;
        for (int i = 0; i < ch.Count; i++)
        {
            res[i] = i == ch.Count - 1 ? avail - used : avail * ch[i].Int("weight", 1) / total;
            used += res[i];
        }
        return res;
    }

    static Font LabelFont(Node n) => n.Str("style") switch
    {
        "heading" => FHeading,
        "muted" => FSmall,
        _ => FNormal
    };

    // ---------------- Рисование ----------------

    static void Draw(Graphics g, Node n, Rectangle r)
    {
        switch (n.Type)
        {
            case "Row":
            {
                var widths = RowWidths(n, r.Width);
                int x = r.X;
                for (int i = 0; i < n.Children.Count; i++)
                {
                    var c = n.Children[i];
                    int ch = Stretches(c) ? r.Height : Height(c, widths[i]);
                    int cy = Stretches(c) ? r.Y : r.Bottom - ch;
                    Draw(g, c, new Rectangle(x, cy, widths[i], ch));
                    x += widths[i] + Gap;
                }
                break;
            }
            case "Column":
                DrawStack(g, n.Children, r.X, r.Y, r.Width);
                break;
            case "Panel":
            {
                using (var path = Rounded(r, 6))
                {
                    g.FillPath(Brushes.White, path);
                    using var p = new Pen(Border);
                    g.DrawPath(p, path);
                }
                int y = r.Y + Pad;
                string title = n.Str("text");
                if (title != null)
                {
                    g.DrawString(title, FTitle, new SolidBrush(Text), r.X + Pad - 2, y);
                    y += 22 + 6;
                }
                DrawStack(g, n.Children, r.X + Pad, y, r.Width - 2 * Pad);
                break;
            }
            case "Label":
            {
                var f = LabelFont(n);
                using var b = new SolidBrush(n.Str("style") == "muted" ? Muted : Text);
                g.DrawString(n.Str("text", ""), f, b, new RectangleF(r.X, r.Y + (r.Height - Height(n, r.Width)) / 2f, r.Width, r.Height + 4));
                break;
            }
            case "Link":
            {
                var sz = g.MeasureString(n.Str("text", ""), FNormal);
                using var b = new SolidBrush(Accent);
                g.DrawString(n.Str("text", ""), FNormal, b, r.X, r.Y + (r.Height - sz.Height) / 2);
                break;
            }
            case "Banner":
            {
                var c = ToneColor(n.Str("tone"));
                using (var path = Rounded(r, 4))
                {
                    using var fill = new SolidBrush(Color.FromArgb(28, c));
                    g.FillPath(fill, path);
                }
                using (var sb = new SolidBrush(c)) g.FillRectangle(sb, r.X, r.Y, 4, r.Height);
                using (var cb = new SolidBrush(c)) g.FillEllipse(cb, r.X + 12, r.Y + r.Height / 2f - 6, 12, 12);
                g.DrawString("!", FBold, Brushes.White, r.X + 13.5f, r.Y + r.Height / 2f - 9);
                g.DrawString(n.Str("text", ""), FNormal, new SolidBrush(Text), new RectangleF(r.X + 32, r.Y + 10, r.Width - 34, r.Height));
                break;
            }
            case "TextField" or "DateField" or "TimeField" or "NumberField" or "Select":
                DrawField(g, n, r);
                break;
            case "Checkbox":
            {
                var box = new Rectangle(r.X, r.Y + 4, 16, 16);
                if (n.Bool("checked"))
                {
                    using (var b = new SolidBrush(Accent)) g.FillRectangle(b, box);
                    using var p = new Pen(Color.White, 2f);
                    g.DrawLines(p, new[] { new PointF(box.X + 3.5f, box.Y + 8), new PointF(box.X + 6.5f, box.Y + 11.5f), new PointF(box.X + 12.5f, box.Y + 4.5f) });
                }
                else
                {
                    g.FillRectangle(Brushes.White, box);
                    using var p = new Pen(Color.FromArgb(0x8A, 0x92, 0x9C));
                    g.DrawRectangle(p, box);
                }
                g.DrawString(n.Str("text", ""), FNormal, new SolidBrush(Text), r.X + 24, r.Y + 2);
                break;
            }
            case "Button":
                DrawButton(g, n, r);
                break;
            case "StatCard":
            {
                using (var path = Rounded(r, 6))
                {
                    g.FillPath(Brushes.White, path);
                    using var p = new Pen(Border);
                    g.DrawPath(p, path);
                }
                using (var sb = new SolidBrush(ToneColor(n.Str("tone")))) g.FillRectangle(sb, r.X + 1, r.Y + 10, 4, r.Height - 20);
                g.DrawString(n.Str("label", ""), FSmall, new SolidBrush(Muted), r.X + 14, r.Y + 10);
                using var vb = new SolidBrush(n.Str("tone") is "warning" or "danger" or "success" ? ToneColor(n.Str("tone")) : Text);
                g.DrawString(n.Str("text", ""), FValue, vb, new RectangleF(r.X + 13, r.Y + 32, r.Width - 16, 30),
                    new StringFormat { Trimming = StringTrimming.EllipsisCharacter, FormatFlags = StringFormatFlags.NoWrap });
                break;
            }
            case "Table":
                DrawTable(g, n, r);
                break;
            case "Chart":
                DrawChart(g, n, r);
                break;
        }
    }

    static void DrawStack(Graphics g, List<Node> children, int x, int y, int w)
    {
        foreach (var c in children)
        {
            int h = Height(c, w);
            if (c.Type == "Button" && !Stretches(c))
            {
                int bw = (int)g.MeasureString(c.Str("text", ""), FBold).Width + 36;
                DrawButton(g, c, new Rectangle(x, y, Math.Min(bw, w), h));
            }
            else Draw(g, c, new Rectangle(x, y, w, h));
            y += h + Gap;
        }
    }

    static void DrawField(Graphics g, Node n, Rectangle r)
    {
        int y = r.Y;
        string label = n.Str("label");
        if (label != null)
        {
            g.DrawString(label, FSmall, new SolidBrush(Text), r.X - 1, y);
            y += LabelH + 4;
        }
        var box = new Rectangle(r.X, y, r.Width, FieldH);
        using (var path = Rounded(box, 4))
        {
            g.FillPath(Brushes.White, path);
            using var p = new Pen(Color.FromArgb(0xA9, 0xB0, 0xBA));
            g.DrawPath(p, path);
        }
        int iconW = n.Type is "Select" or "DateField" or "TimeField" or "NumberField" ? 26 : 0;
        string text = n.Str("text", "");
        using (var tb = new SolidBrush(n.Type == "TextField" && n.Str("label") == null ? Muted : Text))
            g.DrawString(text, FNormal, tb, new RectangleF(box.X + 7, box.Y + 5, box.Width - 12 - iconW, 20),
                new StringFormat { Trimming = StringTrimming.EllipsisCharacter, FormatFlags = StringFormatFlags.NoWrap });
        float ix = box.Right - 18, iy = box.Y + FieldH / 2f;
        using var ip = new Pen(Muted, 1.3f);
        using var ib = new SolidBrush(Muted);
        switch (n.Type)
        {
            case "Select":
                g.FillPolygon(ib, new[] { new PointF(ix - 4, iy - 2), new PointF(ix + 4, iy - 2), new PointF(ix, iy + 3) });
                break;
            case "NumberField":
                g.FillPolygon(ib, new[] { new PointF(ix - 4, iy - 2), new PointF(ix + 4, iy - 2), new PointF(ix, iy - 7) });
                g.FillPolygon(ib, new[] { new PointF(ix - 4, iy + 2), new PointF(ix + 4, iy + 2), new PointF(ix, iy + 7) });
                break;
            case "DateField":
                g.DrawRectangle(ip, ix - 6, iy - 5, 12, 11);
                g.DrawLine(ip, ix - 6, iy - 1, ix + 6, iy - 1);
                break;
            case "TimeField":
                g.DrawEllipse(ip, ix - 6, iy - 6, 12, 12);
                g.DrawLine(ip, ix, iy, ix, iy - 4);
                g.DrawLine(ip, ix, iy, ix + 3, iy + 2);
                break;
        }
    }

    static void DrawButton(Graphics g, Node n, Rectangle r)
    {
        bool primary = n.Bool("primary");
        using var path = Rounded(r, 4);
        if (primary)
            using (var b = new SolidBrush(Accent)) g.FillPath(b, path);
        else
        {
            g.FillPath(Brushes.White, path);
            using var p = new Pen(Color.FromArgb(0x8A, 0x92, 0x9C));
            g.DrawPath(p, path);
        }
        using var tb = new SolidBrush(primary ? Color.White : Text);
        g.DrawString(n.Str("text", ""), FBold, tb, r, new StringFormat
        {
            Alignment = StringAlignment.Center,
            LineAlignment = StringAlignment.Center,
            Trimming = StringTrimming.EllipsisCharacter,
            FormatFlags = StringFormatFlags.NoWrap
        });
    }

    static void DrawTable(Graphics g, Node n, Rectangle r)
    {
        var cols = n.List("columns");
        var rows = n.Children.Select(c => c.List("cells")).ToList();
        // Ширина колонки пропорциональна самому длинному тексту в ней.
        var need = new float[cols.Count];
        for (int i = 0; i < cols.Count; i++)
        {
            need[i] = g.MeasureString(cols[i], FBold).Width;
            foreach (var row in rows)
                if (i < row.Count) need[i] = Math.Max(need[i], g.MeasureString(row[i], FSmall).Width);
            need[i] += 14;
        }
        float sum = need.Sum();
        var widths = need.Select(v => v / sum * r.Width).ToArray();

        g.FillRectangle(Brushes.White, r);
        using (var hb = new SolidBrush(Light)) g.FillRectangle(hb, r.X, r.Y, r.Width, 30);
        using var grid = new Pen(Color.FromArgb(0xDD, 0xE1, 0xE6));
        var fmt = new StringFormat { Trimming = StringTrimming.EllipsisCharacter, FormatFlags = StringFormatFlags.NoWrap, LineAlignment = StringAlignment.Center };
        float x = r.X;
        for (int i = 0; i < cols.Count; i++)
        {
            g.DrawString(cols[i], FBold, new SolidBrush(Text), new RectangleF(x + 6, r.Y, widths[i] - 8, 30), fmt);
            x += widths[i];
        }
        bool actions = cols.Count > 0 && cols[^1] == "Действия";
        for (int k = 0; k < rows.Count; k++)
        {
            float y = r.Y + 30 + 28 * k;
            g.DrawLine(grid, r.X, y, r.Right, y);
            x = r.X;
            for (int i = 0; i < cols.Count && i < rows[k].Count; i++)
            {
                string cell = rows[k][i];
                Color c = cell.StartsWith('✓') ? ToneColor("success")
                    : cell.StartsWith('✗') ? ToneColor("danger")
                    : cell.Contains('⚠') || cell.StartsWith("отложено") ? ToneColor("warning")
                    : actions && i == cols.Count - 1 ? Accent : Text;
                using var b = new SolidBrush(c);
                g.DrawString(cell, FSmall, b, new RectangleF(x + 6, y, widths[i] - 8, 28), fmt);
                x += widths[i];
            }
        }
        using var border = new Pen(Border);
        g.DrawRectangle(border, r.X, r.Y, r.Width - 1, r.Height - 1);
    }

    static void DrawChart(Graphics g, Node n, Rectangle r)
    {
        var labels = n.List("labels");
        var values = n.List("values").Select(v => float.Parse(v, System.Globalization.CultureInfo.InvariantCulture)).ToList();
        if (values.Count == 0) return;
        if (n.Str("kind") == "pie")
        {
            Color[] palette = { ToneColor("success"), ToneColor("warning"), ToneColor("danger"), Accent, Muted };
            float sum = values.Sum();
            float d = Math.Min(r.Height - 10, r.Width / 2f - 10);
            var pie = new RectangleF(r.X + 6, r.Y + (r.Height - d) / 2, d, d);
            float a = -90;
            for (int i = 0; i < values.Count; i++)
            {
                float sweep = values[i] / sum * 360;
                using var b = new SolidBrush(palette[i % palette.Length]);
                g.FillPie(b, pie.X, pie.Y, pie.Width, pie.Height, a, sweep);
                g.DrawPie(new Pen(Color.White, 2), pie.X, pie.Y, pie.Width, pie.Height, a, sweep);
                a += sweep;
            }
            float ly = r.Y + r.Height / 2f - values.Count * 24 / 2f;
            for (int i = 0; i < values.Count; i++)
            {
                using var b = new SolidBrush(palette[i % palette.Length]);
                g.FillRectangle(b, pie.Right + 18, ly + 5, 12, 12);
                g.DrawString($"{labels[i]} — {values[i]:0}", FSmall, new SolidBrush(Text), pie.Right + 36, ly + 2);
                ly += 24;
            }
            return;
        }

        float left = r.X + 34, bottom = r.Bottom - 22, top = r.Y + 8, right = r.Right - 6;
        float max = 100;
        using var grid = new Pen(Color.FromArgb(0xE5, 0xE8, 0xEC));
        using var axisText = new SolidBrush(Muted);
        foreach (var v in new[] { 0, 50, 100 })
        {
            float y = bottom - (bottom - top) * v / max;
            g.DrawLine(grid, left, y, right, y);
            var sz = g.MeasureString(v.ToString(), FSmall);
            g.DrawString(v.ToString(), FSmall, axisText, left - sz.Width - 2, y - sz.Height / 2);
        }
        float step = (right - left) / values.Count;
        var pts = new List<PointF>();
        for (int i = 0; i < values.Count; i++)
        {
            float h = (bottom - top) * values[i] / max;
            float cx = left + step * i + step / 2;
            if (n.Str("kind") == "line") pts.Add(new PointF(cx, bottom - h));
            else
            {
                using var b = new SolidBrush(values[i] >= 90 ? ToneColor("success") : values[i] >= 75 ? ToneColor("warning") : ToneColor("danger"));
                g.FillRectangle(b, cx - step * 0.32f, bottom - h, step * 0.64f, h);
            }
            if (i < labels.Count)
            {
                var sz = g.MeasureString(labels[i], FSmall);
                g.DrawString(labels[i], FSmall, axisText, cx - sz.Width / 2, bottom + 3);
            }
        }
        if (pts.Count > 1) using (var p = new Pen(Accent, 2)) g.DrawLines(p, pts.ToArray());
    }

    public static GraphicsPath Rounded(RectangleF r, float rad)
    {
        var p = new GraphicsPath();
        float d = rad * 2;
        p.AddArc(r.X, r.Y, d, d, 180, 90);
        p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }
}
