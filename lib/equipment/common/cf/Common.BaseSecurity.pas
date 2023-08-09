unit Common.BaseSecurity;

interface

uses Windows, SysUtils, Classes;
{$Z4}

const
  ANYSIZE_ARRAY = 1;
  OBJECT_INHERIT_ACE = ($1);
  SUB_CONTAINERS_AND_OBJECTS_INHERIT = $3;

type
  LPVOID = Pointer;

  SE_OBJECT_TYPE = (SE_UNKNOWN_OBJECT_TYPE, SE_FILE_OBJECT, SE_SERVICE,
    SE_PRINTER, SE_REGISTRY_KEY, SE_LMSHARE, SE_KERNEL_OBJECT, SE_WINDOW_OBJECT,
    SE_DS_OBJECT, SE_DS_OBJECT_ALL, SE_PROVIDER_DEFINED_OBJECT,
    SE_WMIGUID_OBJECT, SE_REGISTRY_WOW64_32KEY);

  ACCESS_MODE = (NOT_USED_ACCESS, GRANT_ACCESS, SET_ACCESS, DENY_ACCESS,
    REVOKE_ACCESS, SET_AUDIT_SUCCESS, SET_AUDIT_FAILURE);

  TRUSTEE_FORM = (TRUSTEE_IS_SID, TRUSTEE_IS_NAME, TRUSTEE_BAD_FORM,
    TRUSTEE_IS_OBJECTS_AND_SID, TRUSTEE_IS_OBJECTS_AND_NAME);

  TRUSTEE_TYPE = (TRUSTEE_IS_UNKNOWN, TRUSTEE_IS_USER, TRUSTEE_IS_GROUP,
    TRUSTEE_IS_DOMAIN, TRUSTEE_IS_ALIAS, TRUSTEE_IS_WELL_KNOWN_GROUP,
    TRUSTEE_IS_DELETED, TRUSTEE_IS_INVALID, TRUSTEE_IS_COMPUTER);

  _MULTIPLE_TRUSTEE_OPERATION = (NO_MULTIPLE_TRUSTEE, TRUSTEE_IS_IMPERSONATE);
  MULTIPLE_TRUSTEE_OPERATION = _MULTIPLE_TRUSTEE_OPERATION;

  PTRUSTEE_W = ^TRUSTEE_W;

  _TRUSTEE_W = record
    pMultipleTrustee: PTRUSTEE_W;
    MultipleTrusteeOperation: MULTIPLE_TRUSTEE_OPERATION;
    TrusteeForm: TRUSTEE_FORM;
    TrusteeType: TRUSTEE_TYPE;
    ptstrName: LPWSTR;
  end;

  TRUSTEE_W = record
    pMultipleTrustee: PTRUSTEE_W;
    MultipleTrusteeOperation: MULTIPLE_TRUSTEE_OPERATION;
    TrusteeForm: TRUSTEE_FORM;
    TrusteeType: TRUSTEE_TYPE;
    ptstrName: LPWSTR;
  end;

  PEXPLICIT_ACCESS_W = ^EXPLICIT_ACCESS;

  EXPLICIT_ACCESS = record
    grfAccessPermissions: DWORD;
    grfAccessMode: ACCESS_MODE;
    grfInheritance: DWORD;
    Trustee: TRUSTEE_W;
  end;

  ACE_HEADER = record
    AceType: Byte;
    AceFlags: Byte;
    AceSize: Word;
  end;

  PACCESS_ALLOWED_ACE = ^ACCESS_ALLOWED_ACE;

  ACCESS_ALLOWED_ACE = record
    Header: ACE_HEADER;
    Mask: ACCESS_MASK;
    SidStart: DWORD;
  end;

  PSid = ^SID;

  _SID = record
    Revision: Byte;
    SubAuthorityCount: Byte;
    IdentifierAuthority: SID_IDENTIFIER_AUTHORITY;
    SubAuthority: array [0 .. ANYSIZE_ARRAY - 1] of DWORD;
  end;
{$EXTERNALSYM _SID}

  SID = _SID;
{$EXTERNALSYM SID}
  PPSID = ^PSid;
{$NODEFINE PPSID}
  TSid = SID;

  PACL = ^ACL;
{$EXTERNALSYM PACL}

  _ACL = record
    AclRevision: Byte;
    Sbz1: Byte;
    AclSize: Word;
    AceCount: Word;
    Sbz2: Word;
  end;
{$EXTERNALSYM _ACL}

  ACL = _ACL;
{$EXTERNALSYM ACL}
  TAcl = ACL;

  PPACL = ^PACL;

  PSID_IDENTIFIER_AUTHORITY = ^SID_IDENTIFIER_AUTHORITY;
{$EXTERNALSYM PSID_IDENTIFIER_AUTHORITY}

  _SID_IDENTIFIER_AUTHORITY = record
    Value: array [0 .. 5] of Byte;
  end;
{$EXTERNALSYM _SID_IDENTIFIER_AUTHORITY}

  SID_IDENTIFIER_AUTHORITY = _SID_IDENTIFIER_AUTHORITY;

  EXPLICIT_ACCESS_W = record
    grfAccessPermissions: DWORD;
    grfAccessMode: ACCESS_MODE;
    grfInheritance: DWORD;
    Trustee: TRUSTEE_W;
  end;
  {$EXTERNALSYM EXPLICIT_ACCESS_W}
  PEXPLICIT_ACCESS_ = PEXPLICIT_ACCESS_W;

