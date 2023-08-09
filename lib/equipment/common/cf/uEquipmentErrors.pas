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
  // ���� ������
  ERR__UnDef = 500; // < ������ ������������� ������ ��� ������� ���� ���������
  // < (������������ ������ ���������)
  // ����� ������
  // ������ ������������� ���������
  // ERR_                =   1;   //< �������� �� ���������������
  // ERR_                =   2;   //< ������ ��������� ������ �������� �������� ���������
  // ERR_                =   3;   //< ������� �������� �������� �������� "������ ��� ������"
  // ERR_                =   4;   //< ������� �������� �������� ��������, ������� ����� ������������� ������ �� ������������� ���������
  // ERR_                =   5;   //< ������ ��� ��������� �������� �������� ���������
  // ERR_                =   6;   //< ������ ��������� �������� ������������ ��� ���������������� �������� ���������
  // ERR_                =   7;   //< ���������� ������ ��� ������������� ���������
  // ERR_                =   8;   //< ������ ��� ������� �������� �������� �����������, �������� � ������������ ��� ���� �� ������ � ����������� �������
  // ERR_                =   9;   //< ����������������  ��� �������� ����������� ������ ������ - ������ ������� �������
  // ERR_                =  10;   //< ��� ���� �� ��������/������ ������ � �������� �����������
  // ERR_                =  11;   //< ������ ��� ������� ���������� ������� ����������� ������ ������������ �������
  // ERR_                =  12;   //< �� ����� ������� ��������� ������� ���������� ������� �������������.
  // ERR_                =  13;   //< �� ���������� ����� ������� ���������� ������� �������������
  // ERR_                =  14;   //< �� ������ ������� ����������� ������������
  // ERR_                =  15;   //< �� ������� �� ������ �������� ������
  // ERR_                =  17;   //< �� ������� ������������ �������� ������
  // ERR_                =  18;   //< ������ ��� ������� ��������� ����� ��������� �������� Models.xml
  // ERR_                =  19;   //< ����������� ������ � �������� ��������� � ����� Models.xml
  // ������ ������ ������ �������
  // ERR_                =  20;   //< ������ ��� ������� ����� �������� �������
  // ERR_                =  21;   //< ������ � ��������� ����� Models.xml �� ������� ��������� �������� ���������
  // ERR_                =  23;   //< ������ ��������� ��������� ������ ��� ������� Models.xml
  // ERR_                =  24;   //< �� ������� �������� ������ � �������� ���������������
  // ERR_                =  25;   //< ���������� ��������������� ������ �������������� �������� � ������������� ��������� ����������
  // ERR_                =  26;   //< ��� ������������� ������� � �������
  // ERR_                =  27;   //< � ������� �� ���������� ���������� �� ������������ ������ ��������������� ������� ������������
  // ������ ������ ������ �����������
  // ERR_                =  31;   //< �� ���������� ���������� �� ���������� � �������� ���������������
  // ERR_                =  32;   //< �� ��������� ���� � ����������� ����������
  // ERR_                =  33;   //< ���� �������� �� ������������� ����������
  // ERR_                =  34;   //< ������������ ������ ����� �������� ���������� Settings.xml �� ���������� ������ �������� ���� �/��� ������ ����������
  // ERR_                =  35;   //< ���������� ������ ���������� ��� ������� ����� �������� ����������
  // ERR_                =  36;   //< ��������� ��������� ����� �������� ����������.
  // ERR_                =  37;   //< ������ �������������� �������� ���������
  // ERR_                =  38;   //< ������ �������������� �������� ��������� �� ���������
  // ERR_                =  39;   //< � ��������� ��������� ��������� ���������������� ��� ��������
  // ������ ��� �������� ������� ����������
  // ERR_                =  40;   //< ������ ������� ����������
  // ERR_                =  41;   //< ������������� ������ ����� ��������� ���
  // ERR_                =  42;   //< ������������� �� ����� ���� ������ �������
  // ERR_                =  43;   //< ���������� ������������� ����� ������������  �����
  // ERR_                =  44;   //< ���������� ������������� �������� ������������ �������
  // ERR_                =  45;   //< ������� ������ ����� ��������� ���
  // ERR_                =  46;   //< ������� �� ����� ���� ������ �������
  // ERR_                =  47;   //< � ���������� ������� ���������� ������������ ������� ��� �����
  // ERR_                =  48;   //< ������ ������������ ����� �������� ���������� Settings.xml
  // ���������� ������ ���������
  // ERR_                =  50;   //< �� ������� ��������� ������������ ��������� ���������� �� ������� ��������� ��������
  // ERR_                =  51;   //< ���������� ������ ��������� ��� ����������� ������ ���������
  // ERR_                =  52;   //< � ������� �� ���������� �� ������ ����������
  // ������ �������������� � ����������
  // ERR_                =  56;   //< ����������� ������ ��������
  // ERR_                =  57;   //< ������ ���������� ������ GetSettings
  // ERR_                =  58;   //< ������ ������� ������������ ������ ������ GetSettings
  // ERR_                =  60;   //< ���������� ������ ���������
  // ERR_                =  63;   //< ������ �������� ������� ��������
  // ERR_                =  64;   //< �� �������������� ��� ��������
  // ERR_                =  65;   //< ������ �������������� ������������� ������� ��������
  // ERR_                =  66;   //< ������ ��� ������ ������ ������������� � ������� ��������
  // ERR_                =  66;   //< ������ ��������� �������� ����������
  // ERR_                =  67;   //< ������ �������� �������� � �������
  // ERR_                =  68;   //< ������ ������ ������ ��������� �������� � ������� ��������
  // ERR_                =  69;   //< ���������� ������ ��� ������ ������ ������������� ������� ��������
  // ������ ���������� ������ ������������
  ERR_DeviceDisabled = 70; // < ���������� �� ��������
  // ERR_                =  71;   //< ���������� ������
  // ERR_                =  72;   //< ���������� �������������
  // ERR_                =  73;   //< ������� ���� ��������
  ERR_TimeOut = 74; // < ����� ������� ��������
  // ERR_                =  76;   //< �������� ��� ���������� ������ ��������
  // ERR_                =  77;   //< �������� ��� ������������� ��������� ��������
  // ERR_                =  79;   //< ���������� ������ ���������
  // ������ �������� ������ ������
  // ERR_                =  80;   //< ������� ����� ������ ����������
  // ERR_                =  81;   //< ������ �������� ������� �������� ����������
  // ERR_                =  82;   //< ������ ������������� ������� �������� ����������
  // ERR_                =  85;   //< ���������� ������ ���������
  // ERR_                = 101;   //< ������� ��������� �� ���������������
  // ERR_                = 102;   //< ������ ������������� ����������
  // ERR_                = 103;   //< ������ ��������� ���������� ������
  // ERR_                = 104;   //< ������ ���������� ���������� ������
  // ERR_                = 105;   //< ������ ��������� ����������
  // ERR_                = 106;   //< ������ ��� ������������� ����� �������������� ����������
  // ERR_                = 107;   //< ������ ����������
  // ERR_                = 108;   //< ������ ������������� ���������� � ����� �����
  // ERR_                = 109;   //< ������ ������� ������ ������
  // ERR_                = 110;   //< ����� ������� ��������
  // ������ ����������� �������������
  // ERR_                = 151;   //< ���������� ��������� ��� ������������ ������������� ������ ��������
  // ERR_                = 152;   //< ���������� ������������ ������� ���������
  // ������ ������� �������� � ���������
  ERR_CancelOperation = 201; // < �������� ���� �������� �������������
  // ����� ������ ���������
{$IF defined(ShopAdidas) or defined(shop2)}
  ERR_offset = 100;
  // �������� ������ �� ��������� 1000-1100. ��������� ��� SHOP ���� ������
{$ELSE}
  ERR_offset = 0;
  // �������� ������ �� ��������� 1000-1100. ��������� ��� SHOP ���� ������
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
  // ������ �������
  ERR_SC__First = 2001;
  ERR_SC_BufferEmpty = 2001;
  ERR_SC__UnDef = ERR_SC__First + ERR__UnDef;
  // < ������ ������������� ������ �������
  // ������ ��
  ERR_FR__First = 3001;
  ERR_FR_PaperEnd = 3001;
  ERR_FR_DayTooLong = 3002;   // ����� �������
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
  // < ������ ������������� ������ ��
  // ������ ��
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
  // < ������ ������������� ������ ��
  // ������ ��������
  ERR_D__First = 5001;
  // ERR_D_... = 5001;
  ERR_D__UnDef = ERR_D__First + ERR__UnDef;
  // < ������ ������������� ������ ��������
  // ������ ���
  ERR_DCT__First = 6001;
  ERR_DCT_EmptyData = ERR_DCT__First;
  ERR_DCT__UnDef = ERR_DCT__First + ERR__UnDef;
  // < ������ ������������� ������ ���
  // ������ �����
  ERR_W__First = 7001;
  ERR_W_WeightNotStable = 7001;
  ERR_W__UnDef = ERR_W__First + ERR__UnDef;
  // < ������ ������������� ������ �����
  // ������ ������
  ERR_CR__First = 8001;
  ERR_CR_BufferEmpty = 8001;
  ERR_CR__UnDef = ERR_CR__First + ERR__UnDef;
  // ������ ������������ ������� (AC)
  ERR_AC__First = 11001;
  ERR_AC_ControllersIsEmpty = 11001;
  ERR_AC__UnDef = ERR_AC__First + ERR__UnDef;
  // ������ �������������� ������������
  ERR_BR__First = 12001;
  ERR_BR_FingerprintNotFound = ERR_BR__First + 0;
  ERR_BR__UnDef = ERR_BR__First + ERR__UnDef;
  // ������ ��������� ��������
  ERR_LP__First = 13001;
  ERR_LP_InvalidTemplateNumber = ERR_LP__First + 0;
  ERR_LP__UnDef = ERR_LP__First + ERR__UnDef;
  // ������ ����������� ������
  ERR_EL__First = 14001;
  ERR_EL_BadActivationDate = ERR_EL__First + 0;
  ERR_EL_BadExpirationDate = ERR_EL__First + 1;
  ERR_EL_GuestRoomNotFound = ERR_EL__First + 2;
  ERR_EL__UnDef = ERR_EL__First + ERR__UnDef;
  // ������ ����������������
  ERR_BV__First = 15001;
  ERR_BV_BillWaitingTimeout = ERR_BV__First + 0;
  ERR_BV__UnDef = ERR_BV__First + ERR__UnDef;
  // ������ ���������
  ERR_CM__First = 16001;
  ERR_CM_WrongItemCode = ERR_CM__First + 0;
  ERR_CM_StandbyMode = ERR_CM__First + 1;
  ERR_CM__UnDef = ERR_CM__First + ERR__UnDef;
  // ������ ���������� �����
  ERR_ST__First = 17001;
  ERR_ST_ServiceNotFound = ERR_ST__First + 0;
  ERR_ST__UnDef = ERR_ST__First + ERR__UnDef;
  // ������ ������ ����������
  ERR_LS__First = 18001;
  ERR_LS_OrderNotFound = ERR_LS__First + 0;

  // ������ OPOS-���������
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

  // ������ ������ ���������
  ERR_UK__First = 100001;
  // ERR_UK_ ... = ERR_UK__First + 0;
  ERR_UK__UnDef = ERR_UK__First + ERR__UnDef;

