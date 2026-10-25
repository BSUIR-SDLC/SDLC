package CurrencyForecast_Main {
  part def Dashboard {
    attribute appTitle = "CurrencyForecast";
    part header : TopBar;
    part rates : CurrencyList;
    part convert : Converter;
    part footer : BottomBar;
  }
  
  part def TopBar {
    attribute logo = "CurrencyForecast Logo";
    attribute navMenu = "Курсы, Архив, Настройки";
  }
  
  part def CurrencyList {
    part usd : CurrencyCard;
    part eur : CurrencyCard;
  }
  
  part def CurrencyCard {
    attribute name = "USD";
    attribute value = "3.25 BYN";
    attribute trend = "up";
  }
  
  part def Converter {
    attribute inputAmount = "100";
    attribute fromCurrency = "BYN";
    attribute toCurrency = "USD";
    attribute result = "30.76";
  }
  
  part def BottomBar {
    attribute info = "© 2026 CurrencyForecast";
  }
}