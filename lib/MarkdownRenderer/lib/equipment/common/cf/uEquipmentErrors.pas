unit uEquipmentErrors;

interface

uses System.Sysutils
{$IFDEF MultiLang}
  ,LangTranslator
{$ENDIF}
;

type
  EquException = class(Exception)
  public
    Code: Integer;
    constructor Create(ACode: Integer; const AMessage: string);
  end;

const
  /// ///////////////////////////////////////////////////
  // Коды ошибок
  ERR__UnDef = 500; // < первая специфическая ошибка для каждого типа устройств
  // < (относительно начала диапазона)
  // Общие ошибки
  // Ошибки инициализации менеджера
  // ERR_                =   1;   //< Менеджер не инициализирован
  // ERR_                =   2;   //< Ошибка установки нового значения свойства менеджера
  // ERR_                =   3;   //< Попытка изменить значение свойства "только для чтения"
  // ERR_                =   4;   //< Попытка изменить значение свойства, которые можно устанавливать только до инициализации менеджера
  // ERR_                =   5;   //< Ошибка при получении значения свойства менеджера
  // ERR_                =   6;   //< Ошибка получения значения неизвестного или неустановленного свойства менеджера
  // ERR_                =   7;   //< Внутренняя ошибка при инициализации менеджера
  // ERR_                =   8;   //< Ошибка при попытке создания каталога экземпляров, возможно у пользователя нет прав на запись в вышестоящий каталог
  // ERR_                =   9;   //< Предопределенное  имя каталога экземпляров занято файлом - нельзя создать каталог
  // ERR_                =  10;   //< Нет прав на создание/запись файлов в каталоге экземпляров
  // ERR_                =  11;   //< Ошибка при попытке определить каталог программных файлов операционной системы
  // ERR_                =  12;   //< Не задан каталог установки системы управления внешним оборудованием.
  // ERR_                =  13;   //< Не обнаружены файлы системы управления внешним оборудованием
  // ERR_                =  14;   //< Не указан каталог экземпляров оборудования
  // ERR_                =  15;   //< Не найдено ни одного описания модели
  // ERR_                =  17;   //< Не найдено запрошенного описания модели
  // ERR_                =  18;   //< Ошибка при разборе основного файла хранилища настроек Models.xml
  // ERR_                =  19;   //< Отсутствуют данные о каталоге устройств в файле Models.xml
  // Ошибки чтения данных моделей
  // ERR_                =  20;   //< Ошибка при разборе файла описания моделей
  // ERR_                =  21;   //< Ошибка в структуре файла Models.xml не найдены требуемые атрибуты заголовка
  // ERR_                =  23;   //< Ошибка получения атрибутов модели при разборе Models.xml
  // ERR_                =  24;   //< Не найдено описание модели с заданным идентификатором
  // ERR_                =  25;   //< Обнаружена несовместимость версий установленного драйвера и используемого менеджера управления
  // ERR_                =  26;   //< Нет установленных моделей в системе
  // ERR_                =  27;   //< В системе не обнаружено информации по запрошенному списку идентификаторов моделей оборудования
  // Ошибки чтения данных экземпляров
  // ERR_                =  31;   //< Не обнаружено информации об устройстве с заданным идентификатором
  // ERR_                =  32;   //< Не обнаружен файл с настройками устройства
  // ERR_                =  33;   //< Файл настроек не соответствует устройству
  // ERR_                =  34;   //< Некорректный формат файла настроек устройства Settings.xml не достаточно данных описания типа и/или модели устройства
  // ERR_                =  35;   //< Внутренняя ошибка исключения при разборе файла настроек устройства
  // ERR_                =  36;   //< Ошибочная структура файла настроек устройства.
  // ERR_                =  37;   //< Ошибка преобразования значения настройки
  // ERR_                =  38;   //< Ошибка преобразования значения настройки по умолчанию
  // ERR_                =  39;   //< В атрибутах настройки обнаружен неподдерживаемый тип значения
  // Ошибки при проверке входных параметров
  // ERR_                =  40;   //< Ошибка входных параметров
  // ERR_                =  41;   //< Идентификатор должен иметь строковый тип
  // ERR_                =  42;   //< Идентификатор не может быть пустой строкой
  // ERR_                =  43;   //< Переданный идентификатор имеет некорректную  длину
  // ERR_                =  44;   //< Переданный идентификатор содержит недопустимые символы
  // ERR_                =  45;   //< Команда должна иметь строковый тип
  // ERR_                =  46;   //< Команда не может быть пустой строкой
  // ERR_                =  47;   //< В переданной команде содержатся недопустимые символы или знаки
  // ERR_                =  48;   //< Ошибка формирования файла настроек устройства Settings.xml
  // Внутренние ошибки менеджера
  // ERR_                =  50;   //< Не удалось сохранить обновившиеся настройки устройства во внешнем хранилище настроек
  // ERR_                =  51;   //< Внутренняя ошибка менеджера при составлении списка устройств
  // ERR_                =  52;   //< В системе не определено ни одного устройства
  // Ошибки взаимодействия с драйверами
  // ERR_                =  56;   //< Неизвестная ошибка драйвера
  // ERR_                =  57;   //< Ошибка выполнения метода GetSettings
  // ERR_                =  58;   //< Ошибка формата возвращаемых данных метода GetSettings
  // ERR_                =  60;   //< Внутренняя ошибка менеджера
  // ERR_                =  63;   //< Ошибка создания объекта драйвера
  // ERR_                =  64;   //< Не поддерживаемый тип драйвера
  // ERR_                =  65;   //< Ошибка первоначальной инициализации объекта драйвера
  // ERR_                =  66;   //< Ошибка при вызове метода инициализации у объекта драйвера
  // ERR_                =  66;   //< Ошибка получения настроек устройства
  // ERR_                =  67;   //< Ошибки передачи настроек в драйвер
  // ERR_                =  68;   //< Ошибка вызова метода установки настроек у объекта драйвера
  // ERR_                =  69;   //< Внутренняя ошибка при вызове метода инициализации объекта драйвера
  // Ошибки исполнения команд оборудования
  ERR_DeviceDisabled = 70; // < Устройство не включено
  // ERR_                =  71;   //< Устройство занято
  // ERR_                =  72;   //< Устройство заблокировано
  // ERR_                =  73;   //< Команда была отменена
  ERR_TimeOut = 74; // < Истек таймаут ожидания
  // ERR_                =  76;   //< Неверный тип результата метода драйвера
  // ERR_                =  77;   //< Неверный тип возвращаемого параметра драйвера
  // ERR_                =  79;   //< Внутренняя ошибка менеджера
  // Ошибки сетевого режима работы
  // ERR_                =  80;   //< Сетевой режим работы недоступен
  // ERR_                =  81;   //< Ошибка создания объекта сетевого транспорта
  // ERR_                =  82;   //< Ошибка инициализации объекта сетевого транспорта
  // ERR_                =  85;   //< Внутренняя ошибка менеджера
  // ERR_                = 101;   //< Сетевой транспорт не инициализирован
  // ERR_                = 102;   //< Ошибка инициализации транспорта
  // ERR_                = 103;   //< Ошибка установки серверного режима
  // ERR_                = 104;   //< Ошибка выключения серверного режима
  // ERR_                = 105;   //< Ошибка установки соединения
  // ERR_                = 106;   //< Ошибка при использовании ранее установленного соединения
  // ERR_                = 107;   //< Разрыв соединения
  // ERR_                = 108;   //< Нельзя устанавливать соединение с самим собой
  // ERR_                = 109;   //< Ошибка разбора пакета данных
  // ERR_                = 110;   //< Истек таймаут ожидания
  // Ошибки совместного использования
  // ERR_                = 151;   //< Устройство захвачено для монопольного использования другим клиентом
  // ERR_                = 152;   //< Устройство используется другими клиентами
  // Ошибки мастера создания и настройки
  ERR_CancelOperation = 201; // < Операция была отменена пользователем
  // Общие ошибки драйверов
{$IF defined(ShopAdidas) or defined(shop2)}
  ERR_offset = 100;
  // Смещение ошибок из диапазона 1000-1100. Актуально для SHOP всех версий
{$ELSE}
  ERR_offset = 0;
  // Смещение ошибок из диапазона 1000-1100. Актуально для SHOP всех версий
{$IFEND}
  ERR_Unknown = 1001 + ERR_offset;
  ERR_FuncUnknown = 1002 + ERR_offset;
  ERR_FuncNotSupported = 1003 + ERR_offset;
  ERR_ParameterMismatch = 1004 + ERR_offset;
  ERR_DeviceNotInitialized = 1005 + ERR_offset;
  ERR_LibraryNotFound = 1006 + ERR_offset;
  ERR_DeviceNoResponse = 1007 + ERR_offset;
  ERR_DeviceNotReady = 1008 + ERR_offset;
  ERR_DeviceBusy = 1009 + ERR_offset;
  ERR_InvalidLibraryVersion = 1010 + ERR_offset;
  ERR_InvalidPort = 1011 + ERR_offset;
  ERR_PortBusy = 1012 + ERR_offset;
  ERR_DeviceNotFound = 1013 + ERR_offset;
  ERR_Protocol = 1014 + ERR_offset;
  ERR_InvalidCommand = 1015 + ERR_offset;
  ERR_WritingPort = 1016 + ERR_offset;
  ERR_ReadingPort = 1017 + ERR_offset;
  ERR_LibCallMethod = 1018 + ERR_offset;
  ERR_OnlySingleDevice = 1019 + ERR_offset;
  ERR_BadDeviceParameters = 1020 + ERR_offset;
  ERR_NotSupportedInThisMode = 1021 + ERR_offset;
  ERR_NotLicensedDriver = 1022 + ERR_offset;
  // Ошибки сканера
  ERR_SC__First = 2001;
  ERR_SC_BufferEmpty = 2001;
  ERR_SC__UnDef = ERR_SC__First + ERR__UnDef;
  // < начало специфических ошибок сканера
  // Ошибки ФР
  ERR_FR__First = 3001;
  ERR_FR_PaperEnd = 3001;
  ERR_FR_DayTooLong = 3002;   // смена истекла
  ERR_FR_JournalEnd = 3003;
  ERR_FR_NotSupportSlip = 3004;
  ERR_FR_DayClosed = 3005;
  ERR_FR_NotEnoughCash = 3006;
  ERR_FR_TemplateNotFound = 3007;
  ERR_FR_NeedCloseDay = 3008;
  ERR_FR_InsufficientAmount = 3009;
  ERR_FR_TaxValueOutOfRange = 3010;
  ERR_FR_UnknownReceiptFiscalState = 3011;
  ERR_FR_PaymentValueOutOfRange = 3012;
  ERR_FR_DepartmentValueOutOfRange = 3013;
  ERR_FR_CustomerAddressIsEmpty = 3014;
  ERR_FR_DayOpened = 3015;
  ERR_FR_NotSupported54FZ = 3016;
  ERR_FR_CashLack = 3017;
  ERR_FR_NOT_FISCAL = 3018;
  ERR_FR_FN_CLOSED = 3019;
  ERR_FR_SignCalculationObjectOutOfRange = 3020;
  ERR_FR_SignMethodCalculationOutOfRange = 3021;
  ERR_FR_PrintOutFilePath = 3022;
  ERR_FR_AgentTypeOutOfRange = 3023;
  ERR_FR_NULL_PRICE = 3024;
  ERR_FR_TaxValueCombined = 3025;
  ERR_FR_IncorrectVATIN = 3026;
  ERR_FR_PrintError = 3027;
  ERR_FR_PrintPrevDoc = 3028;
  ERR_FR_UncorrectCashierName = 3029;
  ERR_FR_CUSTOMER_PHONE_OR_EMAIL = 3030;

  ERR_FR__UnDef = ERR_FR__First + ERR__UnDef;
  // < начало специфических ошибок ФР
  // Ошибки ЭТ
  ERR_AT__First = 4001;
  ERR_AT_PinpadNoResponse = ERR_AT__First + 0;
  ERR_AT_HostNoResponse = ERR_AT__First + 1;
  ERR_AT_OperationNoApprove = ERR_AT__First + 2;
  ERR_AT_TransactionAlreadyExists = ERR_AT__First + 3;
  ERR_AT_UndefinedTransactionResult = ERR_AT__First + 4;
  ERR_AT_OverflowBalance = ERR_AT__First + 5;
  ERR_AT_TransactionNotFound = ERR_AT__First + 6;
  ERR_AT_NoReceiptText = ERR_AT__First + 7;
  ERR_AT__UnDef = ERR_AT__First + ERR__UnDef;
  // < начало специфических ошибок ЭТ
  // Ошибки дисплеев
  ERR_D__First = 5001;
  // ERR_D_... = 5001;
  ERR_D__UnDef = ERR_D__First + ERR__UnDef;
  // < начало специфических ошибок лисплеев
  // Ошибки ТСД
  ERR_DCT__First = 6001;
  ERR_DCT_EmptyData = ERR_DCT__First;
  ERR_DCT__UnDef = ERR_DCT__First + ERR__UnDef;
  // < начало специфических ошибок ТСД
  // Ошибки весов
  ERR_W__First = 7001;
  ERR_W_WeightNotStable = 7001;
  ERR_W__UnDef = ERR_W__First + ERR__UnDef;
  // < начало специфических ошибок весов
  // Ошибки ридера
  ERR_CR__First = 8001;
  ERR_CR_BufferEmpty = 8001;
  ERR_CR__UnDef = ERR_CR__First + ERR__UnDef;
  // Ошибки контроллеров доступа (AC)
  ERR_AC__First = 11001;
  ERR_AC_ControllersIsEmpty = 11001;
  ERR_AC__UnDef = ERR_AC__First + ERR__UnDef;
  // Ошибки биометрических считывателей
  ERR_BR__First = 12001;
  ERR_BR_FingerprintNotFound = ERR_BR__First + 0;
  ERR_BR__UnDef = ERR_BR__First + ERR__UnDef;
  // Ошибки принтеров этикеток
  ERR_LP__First = 13001;
  ERR_LP_InvalidTemplateNumber = ERR_LP__First + 0;
  ERR_LP__UnDef = ERR_LP__First + ERR__UnDef;
  // Ошибки электронных замков
  ERR_EL__First = 14001;
  ERR_EL_BadActivationDate = ERR_EL__First + 0;
  ERR_EL_BadExpirationDate = ERR_EL__First + 1;
  ERR_EL_GuestRoomNotFound = ERR_EL__First + 2;
  ERR_EL__UnDef = ERR_EL__First + ERR__UnDef;
  // Ошибки купюроприемников
  ERR_BV__First = 15001;
  ERR_BV_BillWaitingTimeout = ERR_BV__First + 0;
  ERR_BV__UnDef = ERR_BV__First + ERR__UnDef;
  // Ошибки кофемашин
  ERR_CM__First = 16001;
  ERR_CM_WrongItemCode = ERR_CM__First + 0;
  ERR_CM_StandbyMode = ERR_CM__First + 1;
  ERR_CM__UnDef = ERR_CM__First + ERR__UnDef;
  // Ошибки терминалов услуг
  ERR_ST__First = 17001;
  ERR_ST_ServiceNotFound = ERR_ST__First + 0;
  ERR_ST__UnDef = ERR_ST__First + ERR__UnDef;
  // Ошибки систем лояльности
  ERR_LS__First = 18001;
  ERR_LS_OrderNotFound = ERR_LS__First + 0;

  // Ошибки OPOS-устройств
  ERR_OPOS__First = 99001;
  ERR_OPOS_SUCCESS = ERR_OPOS__First + 0;
  ERR_OPOS_E_CLOSED = ERR_OPOS__First + 101;
  ERR_OPOS_E_CLAIMED = ERR_OPOS__First + 102;
  ERR_OPOS_E_NOTCLAIMED = ERR_OPOS__First + 103;
  ERR_OPOS_E_NOSERVICE = ERR_OPOS__First + 104;
  ERR_OPOS_E_DISABLED = ERR_OPOS__First + 105;
  ERR_OPOS_E_ILLEGAL = ERR_OPOS__First + 106;
  ERR_OPOS_E_NOHARDWARE = ERR_OPOS__First + 107;
  ERR_OPOS_E_OFFLINE = ERR_OPOS__First + 108;
  ERR_OPOS_E_NOEXIST = ERR_OPOS__First + 109;
  ERR_OPOS_E_EXISTS = ERR_OPOS__First + 110;
  ERR_OPOS_E_FAILURE = ERR_OPOS__First + 111;
  ERR_OPOS_E_TIMEOUT = ERR_OPOS__First + 112;
  ERR_OPOS_E_BUSY = ERR_OPOS__First + 113;
  ERR_OPOS_E_EXTENDED = ERR_OPOS__First + 114;
  ERR_OPOS__UnDef = ERR_OPOS__First + ERR__UnDef;

  // Ошибки прочих устройств
  ERR_UK__First = 100001;
  // ERR_UK_ ... = ERR_UK__First + 0;
  ERR_UK__UnDef = ERR_UK__First + ERR__UnDef;

