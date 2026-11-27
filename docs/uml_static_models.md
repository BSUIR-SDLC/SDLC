\# Статические UML-диаграммы проекта «Кабинет фрилансера» (ЛР №6)



\## 1. Диаграмма классов (Class Diagram)



```plantuml

@startuml

skinparam classAttributeIconSize 0



enum TaskStatus {

&#x20; OPEN

&#x20; IN\_PROGRESS

&#x20; SUBMITTED

&#x20; PAYMENT\_REQUESTED

&#x20; COMPLETED

}



class Task {

&#x20; - id : int

&#x20; - title : string

&#x20; - requiredSkill : string

&#x20; - paymentAmount : double

&#x20; - status : TaskStatus

&#x20; - proposalText : string

&#x20; - uploadedFilePath : string

&#x20; - clientRating : int

&#x20; - clientFeedback : string

&#x20; + Task(id: int, title: string, skill: string, amount: double)

&#x20; + getId() : int

&#x20; + getSkill() : string

&#x20; + getStatus() : TaskStatus

&#x20; + setStatus(s: TaskStatus) : void

&#x20; + attachFile(path: string) : bool

}



class Transaction {

&#x20; - txId : int

&#x20; - taskId : int

&#x20; - amount : double

&#x20; - timestamp : string

&#x20; + Transaction(txId: int, taskId: int, amount: double)

&#x20; + toString() : string

}



interface IPaymentValidator {

&#x20; + canRequestPayment(task: Task) : bool

}



class DeliverableValidator {

&#x20; + canRequestPayment(task: Task) : bool

&#x20; + isValidExtension(path: string) : bool

}



class FreelancerCabinet {

&#x20; - tasks : vector<Task>

&#x20; - transactions : vector<Transaction>

&#x20; - freelancerBalance : double

&#x20; - validator : IPaymentValidator\*

&#x20; + showAllTasks() : void

&#x20; + filterBySkill(skill: string) : void

&#x20; + applyForTask(taskId: int, proposal: string) : bool

&#x20; + uploadResultFile(taskId: int, filePath: string) : bool

&#x20; + requestPayment(taskId: int) : bool

&#x20; + printBalanceAndHistory() : void

&#x20; + exportReport(filename: string) : bool

}



Task --> TaskStatus : uses

DeliverableValidator ..|> IPaymentValidator : implements

FreelancerCabinet \*-- Task : contains (composition)

FreelancerCabinet \*-- Transaction : logs (composition)

FreelancerCabinet o-- IPaymentValidator : uses (aggregation)

@enduml
@startuml

package "<<subsystem>> FreelancerCabinetApp" {

&#x20; \[CLI Controller] as CLI

&#x20; \[Task Manager] as TM

&#x20; \[File Validator] as FV

&#x20; \[Payment \& Ledger Engine] as PAY

&#x20; \[Report Exporter] as EXP



&#x20; interface "IUserMenu" as IMenu

&#x20; interface "ITaskService" as ITask

&#x20; interface "IFileCheck" as IFile

&#x20; interface "IPaymentService" as IPay



&#x20; IMenu - CLI

&#x20; CLI ..> ITask : <<use>>

&#x20; ITask - TM

&#x20; TM ..> IFile : <<use>>

&#x20; IFile - FV

&#x20; TM ..> IPay : <<use>>

&#x20; IPay - PAY

&#x20; PAY ..> EXP : <<use>>

}



database "Local File System\\n(reports / deliverables)" as FS

EXP --> FS : writes .txt/.csv

FV --> FS : validates path

@enduml
@startuml

node "User Workstation (Windows 10/11)" <<device>> {

&#x20; node "MSYS2 MinGW64 Runtime" <<executionEnvironment>> {

&#x20;   artifact "freelancer\_cabinet.exe" <<artifact>> {

&#x20;     component "FreelancerCabinetApp" <<component>>

&#x20;   }

&#x20;   artifact "libstdc++-6.dll" <<library>>

&#x20;   artifact "report\_transactions.txt" <<file>>

&#x20; }

&#x20; folder "Local Storage" {

&#x20;   artifact "rezult.zip" <<file>>

&#x20; }

}



"freelancer\_cabinet.exe" ..> "libstdc++-6.dll" : <<use>>

"freelancer\_cabinet.exe" ..> "report\_transactions.txt" : <<manifest>> / writes

"freelancer\_cabinet.exe" ..> "rezult.zip" : reads path

@enduml

