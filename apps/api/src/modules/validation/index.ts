/**
 * Публичный интерфейс модуля validation (ADR-0001: модули обращаются друг к другу только через index.ts).
 * На диаграмме компонентов — компонент «Validation» с предоставляемым интерфейсом IValidation
 * и требуемыми ITokenVerifier, IValidationStore, IOccupancyPublisher (uml/models/component-qrgate.puml).
 */
export {
  AntiPassbackCheck, CapacityCheck, CheckChain, PassExistsCheck, RevocationCheck, ValidityPeriodCheck, ZoneCheck,
  type CheckpointInfo, type PassCheck, type PassRecord, type SiteRules, type ValidationContext,
} from './checks.ts';
export {
  CheckpointNotFoundError, InvalidPassCodeError, ValidationService,
  type AccessEventRecord, type Clock, type OccupancyEvent, type OccupancyPublisher, type TokenPayload,
  type TokenVerifier, type ValidationCommand, type ValidationRepository, type ValidationServiceDeps, type ValidationTx,
} from './validationService.ts';
export { InMemoryValidationRepository } from './inMemoryRepository.ts';
