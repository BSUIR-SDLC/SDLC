# SubScope — исходный код

Maven-проект приложения SubScope: Java 17, Spring Boot 3.5, Thymeleaf, Spring Security, PostgreSQL + Flyway (ADR-0001…0003).

## Сборка и запуск

```bash
mvn verify                      # компиляция и модульные тесты
java -jar target/subscope.jar   # запуск на http://localhost:8080
```

Параметры задаются переменными окружения (REQ-INST-001):

| Переменная | По умолчанию | Назначение |
|------------|--------------|------------|
| `DB_URL` | `jdbc:postgresql://localhost:5432/subscope` | Адрес базы данных |
| `DB_USER`, `DB_PASSWORD` | `subscope` | Учётные данные базы данных |
| `PORT` | `8080` | Порт приложения |

Пустая база для разработки: `createdb subscope` (PostgreSQL 15+); схему при запуске создаёт Flyway.

## Структура

| Пакет / файл | Содержание | SDD |
|--------------|------------|-----|
| `by.bsuir.subscope` | `SubScopeApplication` — точка входа, включены фоновые задачи | 002-composition |
| `config` | `ClockConfig` — бин `Clock` в поясе Europe/Minsk | 003-logical |
| `rates` | `Money`, `ExchangeRate`, `MoneyConverter` (алгоритм А1), `NbrbClient` / `HttpNbrbClient` (API НБ РБ), `RateTable` | 003, 007 |
| `subscription` | `BillingPeriod` (приведение к месяцу, перенос даты списания), `CostCalculator` (доля, стоимость в месяц и в год) | 007 |
| `resources/db/migration` | `V1__init.sql` — схема (004-information), `V2__categories.sql` — справочник категорий | 004 |
| `src/test/resources/nbrb` | Образцы ответов API НБ РБ, полученные при проверке интеграции (POC) | — |

## Состояние по плану v3

| Задача | Содержание | Состояние |
|--------|------------|-----------|
| T-00.1 | Каркас Spring Boot, модули | Каркас и пакеты модулей созданы; общий макет страниц — далее |
| T-00.2 | PostgreSQL, Flyway, начальная схема и справочник категорий | Выполнено: `V1__init.sql`, `V2__categories.sql` |
| T-00.3 | CI в GitHub Actions | Выполнено: `.github/workflows/build.yml` |
| T-03.1 | Проверка API НБ РБ на текущую и прошедшую дату (POC, REQ-POC-001) | Выполнено 19.11.2026: 30 валют на 19.11 и на 01.10.2026, масштабы 1, 10, 100 |
| T-03.2 | Клиент API, таблица курсов, ежедневная загрузка | Клиент API и таблица `exchange_rate` в схеме готовы; сохранение и задача `RatesJob` — далее |
| T-03.5 | Пересчёт сумм: `Cur_Scale`, кросс-курс через BYN, округление | Расчётное ядро и тесты выполнены раньше срока (итерация 3) |
| T-01.1, T-01.2, T-00.4, T-11.1 | Регистрация и вход, блокировка, HTTPS и проверка ввода, журналирование | Итерация 1 (23.11–27.11.2026) |
