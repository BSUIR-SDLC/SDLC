using System.Text;

namespace Sysml2Png;

/// <summary>Элемент модели: пакет, часть, состояние, соединение или переход.</summary>
sealed class Node
{
    public string Kind;          // package, part, state, state def, connection, transition
    public string Name;
    public string Type;          // тип части (после «:»)
    public string Doc;           // текст doc /* ... */
    public string From, To, Event;
    public string Initial;       // для state def: состояние после entry
    public Dictionary<string, object> Attrs = new();
    public List<Node> Children = new();

    public string Str(string key, string def = null) => Attrs.TryGetValue(key, out var v) ? v as string ?? def : def;
    public List<string> List(string key) => Attrs.TryGetValue(key, out var v) && v is List<string> l ? l : new List<string>();
    public bool Bool(string key) => Str(key) == "true";
    public int Int(string key, int def) => int.TryParse(Str(key), out var i) ? i : def;

    public IEnumerable<Node> Descendants()
    {
        foreach (var c in Children)
        {
            yield return c;
            foreach (var d in c.Descendants()) yield return d;
        }
    }
}

/// <summary>
/// Разбор подмножества текстовой нотации SysML v2, достаточного для моделей srs/models:
/// пакеты, использования частей с переопределением атрибутов (attribute :>> x = v;),
/// doc-комментарии, соединения (connection … connect a to b) и автоматы состояний.
/// Определения (part def, enum def, item def) пропускаются.
/// </summary>
sealed class SysmlParser
{
    readonly List<string> _t = new();
    int _p;

    public static Node ParseFile(string path) => new SysmlParser(File.ReadAllText(path, Encoding.UTF8)).ParseRoot();

    SysmlParser(string src) => Tokenize(src);

    void Tokenize(string s)
    {
        int i = 0;
        while (i < s.Length)
        {
            char c = s[i];
            if (char.IsWhiteSpace(c)) { i++; continue; }
            if (c == '/' && i + 1 < s.Length && s[i + 1] == '/') { while (i < s.Length && s[i] != '\n') i++; continue; }
            if (c == '/' && i + 1 < s.Length && s[i + 1] == '*')
            {
                int end = s.IndexOf("*/", i + 2);
                _t.Add("\u0001" + s.Substring(i + 2, end - i - 2).Trim('*', ' ', '\r', '\n'));
                i = end + 2;
                continue;
            }
            if (c == '"')
            {
                int j = i + 1;
                var sb = new StringBuilder();
                while (s[j] != '"') { if (s[j] == '\\') j++; sb.Append(s[j]); j++; }
                _t.Add("\"" + sb);
                i = j + 1;
                continue;
            }
            if (char.IsLetterOrDigit(c) || c == '_' || c == '-' && i + 1 < s.Length && char.IsDigit(s[i + 1]))
            {
                int j = i + 1;
                while (j < s.Length && (char.IsLetterOrDigit(s[j]) || s[j] == '_' || s[j] == '.' && j + 1 < s.Length && char.IsDigit(s[j + 1]))) j++;
                _t.Add(s[i..j]);
                i = j;
                continue;
            }
            foreach (var sym in new[] { ":>>", ":>", "::", "..", ":", "{", "}", "(", ")", ";", ",", "=", "[", "]", "*" })
            {
                if (string.CompareOrdinal(s, i, sym, 0, sym.Length) == 0) { _t.Add(sym); i += sym.Length; goto next; }
            }
            _t.Add(c.ToString());
            i++;
        next:;
        }
    }

    string Peek(int k = 0)
    {
        int p = _p, n = -1;
        while (p < _t.Count)
        {
            if (!_t[p].StartsWith('\u0001') && ++n == k) return _t[p];
            p++;
        }
        return null;
    }

    string Next()
    {
        while (_t[_p].StartsWith('\u0001')) _p++;
        return _t[_p++];
    }

    void Expect(string tok)
    {
        var t = Next();
        if (t != tok) throw new FormatException($"ожидалось «{tok}», получено «{t}» (лексема {_p})");
    }

    void SkipStatement()
    {
        int depth = 0;
        while (true)
        {
            var t = Next();
            if (t == "{") depth++;
            else if (t == "}") { if (--depth == 0) return; }
            else if (t == ";" && depth == 0) return;
        }
    }

    Node ParseRoot()
    {
        var root = new Node { Kind = "root" };
        while (Peek() != null) ParseMember(root);
        return root;
    }

    void ParseBody(Node owner)
    {
        if (Peek() == ";") { Next(); return; }
        Expect("{");
        while (Peek() != "}") ParseMember(owner);
        Next();
    }

    void ParseMember(Node owner)
    {
        string t = Peek();
        switch (t)
        {
            case "package":
                Next();
                var pkg = new Node { Kind = "package", Name = Next() };
                owner.Children.Add(pkg);
                ParseBody(pkg);
                return;
            case "private" or "public" or "import" or "abstract" or "enum" or "item" or "port" or "action":
                SkipStatement();
                return;
            case "doc":
                Next();
                owner.Doc = _t[_p].StartsWith('\u0001') ? _t[_p++][1..].Trim() : null;
                return;
            case "attribute":
                Next();
                if (Peek() == ":>>")
                {
                    Next();
                    string name = Next();
                    Expect("=");
                    owner.Attrs[name] = ParseValue();
                    Expect(";");
                }
                else SkipStatement();
                return;
            case "part" when Peek(1) == "def":
                SkipStatement();
                return;
            case "part":
                Next();
                var part = new Node { Kind = "part", Name = Next() };
                if (Peek() == ":") { Next(); part.Type = Next(); }
                owner.Children.Add(part);
                ParseBody(part);
                return;
            case "connection":
                Next();
                var con = new Node { Kind = "connection", Name = Next() };
                Expect("connect");
                con.From = Next();
                Expect("to");
                con.To = Next();
                owner.Children.Add(con);
                ParseBody(con);
                return;
            case "state" when Peek(1) == "def":
                Next(); Next();
                var sd = new Node { Kind = "state def", Name = Next() };
                owner.Children.Add(sd);
                ParseBody(sd);
                return;
            case "state":
                Next();
                var st = new Node { Kind = "state", Name = Next() };
                owner.Children.Add(st);
                ParseBody(st);
                return;
            case "entry":
                Next();
                Expect(";");
                Expect("then");
                owner.Initial = Next();
                Expect(";");
                return;
            case "transition":
                Next();
                var tr = new Node { Kind = "transition", Name = Next() };
                Expect("first");
                tr.From = Next();
                Expect("accept");
                tr.Event = Next();
                Expect("then");
                tr.To = Next();
                Expect(";");
                owner.Children.Add(tr);
                return;
            default:
                throw new FormatException($"неподдерживаемая конструкция «{t}» (лексема {_p})");
        }
    }

    object ParseValue()
    {
        if (Peek() == "(")
        {
            Next();
            var list = new List<string>();
            while (Peek() != ")")
            {
                list.Add((string)ParseValue());
                if (Peek() == ",") Next();
            }
            Next();
            return list;
        }
        string t = Next();
        if (t.StartsWith('"')) return t[1..];
        // Ссылка на литерал перечисления: Tone::warning → warning
        while (Peek() == "::") { Next(); t = Next(); }
        return t;
    }
}
