#include <iostream>
#include <string>
#include <vector>
#include <iomanip>

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

class FreelancerCabinet {
private:
    std::vector<Task> tasks;
    double freelancerBalance;

public:
    FreelancerCabinet() : freelancerBalance(0.0) {
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
        std::cout << "\n--- Результаты выборки по навыку: " << skill << " ---\n";
        bool found = false;
        for (const auto& t : tasks) {
            if (t.requiredSkill == skill) {
                std::cout << "[" << t.id << "] " << t.title 
                          << " | Бюджет: $" << t.paymentAmount 
                          << " | " << statusToString(t.status) << "\n";
                found = true;
            }
        }
        if (!found) {
            std::cout << "Задач с требуемым стеком не найдено.\n";
        }
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
                if (filePath.empty()) {
                    std::cout << "[ОШИБКА]: Имя файла не может быть пустым!\n";
                    return;
                }
                t.uploadedFilePath = filePath;
                t.status = TaskStatus::SUBMITTED;
                std::cout << "[УСПЕХ]: Файл '" << filePath << "' зафиксирован. Статус: SUBMITTED.\n";
                return;
            }
        }
        std::cout << "[ОШИБКА]: Задача не найдена.\n";
    }

    void requestPayment(int taskId) {
        for (auto& t : tasks) {
            if (t.id == taskId) {
                if (t.status != TaskStatus::SUBMITTED) {
                    std::cout << "[БЛОКИРОВКА БЕЗОПАСНОСТИ]: Требование оплаты отклонено! "
                              << "Сначала прикрепите файл выполненной работы.\n";
                    return;
                }
                t.status = TaskStatus::COMPLETED;
                freelancerBalance += t.paymentAmount;
                t.clientRating = 5;
                t.clientFeedback = "Отличная работа, проект сдан в срок!";
                
                std::cout << "\n>>> [КНОПКА ТРЕБОВАТЬ ОПЛАТУ НАЖАТА] <<<\n";
                std::cout << ">>> Гонорар $" << t.paymentAmount << " успешно зачислен на баланс!\n";
                std::cout << ">>> Заказчик выставил оценку: " << t.clientRating << "/5 ★\n";
                return;
            }
        }
        std::cout << "[ОШИБКА]: Задача не найдена.\n";
    }

    void printBalance() const {
        std::cout << "\n============================================\n";
        std::cout << " Текущий баланс фрилансера: $" << std::fixed << std::setprecision(2) 
                  << freelancerBalance << "\n";
        std::cout << "============================================\n";
    }
};

int main() {
    system("chcp 65001 > nul");
    FreelancerCabinet app;
    int choice = 0;

    while (true) {
        std::cout << "\n===== СИСТЕМА «КАБИНЕТ ФРИЛАНСЕРА» (SDD v2.0) =====\n";
        std::cout << "1. Просмотреть все проекты\n";
        std::cout << "2. Фильтровать проекты по навыку\n";
        std::cout << "3. Подать заявку на проект (форма отклика)\n";
        std::cout << "4. Загрузить файл-результат (сдача работы)\n";
        std::cout << "5. Требовать оплату (кнопка с верификацией)\n";
        std::cout << "6. Проверить баланс фрилансера\n";
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
                std::cout << "Введите имя сдаваемого файла/архива: ";
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
            case 6: app.printBalance(); break;
            default: std::cout << "Неверный ввод.\n";
        }
    }
    return 0;
}
