// Библиотека элементов интерфейса для мокапов 3D Security Monitoring Center.
// Координаты и размеры задаются в пикселях относительно родительского элемента.
package UiLibrary {
    private import ScalarValues::*;

    part def UiElement {
        attribute posX : Integer;
        attribute posY : Integer;
        attribute width : Integer;
        attribute height : Integer;
        attribute caption : String;
        attribute subcaption : String;
        attribute tone : String;
    }

    part def Screen :> UiElement;
    part def Panel :> UiElement;
    part def Heading :> UiElement;
    part def Label :> UiElement;
    part def Mono :> UiElement;
    part def TextField :> UiElement;
    part def Button :> UiElement;
    part def PrimaryButton :> Button;
    part def Badge :> UiElement;
    part def ListRow :> UiElement;
    part def Room :> UiElement;
    part def Host :> UiElement;
    part def Slider :> UiElement {
        attribute marks : String;
    }
    part def Table :> UiElement {
        attribute columns : String;
        attribute columnWidths : String;
    }
    part def TableRow :> UiElement {
        attribute cells : String;
    }
    part def Block :> UiElement;
    part def Actor :> UiElement;

    connection def Link {
        attribute caption : String;
        end endA : UiElement;
        end endB : UiElement;
    }
}
