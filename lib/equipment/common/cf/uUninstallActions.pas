unit uUninstallActions;

interface

uses Common.CommonTypes, System.Classes, Xml.XMLIntf, uWinSvcUtils,
  System.SysUtils, System.IOUtils, Xml.XMLDoc, System.Win.Registry,
  Winapi.Windows;

type
  TActionType = (atDeleteFile, atDeleteDirectory, atDeleteRegKey,
    atDeleteRegValue, atUnregSvr, atUninstallWinSvc, atDeleteLink, atRunApp,
    atStopWinSvc);

  TUninstallAction = class(TCollectionItem)
  private
    FParam2: string;
    FParam3: string;
    FParam1: string;
    FActionType: TActionType;

    function GetTypeAsString: string;
    procedure SetTypeAsString(Value: string);

    procedure ActDeleteFile(const AFileName: string);
    procedure ActDeleteDirectory(const ADirName: string);
    procedure ActDeleteRegKey(const RootKey, RegKey: string);
    procedure ActDeleteRegValue(const RootKey, RegKey, ValueName: string);
    procedure ActUnregSvr(const SvrPath: string);
    procedure ActUninstallWinSvc(const SvcName: string);
    procedure ActStopWinSvc(const SvcName: string);
    procedure ActDeleteLink(const ALinkName: string);
    procedure ActRunApp(const AppName, Param: string);
  public
    procedure Run;
    property ActionType: TActionType read FActionType write FActionType;
    property Param1: string read FParam1 write FParam1;
    property Param2: string read FParam2 write FParam2;
    property Param3: string read FParam3 write FParam3;
    property TypeAsString: string read GetTypeAsString write SetTypeAsString;
  end;

  TUninstalActions = class(TXmlSerializeCollection)
  private
    FProgramId: string;
    FProgramName: string;
    FFileName: string;
    FAdditionalComponents: TStringList;

    // function GetFullFilePath: string;
    function GetItem(Index: Integer): TUninstallAction;
    function GetAddComponentFileName(Index: Integer): string;
    function GetAddComponentProgramName(Index: Integer): string;
    function GetProgramId: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddAction(AActionType: TActionType; const AParam1: string;
      const AParam2: string = ''; const AParam3: string = '');
    function Add: TUninstallAction;
    procedure AddAdditionalComponent(const AFileName, AProgramName: string);

    function XMLSerialize(Root: IXMLNode): IXMLNode; override;
    function XMLDeserialize(Root: IXMLNode): IXMLNode; override;

    procedure LoadFromFile;
    procedure SaveToFile;
    procedure DeleteUninstLogFile;
    procedure RegisterApp(const InstallLocation, AppIcon: string);
    procedure UnregisterApp;

    property ProgramId: string read FProgramId write FProgramId;
    property ProgramName: string read FProgramName write FProgramName;
    property FileName: string read FFileName write FFileName;
    property Item[Index: Integer]: TUninstallAction read GetItem; default;
    property AdditionalComponents: TStringList read FAdditionalComponents
      write FAdditionalComponents;
    property AdditionalComponentFileName[Index: Integer]: string
      read GetAddComponentFileName;
    property AdditionalComponentProgramName[Index: Integer]: string
      read GetAddComponentProgramName;
  end;

const
  CommonUninstallDir = '1C Rarus\UninstallApp\';
  UninstallLogExt = '.unt';
  UninstalKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\';
  UninstallAppExeName = 'UninstallApp.exe';
  UninstallAppExeNameTmp = 'UninstallApp.tmp';

  ActDescrDeleteFile = '';

  sHKEY_CLASSES_ROOT = 'HKEY_CLASSES_ROOT';
  sHKEY_CURRENT_USER = 'HKEY_CURRENT_USER';
  sHKEY_LOCAL_MACHINE = 'HKEY_LOCAL_MACHINE';
  sHKEY_USERS = 'HKEY_USERS';
  sHKEY_PERFORMANCE_DATA = 'HKEY_PERFORMANCE_DATA';
  sHKEY_CURRENT_CONFIG = 'HKEY_CURRENT_CONFIG';
  sHKEY_DYN_DATA = 'HKEY_DYN_DATA';

  tagUninstall = 'uninstall';
  tagActions = 'actions';
  tagAdditionalComponents = 'additionalcomponents';
  tagComponent = 'component';
  tagAction = 'action';
  tagProgramId = 'programid';
  tagProgramName = 'programname';
  tagActionType = 'actiontype';
  tagDeleteFile = 'deletefile';
  tagDeleteDirectory = 'deletedirectory';
  tagDeleteRegKey = 'deleteregkey';
  tagDeleteRegValue = 'deleteregvalue';
  tagUnregSvr = 'unregsvr';
  tagUninstallWinSvc = 'uninstallwinsvc';
  tagStopWinSvc = 'stopwinsvc';
  tagDeleteLink = 'deletelink';
  tagRunApp = 'runapp';
  tagParam1 = 'param1';
  tagParam2 = 'param2';
  tagParam3 = 'param3';

