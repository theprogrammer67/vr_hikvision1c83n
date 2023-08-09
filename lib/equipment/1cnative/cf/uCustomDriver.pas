/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс компоненты 1С:Совместимо
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. STOI 2019
//

unit uCustomDriver;

// Выводить диалоги средствами WinAPI
// {$DEFINE  WinApiDialogs}

interface

uses v8napi, System.Rtti, System.SysUtils, Winapi.Windows;

const
  RESULTCODE_OK = 0;
  RESULTCODE_ERROR = 1001;

const
  ERR_ENUMVALUE = 'Enum value unacceptable';
  ERR_PPROPTYPE = 'Property type unacceptable';
  ERR_VALUETYPE = 'Value type unacceptable';
  ERR_PROPREADONLY = 'Property is read-only';
  ERR_PROPNOTFOUND = 'Property not found';
  ERR_DISPLAYDIALOG = 'Could not display dialog box';
  ERR_PARAMETERMISMATCH = 'Parameter mismatch';

resourcestring
  RsConfirm = 'Подтверждение';
  RsAlert = 'Внимание';

type
  ExportMethAttribute = class(TCustomAttribute)
  private
    FNameLoc: string;
    FParamCount: Integer;
  public
    constructor Create(const ANameLoc: string; AParamCount: Integer);
  public
    property NameLoc: string read FNameLoc write FNameLoc;
    property ParamCount: Integer read FParamCount write FParamCount;
  end;

  ExportPropAttribute = class(TCustomAttribute)
  private
    FNameLoc: string;
    FCaption: string;
    FDefValue: string;
    FReadOnly: Boolean;
  public
    constructor Create(const ANameLoc, ACaption, ADefValue: string;
      AReadOnly: Boolean);
  public
    property NameLoc: string read FNameLoc write FNameLoc;
    property Caption: string read FCaption write FCaption;
    property DefValue: string read FDefValue write FDefValue;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
  end;

  AdditionalActionAttribute = class(TCustomAttribute)
  private
    FCaption: string;
  public
    constructor Create(const ACaption: string);
  public
    property Caption: string read FCaption write FCaption;
  end;

  TParamType = class
  public type
    TValue = (ptString, ptNumber, ptBoolean, ptUnknown);
  protected
    class function GetName(AValue: TParamType.TValue): string; static;
  public
    class property Name[Index: TParamType.TValue]: string read GetName;
  end;

  TResult = record
    ErrorCode: Integer;
    ErrorDescription: string;
    BoolResult: Boolean;
    procedure Clear;
    function GetIntResult: Integer;
    procedure SetError(const ADescription: string;
      const AErrorCode: Integer = 0);
  end;

  TCustomDriver = class(TV8UserObject)
  private
    FLastResult: TResult;
  private
    function GetInterface(iface: TInterfaces): TInterface;
    function GetPropertyValue(LProperty: TRttiProperty;
      AValue: PV8Variant): Boolean;
    function SetPropertyValue(LProperty: TRttiProperty;
      AValue: PV8Variant): Boolean; overload;
    function SetPropertyValue(LProperty: TRttiProperty;
      AValue: Variant): Boolean; overload;
  protected
    procedure SetSuccess(ARetValue: PV8Variant = nil);
    procedure SetError(AExceptObject: TObject; ARetValue: PV8Variant = nil;
      ACodeError: Integer = 1001); overload; virtual;
    procedure SetError(const AMessage: string); overload;
    function GetPlatformInfo: TPlatformInfo;
    function Confirm(const AQueryText: string): Boolean;
    procedure Alert(const AQueryText: string);
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure RegisterClass(AClass: TClass; const AExtension: string);
    class procedure RegisterDriver(AClass: TClass; const AExtension: string);
  public
    function PropertyGetSet(const PropName: WideString; propValue: PV8Variant;
      Get: Boolean; var v8: TV8AddInDefBase): Boolean; overload;
    function PropertyGetSet(const PropName: WideString; propValue: Variant): Boolean; overload;
    function PropertySet(const PropName: WideString;
      propValue: PV8Variant): Boolean; overload;
    function PropertySet(const PropName: WideString;
      propValue: Variant): Boolean; overload;
  public
    property LastResult: TResult read FLastResult;
    class var FileName: string;
  end;

