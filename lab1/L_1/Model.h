// Model.h
#ifndef MODEL_H
#define MODEL_H

#include <QString>
#include <QStringList>

class Model {
private:
    QString inputText;
    QString resultText;
    bool isValid;

public:
    Model();
    void setInputText(const QString& text);
    QString getInputText() const;
    QString getResultText() const;
    bool isValidData() const;
    void processText();
    
private:
    QString invertWord(const QString& word);
};

#endif // MODEL_H