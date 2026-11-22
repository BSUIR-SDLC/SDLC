#include "Controller.h"
#include "View.h"
#include "ResourceIds.h"
#include <string>
#include <exception>
#include <algorithm>

static HMENU menuId(int id) {
    return reinterpret_cast<HMENU>(static_cast<INT_PTR>(id));
}

void Controller::showInputDialog(HWND parent) {
    static bool registered = false;
    if (!registered) {
        WNDCLASSW wc{}; wc.lpfnWndProc = [](HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)->LRESULT {
            auto* c = reinterpret_cast<Controller*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
            if (msg == WM_NCCREATE) { c = static_cast<Controller*>(reinterpret_cast<CREATESTRUCTW*>(lp)->lpCreateParams); SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(c)); }
            if (msg == WM_COMMAND && LOWORD(wp) == UiId::CalculateButton && c) {
                wchar_t y[64]{}, h[64]{};
                GetWindowTextW(GetDlgItem(hwnd, UiId::YearsEdit), y, 64);
                GetWindowTextW(GetDlgItem(hwnd, UiId::HoursEdit), h, 64);
                try {
                    std::wstring yearsText(y), hoursText(h);
                    std::replace(yearsText.begin(), yearsText.end(), L',', L'.');
                    std::replace(hoursText.begin(), hoursText.end(), L',', L'.');
                    size_t a = 0, b = 0;
                    double years = std::stod(yearsText, &a);
                    double hours = std::stod(hoursText, &b);
                    if (a != yearsText.size() || b != hoursText.size()) throw std::exception();
                    std::wstring error; if (c->model_.calculate({years,hours}, error)) { c->model_.save({years,hours}); DestroyWindow(hwnd); }
                    else c->view_.showError(error);
                } catch (...) { c->view_.showError(L"Введите корректные числовые значения."); }
                return 0;
            }
            if (msg == WM_CLOSE) { DestroyWindow(hwnd); return 0; }
            return DefWindowProcW(hwnd,msg,wp,lp);
        };
        wc.hInstance = GetModuleHandleW(nullptr); wc.lpszClassName = L"LifeInputDialog"; wc.hCursor = LoadCursor(nullptr, IDC_ARROW); wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW+1); RegisterClassW(&wc); registered = true;
    }
    HWND d = CreateWindowExW(WS_EX_DLGMODALFRAME, L"LifeInputDialog", L"Ввод данных для расчёта", WS_CAPTION|WS_SYSMENU|WS_VISIBLE,
        CW_USEDEFAULT, CW_USEDEFAULT, 470, 260, parent, nullptr, GetModuleHandleW(nullptr), this);
    if (!d) {
        view_.showError(L"Не удалось открыть окно ввода.");
        return;
    }
    EnableWindow(parent, FALSE);
    HWND yearsLabel = CreateWindowW(L"STATIC", L"Количество лет:", WS_CHILD|WS_VISIBLE, 25, 25, 200, 25, d, nullptr, GetModuleHandleW(nullptr), nullptr);
    HWND years = CreateWindowW(L"EDIT", L"", WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL, 245, 22, 160, 27, d, menuId(UiId::YearsEdit), GetModuleHandleW(nullptr), nullptr);
    HWND hoursLabel = CreateWindowW(L"STATIC", L"Часов за компьютером в день:", WS_CHILD|WS_VISIBLE, 25, 65, 210, 35, d, nullptr, GetModuleHandleW(nullptr), nullptr);
    HWND hours = CreateWindowW(L"EDIT", L"", WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL, 245, 65, 160, 27, d, menuId(UiId::HoursEdit), GetModuleHandleW(nullptr), nullptr);
    HWND calculateButton = CreateWindowW(L"BUTTON", L"Рассчитать", WS_CHILD|WS_VISIBLE|BS_DEFPUSHBUTTON, 245, 125, 160, 32, d, menuId(UiId::CalculateButton), GetModuleHandleW(nullptr), nullptr);
    HFONT font = static_cast<HFONT>(GetStockObject(DEFAULT_GUI_FONT));
    SendMessageW(yearsLabel, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
    SendMessageW(years, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
    SendMessageW(hoursLabel, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
    SendMessageW(hours, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
    SendMessageW(calculateButton, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
    // Каждое новое окно ввода открывается пустым для нового расчёта.
    SetFocus(years);
    MSG msg;
    while (IsWindow(d) && GetMessageW(&msg, nullptr, 0, 0) > 0) {
        if (!IsDialogMessageW(d, &msg)) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    EnableWindow(parent, TRUE);
    SetForegroundWindow(parent);
}