implementation

uses Common.Log;

{ TResult }

procedure TResult.Clear;
begin
  ErrorCode := 0;
  ErrorDescription := '';
  BoolResult := True;
end;

function TResult.GetIntResult: Integer;
begin
  if BoolResult then
    Result := RESULTCODE_OK
  else if ErrorCode <> 0 then
    Result := ErrorCode
  else
    Result := RESULTCODE_ERROR;
end;

procedure TResult.SetError(const ADescription: string;
  const AErrorCode: Integer);
begin
  ErrorCode := AErrorCode;
  ErrorDescription := ADescription;
  BoolResult := False;
end;

{ AttrExportMethod }

constructor ExportMethAttribute.Create(const ANameLoc: string;
  AParamCount: Integer);
begin
  FNameLoc := ANameLoc;
  FParamCount := AParamCount;
end;

procedure TCustomDriver.Alert(const AQueryText: string);
begin
{$IFDEF WinApiDialogs}
  MessageBox(0, PWideChar(AQueryText), PWideChar(RsAlert),
    MB_ICONWARNING or MB_OK);
{$ELSE}
  TV8MsgBox(GetInterface(eIMsgBox)).Alert(PWideChar(AQueryText));
{$ENDIF}
end;

function TCustomDriver.Confirm(const AQueryText: string): Boolean;
{$IFNDEF WinApiDialogs}
var
  LRetVal: V8Variant;
{$ENDIF}
begin
{$IFDEF WinApiDialogs}
  Result := MessageBox(0, PWideChar(AQueryText), PWideChar(RsConfirm),
    MB_ICONQUESTION or MB_OKCANCEL) = IDOK;
{$ELSE}
  if not TV8MsgBox(GetInterface(eIMsgBox)).Confirm(PWideChar(AQueryText),
    @LRetVal) then
    raise Exception.Create(ERR_DISPLAYDIALOG);

  Result := V8AsBool(@LRetVal);
{$ENDIF}
end;

constructor TCustomDriver.Create;
begin
  inherited;
  FLastResult.Clear;
end;

destructor TCustomDriver.Destroy;
begin
  inherited;
end;

procedure TCustomDriver.SetError(AExceptObject: TObject; ARetValue: PV8Variant;
  ACodeError: Integer);
begin
  FLastResult.SetError(Exception(AExceptObject).Message, ACodeError);
  if Assigned(ARetValue) then
    V8SetBool(ARetValue, False);
  TLog.Append('Exception', FLastResult.ErrorDescription, mtError);
end;

function TCustomDriver.GetInterface(iface: TInterfaces): TInterface;
begin
  Result := TV8AddInDefBaseEx(v8).GetInterface(Ord(iface));

  // Ссылка на экземпляр класса указывает на начало его данных,
  // но перед данными еще есть указатель на таблицу виртуальных методов(VTable)
  // класса.Поэтому приходится сдвигать указатель на размер этого указателя,
  // т.к.он тоже является частью представления объекта в памяти.
  Dec(PPointer(Result));
end;

function TCustomDriver.GetPlatformInfo: TPlatformInfo;
var
  LPlatformInfo: TV8PlatformInfo;
begin
  LPlatformInfo := TV8PlatformInfo(GetInterface(eIPlatformInfo));
  Result := LPlatformInfo.PlatformInfo^;
end;

function TCustomDriver.GetPropertyValue(LProperty: TRttiProperty;
  AValue: PV8Variant): Boolean;
var
  LValue: TValue;