function RootKeyToStr(Key: HKEY): string;
function StrToRootKey(const StrKey: string): HKEY;
function GetUninstallAppDir: string;
function GetUninstallAppExe: string;
function GetFullFilePath(const AFileName: string): string;
function UninstallFileExist(const AFileName: string): Boolean;
function GetActionDescr(ActionType: TActionType): string;
function StrToActionType(const Value: string): TActionType;
function ActionTypeToStr(Value: TActionType): string;
function GetProgramName: string;
procedure ExtractUninstallAppFromResource;

resourcestring
  rsPublisher = '1С-Рарус';

  rsFileNotFound = 'Файл не найден';
  rsCantDeleteSvc = 'Не удается удалить службу';
  rsCantStopSvc = 'Не удается остановить службу';
  rsRunAppNotSuccessfull = 'Удаление программы не было выполнено';
  rsInvalidAction = 'Неверная акция';

  rsActDescrDeleteFile = 'Удаление файла';
  rsActDescrDeleteDirectory = 'Удаление папки';
  rsActDescrDeleteRegKey = 'Удаление ключа';
  rsActDescrDeleteRegValue = 'Уделение значения ключа';
  rsActDescrUnregSvr = 'Удаление регистрации сервера';
  rsActDescrUninstallWinSvc = 'Удаление службы';
  rsActDescrStopWinSvc = 'Остановка службы';
  rsActDescrDeleteLink = 'Удаление ярлыка';
  rsActRunApp = 'Выполнение программы';
  rsDeletingProgram = 'Удаление программы';

implementation

uses uXMLUtils, uCommonUtils, uVInfo;

function RootKeyToStr(Key: HKEY): string;
begin
  case Key of
    HKEY_CLASSES_ROOT:
      Result := sHKEY_CLASSES_ROOT;
    HKEY_CURRENT_USER:
      Result := sHKEY_CURRENT_USER;
    HKEY_LOCAL_MACHINE:
      Result := sHKEY_LOCAL_MACHINE;
    HKEY_USERS:
      Result := sHKEY_USERS;
    HKEY_PERFORMANCE_DATA:
      Result := sHKEY_PERFORMANCE_DATA;
    HKEY_CURRENT_CONFIG:
      Result := sHKEY_CURRENT_CONFIG;
    HKEY_DYN_DATA:
      Result := sHKEY_DYN_DATA;
  else
    Result := '';
  end;
end;

function StrToRootKey(const StrKey: string): HKEY;
begin
  if StrKey = sHKEY_CLASSES_ROOT then
    Result := HKEY_CLASSES_ROOT
  else if StrKey = sHKEY_CURRENT_USER then
    Result := HKEY_CURRENT_USER
  else if StrKey = sHKEY_LOCAL_MACHINE then
    Result := HKEY_LOCAL_MACHINE
  else if StrKey = sHKEY_USERS then
    Result := HKEY_USERS
  else if StrKey = sHKEY_PERFORMANCE_DATA then
    Result := HKEY_PERFORMANCE_DATA
  else if StrKey = sHKEY_CURRENT_CONFIG then
    Result := HKEY_CURRENT_CONFIG
  else if StrKey = sHKEY_DYN_DATA then
    Result := HKEY_DYN_DATA
  else
    Result := 0;
end;

function GetUninstallAppDir: string;
begin
  Result := GetProgramFilesCommonPath + CommonUninstallDir;
  TDirectory.CreateDirectory(Result);
end;

function GetUninstallAppExe: string;
begin
  Result := GetUninstallAppDir + UninstallAppExeName;
end;

function GetFullFilePath(const AFileName: string): string;
begin
  if Pos(PathDelim, AFileName) = 0 then // Задано только имя файла
    Result := GetUninstallAppDir + AFileName
  else
    Result := AFileName;

  if Pos(UninstallLogExt, Result) <>
    (Length(Result) - Length(UninstallLogExt) + 1) then
    Result := Result + UninstallLogExt;
