package TourReviewMockups {

    view def PlaceCardView {
        attribute title = "Карточка места";
        attribute rating = "Средний рейтинг: 4.2 (128 отзывов)";
        attribute buttons = "Оставить отзыв | Пожаловаться";
    }

    view def ReviewFormView {
        attribute title = "Новый отзыв";
        attribute fields = "Оценка (1-5) | Текст отзыва | Прикрепить фото";
        attribute actions = "Отправить | Отмена";
    }

    view def ModerationQueueView {
        attribute title = "Очередь жалоб";
        attribute list = "Список жалоб с причинами";
        attribute actions = "Скрыть контент | Отклонить жалобу";
        attribute note = "Действие логируется в аудит-журнал";
    }

    view placeCard : PlaceCardView;
    view reviewForm : ReviewFormView;
    view moderationQueue : ModerationQueueView;
}