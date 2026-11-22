#include "View.h"
#include "Controller.h"
#include "ResourceIds.h"
#include <sstream>
#include <iomanip>
#include <string>

static HINSTANCE g_instance;
static HFONT g_font = nullptr;
static HFONT g_resultFont = nullptr;

static HMENU menuId(int id) {
    return reinterpret_cast<HMENU>(static_cast<INT_PTR>(id));
}

static void applyFont(HWND control) {
    if (control != nullptr) {
        SendMessageW(control, WM_SETFONT, reinterpret_cast<WPARAM>(g_font), TRUE);
    }
}

static HWND createPane(HWND parent, const wchar_t* title, int x, int y, int width, int height) {
    HWND pane = CreateWindowW(L"BUTTON", title, WS_CHILD | WS_VISIBLE | BS_GROUPBOX,
        x, y, width, height, parent, nullptr, g_instance, nullptr);
    applyFont(pane);
    return pane;
}

static HWND createPaneText(HWND parent, const wchar_t* text, int x, int y, int width, int height) {
    HWND value = CreateWindowW(L"STATIC", text, WS_CHILD | WS_VISIBLE | SS_CENTER,
        x, y, width, height, parent, nullptr, g_instance, nullptr);
    return value;
}

bool LifeView::create(HINSTANCE instance) {
    g_instance = instance;
    WNDCLASSW wc{}; wc.lpfnWndProc = windowProc; wc.hInstance = instance; wc.lpszClassName = L"LifeCalculatorWindow";
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW); wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
    RegisterClassW(&wc);
    g_font = static_cast<HFONT>(GetStockObject(DEFAULT_GUI_FONT));
    g_resultFont = CreateFontW(18, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
    window_ = CreateWindowW(wc.lpszClassName, L"Калькулятор Жизни", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 650, 440, nullptr, nullptr, instance, this);
    return window_ != nullptr;
}

LRESULT CALLBACK LifeView::windowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    auto* self = reinterpret_cast<LifeView*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (msg == WM_NCCREATE) { self = static_cast<LifeView*>(reinterpret_cast<CREATESTRUCTW*>(lp)->lpCreateParams); SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self)); }
    if (!self) return DefWindowProcW(hwnd, msg, wp, lp);
    if (msg == WM_CREATE) {
        createPane(hwnd, L"Ввод данных", 24, 20, 580, 120);
        HWND inputButton = CreateWindowW(L"BUTTON", L"Ввести данные", WS_CHILD|WS_VISIBLE|BS_PUSHBUTTON, 55, 58, 175, 40, hwnd, menuId(UiId::InputButton), g_instance, nullptr);
        applyFont(inputButton);

        self->inputInfo_ = createPaneText(hwnd, L"Данные ещё не введены", 270, 52, 285, 58);
        SendMessageW(self->inputInfo_, WM_SETFONT, reinterpret_cast<WPARAM>(g_resultFont), TRUE);

        createPane(hwnd, L"Результаты расчёта", 24, 153, 580, 245);
        createPane(hwnd, L"Время за компьютером", 44, 177, 255, 95);
        createPane(hwnd, L"Пробег курсора", 329, 177, 255, 95);
        createPane(hwnd, L"Клики мышью", 44, 285, 255, 95);
        createPane(hwnd, L"Нажатия клавиш", 329, 285, 255, 95);
        self->hoursValue_ = createPaneText(hwnd, L"— часов\n— суток", 58, 210, 227, 52);
        self->cursorValue_ = createPaneText(hwnd, L"— км", 343, 218, 227, 35);
        self->clicksValue_ = createPaneText(hwnd, L"—", 58, 320, 227, 35);
        self->keystrokesValue_ = createPaneText(hwnd, L"—", 343, 320, 227, 35);
        SendMessageW(self->hoursValue_, WM_SETFONT, reinterpret_cast<WPARAM>(g_resultFont), TRUE);
        SendMessageW(self->cursorValue_, WM_SETFONT, reinterpret_cast<WPARAM>(g_resultFont), TRUE);
        SendMessageW(self->clicksValue_, WM_SETFONT, reinterpret_cast<WPARAM>(g_resultFont), TRUE);
        SendMessageW(self->keystrokesValue_, WM_SETFONT, reinterpret_cast<WPARAM>(g_resultFont), TRUE);
        return 0;
    } else if (msg == WM_COMMAND && LOWORD(wp) == UiId::InputButton) {
        self->openInputDialog();
        return 0;
    }
    else if (msg == WM_DESTROY) {
        if (g_resultFont != nullptr) {
            DeleteObject(g_resultFont);
            g_resultFont = nullptr;
        }
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}

void LifeView::openInputDialog() {
    Controller controller(model_, *this); controller.showInputDialog(window_);
}

void LifeView::modelChanged(const LifeResult& r, void* context) { static_cast<LifeView*>(context)->showResult(r); }
void LifeView::showResult(const LifeResult& r) {
    if (inputInfo_ == nullptr) {
        return;
    }
    const auto& input = model_.lastInput();
    std::wostringstream inputText;
    inputText << std::fixed << std::setprecision(2)
        << L"Количество лет: " << input.years
        << L"\nЧасов за компьютером в день: " << input.hoursPerDay;
    SetWindowTextW(inputInfo_, inputText.str().c_str());

    std::wostringstream hoursText;
    hoursText << std::fixed << std::setprecision(2)
        << r.totalHours << L" часов\n"
        << r.totalDays << L" суток";
    SetWindowTextW(hoursValue_, hoursText.str().c_str());

    std::wostringstream cursorText;
    cursorText << std::fixed << std::setprecision(2) << r.cursorKm << L" км";
    SetWindowTextW(cursorValue_, cursorText.str().c_str());

    SetWindowTextW(clicksValue_, std::to_wstring(r.clicks).c_str());
    SetWindowTextW(keystrokesValue_, std::to_wstring(r.keystrokes).c_str());
}
void LifeView::showError(const std::wstring& message) const { MessageBoxW(window_, message.c_str(), L"Ошибка ввода", MB_OK|MB_ICONERROR); }