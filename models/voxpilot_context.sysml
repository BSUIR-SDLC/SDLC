package VoxPilotContext {
  part def VoxPilot
  part def User
  part def Microphone
  part def LinuxDesktop
  part def WhisperCpp
  part def SQLite
  part def LanguageModelApi
  part def Browser

  part voxPilot : VoxPilot {
    part speech : WhisperCpp
    part history : SQLite
  }
  part user : User
  part microphone : Microphone
  part desktop : LinuxDesktop
  part browser : Browser
  part llm : LanguageModelApi

  interface userSpeech from user to microphone
  interface recognizedText from speech to voxPilot
  interface localAction from voxPilot to desktop
  interface webNavigation from voxPilot to browser
  interface questionText from voxPilot to llm
  interface historyRecord from voxPilot to history
}
