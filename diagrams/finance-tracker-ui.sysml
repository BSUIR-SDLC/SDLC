package FinanceTrackerUI {
  part def MainWindow {
    part summaryPanel : AccountSummaryPanel;
    part txGrid : TransactionDataGrid;
    part chartsView : AnalyticsChartView;
    part entryDialog : TransactionEntryDialog;
  }
  part def AccountSummaryPanel {
    attribute totalBalance : String;
    attribute selectedCurrency : String;
  }
  part def TransactionDataGrid {
    attribute filterCategory : String;
    attribute searchQuery : String;
  }
  part def TransactionEntryDialog {
    attribute amountInput : String;
    attribute currencyCode : String;
  }
  part def AnalyticsChartView {
    attribute pieChart : String;
    attribute barChart : String;
  }
}
