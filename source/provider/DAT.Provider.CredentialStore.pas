unit DAT.Provider.CredentialStore;

interface

uses
  System.SysUtils,
  DAT.Provider.Types;

type
  ECredentialStoreError = class(Exception);

  TProviderCredentialStore = class
  private
    class function TargetName(
      const AProvider: TTranslationProvider): string; static;
  public
    class function Exists(
      const AProvider: TTranslationProvider): Boolean; static;
    class function Read(
      const AProvider: TTranslationProvider): string; static;
    class procedure Write(const AProvider: TTranslationProvider;
      const ASecret: string); static;
    class procedure Delete(
      const AProvider: TTranslationProvider); static;
  end;

implementation

uses
  Winapi.Windows;

const
  CRED_TYPE_GENERIC = 1;
  CRED_PERSIST_LOCAL_MACHINE = 2;
  ERROR_NOT_FOUND = 1168;

type
  PCredentialW = ^TCredentialW;
  PPCredentialW = ^PCredentialW;
  TCredentialW = record
    Flags: DWORD;
    CredentialType: DWORD;
    TargetName: PWideChar;
    Comment: PWideChar;
    LastWritten: TFileTime;
    CredentialBlobSize: DWORD;
    CredentialBlob: PByte;
    Persist: DWORD;
    AttributeCount: DWORD;
    Attributes: Pointer;
    TargetAlias: PWideChar;
    UserName: PWideChar;
  end;

function CredWriteW(Credential: PCredentialW;
  Flags: DWORD): BOOL; stdcall; external 'advapi32.dll';
function CredReadW(TargetName: PWideChar; CredentialType,
  Flags: DWORD; var Credential: PCredentialW): BOOL; stdcall;
  external 'advapi32.dll';
function CredDeleteW(TargetName: PWideChar; CredentialType,
  Flags: DWORD): BOOL; stdcall; external 'advapi32.dll';
procedure CredFree(Buffer: Pointer); stdcall; external 'advapi32.dll';

class function TProviderCredentialStore.TargetName(
  const AProvider: TTranslationProvider): string;
begin
  Result := 'DelphiAppTranslationStudio/Providers/' +
    TranslationProviderDisplayName(AProvider);
end;

class function TProviderCredentialStore.Exists(
  const AProvider: TTranslationProvider): Boolean;
var
  Credential: PCredentialW;
  Name: string;
begin
  Credential := nil;
  Name := TargetName(AProvider);
  Result := CredReadW(PWideChar(Name),
    CRED_TYPE_GENERIC, 0, Credential);
  if Result then
    CredFree(Credential)
  else if GetLastError <> ERROR_NOT_FOUND then
    raise ECredentialStoreError.CreateFmt(
      'Unable to query Windows Credential Manager. Error %d.',
      [GetLastError]);
end;

class function TProviderCredentialStore.Read(
  const AProvider: TTranslationProvider): string;
var
  Credential: PCredentialW;
  Name: string;
  SecretBytes: TBytes;
begin
  Result := '';
  Credential := nil;
  Name := TargetName(AProvider);
  if not CredReadW(PWideChar(Name),
    CRED_TYPE_GENERIC, 0, Credential) then
  begin
    if GetLastError = ERROR_NOT_FOUND then
      Exit;
    raise ECredentialStoreError.CreateFmt(
      'Unable to read Windows Credential Manager. Error %d.',
      [GetLastError]);
  end;
  try
    SetLength(SecretBytes, Credential.CredentialBlobSize);
    if Length(SecretBytes) > 0 then
      Move(Credential.CredentialBlob^,
        SecretBytes[0], Length(SecretBytes));
    Result := TEncoding.UTF8.GetString(SecretBytes);
  finally
    if Length(SecretBytes) > 0 then
      FillChar(SecretBytes[0], Length(SecretBytes), 0);
    CredFree(Credential);
  end;
end;

class procedure TProviderCredentialStore.Write(
  const AProvider: TTranslationProvider; const ASecret: string);
var
  Credential: TCredentialW;
  Name: string;
  SecretBytes: TBytes;
  UserName: string;
begin
  if Trim(ASecret) = '' then
    raise ECredentialStoreError.Create(
      'The provider API key cannot be blank.');
  Name := TargetName(AProvider);
  UserName := 'DelphiAppTranslationStudio';
  SecretBytes := TEncoding.UTF8.GetBytes(ASecret);
  try
    ZeroMemory(@Credential, SizeOf(Credential));
    Credential.CredentialType := CRED_TYPE_GENERIC;
    Credential.TargetName := PWideChar(Name);
    Credential.CredentialBlobSize := Length(SecretBytes);
    Credential.CredentialBlob := @SecretBytes[0];
    Credential.Persist := CRED_PERSIST_LOCAL_MACHINE;
    Credential.UserName := PWideChar(UserName);
    if not CredWriteW(@Credential, 0) then
      raise ECredentialStoreError.CreateFmt(
        'Unable to save the API key in Windows Credential Manager. Error %d.',
        [GetLastError]);
  finally
    if Length(SecretBytes) > 0 then
      FillChar(SecretBytes[0], Length(SecretBytes), 0);
  end;
end;

class procedure TProviderCredentialStore.Delete(
  const AProvider: TTranslationProvider);
var
  Name: string;
begin
  Name := TargetName(AProvider);
  if not CredDeleteW(PWideChar(Name),
    CRED_TYPE_GENERIC, 0) and (GetLastError <> ERROR_NOT_FOUND) then
    raise ECredentialStoreError.CreateFmt(
      'Unable to remove the API key from Windows Credential Manager. Error %d.',
      [GetLastError]);
end;

end.
