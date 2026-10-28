package IoTPanelUI {
    part dashboardScreen : WebScreen {
        :>> w = 1400; :>> h = 860;
        part telemetryChart : ChartView {
            :>> x = 280; :>> y = 345; :>> w = 1070; :>> h = 300;
            :>> title = "Телеметрия в реальном времени (Chart.js)";
        }
        part stateToggleBtn : Toggle {
            :>> x = 296; :>> y = 266; :>> w = 223; :>> h = 42;
            :>> text = "ОХЛАЖДЕНИЕ: ВКЛ|ВЫКЛ"; :>> selected = 0;
        }
    }
    part ruleBuilderScreen : WebScreen {
        :>> w = 1400; :>> h = 860;
        part ruleForm : FormBox {
            :>> x = 280; :>> y = 150; :>> w = 1070; :>> h = 320;
            :>> text = "Выбрать устройство -> Выбрать метрику -> Условие -> Действие";
        }
    }
}