resourcestring
  /// ///////////////////////////////////////////////////
  // Описания ошибок
  // Общие ошибки
  S_ERR_OK = 'Нет ошибок';
  S_ERR_DeviceDisabled = 'Устройство не включено';
  S_ERR_TimeOut = 'Истек таймаут ожидания';
  S_ERR_CancelOperation = 'Операция отменена пользователем';
  S_ERR_Unknown = 'Неизвестная ошибка';
  S_ERR_DeviceListEmpty = 'Устройство не найдено или не проинициализировано';
  S_ERR_FuncUnknown = 'Команда не распознана устройством';
  S_ERR_FuncNotSupported = 'Команда не поддерживается устройством';
  S_ERR_ParameterMismatch = 'Ошибка входных параметров команды';
  S_ERR_DeviceNotReady = 'Оборудование не готово';
  S_ERR_LibraryNotFound = 'Библиотека не найдена';
  S_ERR_DeviceNoResponse = 'Устройство не отвечает';
  S_ERR_DeviceBusy = 'Устройство занято';
  S_ERR_InvalidLibraryVersion = 'Неверная версия библиотеки';
  S_ERR_InvalidPort = 'Порт недоступен';
  S_ERR_PortBusy = 'Порт занят другим приложением';
  S_ERR_DeviceNotFound = 'Устройство не найдено';
  S_ERR_Protocol = 'Ошибка протокола обмена';
  S_ERR_InvalidCommand = 'Неверная последовательность команд';
  S_ERR_WritingPort = 'Ошибка при записи данных в порт';
  S_ERR_ReadingPort = 'Ошибка при чтении данных из порта';
  S_ERR_LibCallMethod = 'Ошибка при вызове метода библиотеки';
  S_ERR_OnlySingleDevice = 'Использование более одного экземпляра устройства одновременно невозможно';
  S_ERR_BadDeviceParameters = 'Неверные параметры устройства';
  S_ERR_NotLicensedDriver = 'Нет лицензии на использвание драйвера';
  // Ошибки сканера
  S_ERR_SC_BufferEmpty = 'Буфер данных пуст';
  // Ошибки ФР
  S_ERR_FR_PaperEnd = 'Нет бумаги';
  S_ERR_FR_DayTooLong =
    'Длительность смены превысила 24 часа. Необходимо снять Z-отчет';
  S_ERR_FR_JournalEnd = 'Нет контрольной ленты';
  S_ERR_FR_NotSupportSlip = 'Отсутствует подкладной документ';
  S_ERR_FR_DayClosed = 'Смена закрыта';
  S_ERR_FR_DayOpened = 'Смена открыта';
  S_ERR_FR_NotEnoughCash = 'Недостаточно наличных в кассе';
  S_ERR_FR_TemplateNotFound = 'Шаблон не найден';
  S_ERR_FR_NeedCloseDay = 'Для выполнения операции требуется закрыть смену';
  S_ERR_FR_InsufficientAmount = 'Сумма оплаты не соответствует сумме документа';
  S_ERR_FR_TaxValueOutOfRange = 'Налоговая группа вне допустимого диапазона';
  S_ERR_FR_UnknownReceiptFiscalState =
    'Не удалось определить результат пробития чека';
  S_ERR_FR_PaymentValueOutOfRange = 'Номер оплаты вне допустимого диапазона';
  S_ERR_FR_DepartmentValueOutOfRange = 'Номер отдела вне допустимого диапазона';
  S_ERR_FR_CustomerAddressIsEmpty = 'Не введен адрес покупателя';
  S_ERR_FR_NotSupported54FZ = 'Устройство не поддерживает 54-ФЗ';
  S_ERR_FR_CashLack = 'Недостаточно наличности в кассе';
  S_ERR_FR_NOT_FISCAL = 'ФР не фискализирован';
  S_ERR_FR_FN_CLOSED = 'ФН закрыт';
  S_ERR_FR_SignCalculationObjectOutOfRange = 'Значение признака предмета расчёта вне допустимого диапазона';
  S_ERR_FR_SignMethodCalculationOfRange = 'Значение признака способа расчёта вне допустимого диапазона';
  S_ERR_FR_PrintOutFilePath = 'Некорректный путь файла вывода чека';
  S_ERR_FR_AgentTypeOutOfRange = 'Значение признака агента по предмету расчёта вне допустимого диапазона';
  S_ERR_FR_NULL_PRICE = 'Нулевая цена не допустима для данной модели оборудования';
  S_ERR_FR_TaxValueCombined = 'Недопустимо сочетание налогов 20% и 18% в одном документе';
  S_ERR_FR_IncorrectVATIN = 'Некорректный ИНН';
  S_ERR_FR_PrintError = 'Ошибка печати чека (документа)';
  S_ERR_FR_PrintPrevDoc = 'Завершена печать предыдущего чека (документа)';
  S_ERR_FR_UncorrectCashierName = 'Не указано имя кассира';
  S_ERR_FR_CUSTOMER_PHONE_OR_EMAIL = 'Некорректный телефон или email покупателя';
  // Ошибки ЭТ
  S_ERR_AT_PinpadNoResponse = 'Нет связи с pinpad';
  S_ERR_AT_HostNoResponse = 'Нет связи с хостом';
  S_ERR_AT_OperationNoApprove = 'Операция не была одобрена';
  S_ERR_AT_TransactionAlreadyExists =
    'Транзакция с указанным номером уже существует';
  S_ERR_AT_UndefinedTransactionResult =
    'Статус выполнения транзакции не определен';
  S_ERR_AT_OverflowBalance = 'Не хватает средств для проведения транзакции';
  S_ERR_AT_TransactionNotFound = 'Транзакция не найдена';
  S_ERR_AT_NoReceiptText = 'Pinpad не вернул текст чека';
  // Ошибки ТСД
  S_ERR_DCT_EmptyData = 'Запрошенные данные отсутствуют';
  // Ошибки весов
  S_ERR_W_WeightNotStable = 'Вес не стабилен';
  // Ошибки ридера
  S_ERR_CR_BufferEmpty = 'Буфер данных пуст';
  // Ошибки контроллеров доступа (AC)
  S_ERR_AC_ControllersIsEmpty = 'Список контроллеров пуст';
  // Ошибки принтеров этикеток
  S_ERR_LP_InvalidTemplateNumber =
    'Шаблон с таким номером не был загружен в принтер';
  // Ошибки биометрических считывателей
  S_ERR_BR_FingerprintNotFound = 'Отпечаток не найден в базе';
  // Ошибки электронных замков
  S_ERR_EL_BadActivationDate = 'Дата заезда должна быть больше текущей даты';
  S_ERR_EL_BadExpirationDate = 'Дата выезда должна быть больше даты заезда';
  S_ERR_EL_GuestRoomNotFound = 'Пользователь или комната не найдены';
  // Ошибки купюроприемников
  S_ERR_BV_BillWaitingTimeout = 'Превышено время ожидания купюры';
  // Ошибки кофемашин
  S_ERR_CM_WrongItemCode = 'Неверный код позиции в чеке';
  S_ERR_CM_StandbyMode =
    'Кофемашина в сосотояни ожидания запроса на приготовление продукта';
  // Ошибки терминалов услуг
  S_ERR_ST_ServiceNotFound = 'Услуга не найдена';
  // Ошибки систем лояльности
  S_ERR_LS_OrderNotFound = 'Заказ не найден';
  // Ошибки OPOS-устройств
  S_ERR_OPOS_SUCCESS = 'Ошибок нет';
  S_ERR_OPOS_E_CLOSED = 'Не подключен Управляющий Объект';
  S_ERR_OPOS_E_CLAIMED = 'Устройство захвачено другим процессом';
  S_ERR_OPOS_E_NOTCLAIMED = 'Устройство не захвачено';
  S_ERR_OPOS_E_NOSERVICE = 'Не удалось обратиться к Управляющему Объекту';
  S_ERR_OPOS_E_DISABLED = 'Устройство не подключено на порту';
  S_ERR_OPOS_E_ILLEGAL =
    'Ошибка команды, либо команда не поддерживается данным устройством, либо переданны некорректные данные';
  S_ERR_OPOS_E_NOHARDWARE =
    'Питание устройства не включено, либо устройство не подключено к порту';
  S_ERR_OPOS_E_OFFLINE = 'Устройство выключено';
  S_ERR_OPOS_E_NOEXIST = 'Имя файла или указанное значение не существует';
  S_ERR_OPOS_E_EXISTS = 'Имя файла или указанное значение уже существует';
  S_ERR_OPOS_E_FAILURE = 'Устройство не может выполнить указанную команду';
  S_ERR_OPOS_E_TIMEOUT = 'Истекло время ожидания ответа от устройства';
  S_ERR_OPOS_E_BUSY =
    'Текущее состояние Исполняющего Объекта не позволяет обработать запрос';
  S_ERR_OPOS_E_EXTENDED =
    'Специфичная для данного класса устройств ошибка. Расширенная информация в дополнительном описании ошибки';

  // Тестовые сообщения общие
  S_MSG_TestOK = 'Тест пройден успешно';
  S_MSG_TraningMode = 'Тренировочный режим';

  /// ///////////////////////////////////////////////////
  // Описания исключений
  EXEPT_MethodNotSupported = 'Метод не поддерживается';
  EXEPT_EqManagerNotFound = 'Менеджер оборудования недоступен';
  EXEPT_MethodError = 'Ошибка при выполнении метода';

