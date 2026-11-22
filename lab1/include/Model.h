#pragma once
#include <string>

struct InputData { double years = 0; double hoursPerDay = 0; };

struct LifeResult {
    double totalHours = 0, totalDays = 0, cursorKm = 0;
    long long clicks = 0, keystrokes = 0;
};

class LifeModel {
public:
    using Observer = void(*)(const LifeResult&, void*);
    void setObserver(Observer observer, void* context);
    bool calculate(const InputData& input, std::wstring& error);
    const InputData& lastInput() const { return input_; }
    const LifeResult& result() const { return result_; }
    bool load();
    bool save(const InputData& input) const;

private:
    InputData input_;
    LifeResult result_;
    Observer observer_ = nullptr;
    void* context_ = nullptr;
};
