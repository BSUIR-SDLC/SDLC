# Матрица трассируемости VoxPilot

Матрица связывает бизнес-цели, бизнес-требования, SRS-карточки, дизайн,
реализацию и проверку. `Планируется` означает, что связь описана для
релиза 1.0, но ещё не реализована в текущем учебном прототипе.

| Req ID | Бизнес-цель / BR | Карточка | Дизайн | Реализация (план) | Проверка | Статус |
|---|---|---|---|---|---|---|
| REQ-FUNC-001 | BG-001 / BR-001 | [карточка](../srs/requirements/REQ-FUNC-001.md) | GUI, Audio | ActivationController | TC-F001 | Планируется |
| REQ-FUNC-002 | BG-001 / BR-001 | [карточка](../srs/requirements/REQ-FUNC-002.md) | SpeechService | WhisperAdapter | TC-F002 | Планируется |
| REQ-FUNC-003 | BG-001 / BR-001 | [карточка](../srs/requirements/REQ-FUNC-003.md) | CommandRouter | CommandRouter | TC-F003 | Планируется |
| REQ-FUNC-004 | BG-001 / BR-001 | [карточка](../srs/requirements/REQ-FUNC-004.md) | ActionService | ProcessLauncher | TC-F004 | Планируется |
| REQ-FUNC-005 | BG-001 / BR-001 | [карточка](../srs/requirements/REQ-FUNC-005.md) | ActionService | ProcessLauncher | TC-F005 | Планируется |
| REQ-FUNC-006 | BG-001 / BR-001 | [карточка](../srs/requirements/REQ-FUNC-006.md) | ActionService | AudioController | TC-F006 | Планируется |
| REQ-FUNC-007 | BG-001 / BR-001 | [карточка](../srs/requirements/REQ-FUNC-007.md) | ActionService | LockController | TC-F007 | Планируется |
| REQ-FUNC-008 | BG-001 / BR-001 | [карточка](../srs/requirements/REQ-FUNC-008.md) | ActionService | FileSearch | TC-F008 | Планируется |
| REQ-FUNC-009 | BG-001 / BR-001 | [карточка](../srs/requirements/REQ-FUNC-009.md) | ActionService | BrowserLauncher | TC-F009 | Планируется |
| REQ-FUNC-010 | BG-001 / BR-001 | [карточка](../srs/requirements/REQ-FUNC-010.md) | ActionService | TimerService | TC-F010 | Планируется |
| REQ-FUNC-011 | BG-002 / BR-002 | [карточка](../srs/requirements/REQ-FUNC-011.md) | AnswerService | LlmClient | TC-F011 | Планируется |
| REQ-FUNC-012 | BG-002 / BR-002 | [карточка](../srs/requirements/REQ-FUNC-012.md) | SpeechOutput | TtsAdapter | TC-F012 | Планируется |
| REQ-FUNC-013 | BG-006 / BR-006 | [карточка](../srs/requirements/REQ-FUNC-013.md) | HistoryRepository | SQLiteHistory | TC-F013 | Планируется |
| REQ-FUNC-014 | BG-005 / BR-005 | [карточка](../srs/requirements/REQ-FUNC-014.md) | SettingsRepository | SQLiteSettings | TC-F014 | Планируется |
| REQ-FUNC-015 | BG-004 / BR-004 | [карточка](../srs/requirements/REQ-FUNC-015.md) | ConfirmationDialog | SafetyGate | TC-F015 | Планируется |
| REQ-NFR-001 | BG-001 | [карточка](../srs/requirements/REQ-NFR-001.md) | Performance view | Timing metrics | TC-N001 | Планируется |
| REQ-NFR-002 | BG-003 / BR-003 | [карточка](../srs/requirements/REQ-NFR-002.md) | Privacy view | AudioBuffer | TC-N002 | Планируется |
| REQ-NFR-003 | BG-002 | [карточка](../srs/requirements/REQ-NFR-003.md) | Reliability view | ErrorBoundary | TC-N003 | Планируется |
| REQ-NFR-004 | BG-005 / BR-005 | [карточка](../srs/requirements/REQ-NFR-004.md) | Accessibility view | Qt UI | TC-N004 | Планируется |
| REQ-SEC-001 | BG-003 / BR-003 | [карточка](../srs/requirements/REQ-SEC-001.md) | Security view | LocalSpeechStore | TC-S001 | Планируется |
| REQ-SEC-002 | BG-004 / BR-004 | [карточка](../srs/requirements/REQ-SEC-002.md) | Security view | SafetyGate | TC-S002 | Планируется |

## Правила обновления

При изменении требования обновляются его карточка, строка матрицы, связанные
элементы дизайна и тест. Изменённая связь получает статус `На пересмотре` до
повторной проверки.