begin
  LValue := LProperty.GetValue(Self);

  case LProperty.PropertyType.TypeKind of
    tkInteger, tkInt64:
      V8SetInt(AValue, LValue.AsInteger);
    tkFloat:
      V8SetDouble(AValue, LValue.AsExtended);
    tkString, tkWString, tkUString, tkLString:
      V8SetWString(AValue, LValue.AsString);
    tkEnumeration:
      begin
        if LProperty.PropertyType.ToString = 'Boolean' then
          V8SetBool(AValue, LValue.AsBoolean)
        else
          raise Exception.Create(ERR_PPROPTYPE);
      end;
  else
    raise Exception.Create(ERR_PPROPTYPE);
  end;

  Result := True;
end;

function TCustomDriver.PropertyGetSet(const PropName: WideString;
  propValue: PV8Variant; Get: Boolean; var v8: TV8AddInDefBase): Boolean;
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LProperty: TRttiProperty;
  LAttribute: TCustomAttribute;
begin
  Result := False;
  LCtx := TRttiContext.Create;
  try
    LType := LCtx.GetType(Self.ClassType);
    for LProperty in LType.GetProperties do
      for LAttribute in LProperty.GetAttributes do
        if (LAttribute is ExportPropAttribute) and
          ((AnsiSameText(LProperty.Name, string(PropName))) or
          (AnsiSameText((ExportPropAttribute(LAttribute).NameLoc),
          string(PropName)))) then
        begin
          if Get then
            Result := GetPropertyValue(LProperty, propValue)
          else
          begin
            if not ExportPropAttribute(LAttribute).ReadOnly then
              Result := SetPropertyValue(LProperty, propValue)
            else
              raise Exception.Create(ERR_PROPREADONLY + ': ' + PropName);
          end;
        end;
  finally
    LCtx.Free;
  end;

  if not Result then
    raise Exception.Create(ERR_PROPNOTFOUND + ': ' + PropName);
end;

function TCustomDriver.PropertySet(const PropName: WideString;
  propValue: PV8Variant): Boolean;
var
  v8: TV8AddInDefBase;
begin
  v8 := nil;
  Result := PropertyGetSet(PropName, propValue, False, v8);
end;

function TCustomDriver.PropertyGetSet(const PropName: WideString; propValue: Variant): Boolean;
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LProperty: TRttiProperty;
  LAttribute: TCustomAttribute;
begin
  Result := False;
  LCtx := TRttiContext.Create;
  try
    LType := LCtx.GetType(Self.ClassType);
    for LProperty in LType.GetProperties do
      for LAttribute in LProperty.GetAttributes do
        if (LAttribute is ExportPropAttribute) and
          ((AnsiSameText(LProperty.Name, string(PropName))) or
          (AnsiSameText((ExportPropAttribute(LAttribute).NameLoc),
          string(PropName)))) then
        begin
          if not ExportPropAttribute(LAttribute).ReadOnly then
            Result := SetPropertyValue(LProperty, propValue)
          else
            raise Exception.Create(ERR_PROPREADONLY + ': ' + PropName);
        end;
  finally
    LCtx.Free;
  end;

  if not Result then
    raise Exception.Create(ERR_PROPNOTFOUND + ': ' + PropName);
end;

function TCustomDriver.PropertySet(const PropName: WideString;
  propValue: Variant): Boolean;
begin
  Result := PropertyGetSet(PropName, propValue);
end;


class procedure TCustomDriver.RegisterClass(AClass: TClass;
  const AExtension: string);
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
  LProperty: TRttiProperty;
  LAttribute: TCustomAttribute;
  LClassReg: TClassReg;
