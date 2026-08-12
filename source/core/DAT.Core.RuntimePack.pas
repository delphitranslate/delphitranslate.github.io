unit DAT.Core.RuntimePack;

interface

uses
  System.SysUtils,
  DAT.Core.Types;

type
  ERuntimePackError = class(Exception);

  TRuntimePackBuilder = class
  private
    class function SourceCatalogChecksum(
      const ACatalog: TTranslationCatalog): string; static;
  public
    class function Serialize(const ACatalog: TTranslationCatalog): string; static;
    class procedure ExportToFile(const ACatalog: TTranslationCatalog;
      const AFileName: string); static;
  end;

implementation

uses
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.JSON,
  DAT.Runtime.LanguagePack,
  DAT.Validation.Catalog;

class function TRuntimePackBuilder.SourceCatalogChecksum(
  const ACatalog: TTranslationCatalog): string;
var
  Entry: TTranslationEntry;
  SourceText: string;
begin
  SourceText := '';
  for Entry in ACatalog.Entries do
    if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
      (Entry.TextOwnership <> tokSuspicious) and
      not (Entry.Status in [tsExcluded, tsObsolete]) then
      SourceText := SourceText + Entry.Key + '=' + Entry.SourceChecksum + #10;
  Result := LowerCase(THashSHA2.GetHashString(SourceText));
end;

class function TRuntimePackBuilder.Serialize(
  const ACatalog: TTranslationCatalog): string;
var
  Entry: TTranslationEntry;
  LanguageObject: TJSONObject;
  LocaleObject: TJSONObject;
  Root: TJSONObject;
  StringsObject: TJSONObject;
  SourceStrings: TDictionary<string, string>;
  SourceStringsObject: TJSONObject;
  SourceTemplates: TDictionary<string, string>;
  SourceTemplatesObject: TJSONObject;
  SourcesObject: TJSONObject;
  TemplatesObject: TJSONObject;
  ExistingText: string;
  SourceText: string;
  ValidationResult: TCatalogValidationResult;
begin
  ValidationResult := TCatalogValidator.Validate(ACatalog);
  try
    if ValidationResult.HasErrors then
      raise ERuntimePackError.CreateFmt(
        'Runtime pack export is blocked by %d validation error(s).',
        [ValidationResult.CountBySeverity(vsError)]);
  finally
    ValidationResult.Free;
  end;

  Root := TJSONObject.Create;
  try
    Root.AddPair('schemaVersion', TJSONNumber.Create(2));
    Root.AddPair('applicationId', ACatalog.ApplicationId);
    Root.AddPair('applicationVersion', ACatalog.ApplicationVersion);
    Root.AddPair('framework', TargetFrameworkToString(ACatalog.Framework));
    Root.AddPair('sourceLanguage', ACatalog.SourceLanguage);
    Root.AddPair('sourceCatalogChecksum', SourceCatalogChecksum(ACatalog));

    LanguageObject := TJSONObject.Create;
    LanguageObject.AddPair('code', ACatalog.Locale.LanguageCode);
    LanguageObject.AddPair('nativeName',
      CanonicalNativeLanguageName(ACatalog.Locale.LanguageCode,
        ACatalog.Locale.NativeLanguageName));
    LanguageObject.AddPair('direction', ACatalog.Locale.TextDirection);
    Root.AddPair('language', LanguageObject);

    LocaleObject := TJSONObject.Create;
    LocaleObject.AddPair('shortDateFormat',
      ACatalog.Locale.ShortDateFormat);
    LocaleObject.AddPair('longDateFormat',
      ACatalog.Locale.LongDateFormat);
    LocaleObject.AddPair('shortTimeFormat',
      ACatalog.Locale.ShortTimeFormat);
    LocaleObject.AddPair('longTimeFormat',
      ACatalog.Locale.LongTimeFormat);
    LocaleObject.AddPair('decimalSeparator',
      ACatalog.Locale.DecimalSeparator);
    LocaleObject.AddPair('thousandSeparator',
      ACatalog.Locale.ThousandSeparator);
    LocaleObject.AddPair('currencySymbol',
      ACatalog.Locale.CurrencySymbol);
    Root.AddPair('locale', LocaleObject);

    StringsObject := TJSONObject.Create;
    TemplatesObject := TJSONObject.Create;
    SourceStringsObject := TJSONObject.Create;
    SourceTemplatesObject := TJSONObject.Create;
    SourcesObject := TJSONObject.Create;
    SourceStrings := TDictionary<string, string>.Create;
    SourceTemplates := TDictionary<string, string>.Create;
    try
      for Entry in ACatalog.Entries do
        if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
          (Entry.TextOwnership <> tokSuspicious) and
          not (Entry.Status in [tsExcluded, tsObsolete]) then
        begin
          SourceText := Entry.SourceText;
          SourcesObject.AddPair(Entry.Key, SourceText);
          case Entry.RuntimeTextRole of
            rtrStaticText:
              begin
                StringsObject.AddPair(Entry.Key, Entry.TranslatedText);
                if (Trim(SourceText) <> '') and
                  (Trim(Entry.TranslatedText) <> '') then
                begin
                  if SourceStrings.TryGetValue(SourceText, ExistingText) and
                    not SameText(ExistingText, Entry.TranslatedText) then
                    SourceStrings[SourceText] := ''
                  else if not SourceStrings.ContainsKey(SourceText) then
                    SourceStrings.Add(SourceText, Entry.TranslatedText);
                end;
              end;
            rtrDynamicValue, rtrRuntimeTemplate:
              begin
                TemplatesObject.AddPair(Entry.Key, Entry.TranslatedText);
                if (Trim(SourceText) <> '') and
                  (Trim(Entry.TranslatedText) <> '') then
                begin
                  if SourceTemplates.TryGetValue(SourceText, ExistingText) and
                    not SameText(ExistingText, Entry.TranslatedText) then
                    SourceTemplates[SourceText] := ''
                  else if not SourceTemplates.ContainsKey(SourceText) then
                    SourceTemplates.Add(SourceText, Entry.TranslatedText);
                end;
              end;
          end;
        end;
      for SourceText in SourceStrings.Keys do
        if SourceStrings[SourceText] <> '' then
          SourceStringsObject.AddPair(SourceText, SourceStrings[SourceText]);
      for SourceText in SourceTemplates.Keys do
        if SourceTemplates[SourceText] <> '' then
          SourceTemplatesObject.AddPair(SourceText, SourceTemplates[SourceText]);
    finally
      SourceTemplates.Free;
      SourceStrings.Free;
    end;
    Root.AddPair('strings', StringsObject);
    Root.AddPair('templates', TemplatesObject);
    Root.AddPair('sourceStrings', SourceStringsObject);
    Root.AddPair('sourceTemplates', SourceTemplatesObject);
    Root.AddPair('sources', SourcesObject);

    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

class procedure TRuntimePackBuilder.ExportToFile(
  const ACatalog: TTranslationCatalog; const AFileName: string);
var
  DirectoryName: string;
begin
  DirectoryName := TPath.GetDirectoryName(AFileName);
  if DirectoryName <> '' then
    TDirectory.CreateDirectory(DirectoryName);
  TFile.WriteAllText(AFileName, Serialize(ACatalog), TEncoding.UTF8);
end;

end.
