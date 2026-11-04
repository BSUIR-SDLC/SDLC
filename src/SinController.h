#pragma once
#include "SinModel.h"
#include "SinData.h"

class SinController {
public:
    SinController(SinModel* model) : m_model(model) {}

    void processInput(const SinData& data) {
        m_model->calculate(data);
    }

private:
    SinModel* m_model;
};