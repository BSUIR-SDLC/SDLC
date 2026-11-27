# Software Design Description (SDD)

## Project: Freelancer Cabinet System (FreelanceHub)

### 1\. System Requirements Specification

#### 1.1 Functional Requirements \& Priority Ranking

Priorities: 10 (Highest / Critical) to 50 (Lowest / Nice-to-have):

|ID|Feature|Description|Priority|Est. Time|
|-|-|-|-|-|
|**SYS-FR-01**|Skill-based Task Filtering|Fast in-memory lookup of tasks by required skills (C++, HTML/CSS, SQL, Figma).|10 (Highest)|16h|
|**SYS-FR-02**|Proposal Submission|Form for submitting cover letter and changing task status to IN\_PROGRESS.|20 (High)|12h|
|**SYS-FR-03**|Deliverable Uploader|Verification of file existence and path for uploaded deliverables.|20 (High)|18h|
|**SYS-FR-04**|Payment Claim Engine|State machine allowing payment request ONLY if task status is SUBMITTED.|10 (Highest)|14h|
|**SYS-FR-05**|Balance and Ledger|Real-time computation of freelancer balance and transaction audit log.|30 (Medium)|10h|
|**SYS-FR-06**|Rating and Reviews|5-star rating and client feedback module after task completion.|40 (Low)|20h|

#### 1.2 Non-Functional Requirements (NFR)

* NFR-01: Task filtering response time under 50 ms for up to 10,000 records.
* NFR-02: Payment claim attempt without attached file throws a handled error code.
* NFR-03: Modular CLI design separating business logic from console presentation.
* NFR-04: C++17 compliant, buildable via MinGW/GCC without third-party GUI dependencies.

### 2\. Architecture Components

* TaskRegistry: in-memory хранилище задач и фильтрация по навыкам.
* BalanceManager: управление балансом и начисление вознаграждения.
* DeliverableValidationService: валидация файлов и контроль статусов.
* UserInterface: текстовое меню управления.

### 3\. Task State Lifecycle

\[OPEN] -> (Отклик) -> \[IN\_PROGRESS] -> (Загрузка файла) -> \[SUBMITTED] -> (Требовать оплату) -> \[COMPLETED]

\### 4. Dynamic Behavior Modeling (UML)

Текстовые модели динамического поведения (Use Case, Activity, State Machine, Sequence) и глоссарий размещены в каталоге `docs/`:

\* `docs/glossary.md` — глоссарий проекта;

\* `docs/supplementary\_specs.md` — дополнительные спецификации и бизнес-правила;

\* `docs/uml\_models.md` — диаграммы PlantUML и потоки событий.