function GetResultDescription(ResultCode: Integer;
  const ResultDescription : WideString = '';
  const DefaultDescription: WideString = ''): WideString;
procedure CorrectUPOSResultCode(var ResultCode: Integer);

implementation

constructor EquException.Create(ACode: Integer; const AMessage: string);
begin
  Inherited Create(AMessage);
  Code := ACode;
end;

procedure CorrectUPOSResultCode(var ResultCode: Integer);
begin
  if ResultCode <> 0 then
    ResultCode := ResultCode + ERR_OPOS__First;
end;

function GetResultDescription(ResultCode: Integer;
  const ResultDescription, DefaultDescription: WideString): WideString;
begin
  if (ResultDescription <> '') and (ResultCode <> 0) then
  begin
    Result := ResultDescription;
    Exit;
  end;

  case ResultCode of
    S_OK:
      Result := S_ERR_OK;
    ERR_TimeOut:
      Result := S_ERR_TimeOut;
    ERR_DeviceDisabled:
      Result := S_ERR_DeviceDisabled;
    ERR_CancelOperation:
      Result := S_ERR_CancelOperation;
    ERR_Unknown:
      Result := S_ERR_Unknown;
    ERR_FuncUnknown:
      Result := S_ERR_FuncUnknown;
    ERR_FuncNotSupported:
      Result := S_ERR_FuncNotSupported;
    ERR_ParameterMismatch:
      Result := S_ERR_ParameterMismatch;
    ERR_DeviceNotInitialized:
      Result := S_ERR_DeviceListEmpty;
    ERR_LibraryNotFound:
      Result := S_ERR_LibraryNotFound;
    ERR_DeviceNoResponse:
      Result := S_ERR_DeviceNoResponse;
    ERR_DeviceNotReady:
      Result := S_ERR_DeviceNotReady;
    ERR_InvalidLibraryVersion:
      Result := S_ERR_InvalidLibraryVersion;
    ERR_DeviceBusy:
      Result := S_ERR_DeviceBusy;
    ERR_InvalidPort:
      Result := S_ERR_InvalidPort;
    ERR_PortBusy:
      Result := S_ERR_PortBusy;
    ERR_DeviceNotFound:
      Result := S_ERR_DeviceNotFound;
    ERR_Protocol:
      Result := S_ERR_Protocol;
    ERR_InvalidCommand:
      Result := S_ERR_InvalidCommand;
    ERR_WritingPort:
      Result := S_ERR_WritingPort;
    ERR_ReadingPort:
      Result := S_ERR_ReadingPort;
    ERR_LibCallMethod:
      Result := S_ERR_LibCallMethod;
    ERR_OnlySingleDevice:
      Result := S_ERR_OnlySingleDevice;
    ERR_BadDeviceParameters:
      Result := S_ERR_BadDeviceParameters;
    ERR_NotLicensedDriver:
      Result := S_ERR_NotLicensedDriver;
    // Ошибки сканера
    ERR_SC_BufferEmpty:
      Result := S_ERR_SC_BufferEmpty;
    // Ошибки ФР
    ERR_FR_PaperEnd:
      Result := S_ERR_FR_PaperEnd;
    ERR_FR_DayTooLong:
      Result := S_ERR_FR_DayTooLong;
    ERR_FR_JournalEnd:
      Result := S_ERR_FR_JournalEnd;
    ERR_FR_NotSupportSlip:
      Result := S_ERR_FR_NotSupportSlip;
    ERR_FR_DayClosed:
      Result := S_ERR_FR_DayClosed;
    ERR_FR_DayOpened:
      Result := S_ERR_FR_DayOpened;
    ERR_FR_NotEnoughCash:
      Result := S_ERR_FR_NotEnoughCash;
    ERR_FR_TemplateNotFound:
      Result := S_ERR_FR_TemplateNotFound;
    ERR_FR_NeedCloseDay:
      Result := S_ERR_FR_NeedCloseDay;
    ERR_FR_InsufficientAmount:
      Result := S_ERR_FR_InsufficientAmount;
    ERR_FR_TaxValueOutOfRange:
      Result := S_ERR_FR_TaxValueOutOfRange;
    ERR_FR_PaymentValueOutOfRange:
      Result := S_ERR_FR_PaymentValueOutOfRange;
    ERR_FR_UnknownReceiptFiscalState:
      Result := S_ERR_FR_UnknownReceiptFiscalState;
    ERR_FR_DepartmentValueOutOfRange:
      Result := S_ERR_FR_DepartmentValueOutOfRange;
    ERR_FR_CustomerAddressIsEmpty:
      Result := S_ERR_FR_CustomerAddressIsEmpty;
    ERR_FR_CashLack:
      Result := S_ERR_FR_CashLack;
    ERR_FR_NOT_FISCAL:
      Result := S_ERR_FR_NOT_FISCAL;
    ERR_FR_FN_CLOSED:
      Result := S_ERR_FR_FN_CLOSED;
    ERR_FR_SignCalculationObjectOutOfRange:
      Result := S_ERR_FR_SignCalculationObjectOutOfRange;
    ERR_FR_SignMethodCalculationOutOfRange:
      Result := S_ERR_FR_SignMethodCalculationOfRange;
    ERR_FR_PrintOutFilePath:
      Result := S_ERR_FR_PrintOutFilePath;
    ERR_FR_AgentTypeOutOfRange:
      Result := S_ERR_FR_AgentTypeOutOfRange;
    ERR_FR_NULL_PRICE:
      Result := S_ERR_FR_NULL_PRICE;
    ERR_FR_TaxValueCombined:
      Result := S_ERR_FR_TaxValueCombined;
    ERR_FR_IncorrectVATIN:
      Result := S_ERR_FR_IncorrectVATIN;
    ERR_FR_UncorrectCashierName:
      Result := S_ERR_FR_UncorrectCashierName;
    ERR_FR_PrintError:
      Result := S_ERR_FR_PrintError;
    ERR_FR_PrintPrevDoc:
      Result := S_ERR_FR_PrintPrevDoc;
    ERR_FR_CUSTOMER_PHONE_OR_EMAIL:
      Result := S_ERR_FR_CUSTOMER_PHONE_OR_EMAIL;
    // Ошибки ЭТ
    ERR_AT_PinpadNoResponse:
      Result := S_ERR_AT_PinpadNoResponse;
    ERR_AT_HostNoResponse:
      Result := S_ERR_AT_HostNoResponse;
    ERR_AT_OperationNoApprove:
      Result := S_ERR_AT_OperationNoApprove;
    ERR_AT_TransactionAlreadyExists:
      Result := S_ERR_AT_TransactionAlreadyExists;
    ERR_AT_UndefinedTransactionResult:
      Result := S_ERR_AT_UndefinedTransactionResult;
    ERR_AT_OverflowBalance:
      Result := S_ERR_AT_OverflowBalance;
    ERR_AT_TransactionNotFound:
      Result := S_ERR_AT_TransactionNotFound;
    ERR_AT_NoReceiptText:
      Result := S_ERR_AT_NoReceiptText;
    // Ошибки ТСД
    ERR_DCT_EmptyData:
      Result := S_ERR_DCT_EmptyData;
    // Ошибки весов
    ERR_W_WeightNotStable:
      Result := S_ERR_W_WeightNotStable;
    // Ошибки ридера
    ERR_CR_BufferEmpty:
      Result := S_ERR_CR_BufferEmpty;
    // Ошибки контроллеров доступа (AC)
    ERR_AC_ControllersIsEmpty:
      Result := S_ERR_AC_ControllersIsEmpty;
    // Ошибки принтеров этикеток
    ERR_LP_InvalidTemplateNumber:
      Result := S_ERR_LP_InvalidTemplateNumber;
    // Ошибки биометрических считывателей
    ERR_BR_FingerprintNotFound:
      Result := S_ERR_BR_FingerprintNotFound;
    // Ошибки электронных замков
    ERR_EL_BadActivationDate:
      Result := S_ERR_EL_BadActivationDate;
    ERR_EL_BadExpirationDate:
      Result := S_ERR_EL_BadExpirationDate;
    ERR_EL_GuestRoomNotFound:
      Result := S_ERR_EL_GuestRoomNotFound;
    // Ошибки купюроприемников
    ERR_BV_BillWaitingTimeout:
      Result := S_ERR_BV_BillWaitingTimeout;
    // Ошибки кофемашин
    ERR_CM_WrongItemCode:
      Result := S_ERR_CM_WrongItemCode;
    ERR_CM_StandbyMode:
      Result := S_ERR_CM_StandbyMode;
    // Ошибки терминалов услуг
    ERR_ST_ServiceNotFound:
      Result := S_ERR_ST_ServiceNotFound;
    // Ошибки систем лояльности
    ERR_LS_OrderNotFound:
      Result := S_ERR_LS_OrderNotFound;
    // Ошибки OPOS-устройств
    ERR_OPOS_SUCCESS:
      Result := S_ERR_OPOS_SUCCESS;
    ERR_OPOS_E_CLOSED:
      Result := S_ERR_OPOS_E_CLOSED;
    ERR_OPOS_E_CLAIMED:
      Result := S_ERR_OPOS_E_CLAIMED;
    ERR_OPOS_E_NOTCLAIMED:
      Result := S_ERR_OPOS_E_NOTCLAIMED;
    ERR_OPOS_E_NOSERVICE:
      Result := S_ERR_OPOS_E_NOSERVICE;
    ERR_OPOS_E_DISABLED:
      Result := S_ERR_OPOS_E_DISABLED;
    ERR_OPOS_E_ILLEGAL:
      Result := S_ERR_OPOS_E_ILLEGAL;
    ERR_OPOS_E_NOHARDWARE:
      Result := S_ERR_OPOS_E_NOHARDWARE;
    ERR_OPOS_E_OFFLINE:
      Result := S_ERR_OPOS_E_OFFLINE;
    ERR_OPOS_E_NOEXIST:
      Result := S_ERR_OPOS_E_NOEXIST;
    ERR_OPOS_E_EXISTS:
      Result := S_ERR_OPOS_E_EXISTS;
    ERR_OPOS_E_FAILURE:
      Result := S_ERR_OPOS_E_FAILURE;
    ERR_OPOS_E_TIMEOUT:
      Result := S_ERR_OPOS_E_TIMEOUT;
    ERR_OPOS_E_BUSY:
      Result := S_ERR_OPOS_E_BUSY;
    ERR_OPOS_E_EXTENDED:
      Result := S_ERR_OPOS_E_EXTENDED;
  else
    if ( DefaultDescription = '' ) then Result := S_ERR_Unknown
                                   else Result := DefaultDescription;
  end;
