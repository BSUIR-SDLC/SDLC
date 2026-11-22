#include "Model.h"
#include <windows.h>
#include <cmath>
#include <fstream>
#include <filesystem>

namespace {
constexpr double KM_PER_ACTIVE_DAY = 1.5;
constexpr double CLICKS_PER_ACTIVE_DAY = 6000.0;
constexpr double KEYSTROKES_PER_ACTIVE_DAY = 8000.0;
std::filesystem::path fileName() {
    wchar_t path[MAX_PATH]{};
    GetModuleFileNameW(nullptr, path, MAX_PATH);
    std::wstring p(path);
    const auto slash = p.find_last_of(L"\\/");
    return std::filesystem::path(p.substr(0, slash + 1)) / L"life_calculator.dat";
}
}

void LifeModel::setObserver(Observer observer, void* context) { observer_ = observer; context_ = context; }

bool LifeModel::calculate(const InputData& input, std::wstring& error) {
    if (!std::isfinite(input.years) || !std::isfinite(input.hoursPerDay) ||
        input.years <= 0 || input.years > 120 || input.hoursPerDay <= 0 || input.hoursPerDay > 24) {
        error = L"Введите положительные числа: лет (до 120) и часов в день (до 24).";
        return false;
    }
    const InputData normalized{
        std::round(input.years * 100.0) / 100.0,
        std::round(input.hoursPerDay * 100.0) / 100.0
    };
    if (normalized.years <= 0 || normalized.hoursPerDay <= 0) {
        error = L"После округления значение должно быть не меньше 0,01.";
        return false;
    }
    input_ = normalized;
    const double days = normalized.years * 365.25;
    result_.totalHours = days * normalized.hoursPerDay;
    result_.totalDays = result_.totalHours / 24.0;
    const double activeDays = days * normalized.hoursPerDay / 8.0;
    result_.cursorKm = activeDays * KM_PER_ACTIVE_DAY;
    result_.clicks = static_cast<long long>(std::llround(activeDays * CLICKS_PER_ACTIVE_DAY));
    result_.keystrokes = static_cast<long long>(std::llround(activeDays * KEYSTROKES_PER_ACTIVE_DAY));
    if (observer_) {
        observer_(result_, context_);
    }
    return true;
}

bool LifeModel::load() {
    std::ifstream in(fileName());
    InputData loaded;
    if (!(in >> loaded.years >> loaded.hoursPerDay)) {
        return false;
    }
    if (!std::isfinite(loaded.years) || !std::isfinite(loaded.hoursPerDay) ||
        loaded.years <= 0 || loaded.years > 120 ||
        loaded.hoursPerDay <= 0 || loaded.hoursPerDay > 24) {
        return false;
    }
    input_ = loaded;
    return true;
}

bool LifeModel::save(const InputData& input) const {
    std::ofstream out(fileName());
    return out && static_cast<bool>(out << input.years << ' ' << input.hoursPerDay);
}