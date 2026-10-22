package GitSpectre {
    doc /*Корневой пакет системы инженерного анализа метаданных GitSpectre.*/

    package Requirements {
        doc /* Спецификация бизнес-, функциональных и нефункциональных требований */

        requirement def SystemRequirement {
            attribute id : ScalarValues::String;
            attribute title : ScalarValues::String;
            attribute description : ScalarValues::String;
        }

        requirement def FunctionalRequirement :> SystemRequirement;
        requirement def NonFunctionalRequirement :> SystemRequirement;
        requirement def SecurityRequirement :> NonFunctionalRequirement;
        requirement def PerformanceRequirement :> NonFunctionalRequirement;

        requirement reqZeroCode : SecurityRequirement {
            attribute id = "REQ-SEC-001";
            attribute title = "Zero-Code Inspection (Гарантия конфиденциальности)";
            doc /* Система принципиально не считывает, не сохраняет и не передает содержимое исходных файлов. Анализ выполняется строго по метаданным коммитов и статистике numstat (+/- строк). */
        }

        requirement reqLocalIngestion : FunctionalRequirement {
            attribute id = "REQ-FUNC-001";
            attribute title = "Парсинг локальных репозиториев";
            doc /* Система должна парсить метаданные из локального каталога .git без необходимости сетевого подключения. */
        }

        requirement reqCloudIngestion : FunctionalRequirement {
            attribute id = "REQ-FUNC-002";
            attribute title = "Синхронизация через Cloud REST API";
            doc /* Система должна поддерживать получение метаданных коммитов и PR через GitHub/GitLab REST API по URL и токену авторизации (PAT) без полного клонирования репозитория. */
        }

        requirement reqBusFactor : FunctionalRequirement {
            attribute id = "REQ-FUNC-003";
            attribute title = "Расчет метрики Bus Factor";
            doc /* Система должна вычислять риск концентрации знаний и ключевых исполнителей по каталогам и проектам на основе соотношения коммитов и затронутых строк. */
        }

        requirement reqCrunchDetection : FunctionalRequirement {
            attribute id = "REQ-FUNC-004";
            attribute title = "Детекция переработок (Crunch / Overtime)";
            doc /* Система должна формировать 24/7 тепловую карту коммитов и выявлять аномальные всплески активности в нерабочие часы и выходные дни. */
        }

        requirement reqBottlenecks : FunctionalRequirement {
            attribute id = "REQ-FUNC-005";
            attribute title = "Выявление узких мест и зависших веток";
            doc /* Система должна идентифицировать ветки без активности более N дней, длительное время до слияния PR (Cycle Time) и всплески Churn Rate. */
        }

        requirement reqCommitHygiene : FunctionalRequirement {
            attribute id = "REQ-FUNC-006";
            attribute title = "Анализ гигиены коммитов";
            doc /* Система должна оценивать качество сообщений коммитов (детектировать бессодержательные описания 'fix', 'asdf', гигантские смешанные коммиты). */
        }

        requirement reqInteractiveDashboard : FunctionalRequirement {
            attribute id = "REQ-FUNC-007";
            attribute title = "Интерактивный дашборд";
            doc /* Графический интерфейс на Qt 6 должен предоставлять KPI-карточки, интерактивные графики и гибкую фильтрацию по диапазону дат и авторам. */
        }

        requirement reqReportExport : FunctionalRequirement {
            attribute id = "REQ-FUNC-008";
            attribute title = "Экспорт отчетов";
            doc /* Система должна обеспечивать экспорт результатов анализа в автономный интерактивный HTML-отчет, JSON и PDF. */
        }

        requirement reqPerfAnalysis : PerformanceRequirement {
            attribute id = "REQ-PERF-001";
            attribute title = "Скорость обработки";
            doc /* Парсинг и расчет метрик локального репозитория объемом до 10 000 коммитов должен занимать не более 5 секунд на типовом ПК. */
        }
    }

    package UseCases {
        actor TeamLead;
        actor CTO;
        actor Developer;

        use case def AnalyzeLocalRepo {
            subject : GitSpectreApp;
            actor user : TeamLead;
            doc /* Анализ локальной директории .git в офлайн-контуре */
        }

        use case def AnalyzeCloudRepo {
            subject : GitSpectreApp;
            actor user : CTO;
            doc /* Получение метаданных удаленного репозитория GitHub/GitLab через REST API */
        }

        use case def ViewDashboardAndRisks {
            subject : GitSpectreApp;
            actor user : TeamLead;
            doc /* Просмотр дашборда: Bus Factor, тепловая карта коммитов, узкие места */
        }

        use case def ExportAuditReport {
            subject : GitSpectreApp;
            actor user : CTO;
            doc /* Формирование автономного отчета для руководства и аудиторов */
        }
    }

    package GUIArchitecture {
        doc /* SysML v2 Part Definition: декомпозиция графического интерфейса GitSpectre */

        part def GitSpectreMainWindow {
            part topBar : TopBarWidget {
                part sourceSelector : SourceModeSelector; // Переключение: Local .git / Cloud GitHub API
                part pathOrUrlInput : LineEdit;
                part tokenInput : PasswordLineEdit;
                part dateFilter : DateRangePicker;
                part btnAnalyze : PushButton;
                part privacyBadge : PrivacyStatusIndicator; // Статус "Zero-Code Protection"
            }

            part kpiContainer : KPICardContainer {
                part cardCommits : MetricCard;    // Всего коммитов
                part cardAuthors : MetricCard;    // Активных авторов
                part cardBusFactor : RiskCard;    // Уровень риска Bus Factor
                part cardCrunch : RiskCard;       // Доля ночных коммитов / переработок
                part cardLeadTime : MetricCard;   // Среднее время жизни веток / PR
            }

            part visualizationArea : SplitterWidget {
                part heatmapView : Heatmap24x7Widget;       // Матрица активности часы/дни недели
                part contributorBarChart : BarChartWidget;  // Распределение нагрузки по авторам
            }

            part riskAlertsPanel : BottlenecksPanel {
                part staleBranchesList : ListView;         // Список зависших веток
                part churnSpikesList : ListView;            // Всплески переписывания кода
                part hygieneAlertsList : ListView;          // Предупреждения о плохих коммитах
            }

            part bottomToolbar : ToolBar {
                part btnExportHtml : PushButton;
                part btnExportJson : PushButton;
                part btnExportPdf : PushButton;
                part progressBar : QProgressBar;
            }
        }
    }
}
