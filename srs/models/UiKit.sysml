/**
 * UiKit — библиотека элементов пользовательского интерфейса для
 * прототипирования экранов (мокапов) веб-приложения SubScope на SysML v2.
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

    /** Экран (страница) веб-приложения. */
    part def Screen :> Container {
        attribute title : String;
        attribute url : String;
    }

    /** Строка: горизонтальный контейнер без рамки. */
    part def Row :> Container {
        attribute :>> orientation = Orientation::horizontal;
    }

    /** Колонка: вертикальный контейнер без рамки. */
    part def Column :> Container;

    /** Панель (карточка): контейнер с рамкой и необязательным заголовком text. */
    part def Panel :> Container;

    /** Главное меню приложения. */
    part def NavBar :> Widget {
        attribute items : String [0..*];
        attribute active : String [0..1];
        attribute user : String [0..1];
    }

    part def Label :> Widget {
        attribute style : TextStyle = TextStyle::normal;
    }

    part def Link :> Widget;

    /** Поле ввода: label — подпись над полем, text — пример значения. */
    part def TextField :> Widget {
        attribute label : String [0..1];
    }

    part def PasswordField :> TextField;
    part def DateField :> TextField;

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
    }

    part def TableRow :> Widget {
        attribute cells : String [0..*];
    }

    part def Table :> Widget {
        attribute columns : String [1..*];
        part rows : TableRow [0..*];
    }

    part def Chart :> Widget {
        attribute kind : ChartKind = ChartKind::bar;
    }
}