const
  SECURITY_WORLD_SID_AUTHORITY: _SID_IDENTIFIER_AUTHORITY =
    (Value: (0, 0, 0, 0, 0, 1));
  SECURITY_WORLD_RID = ($00000000);

procedure SetFullAccess(Path: string);
procedure AddSecurity(const Folder, User: WideString);

function AllocateAndInitializeSid(pIdentifierAuthority
  : PSID_IDENTIFIER_AUTHORITY; SubAuthorityCount: Byte;
  nSubAuthority0, nSubAuthority1, nSubAuthority2, nSubAuthority3,
  nSubAuthority4, nSubAuthority5, nSubAuthority6, nSubAuthority7: DWORD;
  var PSid: PSid): BOOL; stdcall;

function GetNamedSecurityInfo(pObjectName: LPWSTR; ObjectType: SE_OBJECT_TYPE;
  SecurityInfo: SECURITY_INFORMATION; ppsidOwner, ppsidGroup: PPSID;
  ppDacl, ppSacl: PPACL; var ppSecurityDescriptor: PSECURITY_DESCRIPTOR)
  : DWORD; stdcall;

function GetAce(PACL: PACL; dwAceIndex: DWORD; var pAce: LPVOID): BOOL; stdcall;

function SetEntriesInAcl(cCountOfExplicitEntries: ULONG;
  pListOfExplicitEntries: PEXPLICIT_ACCESS_W; OldAcl: PACL; var NewAcl: PACL)
  : DWORD; stdcall;

function SetNamedSecurityInfo(pObjectName: LPWSTR; ObjectType: SE_OBJECT_TYPE;
  SecurityInfo: SECURITY_INFORMATION; psidOwner, psidGroup: PSid;
  pDacl, pSacl: PACL): DWORD; stdcall;

procedure BuildExplicitAccessWithName(pExplicitAccess: PEXPLICIT_ACCESS_;
          pTrusteeName: LPWSTR; AccessPermissions: DWORD; AccessMode: ACCESS_MODE;
          Ineritance: DWORD); stdcall;


implementation

function AllocateAndInitializeSid;
  external advapi32 name 'AllocateAndInitializeSid';
function GetNamedSecurityInfo; external advapi32 name 'GetNamedSecurityInfoW';
function GetAce; external advapi32 name 'GetAce';
function SetEntriesInAcl; external advapi32 name 'SetEntriesInAclW';
function SetNamedSecurityInfo; external advapi32 name 'SetNamedSecurityInfoW';
procedure BuildExplicitAccessWithName;  external advapi32 name 'BuildExplicitAccessWithNameW';

function AddAceToObjectsSecurityDescriptor(pszObjName: PWideChar;
  ObjectType: SE_OBJECT_TYPE; pszTrustee: PWideChar; TrusteeForm: TRUSTEE_FORM;
  dwAccessRights: DWORD; AccessMode: ACCESS_MODE; dwInheritance: DWORD): DWORD;
var
  pOldDACL, pNewDACL: PACL;
  pSD: PSECURITY_DESCRIPTOR;
  EA: EXPLICIT_ACCESS;
