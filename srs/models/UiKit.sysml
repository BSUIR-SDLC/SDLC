/**
 * UiKit — библиотека элементов пользовательского интерфейса для
 * прототипирования экранов (мокапов) настольного приложения PillTrack на SysML v2.
 *
 * Экран описывается как дерево частей (part): контейнеры задают компоновку,
 * листовые элементы — поля, кнопки, таблицы и диаграммы.
 */
package UiKit {
    private import ScalarValues::*;

    enum def Orientation {
        enum vertical;
        enum horizontal;
    }

    enum def TextStyle {
        enum heading;
        enum normal;
        enum muted;
    }

    enum def Tone {
        enum info;
        enum success;
        enum warning;
        enum danger;
    }

    enum def ChartKind {
        enum bar;
        enum line;
        enum pie;
    }

    /** Базовый элемент интерфейса. */
    abstract part def Widget {
        /** Отображаемый текст: надпись, заголовок или пример значения. */
        attribute text : String [0..1];
        /** Относительная ширина элемента в горизонтальном контейнере. */
        attribute weight : Integer = 1;
    }

    /** Контейнер: размещает вложенные элементы вертикально или горизонтально. */
    abstract part def Container :> Widget {
        attribute orientation : Orientation = Orientation::vertical;
        part children : Widget [0..*];
    }

    /** Окно настольного приложения; width — ширина окна в пикселях. */
    part def Screen :> Container {
        attribute title : String;
        attribute width : Integer = 1200;
    }

    /** Строка: горизонтальный контейнер без рамки. */
    part def Row :> Container {
        attribute :>> orientation = Orientation::horizontal;
    }

    /** Колонка: вертикальный контейнер без рамки. */
    part def Column :> Container;

    /** Панель (карточка): контейнер с рамкой и необязательным заголовком text. */
    part def Panel :> Container;

    /** Панель вкладок главного окна; user — текущий профиль. */
    part def TabBar :> Widget {
        attribute items : String [0..*];
        attribute active : String [0..1];
        attribute user : String [0..1];
    }

    part def Label :> Widget {
        attribute style : TextStyle = TextStyle::normal;
    }

    part def Link :> Widget;

    /** Плашка-уведомление внутри окна. */
    part def Banner :> Widget {
        attribute tone : Tone = Tone::info;
        attribute action : String [0..1];
    }

    /** Поле ввода: label — подпись над полем, text — пример значения. */
    part def TextField :> Widget {
        attribute label : String [0..1];
    }
    part def DateField :> TextField;
    part def TimeField :> TextField;
    part def NumberField :> TextField;

    /** Выпадающий список. */
    part def Select :> TextField;

    part def Checkbox :> Widget {
        attribute checked : Boolean = false;
    }

    part def Button :> Widget {
        attribute primary : Boolean = false;
    }

    /** Карточка показателя: label — название, text — значение. */
    part def StatCard :> Widget {
        attribute label : String;
        attribute tone : Tone = Tone::info;
    }

    part def TableRow :> Widget {
        attribute cells : String [0..*];
    }

    part def Table :> Widget {
        attribute columns : String [1..*];
        part rows : TableRow [0..*];
    }

    /** Диаграмма: labels — подписи, values — значения (пример данных). */
    part def Chart :> Widget {
        attribute kind : ChartKind = ChartKind::bar;
        attribute labels : String [0..*];
        attribute values : Real [0..*];
    }
}