end;

function UninstallFileExist(const AFileName: string): Boolean;
var
  FilePath: string;
begin
  FilePath := GetFullFilePath(AFileName);

  Result := TFile.Exists(FilePath);
end;

function GetActionDescr(ActionType: TActionType): string;
begin
  case ActionType of
    atDeleteFile:
      Result := rsActDescrDeleteFile;
    atDeleteDirectory:
      Result := rsActDescrDeleteDirectory;
    atDeleteRegKey:
      Result := rsActDescrDeleteRegKey;
    atDeleteRegValue:
      Result := rsActDescrDeleteRegValue;
    atUnregSvr:
      Result := rsActDescrUnregSvr;
    atUninstallWinSvc:
      Result := rsActDescrUninstallWinSvc;
    atStopWinSvc:
      Result := rsActDescrStopWinSvc;
    atDeleteLink:
      Result := rsActDescrDeleteLink;
    atRunApp:
      Result := rsActRunApp;
  end;
end;

function StrToActionType(const Value: string): TActionType;
begin
  if Value = tagDeleteFile then
    Result := atDeleteFile
  else if Value = tagDeleteDirectory then
    Result := atDeleteDirectory
  else if Value = tagDeleteRegKey then
    Result := atDeleteRegKey
  else if Value = tagDeleteRegValue then
    Result := atDeleteRegValue
  else if Value = tagUnregSvr then
    Result := atUnregSvr
  else if Value = tagUninstallWinSvc then
    Result := atUninstallWinSvc
  else if Value = tagStopWinSvc then
    Result := atStopWinSvc
  else if Value = tagDeleteLink then
    Result := atDeleteLink
  else if Value = tagRunApp then
    Result := atRunApp
  else
    raise Exception.Create(rsInvalidAction);
end;

function ActionTypeToStr(Value: TActionType): string;
begin
  case Value of
    atDeleteFile:
      Result := tagDeleteFile;
    atDeleteDirectory:
      Result := tagDeleteDirectory;
    atDeleteRegKey:
      Result := tagDeleteRegKey;
    atDeleteRegValue:
      Result := tagDeleteRegValue;
    atUnregSvr:
      Result := tagUnregSvr;
    atUninstallWinSvc:
      Result := tagUninstallWinSvc;
    atStopWinSvc:
      Result := tagStopWinSvc;
    atDeleteLink:
      Result := tagDeleteLink;
    atRunApp:
      Result := tagRunApp;
  end;
end;

function GetProgramName: string;
var
  FilePath: string;
begin
  FilePath := GetFullFilePath(ParamStr(1));
  Result := LoadXMLDocument(FilePath).DocumentElement.Attributes
    [tagProgramName];
end;

{ TUninstalActions }

function TUninstalActions.Add: TUninstallAction;
begin
  Result := TUninstallAction(inherited Add);
end;

procedure TUninstalActions.AddAction(AActionType: TActionType;
  const AParam1, AParam2, AParam3: string);
var
  Action: TUninstallAction;
begin
  Action := TUninstallAction(inherited Add);
  Action.ActionType := AActionType;
  Action.Param1 := AParam1;
  Action.Param2 := AParam2;
  Action.Param3 := AParam3;
end;

procedure TUninstalActions.AddAdditionalComponent(const AFileName,
  AProgramName: string);
begin
  FAdditionalComponents.Add(AFileName + FAdditionalComponents.NameValueSeparator
    + AProgramName);
end;

constructor TUninstalActions.Create;
begin
  inherited Create(TUninstallAction);
  FAdditionalComponents := TStringList.Create;
  FFileName := '';
  FProgramName := '';
  FProgramId := '';
end;

procedure TUninstalActions.DeleteUninstLogFile;
var
  FilePath: string;
begin
  FilePath := GetFullFilePath(FFileName);

  if not TFile.Exists(FilePath) then
    Exit;

  TFile.Delete(FilePath);
end;

destructor TUninstalActions.Destroy;
begin
  FAdditionalComponents.Free;
  inherited;
end;

function TUninstalActions.GetAddComponentFileName(Index: Integer): string;
begin
  Result := FAdditionalComponents.Names[Index];
end;

function TUninstalActions.GetAddComponentProgramName(Index: Integer): string;
begin
  Result := FAdditionalComponents.ValueFromIndex[Index];
end;

function TUninstalActions.GetItem(Index: Integer): TUninstallAction;
begin
  Result := TUninstallAction(Items[Index]);
end;

