package CurrencyForecast_Details {
  part def CurrencyPage {
    attribute title = "Детали: USD/BYN";
    part header : TopBar;
    part historyChart : Chart;
    part mlForecast : ForecastPanel;
    part footer : BottomBar;
  }
  
  part def TopBar {
    attribute logo = "CurrencyForecast Logo";
  }
  
  part def Chart {
    attribute period = "30 дней";
    attribute type = "Line";
    attribute dataPoints = "30";
  }
  
  part def ForecastPanel {
    attribute targetDays = "7";
    attribute predictedValue = "3.28 BYN";
    attribute confidence = "85%";
    attribute algorithm = "Linear Regression";
  }
  
  part def BottomBar {
    attribute info = "© 2026 CurrencyForecast";
  }
}