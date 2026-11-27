#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <iomanip>
#include <algorithm>
#include <cctype>

enum class TaskStatus {
    OPEN,
    IN_PROGRESS,
    SUBMITTED,
    PAYMENT_REQUESTED,
    COMPLETED
};

std::string statusToString(TaskStatus status) {
    switch (status) {
        case TaskStatus::OPEN: return "Открыта [OPEN]";
        case TaskStatus::IN_PROGRESS: return "В работе [IN_PROGRESS]";
        case TaskStatus::SUBMITTED: return "Файл сдан [SUBMITTED]";
        case TaskStatus::PAYMENT_REQUESTED: return "Запрос оплаты [PAYMENT_REQ]";
        case TaskStatus::COMPLETED: return "Завершена [COMPLETED]";
        default: return "Неизвестно";
    }
}

struct Task {
    int id;
    std::string title;
    std::string requiredSkill;
    double paymentAmount;
    TaskStatus status;
    std::string proposalText;
    std::string uploadedFilePath;
    int clientRating;
    std::string clientFeedback;
};

struct Transaction {
    int txId;
    int taskId;
    double amount;
    std::string description;
};

class IPaymentValidator {
public:
    virtual ~IPaymentValidator() = default;
    virtual bool canRequestPayment(const Task& task) const = 0;
    virtual bool isValidExtension(const std::string& path) const = 0;
};

class DeliverableValidator : public IPaymentValidator {
public:
    bool canRequestPayment(const Task& task) const override {
        return task.status == TaskStatus::SUBMITTED && !task.uploadedFilePath.empty();
    }

    bool isValidExtension(const std::string& path) const override {
        std::vector<std::string> allowed = {".zip", ".rar", ".cpp", ".pdf", ".fig", ".sql"};
        for (const auto& ext : allowed) {
            if (path.size() >= ext.size() &&
                path.compare(path.size() - ext.size(), ext.size(), ext) == 0) {
                return true;
            }
        }
        return false;
    }
};

class FreelancerCabinet {
private:
    std::vector<Task> tasks;
    std::vector<Transaction> transactions;
    double freelancerBalance;
    int nextTxId;
    IPaymentValidator* validator;

