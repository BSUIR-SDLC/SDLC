package CheqContext {
    doc /* Контекст Android-приложения Cheq для личного учёта покупок. */
    part def 'Приложение';
    part def 'Пользователь';
    part def 'Сервис';
    part def 'Хранилище';
    part def 'Средство Android';
    part <context> 'Контекст Cheq' {
        part <user> 'Владелец' : 'Пользователь';
        part <app> 'Cheq' : 'Приложение';
        part <camera> 'Камера / фото' : 'Средство Android';
        part <groq> 'Groq / Worker' : 'Сервис';
        part <rates> 'НБРБ' : 'Сервис';
        part <db> 'База SQLite' : 'Хранилище';
        part <pending> 'Очередь и фото' : 'Хранилище';
        part <export> 'TXT-экспорт' : 'Хранилище';
        connection 'ввод и просмотр' connect user to app;
        connection 'фото' connect camera to app;
        connection 'OCR-текст' connect app to groq;
        connection 'исторический курс' connect rates to app;
        connection 'покупки' connect app to db;
        connection 'черновики' connect app to pending;
        connection 'экспорт' connect app to export;
    }
}
