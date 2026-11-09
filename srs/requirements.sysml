
package Foodie_Requirements {

    requirement def FoodieRequirement {
        attribute id : String;
        attribute priority : String;
    }

    requirement reqMenu : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-001";
        attribute :>> priority = "Must";
        doc /* Система должна отображать меню блюд по категориям. */
    }

    requirement reqSearch : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-002";
        attribute :>> priority = "Must";
        doc /* Система должна предоставлять поиск блюд по названию. */
    }

    requirement reqCart : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-003";
        attribute :>> priority = "Must";
        doc /* Система должна позволять формировать заказ из блюд меню. */
    }

    requirement reqTotal : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-004";
        attribute :>> priority = "Must";
        doc /* Система должна рассчитывать подытог, доставку, скидку и итог. */
    }

    requirement reqAddress : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-005";
        attribute :>> priority = "Must";
        doc /* Система должна позволять указать адрес доставки. */
    }

    requirement reqPayment : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-006";
        attribute :>> priority = "Must";
        doc /* Система должна позволять выбрать способ оплаты. */
    }

    requirement reqPromo : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-007";
        attribute :>> priority = "Should";
        doc /* Система должна предоставлять возможность применения промокодов. */
    }

    requirement reqPlaceOrder : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-008";
        attribute :>> priority = "Must";
        doc /* Система должна позволять подтвердить и оформить заказ. */
    }

    requirement reqStatus : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-009";
        attribute :>> priority = "Must";
        doc /* Система должна отображать текущий статус заказа. */
    }

    requirement reqHistory : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-010";
        attribute :>> priority = "Should";
        doc /* Система должна хранить историю заказов пользователя. */
    }

    requirement reqValidation : FoodieRequirement {
        attribute :>> id = "REQ-FUNC-011";
        attribute :>> priority = "Must";
        doc /* Система должна проверять обязательные данные перед оформлением заказа. */
    }

    requirement reqNoCardStorage : FoodieRequirement {
        attribute :>> id = "REQ-SEC-001";
        attribute :>> priority = "Must";
        doc /* Система не должна хранить номера банковских карт. */
    }
}

package Foodie_GUI {

    part def MainWindow {
        attribute title = "Foodie";

        part sidebar : Sidebar;
        part topBar : TopBar;
        part promoBanner : PromoBanner;
        part categoryList : CategoryList;
        part dishGrid : DishGrid;
        part orderPanel : OrderPanel;
        part offersPanel : OffersPanel;
    }

    part def Sidebar {
        attribute items = "Home, Orders, Favorites, Offers, Wallet, Profile, Support";
    }

    part def TopBar {
        attribute deliveryAddress = "Адрес доставки";
        attribute searchField = "Поиск блюд";
        attribute notifications = "Уведомления";
        attribute userMenu = "Профиль пользователя";
    }

    part def PromoBanner {
        attribute promoCode = "WELCOME50";
    }

    part def CategoryList {
        attribute categories = "Пицца, Бургеры, Бирьяни, Китайская, Десерты, Здоровое";
    }

    part def DishGrid {
        attribute cardFields = "Название, рейтинг, время доставки, скидка, избранное";
    }

    part def OrderPanel {
        attribute subtotal = "Подытог";
        attribute deliveryFee = "Доставка";
        attribute total = "Итого";
        attribute paymentMethod = "Способ оплаты";
        attribute trackButton = "Отследить заказ";
    }

    part def OffersPanel {
        attribute promoList = "Доступные промокоды";
    }
}