end;

initialization

{$IFDEF MultiLang}
RegTransResString(@S_ERR_OK, 'S_ERR_OK');
RegTransResString(@S_ERR_DeviceDisabled, 'S_ERR_DeviceDisabled');
RegTransResString(@S_ERR_TimeOut, 'S_ERR_TimeOut');
RegTransResString(@S_ERR_CancelOperation, 'S_ERR_CancelOperation');
RegTransResString(@S_ERR_Unknown, 'S_ERR_Unknown');
RegTransResString(@S_ERR_DeviceListEmpty, 'S_ERR_DeviceListEmpty');
RegTransResString(@S_ERR_FuncUnknown, 'S_ERR_FuncUnknown');
RegTransResString(@S_ERR_FuncNotSupported, 'S_ERR_FuncNotSupported');
RegTransResString(@S_ERR_ParameterMismatch, 'S_ERR_ParameterMismatch');
RegTransResString(@S_ERR_DeviceNotReady, 'S_ERR_DeviceNotReady');
RegTransResString(@S_ERR_LibraryNotFound, 'S_ERR_LibraryNotFound');
RegTransResString(@S_ERR_DeviceNoResponse, 'S_ERR_DeviceNoResponse');
RegTransResString(@S_ERR_DeviceBusy, 'S_ERR_DeviceBusy');
RegTransResString(@S_ERR_InvalidLibraryVersion, 'S_ERR_InvalidLibraryVersion');
RegTransResString(@S_ERR_InvalidPort, 'S_ERR_InvalidPort');
RegTransResString(@S_ERR_PortBusy, 'S_ERR_PortBusy');
RegTransResString(@S_ERR_DeviceNotFound, 'S_ERR_DeviceNotFound');
RegTransResString(@S_ERR_Protocol, 'S_ERR_Protocol');
RegTransResString(@S_ERR_SC_BufferEmpty, 'S_ERR_SC_BufferEmpty');
RegTransResString(@S_ERR_FR_PaperEnd, 'S_ERR_FR_PaperEnd');
RegTransResString(@S_ERR_FR_DayTooLong, 'S_ERR_FR_DayTooLong');
RegTransResString(@S_ERR_FR_JournalEnd, 'S_ERR_FR_JournalEnd');
RegTransResString(@S_ERR_FR_NotSupportSlip, 'S_ERR_FR_NotSupportSlip');
RegTransResString(@S_ERR_FR_DayClosed, 'S_ERR_FR_DayClosed');
RegTransResString(@S_ERR_FR_NotEnoughCash, 'S_ERR_FR_NotEnoughCash');
RegTransResString(@S_ERR_FR_TemplateNotFound, 'S_ERR_FR_TemplateNotFound');
RegTransResString(@S_ERR_FR_NeedCloseDay, 'S_ERR_FR_NeedCloseDay');
RegTransResString(@S_ERR_FR_InsufficientAmount, 'S_ERR_FR_InsufficientAmount');
RegTransResString(@S_ERR_FR_TaxValueOutOfRange, 'S_ERR_FR_TaxValueOutOfRange');
RegTransResString(@S_ERR_FR_UnknownReceiptFiscalState,
  'S_ERR_FR_UnknownReceiptFiscalState');
