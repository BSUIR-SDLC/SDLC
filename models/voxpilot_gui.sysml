package VoxPilotGui {
  part def MainWindow {
    part statusIndicator
    part activationButton
    part transcript
    part result
    part historyLink
    part settingsLink
  }
  part def HistoryWindow {
    part filter
    part historyTable
  }
  part def SettingsWindow {
    part microphoneSelector
    part triggerEditor
    part languageSelector
    part allowedCommands
    part ttsSwitch
    part saveButton
  }

  part main : MainWindow
  part history : HistoryWindow
  part settings : SettingsWindow
  connect main.historyLink to history
  connect main.settingsLink to settings
}
