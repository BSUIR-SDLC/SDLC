#pragma once
#include "Model.h"
#include <windows.h>
class LifeView;
class Controller {
public:
    Controller(LifeModel& model, LifeView& view) : model_(model), view_(view) {}
    void showInputDialog(HWND parent);
private:
    LifeModel& model_; LifeView& view_;
};