function TUninstalActions.GetProgramId: string;
begin
  if FProgramId.IsEmpty then
    Result := FProgramName
  else
    Result := FProgramId;
end;

procedure TUninstalActions.LoadFromFile;
var
  FilePath: string;
begin
  FilePath := GetFullFilePath(FFileName);

  if not TFile.Exists(FilePath) then
    raise Exception.Create(rsFileNotFound + ': ' + FilePath);

  XMLDeserialize(LoadXMLDocument(FilePath).DocumentElement);
end;

procedure TUninstalActions.RegisterApp(const InstallLocation,
  AppIcon: string);
var
  Key: string;
  Reg: TRegistry;
  _AppIcon: string;
begin
  if Length(AppIcon) = 0 then
    _AppIcon := GetUninstallAppExe
  else
    _AppIcon := AppIcon;
  Key := UninstalKey + GetProgramId;

  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey(Key, True) then
    begin
      Reg.WriteString('DisplayName', FProgramName);
      Reg.WriteString('DisplayIcon', _AppIcon);
      Reg.WriteString('UnInstallString', GetUninstallAppExe + ' ' + FFileName);
      Reg.WriteString('DisplayVersion', GetFileVerStr);
      Reg.WriteString('Publisher', rsPublisher);
      Reg.WriteString('InstallLocation', InstallLocation);
    end
    else
    begin
      RaiseLastOSError;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TUninstalActions.SaveToFile;
var
  XMLDoc: IXMLDocument;
  FilePath: string;
begin
  FilePath := GetFullFilePath(FFileName);

  XMLDoc := NewXMLDocument;
  XMLSerialize(XMLDoc.AddChild(tagUninstall));

  XMLDoc.SaveToFile(FilePath);
end;

procedure TUninstalActions.UnregisterApp;
var
  Key: string;
  Reg: TRegistry;
begin
  Key := UninstalKey + GetProgramId;

  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey(Key, True) then
    begin
      Reg.CloseKey;
      Reg.DeleteKey(Key);
    end
    else
      RaiseLastOSError;
  finally
    Reg.Free;
  end;
end;

function TUninstalActions.XMLDeserialize(Root: IXMLNode): IXMLNode;
var
  I: Integer;
  Action: TUninstallAction;
  xmlNode: IXMLNode;
  ComponentFileName, ComponentProgramName: string;
begin
  FAdditionalComponents.Clear;
  Clear;

  FProgramId := Root.Attributes[tagProgramId];
  FProgramName := Root.Attributes[tagProgramName];

  xmlNode := selectNode(Root, './' + tagAdditionalComponents);
  for I := 0 to xmlNode.ChildNodes.Count - 1 do
  begin
    ComponentFileName := VarToStringDef(xmlNode.ChildNodes[I].NodeValue, '');
    ComponentProgramName := VarToStringDef(xmlNode.ChildNodes[I].Attributes
      [tagProgramName], '');
    if UninstallFileExist(ComponentFileName) then
      AddAdditionalComponent(ComponentFileName, ComponentProgramName);
  end;

  xmlNode := selectNode(Root, './' + tagActions);
  for I := 0 to xmlNode.ChildNodes.Count - 1 do
  begin
    Action := Add;
    Action.TypeAsString := xmlNode.ChildNodes[I].ChildValues[tagActionType];
    Action.Param1 := VarToStringDef(xmlNode.ChildNodes[I].ChildValues
      [tagParam1], '');
    Action.Param2 := VarToStringDef(xmlNode.ChildNodes[I].ChildValues
      [tagParam2], '');
    Action.Param3 := VarToStringDef(xmlNode.ChildNodes[I].ChildValues
      [tagParam3], '');
  end;
end;

function TUninstalActions.XMLSerialize(Root: IXMLNode): IXMLNode;
var
  I: Integer;
  xmlNode, NodeActions: IXMLNode;
  Action: TUninstallAction;
begin
  Root.Attributes[tagProgramId] := GetProgramId;
  Root.Attributes[tagProgramName] := FProgramName;

  xmlNode := Root.AddChild(tagAdditionalComponents);
  for I := 0 to FAdditionalComponents.Count - 1 do
    AddChildNode(xmlNode, tagComponent, FAdditionalComponents.Names[I])
      .Attributes[tagProgramName] := FAdditionalComponents.ValueFromIndex[I];

  NodeActions := Root.AddChild(tagActions);

  for I := 0 to Count - 1 do
  begin
    Action := Item[I];
    xmlNode := NodeActions.AddChild(tagAction);
    AddChildNode(xmlNode, tagActionType, Action.TypeAsString);
    AddChildNode(xmlNode, tagParam1, Action.Param1);
    AddChildNode(xmlNode, tagParam2, Action.Param2);
    AddChildNode(xmlNode, tagParam3, Action.Param3);
  end;
