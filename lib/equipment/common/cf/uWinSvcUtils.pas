unit uWinSvcUtils;

interface

uses Winapi.Windows;

type
  LPSERVICE_DESCRIPTIONA = ^SERVICE_DESCRIPTIONA;
{$EXTERNALSYM LPSERVICE_DESCRIPTIONA}

  _SERVICE_DESCRIPTIONA = record
    lpDescription: LPSTR;
  end;
{$EXTERNALSYM _SERVICE_DESCRIPTIONA}

  SERVICE_DESCRIPTIONA = _SERVICE_DESCRIPTIONA;
{$EXTERNALSYM SERVICE_DESCRIPTIONA}
  TServiceDescriptionA = SERVICE_DESCRIPTIONA;
  PServiceDescriptionA = LPSERVICE_DESCRIPTIONA;

  //
  // Service description string
  //

  LPSERVICE_DESCRIPTIONW = ^SERVICE_DESCRIPTIONW;
{$EXTERNALSYM LPSERVICE_DESCRIPTIONW}

  _SERVICE_DESCRIPTIONW = record
    lpDescription: LPWSTR;
  end;
{$EXTERNALSYM _SERVICE_DESCRIPTIONW}

  SERVICE_DESCRIPTIONW = _SERVICE_DESCRIPTIONW;
{$EXTERNALSYM SERVICE_DESCRIPTIONW}
  TServiceDescriptionW = SERVICE_DESCRIPTIONW;
  PServiceDescriptionW = LPSERVICE_DESCRIPTIONW;

  // {$IFDEF UNICODE}
  SERVICE_DESCRIPTION = SERVICE_DESCRIPTIONW;
{$EXTERNALSYM SERVICE_DESCRIPTION}
  LPSERVICE_DESCRIPTION = LPSERVICE_DESCRIPTIONW;
{$EXTERNALSYM LPSERVICE_DESCRIPTION}
  TServiceDescription = TServiceDescriptionW;
  PServiceDescription = PServiceDescriptionW;
  // {$ELSE}
  // SERVICE_DESCRIPTION = SERVICE_DESCRIPTIONA;
  // {$EXTERNALSYM SERVICE_DESCRIPTION}
  // LPSERVICE_DESCRIPTION = LPSERVICE_DESCRIPTIONA;
  // {$EXTERNALSYM LPSERVICE_DESCRIPTION}
  // TServiceDescription = TServiceDescriptionA;
  // PServiceDescription = PServiceDescriptionA;
  // {$ENDIF}


  // const
  // StartStopScvTimeout = 60000;

procedure ServiceCreateEventLog(ExecutablePath, aServiceName: string);
function ServiceSetDescription(const aMachine, aServiceName,
  aDescription: string): Boolean;
function ServiceInstall(ExecutablePath, aMachine, aServiceName: string;
  const aDisplayName: string = ''): Boolean;
function ServiceUninstall(aMachine, aServiceName: string): Boolean;
function ServiceStart(aMachine, aServiceName: string;
  out aErrorDescription: string): Boolean; overload;
function ServiceStart(aMachine, aServiceName: string): Boolean; overload;
function ServiceStop(aMachine, aServiceName: string): Boolean;
function ServiceGetStatus(sMachine, sService: string): DWord;

implementation

uses Winapi.WinSvc, System.Win.Registry, System.SysUtils;

// procedure ProcessMessages;
// var
// Msg: TMsg;
//
// function ProcessMessage(var Msg: TMsg): Boolean;
// begin
// Result := False;
// try
// if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
// begin
// Result := True;
// TranslateMessage(Msg);
// DispatchMessage(Msg);
// end;
// except
// end;
// end;
//
// begin
// while ProcessMessage(Msg) do;
// end;

procedure ServiceCreateEventLog(ExecutablePath, aServiceName: string);
var
  Reg: TRegIniFile;