begin
  LClassReg := ClassRegList.RegisterClass(AClass, AExtension, AExtension);

  LCtx := TRttiContext.Create;
  try
    LType := LCtx.GetType(AClass);

    // Экспортируемые методы
    for LMethod in LType.GetMethods do
      for LAttribute in LMethod.GetAttributes do
        if LAttribute is ExportMethAttribute then
          with ExportMethAttribute(LAttribute) do
            LClassReg.AddFunc(LMethod.Name, NameLoc, LMethod.CodeAddress,
              ParamCount);

    // Экспортируемые свойства
    for LProperty in LType.GetProperties do
      for LAttribute in LProperty.GetAttributes do
        if LAttribute is ExportPropAttribute then
          with ExportPropAttribute(LAttribute) do
            LClassReg.AddProp(LProperty.Name, NameLoc, True, ReadOnly = False,
              @TCustomDriver.PropertyGetSet);
  finally
    LCtx.Free;
  end;
end;

class procedure TCustomDriver.RegisterDriver(AClass: TClass;
  const AExtension: string);
begin
  RegisterClass(AClass, AExtension);

  FileName := AExtension;

  TLog.FileName := FileName;
  TLog.Start;
end;

procedure TCustomDriver.SetError(const AMessage: string);
begin
  FLastResult.SetError(AMessage);
end;

function TCustomDriver.SetPropertyValue(LProperty: TRttiProperty;
  AValue: PV8Variant): Boolean;
var
  LValue: TValue;
begin
  case LProperty.PropertyType.TypeKind of
    tkInteger, tkInt64:
      LValue := V8AsInt(AValue);
    tkFloat:
      LValue := V8AsDouble(AValue);
    tkString, tkWString, tkUString, tkLString:
      if V8isString(AValue) then
        LValue := V8AsWString(AValue)
      else
        raise Exception.Create(ERR_VALUETYPE);
    tkEnumeration:
      begin
        if LProperty.PropertyType.ToString = 'Boolean' then
          LValue := V8AsBool(AValue)
        else
          raise Exception.Create(ERR_PPROPTYPE);
      end;
  else
    raise Exception.Create(ERR_PPROPTYPE);
  end;

  LProperty.SetValue(Self, LValue);
  Result := True;
end;

function TCustomDriver.SetPropertyValue(LProperty: TRttiProperty;
  AValue: Variant): Boolean;
var
  LValue: TValue;
begin
  case LProperty.PropertyType.TypeKind of
    tkInteger, tkInt64:
      LValue := Integer(AValue);
    tkFloat:
      LValue := Double(AValue);
    tkString, tkWString, tkUString, tkLString:
      LValue := String(AValue);
    tkEnumeration:
      begin
        if LProperty.PropertyType.ToString = 'Boolean' then
          LValue := Boolean(AValue)
        else
          raise Exception.Create(ERR_PPROPTYPE);
      end;
  else
    raise Exception.Create(ERR_PPROPTYPE);
  end;

  LProperty.SetValue(Self, LValue);
  Result := True;
end;

procedure TCustomDriver.SetSuccess(ARetValue: PV8Variant);
begin
  FLastResult.Clear;
  if Assigned(ARetValue) then
    V8SetBool(ARetValue, True);
end;

{ TParamType }

class function TParamType.GetName(AValue: TParamType.TValue): string;
begin
  case AValue of
    ptString:
      Result := 'String';
    ptNumber:
      Result := 'Number';
    ptBoolean:
      Result := 'Boolean';
    ptUnknown:
      Result := 'Unknown';
  else
    raise Exception.Create(ERR_ENUMVALUE);
  end;
end;

{ ExportPropAttribute }

constructor ExportPropAttribute.Create(const ANameLoc, ACaption,
  ADefValue: string; AReadOnly: Boolean);
begin
  FNameLoc := ANameLoc;
  FCaption := ACaption;
  FDefValue := ADefValue;
  FReadOnly := AReadOnly;
end;

{ AdditionalActionAttribute }

constructor AdditionalActionAttribute.Create(const ACaption: string);
begin
  FCaption := ACaption;
end;

end.
