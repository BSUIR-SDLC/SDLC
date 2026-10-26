#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
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
        case TaskStatus::OPEN: return "Открыта";
        case TaskStatus::IN_PROGRESS: return "В работе";
        case TaskStatus::SUBMITTED: return "Результат загружен";
        case TaskStatus::PAYMENT_REQUESTED: return "Ожидает оплаты";
        case TaskStatus::COMPLETED: return "Оплачена/Завершена";
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
};

class FreelancerCabinet {
private:
    std::vector<Task> tasks;
    double freelancerBalance;

public:
    FreelancerCabinet() : freelancerBalance(0.0) {
        // Инициализация демонстрационных задач
        tasks.push_back({1, "Разработка парсера данных", "C++", 250.0, TaskStatus::OPEN, "", ""});
        tasks.push_back({2, "Верстка лендинга", "HTML/CSS", 120.0, TaskStatus::OPEN, "", ""});
        tasks.push_back({3, "Оптимизация SQL-запросов", "SQL", 180.0, TaskStatus::OPEN, "", ""});
        tasks.push_back({4, "Написание модуля авторизации", "C++", 300.0, TaskStatus::OPEN, "", ""});
        tasks.push_back({5, "Редизайн мобильного приложения", "Figma", 200.0, TaskStatus::OPEN, "", ""});
    }

    void showAllTasks() const {
        std::cout << "\n================= ДОСТУПНЫЕ ЗАДАЧИ =================\n";
        for (const auto& task : tasks) {
            std::cout << "[" << task.id << "] " << task.title 
                      << " | Навык: " << task.requiredSkill 
                      << " | Бюджет: $" << std::fixed << std::setprecision(2) << task.paymentAmount 
                      << " | Статус: " << statusToString(task.status) << "\n";
        }
        std::cout << "===================================================\n";
    }

    void filterBySkill(const std::string& skill) const {
        std::cout << "\n--- Задачи по навыку: " << skill << " ---\n";
        bool found = false;
        for (const auto& task : tasks) {
            if (task.requiredSkill == skill) {
                std::cout << "[" << task.id << "] " << task.title 
                          << " | Бюджет: $" << task.paymentAmount 
                          << " | Статус: " << statusToString(task.status) << "\n";
                found = true;
            }
        }
        if (!found) {
            std::cout << "Задач с требуемым навыком не найдено.\n";
        }
    }

    void applyForTask(int taskId, const std::string& proposal) {
        for (auto& task : tasks) {
            if (task.id == taskId) {
                if (task.status != TaskStatus::OPEN) {
                    std::cout << "Ошибка: Откликнуться можно только на открытую задачу!\n";
                    return;
                }
                task.status = TaskStatus::IN_PROGRESS;
                task.proposalText = proposal;
                std::cout << "Успех: Отклик отправлен! Задача переведена в статус 'В работе'.\n";
                return;
            }
        }
        std::cout << "Ошибка: Задача с ID " << taskId << " не найдена.\n";
    }

    void uploadResultFile(int taskId, const std::string& filePath) {
        for (auto& task : tasks) {
            if (task.id == taskId) {
                if (task.status != TaskStatus::IN_PROGRESS) {
                    std::cout << "Ошибка: Загрузить файл можно только для задачи 'В работе'!\n";
                    return;
                }
                task.uploadedFilePath = filePath;
                task.status = TaskStatus::SUBMITTED;
                std::cout << "Успех: Файл '" << filePath << "' прикреплен к задаче №" << taskId << ".\n";
                return;
            }
        }
        std::cout << "Ошибка: Задача не найдена.\n";
    }

    void requestPayment(int taskId) {
        for (auto& task : tasks) {
            if (task.id == taskId) {
                if (task.status != TaskStatus::SUBMITTED) {
                    std::cout << "Ошибка: Нельзя требовать оплату без загруженного файла-результата!\n";
                    return;
                }
                task.status = TaskStatus::PAYMENT_REQUESTED;
                std::cout << "\n>>> [КНОПКА НАЖАТА]: Запрос на выплату $" << task.paymentAmount 
                          << " отправлен заказчику!\n";
                
                // Имитация одобрения заказчиком
                task.status = TaskStatus::COMPLETED;
                freelancerBalance += task.paymentAmount;
                std::cout << ">>> Средства успешно зачислены на ваш баланс!\n";
                return;
            }
        }
        std::cout << "Ошибка: Задача не найдена.\n";
    }

    void printBalance() const {
        std::cout << "\nТекущий баланс фрилансера: $" << std::fixed << std::setprecision(2) 
                  << freelancerBalance << "\n";
    }
};

int main() {
    system("chcp 65001 > nul"); // Поддержка кодировки UTF-8 в консоли Windows
    FreelancerCabinet cabinet;
    int choice = 0;

    while (true) {
        std::cout << "\n======== КАБИНЕТ ФРИЛАНСЕРА ========\n";
        std::cout << "1. Показать все задачи\n";
        std::cout << "2. Фильтровать задачи по навыкам\n";
        std::cout << "3. Форма отклика на задачу\n";
        std::cout << "4. Загрузить файл-результат\n";
        std::cout << "5. Требовать оплату (кнопка)\n";
        std::cout << "6. Проверить баланс\n";
        std::cout << "0. Выход\n";
        std::cout << "Выберите действие: ";

        if (!(std::cin >> choice)) {
            std::cin.clear();
            std::cin.ignore(10000, '\n');
            continue;
        }

        if (choice == 0) {
            std::cout << "Выход из системы.\n";
            break;
        }

        switch (choice) {
            case 1:
                cabinet.showAllTasks();
                break;
            case 2: {
                std::string skill;
                std::cout << "Введите навык (C++, HTML/CSS, SQL, Figma): ";
                std::cin >> skill;
                cabinet.filterBySkill(skill);
                break;
            }
            case 3: {
                int id;
                std::string proposal;
                std::cout << "Введите ID задачи: ";
                std::cin >> id;
                std::cin.ignore();
                std::cout << "Введите текст сопроводительного письма (отклика): ";
                std::getline(std::cin, proposal);
                cabinet.applyForTask(id, proposal);
                break;
            }
            case 4: {
                int id;
                std::string path;
                std::cout << "Введите ID задачи: ";
                std::cin >> id;
                std::cin.ignore();
                std::cout << "Введите имя/путь к файлу-результату (например, solution.zip): ";
                std::getline(std::cin, path);
                cabinet.uploadResultFile(id, path);
                break;
            }
            case 5: {
                int id;
                std::cout << "Введите ID сданной задачи для требования оплаты: ";
                std::cin >> id;
                cabinet.requestPayment(id);
                break;
            }
            case 6:
                cabinet.printBalance();
                break;
            default:
                std::cout << "Неверный пункт меню.\n";
        }
    }

    return 0;
}