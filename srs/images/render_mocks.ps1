Add-Type -AssemblyName System.Drawing
$outDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$bg = [System.Drawing.ColorTranslator]::FromHtml('#f4f6fb')
$ink = [System.Drawing.ColorTranslator]::FromHtml('#20243a')
$muted = [System.Drawing.ColorTranslator]::FromHtml('#70778c')
$purple = [System.Drawing.ColorTranslator]::FromHtml('#6558d3')
$line = [System.Drawing.ColorTranslator]::FromHtml('#e4e7ef')
$white = [System.Drawing.Color]::White
$font = New-Object System.Drawing.Font('Segoe UI', 15)
$small = New-Object System.Drawing.Font('Segoe UI', 11)
$bold = New-Object System.Drawing.Font('Segoe UI', 21, [System.Drawing.FontStyle]::Bold)
$brushes = @{}
foreach ($name in @('bg','ink','muted','purple','line','white')) {
  $brushes[$name] = New-Object System.Drawing.SolidBrush((Get-Variable $name -ValueOnly))
}
function Box($g,$x,$y,$w,$h,$fill,$radius=12,$stroke=$null) {
  $b = New-Object System.Drawing.SolidBrush($fill)
  [Rounded]::FillRoundedRectangle($g,$b,$x,$y,$w,$h,$radius)
  if ($stroke) { $p=New-Object System.Drawing.Pen($stroke,1); [Rounded]::DrawRoundedRectangle($g,$p,$x,$y,$w,$h,$radius); $p.Dispose() }
  $b.Dispose()
}
function Label($g,$x,$y,$value,$f=$font,$color=$ink) { $g.DrawString($value,$f,(New-Object System.Drawing.SolidBrush($color)),$x,$y) }
# Add rounded rectangle helpers using GraphicsPath.
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System.Drawing; using System.Drawing.Drawing2D;
public static class Rounded {
 public static void FillRoundedRectangle(this Graphics g, Brush b, int x,int y,int w,int h,int r) {
  using(var p=new GraphicsPath()){p.AddArc(x,y,r,r,180,90);p.AddArc(x+w-r,y,r,r,270,90);p.AddArc(x+w-r,y+h-r,r,r,0,90);p.AddArc(x,y+h-r,r,r,90,90);p.CloseFigure();g.FillPath(b,p);}
 }
 public static void DrawRoundedRectangle(this Graphics g, Pen pen, int x,int y,int w,int h,int r) {
  using(var p=new GraphicsPath()){p.AddArc(x,y,r,r,180,90);p.AddArc(x+w-r,y,r,r,270,90);p.AddArc(x+w-r,y+h-r,r,r,0,90);p.AddArc(x,y+h-r,r,r,90,90);p.CloseFigure();g.DrawPath(pen,p);}
 }
}
'@
function NewCanvas($title,$active) {
  $bmp=New-Object System.Drawing.Bitmap(1200,760)
  $g=[System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode='AntiAlias'; $g.Clear($bg)
  Box $g 24 24 1152 712 $white 18
  Label $g 56 42 'Planora' $bold $purple
  $nav=@(@('Сегодня',56,120),@('Календарь',184,140),@('Задачи',332,110),@('Заметки',450,120),@('Цели',578,90))
  foreach($n in $nav){$fill=$white;$color=$muted;if($n[0] -eq $active){$fill=[System.Drawing.ColorTranslator]::FromHtml('#eeeaff');$color=$purple};Box $g $n[1] 96 $n[2] 42 $fill 10;Label $g ($n[1]+12) 106 $n[0] $small $color}
  Label $g 850 52 'Понедельник, 26 октября' $small $muted
  Label $g 56 158 $title $bold $ink
  return ,@($bmp,$g)
}
function SaveCanvas($canvas,$name){$canvas[1].Dispose();$canvas[0].Save((Join-Path $outDir ($name+'.png')),[System.Drawing.Imaging.ImageFormat]::Png);$canvas[0].Dispose()}

# Today dashboard
$c=NewCanvas 'Сегодня' 'Сегодня';$g=$c[1]
Label $g 56 210 'Ваш план на день' $font $muted;Box $g 56 245 690 420 $white 14 $line;Label $g 82 265 'Задачи' $bold
$items=@(@('09:00','Подготовить план недели','В работе'),@('11:30','Позвонить врачу','Напоминание'),@('15:00','Отправить документы','Сегодня'))
for($i=0;$i -lt $items.Count;$i++){ $y=320+$i*88;Box $g 78 $y 646 66 ([System.Drawing.ColorTranslator]::FromHtml('#fbfbfe')) 10 $line;Label $g 96 ($y+19) $items[$i][0] $small $purple;Label $g 168 ($y+17) $items[$i][1] $font;Label $g 555 ($y+20) $items[$i][2] $small $muted }
Box $g 770 245 370 190 $white 14 $line;Label $g 798 270 'Ближайшее событие' $small $muted;Label $g 798 310 'Встреча с командой' $font $ink;Label $g 798 350 '16:00 · Онлайн' $small $purple
Box $g 770 455 370 210 ([System.Drawing.ColorTranslator]::FromHtml('#eeeaff')) 14;Label $g 798 480 'Быстрое добавление' $font $purple;Box $g 798 520 310 48 $white 8;Label $g 814 533 'Новая задача…' $small $muted;Box $g 798 584 132 42 $purple 8;Label $g 814 596 '+ Добавить' $small $white
SaveCanvas $c '01-today'

# Calendar screen
$c=NewCanvas 'Календарь' 'Календарь';$g=$c[1];Box $g 56 220 1088 450 $white 14 $line;Label $g 82 240 '‹' $bold $purple;Label $g 122 247 'Октябрь 2026' $font $ink;Label $g 1090 240 '›' $bold $purple
$days=@('ПН','ВТ','СР','ЧТ','ПТ','СБ','ВС');for($j=0;$j -lt 7;$j++){Label $g (95+$j*148) 288 $days[$j] $small $muted}
for($i=0;$i -lt 35;$i++){ $row=[math]::Floor($i/7);$col=$i%7;$x=82+$col*148;$y=315+$row*58;$num=$i-2;$fill=$white;if($num -eq 26){$fill=[System.Drawing.ColorTranslator]::FromHtml('#eeeaff')};Box $g $x $y 132 49 $fill 8 $line;if($num -ge 1 -and $num -le 31){$colr=$ink;if($num -eq 26){$colr=$purple};Label $g ($x+10) ($y+7) "$num" $small $colr;if($num -in @(5,12,19,26)){$b=New-Object System.Drawing.SolidBrush($purple);$g.FillEllipse($b,($x+104),($y+12),8,8);$b.Dispose()}}}
Label $g 84 640 'Выбранный день: 26 октября · 2 события · 3 задачи' $small $muted;SaveCanvas $c '02-calendar'

# Tasks screen
$c=NewCanvas 'Задачи' 'Задачи';$g=$c[1];Box $g 56 220 1088 68 $white 12 $line;Box $g 78 232 485 44 ([System.Drawing.ColorTranslator]::FromHtml('#fbfbfe')) 8 $line;Label $g 94 242 'Поиск задач…' $small $muted
$filters=@(@('Все',590,70,$true),@('Активные',670,118,$false),@('Выполненные',796,145,$false));foreach($f in $filters){$fill=$white;$col=$muted;if($f[3]){$fill=[System.Drawing.ColorTranslator]::FromHtml('#eeeaff');$col=$purple};Box $g $f[1] 232 $f[2] 44 $fill 8 $line;Label $g ($f[1]+10) 244 $f[0] $small $col}
Box $g 1000 232 116 44 $purple 8;Label $g 1012 244 '+ Задача' $small $white;Box $g 56 310 1088 355 $white 14 $line
$tasks=@(@('Согласовать план проекта','Сегодня · 11:00','Активная'),@('Оплатить интернет','Завтра','Активная'),@('Подготовить список покупок','28 октября','Выполнена'),@('Разобрать заметки','30 октября','Активная'))
for($i=0;$i -lt $tasks.Count;$i++){ $y=340+$i*75;$pen=New-Object System.Drawing.Pen($purple,2);$g.DrawEllipse($pen,82,$y+4,20,20);$pen.Dispose();Label $g 120 $y $tasks[$i][0] $font;Label $g 700 $y $tasks[$i][1] $small $muted;Label $g 970 $y $tasks[$i][2] $small $purple;if($i -lt 3){$p=New-Object System.Drawing.Pen($line,1);$g.DrawLine($p,82,($y+38),1115,($y+38));$p.Dispose()}}
SaveCanvas $c '03-tasks'

# Entry form screen
$c=NewCanvas 'Новая запись' 'Сегодня';$g=$c[1];Box $g 240 215 720 455 $white 16 $line;Label $g 278 238 'Создать запись' $bold
Label $g 278 282 'Тип записи' $small $muted;$types=@(@('Задача',278,100,$true),@('Событие',388,110,$false),@('Заметка',508,104,$false));foreach($t in $types){$fill=$white;$col=$muted;if($t[3]){$fill=[System.Drawing.ColorTranslator]::FromHtml('#eeeaff');$col=$purple};Box $g $t[1] 304 $t[2] 38 $fill 8 $line;Label $g ($t[1]+12) 314 $t[0] $small $col}
$fields=@(@('Название','Например, подготовить отчёт'),@('Описание','Добавьте подробности'),@('Дата и время','26 октября 2026 · 14:00'),@('Напоминание','За 15 минут'));for($i=0;$i -lt $fields.Count;$i++){ $y=355+$i*57;Label $g 278 $y $fields[$i][0] $small $muted;Box $g 278 ($y+20) 642 34 ([System.Drawing.ColorTranslator]::FromHtml('#fbfbfe')) 7 $line;Label $g 292 ($y+25) $fields[$i][1] $small $muted}
Box $g 680 610 105 38 $white 8 $line;Label $g 704 619 'Отмена' $small $muted;Box $g 800 610 120 38 $purple 8;Label $g 818 619 'Сохранить' $small $white;SaveCanvas $c '04-entry-form'
