package QRGate_UseCases {
    doc /* Варианты использования QRGate. */

    private import QRGate_Context::*;

    use case def ControllerUseCase {
        subject qrgate : QRGate;
        actor controller : Controller;
    }
    use case def AdminUseCase {
        subject qrgate : QRGate;
        actor admin : Administrator;
    }

    use case <'UC-01'> login : ControllerUseCase {
        doc /* Войти и выбрать точку прохода */
    }
    use case <'UC-02'> scanPass : ControllerUseCase {
        doc /* Отсканировать QR и получить решение */
    }
    use case <'UC-03'> manualEntry : ControllerUseCase {
        doc /* Ввести код пропуска вручную */
    }
    use case <'UC-04'> issuePass : AdminUseCase {
        doc /* Выпустить, продлить, отозвать пропуск */
    }
    use case <'UC-05'> watchOccupancy : AdminUseCase {
        doc /* Следить за live-графиком заполняемости */
    }
    use case <'UC-06'> viewLog : AdminUseCase {
        doc /* Просмотреть и выгрузить журнал проходов */
    }
    use case <'UC-07'> configure : AdminUseCase {
        doc /* Настроить точки прохода и вместимость */
    }
}
