// Model.cpp
#include "Model.h"
#include <QDebug>

Model::Model() : isValid(false) {}

void Model::setInputText(const QString& text) {
    inputText = text;
    isValid = !text.trimmed().isEmpty();
    if (isValid) {
        processText();
    } else {
        resultText = "";
    }
}

QString Model::getInputText() const {
    return inputText;
}

QString Model::getResultText() const {
    return resultText;
}

bool Model::isValidData() const {
    return isValid;
}

void Model::processText() {
    if (!isValid) return;
    
    QStringList words = inputText.split(' ', Qt::SkipEmptyParts);
    QStringList invertedWords;
    
    for (const QString& word : words) {
        invertedWords.append(invertWord(word));
    }
    
    resultText = invertedWords.join(' ');
}

QString Model::invertWord(const QString& word) {
    QString inverted;
    for (int i = word.length() - 1; i >= 0; --i) {
        inverted.append(word[i]);
    }
    return inverted;
}