begin
  pOldDACL := nil;
  pNewDACL := nil;
  pSD := nil;

  Result := GetNamedSecurityInfo(pszObjName, ObjectType,
    DACL_SECURITY_INFORMATION, nil, nil, @pOldDACL, nil, pSD);
  if Result <> ERROR_SUCCESS then
    Exit;

  ZeroMemory(@EA, SizeOf(EXPLICIT_ACCESS));
  BuildExplicitAccessWithName(@EA, pszTrustee, dwAccessRights, AccessMode,
    dwInheritance);

  Result := SetEntriesInAcl(1, @EA, pOldDACL, pNewDACL);
  if Result <> ERROR_SUCCESS then
    Exit;

  Result := SetNamedSecurityInfo(pszObjName, ObjectType,
    DACL_SECURITY_INFORMATION, nil, nil, pNewDACL, nil);
end;

procedure SetFullAccess(Path: string);
var
  SIA: SID_IDENTIFIER_AUTHORITY;
  SID: PSid;
  OldPacl, NewPacl: PACL;
  PSd: PSECURITY_DESCRIPTOR;
  EA: EXPLICIT_ACCESS;
  I: Integer;
  P: Pointer;
  TheACE: PACCESS_ALLOWED_ACE;
  TheSID: PSid;
  Name, Domain: string;
  AlreadyGranted: Boolean;
  Error: Integer;
begin
  SIA := Common.BaseSecurity.SECURITY_WORLD_SID_AUTHORITY;
  if not AllocateAndInitializeSid(@SIA, 1, SECURITY_WORLD_RID, 0, 0, 0, 0, 0, 0,
    0, SID) then
  begin
    RaiseLastOSError;
  end;
  try
    PSd := nil;
    OldPacl := nil;
    I := GetNamedSecurityInfo(PWideChar(Path), SE_FILE_OBJECT,
      DACL_SECURITY_INFORMATION, nil, nil, @OldPacl, nil, PSd);
    try
      if I <> ERROR_SUCCESS then
      begin
        RaiseLastOSError;
      end;
      AlreadyGranted := False;
      if OldPacl = nil then
      begin
        AlreadyGranted := True;
      end;
      if not AlreadyGranted then
        for I := 0 to OldPacl^.AceCount - 1 do
        begin
          GetAce(OldPacl, I, P);
          TheACE := P;
          TheSID := PSid(@TheACE^.SidStart);
          SetLength(Name, 100);
          SetLength(Domain, 100);
          if EqualSid(SID, TheSID) then
          begin
            if TheACE^.Mask = GENERIC_ALL then
            begin
              AlreadyGranted := True;
              break;
            end;
          end;
        end;
      if not AlreadyGranted then
      begin
        FillChar(EA, SizeOf(EA), 0);
        EA.grfAccessPermissions := GENERIC_ALL;
        EA.grfAccessMode := GRANT_ACCESS;
        EA.grfInheritance := SUB_CONTAINERS_AND_OBJECTS_INHERIT or
          OBJECT_INHERIT_ACE;
        EA.Trustee.TrusteeForm := TRUSTEE_IS_SID;
        EA.Trustee.TrusteeType := TRUSTEE_IS_WELL_KNOWN_GROUP;
        EA.Trustee.ptstrName := PWideChar(SID);

        NewPacl := nil;
        Error := SetEntriesInAcl(1, @EA, OldPacl, NewPacl);
        if Error <> ERROR_SUCCESS then
        begin
          RaiseLastOSError;
        end;
        SetNamedSecurityInfo(PWideChar(Path), SE_FILE_OBJECT,
          DACL_SECURITY_INFORMATION { or PROTECTED_DACL_SECURITY_INFORMATION } ,
          nil, nil, NewPacl, nil);
      end;
    finally
      if PSd <> nil then
        LocalFree(HLOCAL(PSd))
    end;
  finally
    FreeSid(SID);
  end;
end;

procedure AddSecurity(const Folder, User: WideString);
var
  res: DWORD;
begin
  // if not DirectoryExists(Folder) then ForceDirectories(Folder);
  if DirectoryExists(Folder) then
  begin
    res := AddAceToObjectsSecurityDescriptor(PWideChar(Folder), SE_FILE_OBJECT,
      PWideChar(User), TRUSTEE_IS_NAME, GENERIC_ALL, GRANT_ACCESS,
      SUB_CONTAINERS_AND_OBJECTS_INHERIT);
    if res <> ERROR_SUCCESS then
      raise EOSError.Create(SysErrorMessage(res));
  end;
end;


end.
