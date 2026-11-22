#pragma once
#include "Model.h"
#include <windows.h>

class LifeView {
public:
    explicit LifeView(LifeModel& model) : model_(model) {}
    bool create(HINSTANCE instance);
    HWND window() const { return window_; }
    void showResult(const LifeResult& result);
    void showError(const std::wstring& message) const;
    static void modelChanged(const LifeResult& result, void* context);
    static LRESULT CALLBACK windowProc(HWND, UINT, WPARAM, LPARAM);

private:
    LifeModel& model_; HWND window_ = nullptr;
    HWND inputInfo_ = nullptr;
    HWND hoursValue_ = nullptr;
    HWND cursorValue_ = nullptr;
    HWND clicksValue_ = nullptr;
    HWND keystrokesValue_ = nullptr;
    void openInputDialog();
};