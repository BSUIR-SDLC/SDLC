using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;

namespace Sysml2Png;

/// <summary>Контекстная диаграмма (части и соединения) и карта окон (автомат состояний).</summary>
static class DiagramRenderer
{
    const float Scale = 2f;
    static readonly Color Line = Color.FromArgb(0x55, 0x5E, 0x6A);
    static readonly Color Text = Color.FromArgb(0x1F, 0x29, 0x37);
    static readonly Color Muted = Color.FromArgb(0x6B, 0x72, 0x80);
    static readonly Color SystemFill = Color.FromArgb(0xDC, 0xE8, 0xFB);
    static readonly Color SystemBorder = Color.FromArgb(0x2F, 0x6F, 0xDE);
    static readonly Font FName = new("Segoe UI Semibold", 9.5f, GraphicsUnit.Point);
    static readonly Font FType = new("Segoe UI", 8f, GraphicsUnit.Point);
    static readonly Font FEdge = new("Segoe UI", 8f, GraphicsUnit.Point);

    sealed class Box
    {
        public string Name, Title, Type;
        public RectangleF R;
        public PointF C => new(R.X + R.Width / 2, R.Y + R.Height / 2);
    }

    static (Bitmap, Graphics) Canvas(int w, int h)
    {
        var bmp = new Bitmap((int)(w * Scale), (int)(h * Scale), PixelFormat.Format24bppRgb);
        var g = Graphics.FromImage(bmp);
        g.ScaleTransform(Scale, Scale);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
        g.Clear(Color.White);
        return (bmp, g);
    }

    // ---------------- Контекст ----------------

    public static void RenderContext(Node context, string pngPath)
    {
        var parts = context.Children.Where(c => c.Kind == "part").ToList();
        var cons = context.Children.Where(c => c.Kind == "connection").ToList();
        var app = parts.First(p => p.Type == "DesktopApplication");
        bool Linked(Node p) => cons.Any(c => c.From == p.Name && c.To == app.Name || c.To == p.Name && c.From == app.Name);

        // Колонки: пользователи системы | система | окружение | получатели результатов.
        int Column(Node p) => p == app ? 1 : p.Type == "Person" ? (Linked(p) ? 0 : 3) : 2;
        const int colW = 340, boxW = 200, boxH = 58, rowH = 100, marginX = 30;
        var groups = parts.GroupBy(Column).ToDictionary(gr => gr.Key, gr => gr.ToList());
        int maxRows = groups.Values.Max(l => l.Count);
        int width = marginX * 2 + colW * 3 + boxW;
        int height = maxRows * rowH + 90;

        var boxes = new Dictionary<string, Box>();
        foreach (var (col, list) in groups)
        {
            float top = (height - 50 - list.Count * rowH) / 2f;
            for (int i = 0; i < list.Count; i++)
            {
                var p = list[i];
                float x = marginX + col * colW;
                float y = top + i * rowH + (rowH - boxH) / 2f;
                boxes[p.Name] = new Box { Name = p.Name, Title = p.Doc ?? p.Name, Type = p.Type, R = new RectangleF(x, y, boxW, boxH) };
            }
        }

        var (bmp, g) = Canvas(width, height);
        using (bmp)
        using (g)
        {
            foreach (var c in cons)
            {
                var a = boxes[c.From];
                var b = boxes[c.To];
                var pa = Border(a, b.C);
                var pb = Border(b, a.C);
                bool back = b.R.X < a.R.X - 1 && Math.Abs(b.R.X - a.R.X) > colW * 1.5f;
                if (back)
                {
                    // Длинная обратная связь: дуга под схемой.
                    pa = new PointF(a.C.X, a.R.Bottom);
                    pb = new PointF(b.C.X, b.R.Bottom);
                    float low = height - 8;
                    var c1 = new PointF(pa.X, low);
                    var c2 = new PointF(pb.X, low);
                    using (var pen = new Pen(Line, 1.2f)) g.DrawBezier(pen, pa, c1, c2, pb);
                    Arrow(g, c2, pb);
                    EdgeLabel(g, c.Doc, new PointF((pa.X + pb.X) / 2, low - 14));
                }
                else
                {
                    using (var pen = new Pen(Line, 1.2f)) g.DrawLine(pen, pa, pb);
                    Arrow(g, pa, pb);
                    EdgeLabel(g, c.Doc, new PointF((pa.X + pb.X) / 2, (pa.Y + pb.Y) / 2));
                }
            }
            foreach (var box in boxes.Values) DrawBox(g, box);
            bmp.Save(pngPath, ImageFormat.Png);
        }
    }

