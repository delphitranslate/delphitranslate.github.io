unit DAT.Runtime.VCL;

interface

uses
  System.Classes,
  Vcl.Forms,
  DAT.Runtime.LanguagePack;

type
  TVCLTranslationApplicator = class
  public
    class function ApplyToForm(const AForm: TCustomForm;
      const APack: TRuntimeLanguagePack): Integer; static;
  end;

implementation

uses
  System.SysUtils,
  System.TypInfo;

function ComponentKey(const AForm, AComponent: TComponent;
  const APropertyName: string): string;
begin
  if AComponent = AForm then
    Result := AForm.Name + '.' + APropertyName
  else
    Result := AForm.Name + '.' + AComponent.Name + '.' + APropertyName;
end;

function ApplyTextProperty(const AForm, AComponent: TComponent;
  const APropertyName: string; const APack: TRuntimeLanguagePack): Boolean;
var
  PropertyInfo: PPropInfo;
  TranslatedText: string;
begin
  Result := False;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName,
    [tkString, tkLString, tkWString, tkUString]);
  if (PropertyInfo <> nil) and APack.TryGetText(
    ComponentKey(AForm, AComponent, APropertyName), TranslatedText) then
  begin
    SetStrProp(AComponent, PropertyInfo, TranslatedText);
    Result := True;
  end;
end;

function ApplyStringCollection(const AForm, AComponent: TComponent;
  const APropertyName, AKeyPropertyName: string;
  const APack: TRuntimeLanguagePack): Integer;
var
  PropertyInfo: PPropInfo;
  StringObject: TObject;
begin
  Result := 0;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName, [tkClass]);
  if PropertyInfo = nil then
    Exit;
  StringObject := GetObjectProp(AComponent, PropertyInfo);
  if StringObject is TStrings then
    Result := APack.ReadIndexedStrings(
      ComponentKey(AForm, AComponent, AKeyPropertyName),
      TStrings(StringObject));
end;

class function TVCLTranslationApplicator.ApplyToForm(
  const AForm: TCustomForm; const APack: TRuntimeLanguagePack): Integer;
const
  TextProperties: array[0..2] of string = ('Caption', 'Hint', 'TextHint');
  StringProperties: array[0..1] of string = ('Items', 'Lines');
var
  Component: TComponent;
  ComponentIndex: Integer;
  PropertyName: string;
begin
  if AForm = nil then
    raise EArgumentNilException.Create('A VCL form is required.');
  if APack = nil then
    Exit(0);

  Result := 0;
  for PropertyName in TextProperties do
    if ApplyTextProperty(AForm, AForm, PropertyName, APack) then
      Inc(Result);

  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
  begin
    Component := AForm.Components[ComponentIndex];
    if Component.Name = '' then
      Continue;
    for PropertyName in TextProperties do
      if ApplyTextProperty(AForm, Component, PropertyName, APack) then
        Inc(Result);
    for PropertyName in StringProperties do
      Inc(Result, ApplyStringCollection(
        AForm, Component, PropertyName, PropertyName + '.Strings', APack));
  end;
end;

end.
