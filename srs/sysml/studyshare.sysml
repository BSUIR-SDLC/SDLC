package StudyShareRequirements {
  doc /* Требования к веб-приложению StudyShare. Версия 0.2. */
  import ScalarValues::*;

  part def Student;
  part def Moderator;
  part def Administrator;
  part def MailServer;
  part def StudyShare {
    part accountModule;
    part materialModule;
    part searchModule;
    part discussionModule;
    part moderationModule;
    part profileModule;
  }

  requirement def FunctionalRequirement {
    attribute priority : String; // MoSCoW: Must | Should | Could
    subject system : StudyShare;
  }
  requirement def QualityRequirement {
    attribute metric : String;
    subject system : StudyShare;
  }

  requirement studyShareFunctional {
    doc /* Функциональные требования StudyShare. */
    requirement accessAndRoles {
      requirement <'REQ-FUNC-001'> req001 : FunctionalRequirement {
        doc /* Система должна позволять пользователю зарегистрироваться по e-mail и паролю и войти в систему. */
        attribute :>> priority = "Must";
      }
      requirement <'REQ-FUNC-002'> req002 : FunctionalRequirement {
        doc /* Система должна разграничивать права ролей: студент, модератор, администратор. */
        attribute :>> priority = "Must";
      }
    }
    requirement materialsAndCatalog {
      requirement <'REQ-FUNC-003'> req003 : FunctionalRequirement {
        doc /* Система должна позволять студенту загрузить файл с указанием названия, типа, предмета, преподавателя, семестра, тегов и описания. */
        attribute :>> priority = "Must";
      }
      requirement <'REQ-FUNC-004'> req004 : FunctionalRequirement {
        doc /* Система должна показывать каталог опубликованных материалов с тегами. */
        attribute :>> priority = "Must";
      }
      requirement <'REQ-FUNC-005'> req005 : FunctionalRequirement {
        doc /* Система должна фильтровать каталог по предмету, преподавателю и семестру (в любом сочетании). */
        attribute :>> priority = "Must";
      }
      requirement <'REQ-FUNC-006'> req006 : FunctionalRequirement {
        doc /* Система должна позволять скачать опубликованный материал и фиксировать каждое скачивание в истории пользователя. */
        attribute :>> priority = "Must";
      }
      requirement <'REQ-FUNC-007'> req007 : FunctionalRequirement {
        doc /* Система должна позволять администратору добавлять, изменять и удалять предметы, преподавателей и семестры. */
        attribute :>> priority = "Should";
      }
    }
    requirement ratingAndDiscussion {
      requirement <'REQ-FUNC-009'> req009 : FunctionalRequirement {
        doc /* Система должна позволять студенту поставить опубликованному материалу оценку от 1 до 5 (одну на материал, с возможностью изменить). */
        attribute :>> priority = "Should";
      }
      requirement <'REQ-FUNC-010'> req010 : FunctionalRequirement {
        doc /* Система должна вычислять рейтинг материала на основе средней оценки и числа скачиваний и позволять сортировать каталог по рейтингу. */
        attribute :>> priority = "Should";
      }
      requirement <'REQ-FUNC-011'> req011 : FunctionalRequirement {
        doc /* Система должна позволять оставлять комментарии и вопросы к материалу и отвечать на них. */
        attribute :>> priority = "Should";
      }
    }
    requirement searchAndProfile {
      requirement <'REQ-FUNC-012'> req012 : FunctionalRequirement {
        doc /* Система должна выполнять поиск материалов по названию, тегам и описанию. */
        attribute :>> priority = "Must";
      }
      requirement <'REQ-FUNC-013'> req013 : FunctionalRequirement {
        doc /* Система должна извлекать текст из загруженных документов и выполнять поиск по нему. */
        attribute :>> priority = "Should";
      }
      requirement <'REQ-FUNC-014'> req014 : FunctionalRequirement {
        doc /* Система должна показывать пользователю его загрузки (со статусами и причиной отклонения) и историю скачиваний. */
        attribute :>> priority = "Should";
      }
    }
    requirement moderation {
      requirement <'REQ-FUNC-008'> req008 : FunctionalRequirement {
        doc /* Система должна передавать загруженные материалы модератору, который публикует или отклоняет их с указанием причины; допустимые переходы статусов заданы таблицей переходов. */
        attribute :>> priority = "Must";
      }
      requirement <'REQ-FUNC-015'> req015 : FunctionalRequirement {
        doc /* Система должна позволять пожаловаться на материал или комментарий, а модератору – скрыть объект или отклонить жалобу. */
        attribute :>> priority = "Could";
      }
      requirement <'REQ-FUNC-016'> req016 : FunctionalRequirement {
        doc /* Система должна отправлять e-mail о результате модерации и об ответе на вопрос пользователя. */
        attribute :>> priority = "Could";
      }
    }
  }

  requirement studyShareQuality {
    doc /* Нефункциональные требования StudyShare. */
    requirement <'REQ-PERF-001'> reqPERF001 : QualityRequirement {
      doc /* Время отклика страниц. */
      attribute :>> metric = "Не более 1,5 с для 95 % запросов";
    }
    requirement <'REQ-PERF-002'> reqPERF002 : QualityRequirement {
      doc /* Поиск по содержимому. */
      attribute :>> metric = "Не более 3 с для 95 % запросов при базе до 10 000 документов";
    }
    requirement <'REQ-PERF-003'> reqPERF003 : QualityRequirement {
      doc /* Загрузка файла до 20 МБ. */
      attribute :>> metric = "Не более 30 с при канале 10 Мбит/с";
    }
    requirement <'REQ-SEC-001'> reqSEC001 : QualityRequirement {
      doc /* Хранение паролей. */
      attribute :>> metric = "bcrypt, стоимость не менее 10";
    }
    requirement <'REQ-SEC-002'> reqSEC002 : QualityRequirement {
      doc /* Проверка загружаемых файлов. */
      attribute :>> metric = "Только PDF, DOCX, PPTX, TXT, PNG, JPG; не более 20 МБ; тип проверяется по содержимому";
    }
    requirement <'REQ-SEC-003'> reqSEC003 : QualityRequirement {
      doc /* Защита веб-приложения. */
      attribute :>> metric = "Защита от CSRF, XSS и SQL-инъекций";
    }
    requirement <'REQ-SEC-004'> reqSEC004 : QualityRequirement {
      doc /* Сеансы и блокировка входа. */
      attribute :>> metric = "Сеанс 30 минут; блокировка на 15 минут после пяти неудачных попыток";
    }
    requirement <'REQ-REL-001'> reqREL001 : QualityRequirement {
      doc /* Резервные копии базы и файлов. */
      attribute :>> metric = "Ежедневно, хранятся семь последних";
    }
    requirement <'REQ-AVAIL-001'> reqAVAIL001 : QualityRequirement {
      doc /* Доступность сервиса. */
      attribute :>> metric = "Не менее 99 % за месяц";
    }
    requirement <'REQ-COMP-001'> reqCOMP001 : QualityRequirement {
      doc /* Персональные данные. */
      attribute :>> metric = "Хранится минимум данных; удаление аккаунта по запросу";
    }
    requirement <'REQ-COMP-002'> reqCOMP002 : QualityRequirement {
      doc /* Авторские права. */
      attribute :>> metric = "Подтверждение права на публикацию при загрузке; удаление по обоснованному обращению правообладателя";
    }
    requirement <'REQ-INT-001'> reqINT001 : QualityRequirement {
      doc /* Веб-интерфейс. */
      attribute :>> metric = "На русском языке, адаптивный (от 360 px)";
    }
    requirement <'REQ-INT-002'> reqINT002 : QualityRequirement {
      doc /* Хранение данных. */
      attribute :>> metric = "PostgreSQL";
    }
    requirement <'REQ-INT-003'> reqINT003 : QualityRequirement {
      doc /* Отправка почты. */
      attribute :>> metric = "По протоколу SMTP";
    }
    requirement <'REQ-MAINT-001'> reqMAINT001 : QualityRequirement {
      doc /* Покрытие тестами сервисного слоя. */
      attribute :>> metric = "Не менее 70 %";
    }
    requirement <'REQ-COST-001'> reqCOST001 : QualityRequirement {
      doc /* Стоимость хостинга. */
      attribute :>> metric = "Не более 10 USD в месяц";
    }
  }

  // ---------- Связи «удовлетворяет» (satisfy) ----------
  part studyShare : StudyShare {
    satisfy requirement <'REQ-FUNC-003'> by materialModule;
    satisfy requirement <'REQ-FUNC-008'> by moderationModule;
    satisfy requirement <'REQ-FUNC-012'> by searchModule;
    satisfy requirement <'REQ-FUNC-011'> by discussionModule;
    satisfy requirement <'REQ-FUNC-014'> by profileModule;
    satisfy requirement <'REQ-FUNC-001'> by accountModule;
  }
}