begin
  Reg := TRegIniFile.Create(KEY_ALL_ACCESS);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    // Создаём системный лог для себя
    Reg.OpenKey('\SYSTEM\CurrentControlSet\Services\Eventlog\Application\' +
      aServiceName, True);
    Reg.WriteString('\SYSTEM\CurrentControlSet\Services\Eventlog\Application\' +
      aServiceName, 'EventMessageFile', ExecutablePath);
    TRegistry(Reg).WriteInteger('TypesSupported', 7);
  finally
    Reg.Free;
  end;
end;

function ServiceSetDescription(const aMachine, aServiceName,
  aDescription: string): Boolean;
var
  h_manager, h_service: SC_HANDLE;
  Desc: TServiceDescription;
begin
  Result := False;

  h_manager := OpenSCManager(PChar(aMachine), nil, SC_MANAGER_ALL_ACCESS);
  if h_manager > 0 then
  begin
    h_service := OpenService(h_manager, PChar(aServiceName),
      STANDARD_RIGHTS_REQUIRED or SERVICE_CHANGE_CONFIG);
    if h_service > 0 then
    begin
      Desc.lpDescription := PChar(aDescription);

      Result := ChangeServiceConfig2(h_service,
        SERVICE_CONFIG_DESCRIPTION, @Desc);
      CloseServiceHandle(h_service);
    end;
    CloseServiceHandle(h_manager);
  end;
end;

function ServiceInstall(ExecutablePath, aMachine, aServiceName: string;
  const aDisplayName: string = ''): Boolean;
var
  hNewService, hSCMgr: SC_HANDLE;
  DisplayName: string;
begin
  Result := False;
  if Length(aDisplayName) = 0 then
    DisplayName := aServiceName
  else
    DisplayName := aDisplayName;

  hSCMgr := OpenSCManager(PChar(aMachine), nil, SC_MANAGER_CREATE_SERVICE);
  if (hSCMgr <> 0) then
  begin
    hNewService := CreateService(hSCMgr, PChar(aServiceName),
      PChar(DisplayName), STANDARD_RIGHTS_REQUIRED, SERVICE_WIN32_OWN_PROCESS,
      SERVICE_AUTO_START, SERVICE_ERROR_NORMAL, PChar(ExecutablePath), nil, nil,
      nil, nil, nil);

    Result := hNewService <> 0;

    if Result then
      CloseServiceHandle(hNewService);
    CloseServiceHandle(hSCMgr);
  end;
end;

function ServiceUninstall(aMachine, aServiceName: string): Boolean;
var
  Service, SCManager: SC_HANDLE;
  Stat: DWord;
begin
  Stat := ServiceGetStatus(aMachine, aServiceName);
  Result := Stat = 0;
  if Result then
    Exit
  else if Stat <> SERVICE_STOPPED then
  begin
    Result := ServiceStop(aMachine, aServiceName);
    if not Result then
      Exit;
  end;

  Result := False;

  SCManager := OpenSCManager(PChar(aMachine), nil, SC_MANAGER_ALL_ACCESS);

  if SCManager <> 0 then
  begin
    Service := OpenService(SCManager, PChar(aServiceName), SERVICE_ALL_ACCESS);
    if Service <> 0 then
    begin
      Result := DeleteService(Service);
      CloseServiceHandle(Service);
    end;
    CloseServiceHandle(SCManager);
  end;

  // EndTime := GetTickCount + StartStopScvTimeout;
  // while GetTickCount < EndTime do
  // begin
  // Result := ServiceGetStatus(aMachine, aServiceName) = 0;
  // if Result then
  // Break;
  // Sleep(2000);
  // ProcessMessages;
  // end;
end;

function ServiceStart(aMachine, aServiceName: string;
  out aErrorDescription: string): Boolean;
// aMachine это UNC путь, либо локальный компьютер если пусто
var
  h_manager, h_svc: SC_HANDLE;
  svc_status: TServiceStatus;
  Temp: PChar;
  dwCheckPoint: DWord;
