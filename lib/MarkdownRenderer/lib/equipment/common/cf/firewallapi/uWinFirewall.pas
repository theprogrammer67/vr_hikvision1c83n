unit uWinFirewall;

interface

// Common
procedure AddExceptionToFirewall(const Caption, Executable: string);
procedure OpenPortFirewall(const Caption: string; PortNumber: Integer);

// Windows Vista and higer
procedure AddExceptionToFirewall2(const Caption, Executable: string);
procedure OpenPortFirewall2(const Caption: string; PortNumber: Integer);

// Windows XP
function IsWindowsFirewallServicePresent1: Boolean;
procedure OpenPortFirewall1(const Caption: string; PortNumber: cardinal);
procedure AddExceptionToFirewall1(const Caption, Executable: string);

implementation

uses System.SysUtils, System.Win.ComObj, NetFwTypeLib_TLB,
  Winapi.Windows, Winapi.WinSvc, System.Variants;

function IsWindowsFirewallServicePresent1: Boolean;
var
  scm, svc: SC_HANDLE;
  sz: DWORD;
  pConfig: LPQUERY_SERVICE_CONFIG;
  spPath: array [0 .. 255] of Char;
  ptr: Pchar;
begin
  Result := False;
  if Win32Platform <> VER_PLATFORM_WIN32_NT then
    Exit;
  scm := Winapi.WinSvc.OpenSCManager(nil, nil, GENERIC_READ);
  try
    if scm > 0 then
    begin
      svc := Winapi.WinSvc.OpenService(scm, Pchar('SharedAccess'),
        SERVICE_QUERY_CONFIG); // please don't change the name of the service.
      if svc > 0 then
      begin
        Winapi.WinSvc.QueryServiceConfig(svc, nil, 0, sz);
        if GetLastError = ERROR_INSUFFICIENT_BUFFER then
        begin
          pConfig := LPQUERY_SERVICE_CONFIG(GlobalAlloc(GMEM_FIXED, sz));
          if Assigned(pConfig) then
          begin
            if Winapi.WinSvc.QueryServiceConfig(svc, pConfig, sz, sz) then
              Result := (pConfig.dwStartType < SERVICE_DEMAND_START);
            GlobalFree(HGLOBAL(pConfig));
          end;
        end;
      end;
      Winapi.WinSvc.CloseServiceHandle(svc);
    end;
  finally
    Winapi.WinSvc.CloseServiceHandle(scm);
  end;

  if Result then // check if HNetCfg.dll is located somewhere on system
    Result := (Winapi.Windows.SearchPath(nil, Pchar('hnetcfg.dll'), nil, 255,
      spPath, ptr) > 0) and (FileExists(StrPas(spPath)));
end;

function GetVistaPolicyRules(var Rules: OleVariant): Boolean;
var
  fwPolicy2: OleVariant;
begin
  Result := (Win32Platform = VER_PLATFORM_WIN32_NT) and
    (Win32MajorVersion >= 6);

  if Result then
    try
      try
        fwPolicy2 := CreateOleObject('HNetCfg.FwPolicy2');
        Rules := fwPolicy2.Rules;
      except
        Result := False;
      end;
    finally
      fwPolicy2 := Unassigned;
    end;
end;

procedure AddExceptionToFirewall2(const Caption, Executable: string);
var
  RulesObject, NewRule: OleVariant;
begin
  if GetVistaPolicyRules(RulesObject) then
    try
      NewRule := CreateOleObject('HNetCfg.FWRule');
      NewRule.Name := Caption;
      NewRule.Description := Caption;
      NewRule.Applicationname := Executable;
      NewRule.Protocol := NET_FW_IP_PROTOCOL_TCP;
      NewRule.Enabled := True;
      NewRule.Profiles := NET_FW_PROFILE2_ALL;
      NewRule.Action := NET_FW_ACTION_ALLOW;

      RulesObject.Add(NewRule);
    finally
      RulesObject := Unassigned;
    end;
end;

procedure OpenPortFirewall2(const Caption: string; PortNumber: Integer);
var
  RulesObject, NewRule: OleVariant;
begin
  if GetVistaPolicyRules(RulesObject) then
    try
      NewRule := CreateOleObject('HNetCfg.FWRule');
      NewRule.Name := Caption;
      NewRule.Description := Caption;
      NewRule.Protocol := NET_FW_IP_PROTOCOL_TCP;
      NewRule.Profiles := NET_FW_PROFILE2_ALL;
      NewRule.Action := NET_FW_ACTION_ALLOW;
      NewRule.Enabled := True;
      NewRule.InterfaceTypes := 'All';
      NewRule.LocalPorts := IntToStr(PortNumber);
      NewRule.Direction := NET_FW_RULE_DIR_IN;

      RulesObject.Add(NewRule);
    finally
      RulesObject := Unassigned;
    end;
end;

function GetXPFirewallProfile(var Profile: OleVariant): Boolean;
var
  fwMgr: OleVariant;
begin
  Result := (Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion > 5)
    or ((Win32MajorVersion = 5) and (Win32MinorVersion > 0));
  if Result then // need Windows XP at least
    try
      try
        fwMgr := CreateOleObject('HNetCfg.FwMgr');
        Profile := fwMgr.LocalPolicy.CurrentProfile;
      except
        Result := False;
      end;
    finally
      fwMgr := Unassigned;
    end;
end;

procedure AddExceptionToFirewall1(const Caption, Executable: string);
var
  Profile, app: OleVariant;
begin
  if GetXPFirewallProfile(Profile) then
    try
      if Profile.FirewallEnabled then
      begin
        app := CreateOleObject('HNetCfg.FwAuthorizedApplication');
        try
          app.ProcessImageFileName := Executable;
          app.Name := Caption;
          app.Scope := NET_FW_SCOPE_ALL;
          app.IpVersion := NET_FW_IP_VERSION_ANY;
          app.Enabled := True;
          Profile.AuthorizedApplications.Add(app);
        finally
          app := Unassigned;
        end;
      end;
    finally
      Profile := Unassigned;
    end;
end;

procedure OpenPortFirewall1(const Caption: string; PortNumber: cardinal);
var
  Profile, port: OleVariant;
begin
  if GetXPFirewallProfile(Profile) then
    try
      if Profile.FirewallEnabled then
      begin
        port := CreateOleObject('HNetCfg.FWOpenPort');
        port.Name := Caption;
        port.Protocol := NET_FW_IP_PROTOCOL_TCP;
        port.port := PortNumber;
        port.Scope := NET_FW_SCOPE_ALL;
        port.Enabled := True;
        Profile.GloballyOpenPorts.Add(port);
      end;
    finally
      port := Unassigned;
      Profile := Unassigned;
    end;
end;

procedure AddExceptionToFirewall(const Caption, Executable: string);
begin
  if TOSVersion.Major = 5 then
    AddExceptionToFirewall1(Caption, Executable)
  else
    AddExceptionToFirewall2(Caption, Executable);
end;

procedure OpenPortFirewall(const Caption: string; PortNumber: Integer);
begin
  if TOSVersion.Major = 5 then
    OpenPortFirewall1(Caption, PortNumber)
  else
    OpenPortFirewall2(Caption, PortNumber);
end;

end.
