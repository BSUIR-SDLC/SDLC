---
status: "accepted"
date: 2026-11-21
decision-makers: А. В. Голуб (Архитектор / Исполнитель)
consulted: Заказчик
informed: Преподаватель (О. М. Внук)
---

# Ограничение нативной поставки архитектурой `arm64-v8a` с R8-оптимизацией и повторяемой CLI-сборкой

## Контекст и постановка задачи

В состав APK Cheq входят два тяжёлых нативных компонента OCR: Google ML Kit Text Recognition (`16.0.1`) и Tesseract4Android (`4.9.0`, включающий нативные библиотеки Tesseract, Leptonica, libjpeg, libpng) плюс встроенные языковые модели `tessdata/{rus,eng}.traineddata`. При упаковке всех четырёх Android ABI (`armeabi-v7a`, `arm64-v8a`, `x86`, `x86_64`) размер универсального APK резко возрастает, а сборка и установка на учебное устройство замедляются.

Как настроить конфигурацию сборки Gradle и целевую поставку APK для Android 8.0+ (`REQ-INST-001`, `REQ-BUILD-001`, `REQ-PORT-001`, `REQ-COMP-001`)?

## Драйверы решения

* **Размер APK и память устройства (`REQ-INST-001`, ISO 25010 Portability/Resources):** исключение лишних нативных библиотек OCR для устаревших 32-битных и x86-архитектур.
* **Воспроизводимость сборки без Android Studio (`REQ-BUILD-001`):** сборка и тестирование должны запускаться одной командой (`Build-Cheq.cmd` / `gradlew`) на JDK 17 и Android SDK.
* **Актуальная целевая платформа (`REQ-INST-001`, `REQ-PORT-001`):** все современные физические смартфоны на Android 8.0+ (API 26–36) поддерживают `arm64-v8a`; iOS/Web/Desktop вне объёма.
* **Учёт лицензий (`REQ-COMP-001`):** все встроенные модели, шрифты (Roboto OFL) и иконки (Lucide ISC) учтены в `THIRD_PARTY.md` и `assets/licenses/`.

## Рассмотренные варианты

* **Вариант 1: Единый ARM64 APK (`abiFilters 'arm64-v8a'`) + R8 (`minifyEnabled`, `shrinkResources`) + Gradle Wrapper / PowerShell CLI-скрипты**
* **Вариант 2: Универсальный Fat APK со всеми ABI (`armeabi-v7a`, `arm64-v8a`, `x86`, `x86_64`)**
* **Вариант 3: Android App Bundle (`.aab`) для Google Play Dynamic Delivery**

## Итог решения

Выбранный вариант: **«Единый ARM64 APK (`abiFilters 'arm64-v8a'`) + R8 (`minifyEnabled`, `shrinkResources`) + Gradle Wrapper / PowerShell CLI-скрипты»**, потому что прямая установка APK на физическое устройство (через `adb install` / `Build-Cheq.cmd -Install`) требует `.apk`, а фильтрация `arm64-v8a` совместно с R8 сокращает размер нативной части в ~3 раза при полном покрытии современных Android-смартфонов.

### Последствия

* Хорошо, потому что в APK попадают нативные `.so` Tesseract и ML Kit только для `arm64-v8a`, что радикально уменьшает размер артефакта и время установки.
* Хорошо, потому что `Build-Cheq.cmd` (`-Check`, `-Install`, `-Configuration Release`) автоматизирует выбор JDK 17, проверку тестов `:core` и `:app` и выпуск сжатой release-сборки с R8 без необходимости устанавливать Android Studio.
* Хорошо, потому что отсутствие камеры (`android:required="false"`) не блокирует установку и ручной режим работы (`REQ-INST-001`).
* Плохо, потому что собранный APK нельзя установить на устаревшие 32-битные устройства (`armeabi-v7a`) или x86-эмуляторы без временного снятия `abiFilters`.
* Нейтрально, потому что release-сборка без настроенного keystore формирует `Cheq-unsigned.apk`, требующий подписи владельца перед распространением.

### Подтверждение

1. Инспекция `app/build.gradle`: `minSdk 26`, `targetSdk 36`, `compileSdk 36`, `ndk { abiFilters 'arm64-v8a' }`, `minifyEnabled true`, `shrinkResources true`, `coreLibraryDesugaringEnabled true`.
2. Инспекция `scripts/build.ps1`, `scripts/setup.ps1`, `Build-Cheq.cmd` и `THIRD_PARTY.md`.

## Плюсы и минусы вариантов

### ARM64 APK + R8 + Gradle CLI

Фильтрация ABI до `arm64-v8a`, сжатие кода и ресурсов R8 в релизе.

* Хорошо, потому что оптимальный размер прямого APK для демонстрации и личного использования.
* Хорошо, потому что сборка полностью воспроизводима из CLI с JDK 17 (`REQ-BUILD-001`).
* Плохо, потому что не поддерживает 32-битные и x86-устройства/эмуляторы из коробки.

### Универсальный Fat APK (все ABI)

Включение нативных библиотек для всех 4 ABI.

* Хорошо, потому что запускается на любом эмуляторе и старом смартфоне.
* Плохо, потому что размер APK раздувается в ~3–4 раза за счёт дублирования Tesseract/Leptonica/ML Kit `.so` под неиспользуемые архитектуры.

### Android App Bundle (`.aab`)

Сборка в формате AAB с генерацией split-APK на стороне магазина.

* Хорошо, потому что является стандартом для публикации в Google Play.
* Плохо, потому что `.aab` нельзя напрямую установить на телефон без `bundletool` или Google Play, а публичный релиз в Google Play в текущий объём не входит (`REQ-DIST-001`).

## Дополнительная информация

* **Связанные требования SRS:** `REQ-INST-001`, `REQ-BUILD-001`, `REQ-DIST-001`, `REQ-PORT-001`, `REQ-COMP-001`.
* **Связанные системные требования:** `SYS-FUNC-013`, `SYS-NFR-009`, `SYS-NFR-010`.
* **Затронутые представления SDD:** [DV-11 Развёртывание](../sdd/sdd-cheq.md#dv-11), [DV-12 Ресурсы](../sdd/sdd-cheq.md#dv-12).
* **Связанные ADR:** [ADR-0003](0003-hybrid-on-device-ocr-mlkit-and-tesseract.md), [ADR-0004](0004-groq-cloud-parsing-route-worker-vs-direct-https.md).
* **Условия пересмотра:** при подготовке публикации в Google Play перейти на `.aab` и добавить `armeabi-v7a` при наличии целевой аудитории на 32-битных устройствах.
