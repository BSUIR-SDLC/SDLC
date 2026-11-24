/**
 * Публичный интерфейс модуля passes (ADR-0001). На диаграмме компонентов — компонент «Passes»
 * с предоставляемым интерфейсом IPassAdmin и требуемыми IQrSigner и IPassStore.
 */
export {
  DAY_MS, InMemoryPassRepository, MAX_DURATION_MS, PassNotFoundError, PassRuleError, PassService,
  formatPassCode, lifecycleOf,
  type IdGenerator, type IssuePassInput, type IssuedPass, type Pass, type PassRepository, type PassStatus,
  type QrSigner, type StoredStatus,
} from './passService.ts';