begin
  aErrorDescription := '';
  svc_status.dwCurrentState := SERVICE_STOPPED;

  h_manager := OpenSCManager(PChar(aMachine), nil, SC_MANAGER_CONNECT);
  if h_manager > 0 then
  begin
    try
      h_svc := OpenService(h_manager, PChar(aServiceName), SERVICE_START or
        SERVICE_QUERY_STATUS);
      if h_svc > 0 then
      begin
        try
          if (QueryServiceStatus(h_svc, svc_status)) then
          begin
            Result := svc_status.dwCurrentState = SERVICE_RUNNING;
            if Result then
              Exit;
          end;

          Temp := nil;
          if (StartService(h_svc, 0, Temp)) then
          begin
            if (QueryServiceStatus(h_svc, svc_status)) then
            begin
              while (SERVICE_RUNNING <> svc_status.dwCurrentState) do
              begin
                dwCheckPoint := svc_status.dwCheckPoint;
                Sleep(svc_status.dwWaitHint);
                if (not QueryServiceStatus(h_svc, svc_status)) then
                begin
                  aErrorDescription := SysErrorMessage(GetLastError);
                  Break;
                end;
                if (svc_status.dwCheckPoint <= dwCheckPoint) then
                begin
                  // QueryServiceStatus не увеличивает dwCheckPoint
                  Break;
                end;
              end;
            end
            else
              aErrorDescription := SysErrorMessage(GetLastError);
          end
          else
            aErrorDescription := SysErrorMessage(GetLastError);
        finally
          CloseServiceHandle(h_svc);
        end;
      end
      else
        aErrorDescription := SysErrorMessage(GetLastError);
    finally
      CloseServiceHandle(h_manager);
    end;
  end;

  Result := SERVICE_RUNNING = svc_status.dwCurrentState;
end;

function ServiceStart(aMachine, aServiceName: string): Boolean; overload;
  deprecated;
var
  LErrorDescriprion: string;
begin
  Result := ServiceStart(aMachine, aServiceName, LErrorDescriprion);
end;

function ServiceStop(aMachine, aServiceName: string): Boolean;
// aMachine это UNC путь, либо локальный компьютер если пусто
var
  h_manager, h_svc: SC_HANDLE;
  svc_status: TServiceStatus;
  dwCheckPoint: DWord;
begin
  svc_status.dwCurrentState := 0;

  h_manager := OpenSCManager(PChar(aMachine), nil, SC_MANAGER_CONNECT);
  if h_manager > 0 then
  begin
    h_svc := OpenService(h_manager, PChar(aServiceName), SERVICE_STOP or
      SERVICE_QUERY_STATUS);
    if h_svc > 0 then
    begin
      if (ControlService(h_svc, SERVICE_CONTROL_STOP, svc_status)) then
      begin
        if (QueryServiceStatus(h_svc, svc_status)) then
        begin
          while (SERVICE_STOPPED <> svc_status.dwCurrentState) do
          begin
            dwCheckPoint := svc_status.dwCheckPoint;
            Sleep(svc_status.dwWaitHint);
            if (not QueryServiceStatus(h_svc, svc_status)) then
            begin
              // couldn't check status
              Break;
            end;
            if (svc_status.dwCheckPoint < dwCheckPoint) then
              Break;
          end;
        end;
      end;
      CloseServiceHandle(h_svc);
    end;
    CloseServiceHandle(h_manager);
  end;

  Result := SERVICE_STOPPED = svc_status.dwCurrentState;
end;

function ServiceGetStatus(sMachine, sService: string): DWord;
var
  h_manager, h_service: SC_HANDLE;
  SERVICE_STATUS: TServiceStatus;
  // hStat: DWord;
begin
  Result := 0;

  h_manager := OpenSCManager(PChar(sMachine), nil, SC_MANAGER_CONNECT);
  if h_manager > 0 then
  begin
    h_service := OpenService(h_manager, PChar(sService), SERVICE_QUERY_STATUS);
    if h_service > 0 then
    begin
      if (QueryServiceStatus(h_service, SERVICE_STATUS)) then
        Result := SERVICE_STATUS.dwCurrentState;
      CloseServiceHandle(h_service);
    end;
    CloseServiceHandle(h_manager);
  end;
end;

end.