resourcestring
  /// ///////////////////////////////////////////////////
  // �������� ������
  // ����� ������
  S_ERR_OK = '��� ������';
  S_ERR_DeviceDisabled = '���������� �� ��������';
  S_ERR_TimeOut = '����� ������� ��������';
  S_ERR_CancelOperation = '�������� �������� �������������';
  S_ERR_Unknown = '����������� ������';
  S_ERR_DeviceListEmpty = '���������� �� ������� ��� �� �������������������';
  S_ERR_FuncUnknown = '������� �� ���������� �����������';
  S_ERR_FuncNotSupported = '������� �� �������������� �����������';
  S_ERR_ParameterMismatch = '������ ������� ���������� �������';
  S_ERR_DeviceNotReady = '������������ �� ������';
  S_ERR_LibraryNotFound = '���������� �� �������';
  S_ERR_DeviceNoResponse = '���������� �� ��������';
  S_ERR_DeviceBusy = '���������� ������';
  S_ERR_InvalidLibraryVersion = '�������� ������ ����������';
  S_ERR_InvalidPort = '���� ����������';
  S_ERR_PortBusy = '���� ����� ������ �����������';
  S_ERR_DeviceNotFound = '���������� �� �������';
  S_ERR_Protocol = '������ ��������� ������';
  S_ERR_InvalidCommand = '�������� ������������������ ������';
  S_ERR_WritingPort = '������ ��� ������ ������ � ����';
  S_ERR_ReadingPort = '������ ��� ������ ������ �� �����';
  S_ERR_LibCallMethod = '������ ��� ������ ������ ����������';
  S_ERR_OnlySingleDevice = '������������� ����� ������ ���������� ���������� ������������ ����������';
  S_ERR_BadDeviceParameters = '�������� ��������� ����������';
  S_ERR_NotLicensedDriver = '��� �������� �� ������������ ��������';
  // ������ �������
  S_ERR_SC_BufferEmpty = '����� ������ ����';
  // ������ ��
  S_ERR_FR_PaperEnd = '��� ������';
  S_ERR_FR_DayTooLong =
    '������������ ����� ��������� 24 ����. ���������� ����� Z-�����';
  S_ERR_FR_JournalEnd = '��� ����������� �����';
  S_ERR_FR_NotSupportSlip = '����������� ���������� ��������';
  S_ERR_FR_DayClosed = '����� �������';
  S_ERR_FR_DayOpened = '����� �������';
  S_ERR_FR_NotEnoughCash = '������������ �������� � �����';
  S_ERR_FR_TemplateNotFound = '������ �� ������';
  S_ERR_FR_NeedCloseDay = '��� ���������� �������� ��������� ������� �����';
  S_ERR_FR_InsufficientAmount = '����� ������ �� ������������� ����� ���������';
  S_ERR_FR_TaxValueOutOfRange = '��������� ������ ��� ����������� ���������';
  S_ERR_FR_UnknownReceiptFiscalState =
    '�� ������� ���������� ��������� �������� ����';
  S_ERR_FR_PaymentValueOutOfRange = '����� ������ ��� ����������� ���������';
  S_ERR_FR_DepartmentValueOutOfRange = '����� ������ ��� ����������� ���������';
  S_ERR_FR_CustomerAddressIsEmpty = '�� ������ ����� ����������';
  S_ERR_FR_NotSupported54FZ = '���������� �� ������������ 54-��';
  S_ERR_FR_CashLack = '������������ ���������� � �����';
  S_ERR_FR_NOT_FISCAL = '�� �� ��������������';
  S_ERR_FR_FN_CLOSED = '�� ������';
  S_ERR_FR_SignCalculationObjectOutOfRange = '�������� �������� �������� ������� ��� ����������� ���������';
  S_ERR_FR_SignMethodCalculationOfRange = '�������� �������� ������� ������� ��� ����������� ���������';
  S_ERR_FR_PrintOutFilePath = '������������ ���� ����� ������ ����';
  S_ERR_FR_AgentTypeOutOfRange = '�������� �������� ������ �� �������� ������� ��� ����������� ���������';
  S_ERR_FR_NULL_PRICE = '������� ���� �� ��������� ��� ������ ������ ������������';
  S_ERR_FR_TaxValueCombined = '����������� ��������� ������� 20% � 18% � ����� ���������';
  S_ERR_FR_IncorrectVATIN = '������������ ���';
  S_ERR_FR_PrintError = '������ ������ ���� (���������)';
  S_ERR_FR_PrintPrevDoc = '��������� ������ ����������� ���� (���������)';
  S_ERR_FR_UncorrectCashierName = '�� ������� ��� �������';
  S_ERR_FR_CUSTOMER_PHONE_OR_EMAIL = '������������ ������� ��� email ����������';
  // ������ ��
  S_ERR_AT_PinpadNoResponse = '��� ����� � pinpad';
  S_ERR_AT_HostNoResponse = '��� ����� � ������';
  S_ERR_AT_OperationNoApprove = '�������� �� ���� ��������';
  S_ERR_AT_TransactionAlreadyExists =
    '���������� � ��������� ������� ��� ����������';
  S_ERR_AT_UndefinedTransactionResult =
    '������ ���������� ���������� �� ���������';
  S_ERR_AT_OverflowBalance = '�� ������� ������� ��� ���������� ����������';
  S_ERR_AT_TransactionNotFound = '���������� �� �������';
  S_ERR_AT_NoReceiptText = 'Pinpad �� ������ ����� ����';
  // ������ ���
  S_ERR_DCT_EmptyData = '����������� ������ �����������';
  // ������ �����
  S_ERR_W_WeightNotStable = '��� �� ��������';
  // ������ ������
  S_ERR_CR_BufferEmpty = '����� ������ ����';
  // ������ ������������ ������� (AC)
  S_ERR_AC_ControllersIsEmpty = '������ ������������ ����';
  // ������ ��������� ��������
  S_ERR_LP_InvalidTemplateNumber =
    '������ � ����� ������� �� ��� �������� � �������';
  // ������ �������������� ������������
  S_ERR_BR_FingerprintNotFound = '��������� �� ������ � ����';
  // ������ ����������� ������
  S_ERR_EL_BadActivationDate = '���� ������ ������ ���� ������ ������� ����';
  S_ERR_EL_BadExpirationDate = '���� ������ ������ ���� ������ ���� ������';
  S_ERR_EL_GuestRoomNotFound = '������������ ��� ������� �� �������';
  // ������ ����������������
  S_ERR_BV_BillWaitingTimeout = '��������� ����� �������� ������';
  // ������ ���������
  S_ERR_CM_WrongItemCode = '�������� ��� ������� � ����';
  S_ERR_CM_StandbyMode =
    '���������� � ��������� �������� ������� �� ������������� ��������';
  // ������ ���������� �����
  S_ERR_ST_ServiceNotFound = '������ �� �������';
  // ������ ������ ����������
  S_ERR_LS_OrderNotFound = '����� �� ������';
  // ������ OPOS-���������
  S_ERR_OPOS_SUCCESS = '������ ���';
  S_ERR_OPOS_E_CLOSED = '�� ��������� ����������� ������';
  S_ERR_OPOS_E_CLAIMED = '���������� ��������� ������ ���������';
  S_ERR_OPOS_E_NOTCLAIMED = '���������� �� ���������';
  S_ERR_OPOS_E_NOSERVICE = '�� ������� ���������� � ������������ �������';
  S_ERR_OPOS_E_DISABLED = '���������� �� ���������� �� �����';
  S_ERR_OPOS_E_ILLEGAL =
    '������ �������, ���� ������� �� �������������� ������ �����������, ���� ��������� ������������ ������';
  S_ERR_OPOS_E_NOHARDWARE =
    '������� ���������� �� ��������, ���� ���������� �� ���������� � �����';
  S_ERR_OPOS_E_OFFLINE = '���������� ���������';
  S_ERR_OPOS_E_NOEXIST = '��� ����� ��� ��������� �������� �� ����������';
  S_ERR_OPOS_E_EXISTS = '��� ����� ��� ��������� �������� ��� ����������';
  S_ERR_OPOS_E_FAILURE = '���������� �� ����� ��������� ��������� �������';
  S_ERR_OPOS_E_TIMEOUT = '������� ����� �������� ������ �� ����������';
  S_ERR_OPOS_E_BUSY =
    '������� ��������� ������������ ������� �� ��������� ���������� ������';
  S_ERR_OPOS_E_EXTENDED =
    '����������� ��� ������� ������ ��������� ������. ����������� ���������� � �������������� �������� ������';

  // �������� ��������� �����
  S_MSG_TestOK = '���� ������� �������';
  S_MSG_TraningMode = '������������� �����';

  /// ///////////////////////////////////////////////////
  // �������� ����������
  EXEPT_MethodNotSupported = '����� �� ��������������';
  EXEPT_EqManagerNotFound = '�������� ������������ ����������';
  EXEPT_MethodError = '������ ��� ���������� ������';

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
    // ������ �������
    ERR_SC_BufferEmpty:
      Result := S_ERR_SC_BufferEmpty;
    // ������ ��
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
    // ������ ��
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
    // ������ ���
    ERR_DCT_EmptyData:
      Result := S_ERR_DCT_EmptyData;
    // ������ �����
    ERR_W_WeightNotStable:
      Result := S_ERR_W_WeightNotStable;
    // ������ ������
    ERR_CR_BufferEmpty:
      Result := S_ERR_CR_BufferEmpty;
    // ������ ������������ ������� (AC)
    ERR_AC_ControllersIsEmpty:
      Result := S_ERR_AC_ControllersIsEmpty;
    // ������ ��������� ��������
    ERR_LP_InvalidTemplateNumber:
      Result := S_ERR_LP_InvalidTemplateNumber;
    // ������ �������������� ������������
    ERR_BR_FingerprintNotFound:
      Result := S_ERR_BR_FingerprintNotFound;
    // ������ ����������� ������
    ERR_EL_BadActivationDate:
      Result := S_ERR_EL_BadActivationDate;
    ERR_EL_BadExpirationDate:
      Result := S_ERR_EL_BadExpirationDate;
    ERR_EL_GuestRoomNotFound:
      Result := S_ERR_EL_GuestRoomNotFound;
    // ������ ����������������
    ERR_BV_BillWaitingTimeout:
      Result := S_ERR_BV_BillWaitingTimeout;
    // ������ ���������
    ERR_CM_WrongItemCode:
      Result := S_ERR_CM_WrongItemCode;
    ERR_CM_StandbyMode:
      Result := S_ERR_CM_StandbyMode;
    // ������ ���������� �����
    ERR_ST_ServiceNotFound:
      Result := S_ERR_ST_ServiceNotFound;
    // ������ ������ ����������
    ERR_LS_OrderNotFound:
      Result := S_ERR_LS_OrderNotFound;
    // ������ OPOS-���������
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