end;

{ TUninstallAction }

procedure TUninstallAction.ActDeleteDirectory(const ADirName: string);
begin
  if not TDirectory.Exists(ADirName) then
    Exit;

  TDirectory.Delete(ADirName, True);
end;

procedure TUninstallAction.ActDeleteFile(const AFileName: string);
begin
  if not TFile.Exists(AFileName) then
    Exit;

  TFile.Delete(AFileName);
end;

procedure TUninstallAction.ActDeleteLink(const ALinkName: string);
begin
  ActDeleteFile(ALinkName);
end;

procedure TUninstallAction.ActDeleteRegKey(const RootKey, RegKey: string);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := StrToRootKey(RootKey);
    Reg.DeleteKey(RegKey);
  finally
    Reg.Free;
  end;
end;

procedure TUninstallAction.ActDeleteRegValue(const RootKey, RegKey,
  ValueName: string);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := StrToRootKey(RootKey);
    if Reg.OpenKey(RegKey, False) and Reg.ValueExists(ValueName) then
      Reg.DeleteValue(ValueName);
  finally
    Reg.Free;
  end;
end;

procedure TUninstallAction.ActRunApp(const AppName, Param: string);
begin
  if ExecuteApplication(AppName, Param, False, False, True) = INVALID_HANDLE_VALUE
  then
    RaiseLastOSError;

  if ExitCode <> 0 then
    raise Exception.Create(rsRunAppNotSuccessfull);
end;

procedure TUninstallAction.ActStopWinSvc(const SvcName: string);
begin
  if not ServiceStop('', SvcName) then
    raise Exception.Create(rsCantDeleteSvc + ' ' + SvcName);
end;

procedure TUninstallAction.ActUninstallWinSvc(const SvcName: string);
begin
  ServiceStop('', SvcName);
  if not ServiceUninstall('', SvcName) then
    raise Exception.Create(rsCantDeleteSvc + ' ' + SvcName);
end;

procedure TUninstallAction.ActUnregSvr(const SvrPath: string);
begin
  RegisterCOM(SvrPath, True);
end;

function TUninstallAction.GetTypeAsString: string;
begin
  Result := ActionTypeToStr(FActionType);
end;

procedure TUninstallAction.Run;
begin
  case ActionType of
    atDeleteFile:
      ActDeleteFile(Param1);
    atDeleteDirectory:
      ActDeleteDirectory(Param1);
    atDeleteRegKey:
      ActDeleteRegKey(Param1, Param2);
    atDeleteRegValue:
      ActDeleteRegValue(Param1, Param2, Param3);
    atUnregSvr:
      ActUnregSvr(Param1);
    atUninstallWinSvc:
      ActUninstallWinSvc(Param1);
    atStopWinSvc:
      ActStopWinSvc(Param1);
    atDeleteLink:
      ActDeleteLink(Param1);
    atRunApp:
      ActRunApp(Param1, Param2);
  end;
end;

procedure TUninstallAction.SetTypeAsString(Value: string);
begin
  FActionType := StrToActionType(Value);
end;

procedure ExtractRes(ResType: Pchar; const ResName, FileName: String);
var
  Res: TResourceStream;
begin
  Res := TResourceStream.Create(hInstance, ResName, Pchar(ResType));
  Res.SaveToFile(FileName);
  Res.Free;
end;

procedure ExtractUninstallAppFromResource;
var
  VerOld, VerNew: TVersionInfo;
  ExeName, TmpName: string;
begin
  ExeName := GetUninstallAppExe;

  if not TFile.Exists(ExeName) then
  begin
    ExtractRes('EXEFILE', tagUninstall, ExeName);
    Exit;
  end;

  // Нужно сравнить версии
  TmpName := GetUninstallAppDir + UninstallAppExeNameTmp;

  ExtractRes('EXEFILE', tagUninstall, TmpName);

  VerOld := GetFileVer(ExeName);
  VerNew := GetFileVer(TmpName);

  if CompareFileVer(VerOld, VerNew) >= 0 then
  begin
    TFile.Delete(TmpName);
    Exit;
  end;

  TFile.Delete(ExeName);
  TFile.Move(TmpName, ExeName);
end;

end.
