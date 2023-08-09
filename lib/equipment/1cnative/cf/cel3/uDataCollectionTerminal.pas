unit uDataCollectionTerminal;

interface

uses uCommonDriver, uCustomDriver, v8napi, Xml.XMLDoc, Xml.XMLIntf;

type
  TDataCollectionTerminal = class(TCommonDriver)
  private
  protected
    // Перегруженные абстрактные методы типа оборудования
    procedure UploadTable(AInputParameters: IXMLDocument;
      const APackageStatus: string); overload; virtual; abstract;
    procedure DownloadTable(AInputParameters: IXMLDocument); overload;
      virtual; abstract;
    procedure ClearTable; overload; virtual; abstract;

  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
    constructor Create; override;
    destructor Destroy; override;
  public
    // Экспортируемые методы типа оборудования
    [ExportMethAttribute('ВыгрузитьТаблицу', 3)]
    function UploadTable(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    [ExportMethAttribute('ЗагрузитьТаблицу', 2)]
    function DownloadTable(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    [ExportMethAttribute('ОчиститьТаблицу', 1)]
    function ClearTable(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  end;

implementation

uses
  Variants, SysUtils, uCommonUtils, uEquipmentErrors
{$IF Defined(DEBUG_FORM)}
    , uXMLDialog
{$IFEND}
    ;

constructor TDataCollectionTerminal.Create;
begin
  inherited;
{$IF Defined(DEBUG_FORM)}
  if not Assigned(fmXmlDialog) then
    fmXmlDialog := TfmXmlDialog.Create(nil);
{$IFEND}
end;

destructor TDataCollectionTerminal.Destroy;
begin
{$IF Defined(DEBUG_FORM)}
  FreeAndNil(fmXmlDialog);
{$IFEND}
  inherited;
end;

function TDataCollectionTerminal.UploadTable(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters: IXMLDocument;
  LPackageStatus: string;
begin
  try
{$IF Defined(DEBUG_FORM)}
    fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
    fmXmlDialog.ShowModal;
    LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
{$ELSE}
    LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
{$IFEND}
    LPackageStatus := V8AsWString(@Params[3]);
    UploadTable(LInputParameters, LPackageStatus);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TDataCollectionTerminal.DownloadTable(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LOutputParameters: IXMLDocument;
begin
  try
    LOutputParameters := NewXMLDocument;
    DownloadTable(LOutputParameters);
    V8SetWString(@Params[2], LOutputParameters.Xml.Text);
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TDataCollectionTerminal.ClearTable(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    ClearTable;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

class procedure TDataCollectionTerminal.UpdateDriverInfo
  (ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etDataCollectionTerminal;
end;

end.
