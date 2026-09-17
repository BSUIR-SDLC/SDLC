// Controller.cpp
#include "Controller.h"

Controller::Controller() {}

void Controller::processInput(const QString& text) {
    model.setInputText(text);
}

QString Controller::getInputText() const {
    return model.getInputText();
}

QString Controller::getResultText() const {
    return model.getResultText();
}

bool Controller::isValidData() const {
    return model.isValidData();
}