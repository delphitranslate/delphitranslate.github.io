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
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  DAT.Core.AtomicFile,
  DAT.Core.Diagnostics;

function SelectedLanguage(const AText: string): string;
var
  InLanguageSection: Boolean;
  Line: string;
  Lines: TStringList;
begin
  Result := '';
  InLanguageSection := False;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for Line in Lines do
    begin
      if (Length(Trim(Line)) > 1) and (Trim(Line)[1] = '[') then
      begin
        InLanguageSection := SameText(Trim(Line), '[Language]');
        Continue;
      end;
      if InLanguageSection and SameText(Copy(Trim(Line), 1, 9), 'Selected=') then
      begin
        Result := Trim(Copy(Trim(Line), 10, MaxInt));
        Exit;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

procedure ValidatePreferenceText(const AText: string);
begin
  if SelectedLanguage(AText) = '' then
    raise EConvertError.Create(
      'The language preference has no selected language.');
end;

class function TLanguagePreference.ReadLanguageCode(const AFileName,
  ADefaultLanguageCode: string): string;
var
  PreferenceText: string;
  Recovered: Boolean;
begin
  Result := ADefaultLanguageCode;
  if not TFile.Exists(AFileName) then
    Exit;
  try
    PreferenceText := TAtomicTextFile.ReadAllText(AFileName,
      TEncoding.ASCII, ValidatePreferenceText, Recovered);
    Result := SelectedLanguage(PreferenceText);
    if Recovered then
      TDATDiagnostics.Log('DAT-PREFERENCE-RECOVERY-001', 'ReadLanguageCode',
        'Recovered the prior language preference and quarantined the invalid file: ' +
        AFileName, dsWarning);
  except
    on E: Exception do
    begin
      TDATDiagnostics.LogException('DAT-PREFERENCE-READ-001',
        'ReadLanguageCode(' + AFileName + ')', E);
      Result := ADefaultLanguageCode;
    end;
  end;
end;

class procedure TLanguagePreference.WriteLanguageCode(const AFileName,
  ALanguageCode: string);
var
  Contents: TStringList;
begin
  Contents := TStringList.Create;
  try
    Contents.Add('[Language]');
    Contents.Add('Selected=' + Trim(ALanguageCode));
    { TIniFile on Windows treats a UTF-8 BOM as part of the first section
      name.  Preference values are canonical language tags, so an ASCII
      INI is both sufficient and compatible with the existing reader. }
    TAtomicTextFile.WriteAllText(AFileName, Contents.Text, TEncoding.ASCII,
      ValidatePreferenceText);
  finally
    Contents.Free;
  end;
end;

end.