    static void DrawBox(Graphics g, Box b)
    {
        var r = b.R;
        using var pen = new Pen(Line, 1.2f);
        switch (b.Type)
        {
            case "Person":
                g.FillEllipse(Brushes.White, r);
                g.DrawEllipse(pen, r);
                break;
            case "DesktopApplication":
                using (var path = MockupRenderer.Rounded(r, 8))
                {
                    using var fill = new SolidBrush(SystemFill);
                    g.FillPath(fill, path);
                    using var sp = new Pen(SystemBorder, 2f);
                    g.DrawPath(sp, path);
                }
                break;
            case "Database":
            {
                float e = 12;
                g.FillRectangle(Brushes.White, r.X, r.Y + e / 2, r.Width, r.Height - e);
                g.FillEllipse(Brushes.White, r.X, r.Bottom - e, r.Width, e);
                g.DrawLine(pen, r.X, r.Y + e / 2, r.X, r.Bottom - e / 2);
                g.DrawLine(pen, r.Right, r.Y + e / 2, r.Right, r.Bottom - e / 2);
                g.DrawArc(pen, r.X, r.Bottom - e, r.Width, e, 0, 180);
                g.FillEllipse(Brushes.White, r.X, r.Y, r.Width, e);
                g.DrawEllipse(pen, r.X, r.Y, r.Width, e);
                r = new RectangleF(r.X, r.Y + e / 2, r.Width, r.Height - e / 2);
                break;
            }
            default:
                using (var path = MockupRenderer.Rounded(r, 8))
                {
                    g.FillPath(Brushes.White, path);
                    using var dp = new Pen(Line, 1.2f) { DashStyle = DashStyle.Dash };
                    g.DrawPath(dp, path);
                }
                break;
        }
        var center = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
        g.DrawString(b.Title, FName, new SolidBrush(Text), new RectangleF(r.X + 4, r.Y + 2, r.Width - 8, r.Height / 2 + 8), center);
        g.DrawString("«" + b.Type + "»", FType, new SolidBrush(Muted), new RectangleF(r.X, r.Y + r.Height / 2 + 6, r.Width, r.Height / 2 - 8), center);
    }

    static PointF Border(Box b, PointF toward)
    {
        var c = b.C;
        float dx = toward.X - c.X, dy = toward.Y - c.Y;
        if (dx == 0 && dy == 0) return c;
        float hw = b.R.Width / 2, hh = b.R.Height / 2;
        if (b.Type == "Person")
        {
            double t = 1 / Math.Sqrt(dx * dx / (hw * hw) + dy * dy / (hh * hh));
            return new PointF(c.X + (float)(dx * t), c.Y + (float)(dy * t));
        }
        float s = Math.Min(Math.Abs(hw / (dx == 0 ? 1e-6f : dx)), Math.Abs(hh / (dy == 0 ? 1e-6f : dy)));
        return new PointF(c.X + dx * s, c.Y + dy * s);
    }

    static void Arrow(Graphics g, PointF from, PointF to)
    {
        float dx = to.X - from.X, dy = to.Y - from.Y;
        float len = (float)Math.Sqrt(dx * dx + dy * dy);
        if (len < 1) return;
        dx /= len; dy /= len;
        const float L = 9, W = 4;
        var p1 = new PointF(to.X - dx * L - dy * W, to.Y - dy * L + dx * W);
        var p2 = new PointF(to.X - dx * L + dy * W, to.Y - dy * L - dx * W);
        using var b = new SolidBrush(Line);
        g.FillPolygon(b, new[] { to, p1, p2 });
    }

    static void EdgeLabel(Graphics g, string text, PointF at)
    {
        if (string.IsNullOrEmpty(text)) return;
        var sz = g.MeasureString(text, FEdge, 120);
        var r = new RectangleF(at.X - sz.Width / 2, at.Y - sz.Height / 2, sz.Width + 1, sz.Height);
        g.FillRectangle(Brushes.White, r);
        g.DrawString(text, FEdge, new SolidBrush(Muted), r, new StringFormat { Alignment = StringAlignment.Center });
    }

    // ---------------- Карта окон ----------------

