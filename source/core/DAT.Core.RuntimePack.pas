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
  TemplatesObject: TJSONObject;
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
    Root.AddPair('schemaVersion', TJSONNumber.Create(1));
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
    for Entry in ACatalog.Entries do
      if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
        not (Entry.Status in [tsExcluded, tsObsolete]) then
        case Entry.RuntimeTextRole of
          rtrStaticText:
            StringsObject.AddPair(Entry.Key, Entry.TranslatedText);
          rtrDynamicValue, rtrRuntimeTemplate:
            TemplatesObject.AddPair(Entry.Key, Entry.TranslatedText);
        end;
    Root.AddPair('strings', StringsObject);
    Root.AddPair('templates', TemplatesObject);

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
