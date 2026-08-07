unit DAT.Runtime.Preference;

interface

type
  TLanguagePreference = class
  public
    class function ReadLanguageCode(const AFileName,
      ADefaultLanguageCode: string): string; static;
    class procedure WriteLanguageCode(const AFileName,
      ALanguageCode: string); static;
  end;

implementation

uses
  System.IniFiles,
  System.IOUtils,
  System.SysUtils;

class function TLanguagePreference.ReadLanguageCode(const AFileName,
  ADefaultLanguageCode: string): string;
var
  IniFile: TIniFile;
begin
  Result := ADefaultLanguageCode;
  if not TFile.Exists(AFileName) then
    Exit;
  IniFile := TIniFile.Create(AFileName);
  try
    Result := IniFile.ReadString('Language', 'Selected',
      ADefaultLanguageCode);
  finally
    IniFile.Free;
  end;
end;

class procedure TLanguagePreference.WriteLanguageCode(const AFileName,
  ALanguageCode: string);
var
  DirectoryName: string;
  IniFile: TIniFile;
begin
  DirectoryName := TPath.GetDirectoryName(AFileName);
  if DirectoryName <> '' then
    TDirectory.CreateDirectory(DirectoryName);
  IniFile := TIniFile.Create(AFileName);
  try
    IniFile.WriteString('Language', 'Selected', ALanguageCode);
  finally
    IniFile.Free;
  end;
end;

end.