    public static void RenderScreenFlow(Node flow, string pngPath)
    {
        var states = flow.Children.Where(c => c.Kind == "state").ToList();
        var trans = flow.Children.Where(c => c.Kind == "transition").ToList();

        // Слои — расстояние от начального состояния (поиск в ширину).
        var layer = new Dictionary<string, int> { [flow.Initial] = 0 };
        var queue = new Queue<string>();
        queue.Enqueue(flow.Initial);
        while (queue.Count > 0)
        {
            var s = queue.Dequeue();
            foreach (var t in trans.Where(t => t.From == s && !layer.ContainsKey(t.To)))
            {
                layer[t.To] = layer[s] + 1;
                queue.Enqueue(t.To);
            }
        }

        const int colW = 290, boxW = 170, boxH = 48, rowH = 120, marginX = 30, startW = 60;
        int layers = layer.Values.Max() + 1;
        int maxRows = layer.GroupBy(kv => kv.Value).Max(gr => gr.Count());
        int width = marginX * 2 + startW + colW * (layers - 1) + boxW;
        int height = maxRows * rowH + 40;

        var boxes = new Dictionary<string, Box>();
        foreach (var gr in states.GroupBy(s => layer[s.Name]))
        {
            var list = gr.ToList();
            float top = (height - list.Count * rowH) / 2f;
            for (int i = 0; i < list.Count; i++)
            {
                float x = marginX + startW + gr.Key * colW;
                float y = top + i * rowH + (rowH - boxH) / 2f;
                boxes[list[i].Name] = new Box { Name = list[i].Name, Title = list[i].Doc ?? list[i].Name, Type = "state", R = new RectangleF(x, y, boxW, boxH) };
            }
        }

        var (bmp, g) = Canvas(width, height);
        using (bmp)
        using (g)
        {
            // Начальное псевдосостояние.
            var first = boxes[flow.Initial];
            var dot = new PointF(marginX + 6, first.C.Y);
            using (var b = new SolidBrush(Text)) g.FillEllipse(b, dot.X - 6, dot.Y - 6, 12, 12);
            using (var pen = new Pen(Line, 1.2f)) g.DrawLine(pen, dot.X + 6, dot.Y, first.R.X, dot.Y);
            Arrow(g, dot, new PointF(first.R.X, dot.Y));

            foreach (var t in trans)
            {
                var a = boxes[t.From];
                var b = boxes[t.To];
                bool pair = trans.Any(o => o.From == t.To && o.To == t.From);
                float dx = b.C.X - a.C.X, dy = b.C.Y - a.C.Y;
                float len = (float)Math.Sqrt(dx * dx + dy * dy);
                // Встречные переходы расходятся в разные стороны от прямой.
                float bend = pair ? 24 : 0;
                float nx = -dy / len * bend, ny = dx / len * bend;
                var mid = new PointF((a.C.X + b.C.X) / 2 + nx, (a.C.Y + b.C.Y) / 2 + ny);
                var pa = Border(a, mid);
                var pb = Border(b, mid);
                var c1 = new PointF(pa.X + (mid.X - pa.X) * 0.7f, pa.Y + (mid.Y - pa.Y) * 0.7f);
                var c2 = new PointF(pb.X + (mid.X - pb.X) * 0.7f, pb.Y + (mid.Y - pb.Y) * 0.7f);
                using (var pen = new Pen(Line, 1.2f)) g.DrawBezier(pen, pa, c1, c2, pb);
                Arrow(g, c2, pb);
                EdgeLabel(g, t.Event, mid);
            }
            foreach (var box in boxes.Values)
            {
                using (var path = MockupRenderer.Rounded(box.R, 10))
                {
                    using var fill = new SolidBrush(box.Name == flow.Initial ? Color.FromArgb(0xF3, 0xF5, 0xF8) : SystemFill);
                    g.FillPath(fill, path);
                    using var pen = new Pen(SystemBorder, 1.4f);
                    g.DrawPath(pen, path);
                }
                var center = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
                var r = box.R;
                g.DrawString(box.Title, FName, new SolidBrush(Text), new RectangleF(r.X, r.Y + 3, r.Width, r.Height / 2), center);
                g.DrawString(box.Name, FType, new SolidBrush(Muted), new RectangleF(r.X, r.Y + r.Height / 2 - 1, r.Width, r.Height / 2), center);
            }
            bmp.Save(pngPath, ImageFormat.Png);
        }
    }
}
