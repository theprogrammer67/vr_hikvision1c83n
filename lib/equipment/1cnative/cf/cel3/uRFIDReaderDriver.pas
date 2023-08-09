/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера RFID-считывателя для ревизии интерфейса (версии требований 1С) 3.X
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. 2021
//

unit uRFIDReaderDriver;

interface

uses uCommonDriver, uCustomDriver, v8napi, Winapi.Windows, Xml.XMLDoc, Xml.XMLIntf;

type
  TRFIDReaderDriver = class(TCommonDriver)
  private
  protected
    FPackageID: string;
  // Перегруженные абстрактные методы типа оборудования
    procedure OpenSessionRFID; overload; virtual; abstract;
    procedure CloseSessionRFID; overload; virtual; abstract;
    procedure GetDataTagsRFID (const APackageID: string;
      AOutputParameters: IXMLDocument); overload; virtual; abstract;
    procedure SaveDataTagRFID(const ATID, AEPC, AData: string;
      const AMemoryBank: Integer); overload; virtual; abstract;
  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;

    // Экспортируемые методы типа оборудования
    [ExportMethAttribute('ОткрытьСессиюRFID', 1)]
    function OpenSessionRFID(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    [ExportMethAttribute('ЗакрытьСессиюRFID', 1)]
    function CloseSessionRFID(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    [ExportMethAttribute('ПолучитьДанныеМетокRFID', 3)]
    function GetDataTagsRFID(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    [ExportMethAttribute('ЗаписатьДанныеВМеткуRFID', 6)]
    function SaveDataTagRFID(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

  end;

implementation
uses Variants, SysUtils, uCommonUtils;

function TRFIDReaderDriver.CloseSessionRFID(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    CloseSessionRFID;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TRFIDReaderDriver.GetDataTagsRFID(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LPackageID: string;
  LOutputParameters: IXMLDocument;
begin
  try
    LPackageID := V8AsWString(@Params[2]);
    LOutputParameters := NewXMLDocument();
    GetDataTagsRFID(LPackageID, LOutputParameters);
    V8SetWString(@Params[3], LOutputParameters.Xml.Text);
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TRFIDReaderDriver.OpenSessionRFID(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    OpenSessionRFID;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TRFIDReaderDriver.SaveDataTagRFID(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LTID, LEPC, LData: string;
  LMemoryBank: Integer;

begin
  try
    LTID := V8AsWString(@Params[2]);
    LEPC := V8AsWString(@Params[3]);
    LData := V8AsWString(@Params[4]);
    LMemoryBank := V8AsInt(@Params[5]);
    SaveDataTagRFID(LTID, LEPC, LData, LMemoryBank);
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

class procedure TRFIDReaderDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etRFIDReader;
  DriverInfo.IntegrationComponent := false;
end;

end.

