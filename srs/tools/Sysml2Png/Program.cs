// Sysml2Png — строит PNG-изображения графической части SRS из моделей SysML v2.
// Использование: dotnet run --project srs/tools/Sysml2Png -- srs/models srs/images
using System.Text.RegularExpressions;
using Sysml2Png;

string models = args.Length > 0 ? args[0] : "srs/models";
string images = args.Length > 1 ? args[1] : "srs/images";
Directory.CreateDirectory(images);

void Save(string file) => Console.WriteLine($"  {Path.Combine(images, file).Replace('\\', '/')}");

Console.WriteLine($"Модель {models}/Context.sysml");
var context = SysmlParser.ParseFile(Path.Combine(models, "Context.sysml"));
var system = context.Descendants().First(n => n.Kind == "part" && n.Name == "systemContext");
DiagramRenderer.RenderContext(system, Path.Combine(images, "context.png"));
Save("context.png");
var flow = context.Descendants().First(n => n.Kind == "state def");
DiagramRenderer.RenderScreenFlow(flow, Path.Combine(images, "screen-flow.png"));
Save("screen-flow.png");

Console.WriteLine($"Модель {models}/Mockups.sysml");
var mockups = SysmlParser.ParseFile(Path.Combine(models, "Mockups.sysml"));
foreach (var screen in mockups.Descendants().Where(n => n.Kind == "part" && n.Type == "Screen"))
{
    // todayScreen → mockup-today.png, courseFormScreen → mockup-course-form.png
    string name = Regex.Replace(screen.Name.Replace("Screen", ""), "([a-z])([A-Z])", "$1-$2").ToLowerInvariant();
    string file = $"mockup-{name}.png";
    MockupRenderer.Render(screen, Path.Combine(images, file));
    Save(file);
}
