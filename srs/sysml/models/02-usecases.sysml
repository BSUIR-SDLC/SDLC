package CheqUseCases {
    private import CheqContext::*;
    use case def <UC1> 'ВИ-1 Добавить покупку вручную';
    use case def <UC2> 'ВИ-2 Импортировать и проверить чек';
    use case def <UC3> 'ВИ-3 Найти покупку и историю цен';
    use case def <UC4> 'ВИ-4 Контролировать расходы и бюджет';
    use case def <UC5> 'ВИ-5 Настроить карты и валюту';
    use case def <UC6> 'ВИ-6 Экспортировать выбранные записи';
    use case def <Work> 'Работа с личным архивом Cheq' {
        subject app : 'Приложение';
        actor user : 'Пользователь';
        include use case scenario1 : UC1;
        include use case scenario2 : UC2;
        include use case scenario3 : UC3;
        include use case scenario4 : UC4;
        include use case scenario5 : UC5;
        include use case scenario6 : UC6;
    }
}
