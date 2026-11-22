#include "Model.h"
#include "View.h"
#include <windows.h>

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int show) {
    LifeModel model;
    model.load();

    LifeView view(model);
    model.setObserver(LifeView::modelChanged, &view);

    view.create(instance);

    if (model.lastInput().years > 0) {
        std::wstring error;
        model.calculate(model.lastInput(), error);
    }

    ShowWindow(view.window(), show);
    UpdateWindow(view.window());

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    return static_cast<int>(msg.wParam);
}
