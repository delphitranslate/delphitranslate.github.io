unit DAT.Core.CatalogJson;

interface

uses
  System.SysUtils,
  System.JSON,
  DAT.Core.Types;

type
  ECatalogJsonError = class(Exception);

  TCatalogJson = class
  private
    class function JsonValueText(AObject: TJSONObject;
      const AName, ADefault: string): string; static;
  public
    class function Serialize(const ACatalog: TTranslationCatalog): string; static;
    class function Deserialize(const AJson: string): TTranslationCatalog; static;
  end;

implementation

class function TCatalogJson.JsonValueText(AObject: TJSONObject;
  const AName, ADefault: string): string;
var
  JsonValue: TJSONValue;
begin
  Result := ADefault;
  if AObject = nil then
    Exit;

  JsonValue := AObject.GetValue(AName);
  if JsonValue <> nil then
    Result := JsonValue.Value;
end;

class function TCatalogJson.Serialize(
  const ACatalog: TTranslationCatalog): string;
var
  Root: TJSONObject;
  LocaleObject: TJSONObject;
  EntriesArray: TJSONArray;
  EntryObject: TJSONObject;
  Entry: TTranslationEntry;
begin
  if ACatalog = nil then
    raise ECatalogJsonError.Create('A catalog is required.');

  Root := TJSONObject.Create;
  try
    Root.AddPair('schemaVersion', TJSONNumber.Create(ACatalog.SchemaVersion));
    Root.AddPair('applicationId', ACatalog.ApplicationId);
    Root.AddPair('applicationVersion', ACatalog.ApplicationVersion);
    Root.AddPair('framework', TargetFrameworkToString(ACatalog.Framework));
    Root.AddPair('sourceLanguage', ACatalog.SourceLanguage);

    LocaleObject := TJSONObject.Create;
    LocaleObject.AddPair('languageCode', ACatalog.Locale.LanguageCode);
    LocaleObject.AddPair('nativeLanguageName', ACatalog.Locale.NativeLanguageName);
    LocaleObject.AddPair('textDirection', ACatalog.Locale.TextDirection);
    LocaleObject.AddPair('shortDateFormat', ACatalog.Locale.ShortDateFormat);
    LocaleObject.AddPair('longDateFormat', ACatalog.Locale.LongDateFormat);
    LocaleObject.AddPair('shortTimeFormat', ACatalog.Locale.ShortTimeFormat);
    LocaleObject.AddPair('longTimeFormat', ACatalog.Locale.LongTimeFormat);
    LocaleObject.AddPair('decimalSeparator', ACatalog.Locale.DecimalSeparator);
    LocaleObject.AddPair('thousandSeparator', ACatalog.Locale.ThousandSeparator);
    LocaleObject.AddPair('currencySymbol', ACatalog.Locale.CurrencySymbol);
    Root.AddPair('locale', LocaleObject);

    EntriesArray := TJSONArray.Create;
    for Entry in ACatalog.Entries do
    begin
      EntryObject := TJSONObject.Create;
      EntryObject.AddPair('key', Entry.Key);
      EntryObject.AddPair('sourceText', Entry.SourceText);
      EntryObject.AddPair('translatedText', Entry.TranslatedText);
      EntryObject.AddPair('formName', Entry.FormName);
      EntryObject.AddPair('componentName', Entry.ComponentName);
      EntryObject.AddPair('componentClassName', Entry.ComponentClassName);
      EntryObject.AddPair('propertyName', Entry.PropertyName);
      EntryObject.AddPair('sourceChecksum', Entry.SourceChecksum);
      EntryObject.AddPair('developerNote', Entry.DeveloperNote);
      EntryObject.AddPair('status', TranslationStatusToString(Entry.Status));
      EntriesArray.AddElement(EntryObject);
    end;
    Root.AddPair('entries', EntriesArray);

    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

class function TCatalogJson.Deserialize(
  const AJson: string): TTranslationCatalog;
var
  JsonValue: TJSONValue;
  Root: TJSONObject;
  LocaleObject: TJSONObject;
  EntriesArray: TJSONArray;
  ArrayValue: TJSONValue;
  EntryObject: TJSONObject;
  Entry: TTranslationEntry;
begin
  JsonValue := TJSONObject.ParseJSONValue(AJson);
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    raise ECatalogJsonError.Create('The catalog JSON root must be an object.');
  end;

  Root := TJSONObject(JsonValue);
  try
    Result := TTranslationCatalog.Create;
    try
      Result.SchemaVersion := StrToIntDef(
        JsonValueText(Root, 'schemaVersion', '1'), 1);
      Result.ApplicationId := JsonValueText(Root, 'applicationId', '');
      Result.ApplicationVersion := JsonValueText(Root, 'applicationVersion', '');
      Result.Framework := StringToTargetFramework(
        JsonValueText(Root, 'framework', 'Unknown'));
      Result.SourceLanguage := JsonValueText(Root, 'sourceLanguage', '');

      LocaleObject := Root.GetValue('locale') as TJSONObject;
      if LocaleObject <> nil then
      begin
        Result.Locale.LanguageCode :=
          JsonValueText(LocaleObject, 'languageCode', '');
        Result.Locale.NativeLanguageName :=
          JsonValueText(LocaleObject, 'nativeLanguageName', '');
        Result.Locale.TextDirection :=
          JsonValueText(LocaleObject, 'textDirection', 'ltr');
        Result.Locale.ShortDateFormat :=
          JsonValueText(LocaleObject, 'shortDateFormat', '');
        Result.Locale.LongDateFormat :=
          JsonValueText(LocaleObject, 'longDateFormat', '');
        Result.Locale.ShortTimeFormat :=
          JsonValueText(LocaleObject, 'shortTimeFormat', '');
        Result.Locale.LongTimeFormat :=
          JsonValueText(LocaleObject, 'longTimeFormat', '');
        Result.Locale.DecimalSeparator :=
          JsonValueText(LocaleObject, 'decimalSeparator', '');
        Result.Locale.ThousandSeparator :=
          JsonValueText(LocaleObject, 'thousandSeparator', '');
        Result.Locale.CurrencySymbol :=
          JsonValueText(LocaleObject, 'currencySymbol', '');
      end;

      EntriesArray := Root.GetValue('entries') as TJSONArray;
      if EntriesArray <> nil then
        for ArrayValue in EntriesArray do
          if ArrayValue is TJSONObject then
          begin
            EntryObject := TJSONObject(ArrayValue);
            Entry := TTranslationEntry.Create;
            Entry.Key := JsonValueText(EntryObject, 'key', '');
            Entry.SourceText := JsonValueText(EntryObject, 'sourceText', '');
            Entry.TranslatedText :=
              JsonValueText(EntryObject, 'translatedText', '');
            Entry.FormName := JsonValueText(EntryObject, 'formName', '');
            Entry.ComponentName :=
              JsonValueText(EntryObject, 'componentName', '');
            Entry.ComponentClassName :=
              JsonValueText(EntryObject, 'componentClassName', '');
            Entry.PropertyName :=
              JsonValueText(EntryObject, 'propertyName', '');
            Entry.SourceChecksum :=
              JsonValueText(EntryObject, 'sourceChecksum', '');
            Entry.DeveloperNote :=
              JsonValueText(EntryObject, 'developerNote', '');
            Entry.Status := StringToTranslationStatus(
              JsonValueText(EntryObject, 'status', 'needsTranslation'));
            Result.Entries.Add(Entry);
          end;
    except
      Result.Free;
      raise;
    end;
  finally
    Root.Free;
  end;
end;

end.
