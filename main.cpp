#include <iostream>
#include <string>
#include <vector>
#include <iomanip>
#include <algorithm>
#include <cctype>

enum class TaskStatus { OPEN, IN_PROGRESS, SUBMITTED, PAYMENT_REQUESTED, COMPLETED };

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

std::string toLowerASCII(std::string str) {
    std::transform(str.begin(), str.end(), str.begin(), [](unsigned char c) { return std::tolower(c); });
    return str;
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

struct TransactionRecord {
    int txId;
    int taskId;
    std::string taskTitle;
    double amount;
};

class FreelancerCabinet {
private:
    std::vector<Task> tasks;
    std::vector<TransactionRecord> ledger;
    double freelancerBalance;

    bool isValidFileExtension(const std::string& path) const {
        size_t dotPos = path.find_last_of('.');
        return dotPos != std::string::npos && dotPos != path.length() - 1;
    }

public:
    FreelancerCabinet() : freelancerBalance(0.0) {
        tasks.push_back({1, "Разработка парсера данных", "C++", 250.0, TaskStatus::OPEN, "", "", 0, ""});
        tasks.push_back({2, "Верстка лендинга", "HTML/CSS", 120.0, TaskStatus::OPEN, "", "", 0, ""});
        tasks.push_back({3, "Оптимизация SQL-запросов", "SQL", 180.0, TaskStatus::OPEN, "", "", 0, ""});
        tasks.push_back({4, "Модуль авторизации OAuth2", "C++", 300.0, TaskStatus::OPEN, "", "", 0, ""});
        tasks.push_back({5, "UI/UX макет мобильного банка", "Figma", 210.0, TaskStatus::OPEN, "", "", 0, ""});
    }

    void showAllTasks() const {
        std::cout << "\n================ РЕЕСТР ПРОЕКТОВ БИРЖИ ================\n";
        for (const auto& t : tasks) {
            std::cout << "[" << t.id << "] " << std::left << std::setw(30) << t.title
                      << " | Стек: " << std::setw(8) << t.requiredSkill
                      << " | $" << std::fixed << std::setprecision(2) << std::setw(7) << t.paymentAmount
                      << " | " << statusToString(t.status) << "\n";
            if (!t.uploadedFilePath.empty()) std::cout << "      ├─ Файл: " << t.uploadedFilePath << "\n";
            if (t.status == TaskStatus::COMPLETED && t.clientRating > 0)
                std::cout << "      └─ Оценка: " << t.clientRating << "/5 ★ | Отзыв: \"" << t.clientFeedback << "\"\n";
        }
        std::cout << "=======================================================\n";
    }

    void filterBySkill(const std::string& skill) const {
        std::string query = toLowerASCII(skill);
        std::cout << "\n--- Результаты выборки по навыку: " << skill << " ---\n";
        bool found = false;
        for (const auto& t : tasks) {
            if (toLowerASCII(t.requiredSkill).find(query) != std::string::npos) {
                std::cout << "[" << t.id << "] " << t.title << " | " << t.requiredSkill
                          << " | $" << std::fixed << std::setprecision(2) << t.paymentAmount
                          << " | " << statusToString(t.status) << "\n";
                found = true;
            }
        }
        if (!found) std::cout << "Задач с требуемым стеком не найдено.\n";
    }

    void applyForTask(int taskId, const std::string& proposal) {
        if (proposal.empty()) { std::cout << "[ОШИБКА]: Пустой текст отклика!\n"; return; }
        for (auto& t : tasks) {
            if (t.id == taskId) {
                if (t.status != TaskStatus::OPEN) { std::cout << "[ОШИБКА]: Проект уже занят!\n"; return; }
                t.status = TaskStatus::IN_PROGRESS;
                t.proposalText = proposal;
                std::cout << "[УСПЕХ]: Отклик принят! Статус: IN_PROGRESS.\n";
                return;
            }
        }
        std::cout << "[ОШИБКА]: Задача не найдена.\n";
    }

    void uploadResultFile(int taskId, const std::string& filePath) {
        for (auto& t : tasks) {
            if (t.id == taskId) {
                if (t.status != TaskStatus::IN_PROGRESS) { std::cout << "[ОШИБКА]: Сначала откликнитесь на проект!\n"; return; }
                if (filePath.empty() || !isValidFileExtension(filePath)) {
                    std::cout << "[ОШИБКА ВАЛИДАЦИИ]: Укажите файл с расширением (например, archive.zip)!\n";
                    return;
                }
                t.uploadedFilePath = filePath;
                t.status = TaskStatus::SUBMITTED;
                std::cout << "[УСПЕХ]: Файл '" << filePath << "' загружен. Статус: SUBMITTED.\n";
                return;
            }
        }
        std::cout << "[ОШИБКА]: Задача не найдена.\n";
    }

    void requestPayment(int taskId) {
        for (auto& t : tasks) {
            if (t.id == taskId) {
                if (t.status != TaskStatus::SUBMITTED) {
                    std::cout << "[БЛОКИРОВКА]: Нельзя требовать оплату без сданного файла!\n";
                    return;
                }
                t.status = TaskStatus::COMPLETED;
                freelancerBalance += t.paymentAmount;
                int txId = static_cast<int>(ledger.size()) + 1001;
                ledger.push_back({txId, t.id, t.title, t.paymentAmount});
                t.clientRating = 5;
                t.clientFeedback = "Работа принята без замечаний, спасибо!";
                std::cout << "\n>>> [КНОПКА «ТРЕБОВАТЬ ОПЛАТУ» НАЖАТА] <<<\n";
                std::cout << ">>> Транзакция #" << txId << " подтверждена! Начислено: $" << t.paymentAmount << "\n";
                std::cout << ">>> Заказчик оставил оценку: " << t.clientRating << "/5 ★\n";
                return;
            }
        }
        std::cout << "[ОШИБКА]: Задача не найдена.\n";
    }

    void showBalanceAndLedger() const {
        std::cout << "\n================ ФИНАНСОВЫЙ КАБИНЕТ ================\n";
        std::cout << "Баланс: $" << std::fixed << std::setprecision(2) << freelancerBalance << "\n";
        for (const auto& tx : ledger)
            std::cout << "  - TX #" << tx.txId << " | [" << tx.taskId << "] " << tx.taskTitle << " | +$" << tx.amount << "\n";
        std::cout << "====================================================\n";
    }
};

int main() {
    system("chcp 65001 > nul");
    FreelancerCabinet app;
    int choice = 0;
    while (true) {
        std::cout << "\n===== КАБИНЕТ ФРИЛАНСЕРА (v3.0 — Dynamic UML) =====\n"
                  << "1. Все проекты\n2. Фильтр по навыку\n3. Подать отклик\n"
                  << "4. Загрузить файл\n5. Требовать оплату\n6. Баланс и транзакции\n0. Выход\nВыбор: ";
        if (!(std::cin >> choice)) { std::cin.clear(); std::cin.ignore(10000, '\n'); continue; }
        if (choice == 0) break;
        if (choice == 1) app.showAllTasks();
        else if (choice == 2) { std::string s; std::cout << "Навык: "; std::cin >> s; app.filterBySkill(s); }
        else if (choice == 3) { int id; std::string p; std::cout << "ID: "; std::cin >> id; std::cin.ignore(); std::cout << "Отклик: "; std::getline(std::cin, p); app.applyForTask(id, p); }
        else if (choice == 4) { int id; std::string f; std::cout << "ID: "; std::cin >> id; std::cin.ignore(); std::cout << "Файл: "; std::getline(std::cin, f); app.uploadResultFile(id, f); }
        else if (choice == 5) { int id; std::cout << "ID: "; std::cin >> id; app.requestPayment(id); }
        else if (choice == 6) app.showBalanceAndLedger();
    }
    return 0;
}