    static std::string toLower(std::string s) {
        std::transform(s.begin(), s.end(), s.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        return s;
    }

public:
    explicit FreelancerCabinet(IPaymentValidator* val)
        : freelancerBalance(0.0), nextTxId(1001), validator(val) {
        tasks.push_back({1, "Разработка парсера данных", "C++", 250.0, TaskStatus::OPEN, "", "", 0, ""});
        tasks.push_back({2, "Верстка лендинга", "HTML/CSS", 120.0, TaskStatus::OPEN, "", "", 0, ""});
        tasks.push_back({3, "Оптимизация SQL-запросов", "SQL", 180.0, TaskStatus::OPEN, "", "", 0, ""});
        tasks.push_back({4, "Модуль авторизации OAuth2", "C++", 300.0, TaskStatus::OPEN, "", "", 0, ""});
        tasks.push_back({5, "UI/UX макет мобильного банка", "Figma", 210.0, TaskStatus::OPEN, "", "", 0, ""});
    }

    void showAllTasks() const {
        std::cout << "\n================ РЕЕСТР ДОСТУПНЫХ ПРОЕКТОВ ================\n";
        for (const auto& t : tasks) {
            std::cout << "[" << t.id << "] " << std::left << std::setw(30) << t.title
                      << " | Стек: " << std::setw(8) << t.requiredSkill
                      << " | $" << std::fixed << std::setprecision(2) << std::setw(7) << t.paymentAmount
                      << " | " << statusToString(t.status) << "\n";
            if (t.status == TaskStatus::COMPLETED && t.clientRating > 0) {
                std::cout << "      └─ Оценка: " << t.clientRating << "/5 ★ | Отзыв: \"" << t.clientFeedback << "\"\n";
            }
        }
        std::cout << "===========================================================\n";
    }

    void filterBySkill(const std::string& skill) const {
        std::string query = toLower(skill);
        if (query == "cpp") query = "c++";
        std::cout << "\n--- Результаты выборки по навыку: " << skill << " ---\n";
        bool found = false;
        for (const auto& t : tasks) {
            if (toLower(t.requiredSkill).find(query) != std::string::npos) {
                std::cout << "[" << t.id << "] " << t.title
                          << " | Бюджет: $" << t.paymentAmount
                          << " | " << statusToString(t.status) << "\n";
                found = true;
            }
        }
        if (!found) std::cout << "Задач с требуемым стеком не найдено.\n";
    }

    void applyForTask(int taskId, const std::string& proposal) {
        for (auto& t : tasks) {
            if (t.id == taskId) {
                if (t.status != TaskStatus::OPEN) {
                    std::cout << "[ОШИБКА]: Подать отклик можно только на открытый проект!\n";
                    return;
                }
                t.status = TaskStatus::IN_PROGRESS;
                t.proposalText = proposal;
                std::cout << "[УСПЕХ]: Заявка зарегистрирована! Проект взят в работу.\n";
                return;
            }
        }
        std::cout << "[ОШИБКА]: Задача с ID " << taskId << " не найдена.\n";
    }

    void uploadResultFile(int taskId, const std::string& filePath) {
        for (auto& t : tasks) {
            if (t.id == taskId) {
                if (t.status != TaskStatus::IN_PROGRESS) {
                    std::cout << "[ОШИБКА]: Прикрепление файла доступно только в статусе IN_PROGRESS!\n";
                    return;
                }
                if (!validator->isValidExtension(filePath)) {
                    std::cout << "[ОШИБКА ВАЛИДАЦИИ]: Недопустимый формат файла! Разрешены: .zip, .rar, .cpp, .pdf, .fig, .sql\n";
                    return;
                }
                t.uploadedFilePath = filePath;
                t.status = TaskStatus::SUBMITTED;
                std::cout << "[УСПЕХ]: Файл '" << filePath << "' прошёл проверку. Статус: SUBMITTED.\n";
                return;
            }
        }
        std::cout << "[ОШИБКА]: Задача не найдена.\n";
    }

    void requestPayment(int taskId) {
        for (auto& t : tasks) {
            if (t.id == taskId) {
                if (!validator->canRequestPayment(t)) {
                    std::cout << "[БЛОКИРОВКА БЕЗОПАСНОСТИ]: Требование оплаты отклонено! "
                              << "Сначала прикрепите валидный файл выполненной работы.\n";
                    return;
                }
                t.status = TaskStatus::COMPLETED;
                freelancerBalance += t.paymentAmount;
                t.clientRating = 5;
                t.clientFeedback = "Отличная работа, проект сдан в срок!";
                transactions.push_back({nextTxId++, t.id, t.paymentAmount, "Оплата проекта: " + t.title});
                std::cout << "\n>>> [КНОПКА ТРЕБОВАТЬ ОПЛАТУ НАЖАТА] <<<\n";
                std::cout << ">>> Транзакция #" << (nextTxId - 1) << ": зачислено $" << t.paymentAmount << "\n";
                std::cout << ">>> Заказчик выставил оценку: " << t.clientRating << "/5 ★\n";
                return;
            }
        }
        std::cout << "[ОШИБКА]: Задача не найдена.\n";
    }

    void printBalanceAndHistory() const {
        std::cout << "\n============================================\n";
        std::cout << " Текущий баланс фрилансера: $" << std::fixed << std::setprecision(2)
                  << freelancerBalance << "\n";
        std::cout << " История транзакций (" << transactions.size() << "):\n";
        for (const auto& tx : transactions) {
            std::cout << "  - TX #" << tx.txId << " | Задача #" << tx.taskId
                      << " | +$" << tx.amount << " | " << tx.description << "\n";
        }
        std::cout << "============================================\n";
    }

    void exportReport(const std::string& filename) const {
        std::ofstream out(filename);
        if (!out.is_open()) {
            std::cout << "[ОШИБКА]: Не удалось создать файл отчёта.\n";
            return;
        }
        out << "ОТЧЁТ ПО ТРАНЗАКЦИЯМ — КАБИНЕТ ФРИЛАНСЕРА\n";
        out << "Итоговый баланс: $" << std::fixed << std::setprecision(2) << freelancerBalance << "\n";
        for (const auto& tx : transactions) {
            out << "TX #" << tx.txId << " | Task #" << tx.taskId
                << " | $" << tx.amount << " | " << tx.description << "\n";
        }
        out.close();
        std::cout << "[УСПЕХ]: Отчёт успешно экспортирован в файл '" << filename << "'.\n";
    }
};

int main() {
    system("chcp 65001 > nul");
    DeliverableValidator validator;
    FreelancerCabinet app(&validator);
    int choice = 0;

    while (true) {
        std::cout << "\n===== СИСТЕМА «КАБИНЕТ ФРИЛАНСЕРА» (v4.0 — Static UML) =====\n";
        std::cout << "1. Просмотреть все проекты\n";
        std::cout << "2. Фильтровать проекты по навыку\n";
        std::cout << "3. Подать заявку на проект (форма отклика)\n";
        std::cout << "4. Загрузить файл-результат (с проверкой формата)\n";
        std::cout << "5. Требовать оплату (кнопка с верификацией)\n";
        std::cout << "6. Баланс и история транзакций\n";
        std::cout << "7. Экспортировать отчёт по транзакциям в файл\n";
        std::cout << "0. Выход\n";
        std::cout << "Выберите действие: ";

        if (!(std::cin >> choice)) {
            std::cin.clear();
            std::cin.ignore(10000, '\n');
            continue;
        }
        if (choice == 0) break;

        switch (choice) {
            case 1: app.showAllTasks(); break;
            case 2: {
                std::string s;
                std::cout << "Введите стек технологий (C++, HTML/CSS, SQL, Figma): ";
                std::cin >> s;
                app.filterBySkill(s);
                break;
            }
            case 3: {
                int id;
                std::string prop;
                std::cout << "Введите ID проекта: ";
                std::cin >> id;
                std::cin.ignore();
                std::cout << "Введите текст отклика: ";
                std::getline(std::cin, prop);
                app.applyForTask(id, prop);
                break;
            }
            case 4: {
                int id;
                std::string path;
                std::cout << "Введите ID проекта: ";
                std::cin >> id;
                std::cin.ignore();
                std::cout << "Введите путь к файлу (.zip/.cpp/.pdf): ";
                std::getline(std::cin, path);
                app.uploadResultFile(id, path);
                break;
            }
            case 5: {
                int id;
                std::cout << "Введите ID сданного проекта: ";
                std::cin >> id;
                app.requestPayment(id);
                break;
            }
            case 6: app.printBalanceAndHistory(); break;
            case 7: app.exportReport("report_transactions.txt"); break;
            default: std::cout << "Неверный ввод.\n";
        }
    }
    return 0;
}