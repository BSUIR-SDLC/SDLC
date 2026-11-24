package QRGate_ScannerStates {
    doc /* Динамика состояний сканера (SDD, представление 007). Отказ при потере связи — fail-closed (REQ-REL-001, ADR-0006). */

    attribute def LoginOk;
    attribute def CheckpointSelected;
    attribute def QrDecoded;
    attribute def ManualRequested;
    attribute def CodeEntered;
    attribute def Allow;
    attribute def Deny;
    attribute def Timeout;
    attribute def Unauthorized;
    attribute def NextPressed;
    attribute def RetryPressed;
    attribute def ChangeCheckpoint;
    attribute def EvacuationOpened;
    attribute def Back;

    state def ScannerStates {
        attribute w = 1900; attribute h = 1000;
        attribute title = "Состояния сканера";

        entry; then login;

        state login { doc /* Вход */ attribute x = 80; attribute y = 140; }
        state selectCheckpoint { doc /* Выбор точки и направления */ attribute x = 560; attribute y = 140; }
        state scanning { doc /* Сканирование (камера активна) */ attribute x = 560; attribute y = 470; }
        state manual { doc /* Ручной ввод кода */ attribute x = 80; attribute y = 820; }
        state evacuation { doc /* Список находящихся внутри */ attribute x = 560; attribute y = 800; }
        state validating { doc /* Проверка (ожидание ответа ≤ 5 с) */ attribute x = 1050; attribute y = 470; }
        state allowed { doc /* ПРОХОД РАЗРЕШЁН */ attribute x = 1500; attribute y = 140; attribute color = "ok"; }
        state denied { doc /* ОТКАЗ В ПРОХОДЕ */ attribute x = 1050; attribute y = 820; attribute color = "deny"; }
        state offline { doc /* Нет связи с сервером */ attribute x = 1500; attribute y = 800; attribute color = "deny"; }

        transition t01 first login accept LoginOk then selectCheckpoint { doc /* вход выполнен */ }
        transition t02 first selectCheckpoint accept CheckpointSelected then scanning { doc /* точка выбрана */ }
        transition t03 first scanning accept QrDecoded then validating { doc /* QR распознан */ }
        transition t04 first scanning accept ManualRequested then manual { doc /* «Ввести код» */ attribute t = 70; }
        transition t05 first manual accept CodeEntered then validating { doc /* код P-/G-NNNNNN */ attribute t = 72; }
        transition t06 first validating accept Allow then allowed { doc /* ALLOW */ }
        transition t07 first validating accept Deny then denied { doc /* DENY */ attribute t = 25; }
        transition t08 first validating accept Timeout then offline { doc /* > 5 с или ошибка сети */ }
        transition t09 first allowed accept NextPressed then scanning { doc /* через 3 с */ }
        transition t10 first denied accept NextPressed then scanning { doc /* «Следующий» */ }
        transition t11 first offline accept RetryPressed then scanning { doc /* «Повторить» */ attribute t = 40; }
        transition t12 first validating accept Unauthorized then login { doc /* 401: сессия истекла */ attribute t = 85; }
        transition t13 first scanning accept ChangeCheckpoint then selectCheckpoint { doc /* «Сменить точку» */ }
        transition t14 first scanning accept EvacuationOpened then evacuation { doc /* «Кто внутри» */ }
        transition t15 first evacuation accept Back then scanning { doc /* «Назад» */ }
    }
}