RegTransResString(@S_ERR_FR_PaymentValueOutOfRange,
  'S_ERR_FR_PaymentValueOutOfRange');
RegTransResString(@S_ERR_AT_PinpadNoResponse, 'S_ERR_AT_PinpadNoResponse');
RegTransResString(@S_ERR_AT_HostNoResponse, 'S_ERR_AT_HostNoResponse');
RegTransResString(@S_ERR_AT_OperationNoApprove, 'S_ERR_AT_OperationNoApprove');
RegTransResString(@S_ERR_AT_TransactionAlreadyExists,
  'S_ERR_AT_TransactionAlreadyExists');
RegTransResString(@S_ERR_AT_UndefinedTransactionResult,
  'S_ERR_AT_UndefinedTransactionResult');
RegTransResString(@S_ERR_AT_OverflowBalance, 'S_ERR_AT_OverflowBalance');
RegTransResString(@S_ERR_AT_TransactionNotFound,
  'S_ERR_AT_TransactionNotFound');
RegTransResString(@S_ERR_W_WeightNotStable, 'S_ERR_W_WeightNotStable');
RegTransResString(@S_ERR_CR_BufferEmpty, 'S_ERR_CR_BufferEmpty');
RegTransResString(@S_ERR_AC_ControllersIsEmpty, 'S_ERR_AC_ControllersIsEmpty');
RegTransResString(@S_MSG_TestOK, 'S_MSG_TestOK');
RegTransResString(@S_MSG_TraningMode, 'S_MSG_TraningMode');
RegTransResString(@EXEPT_MethodNotSupported, 'EXEPT_MethodNotSupported');
RegTransResString(@EXEPT_EqManagerNotFound, 'EXEPT_EqManagerNotFound');
RegTransResString(@EXEPT_MethodError, 'EXEPT_MethodError');
{$ENDIF}

end.
