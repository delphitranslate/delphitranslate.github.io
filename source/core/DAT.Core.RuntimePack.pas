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
    class function Serialize(const ACatalog: TTranslationCatalog): string; overload; static;
    class function Serialize(const ACatalog: TTranslationCatalog;
      const ALayoutProposalFileName: string): string; overload; static;
    class procedure ExportToFile(const ACatalog: TTranslationCatalog;
      const AFileName: string); overload; static;
    class procedure ExportToFile(const ACatalog: TTranslationCatalog;
      const AFileName, ALayoutProposalFileName: string); overload; static;
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
begin
  Result := Serialize(ACatalog, '');
end;

class function TRuntimePackBuilder.Serialize(
  const ACatalog: TTranslationCatalog;
  const ALayoutProposalFileName: string): string;
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
  LayoutRootValue: TJSONValue;
  LayoutRoot: TJSONObject;
  LayoutItems: TJSONArray;
  LayoutItemValue: TJSONValue;
  LayoutItem: TJSONObject;
  LayoutArray: TJSONArray;
  RuntimeLayoutItem: TJSONObject;
  ProposalApplicationId: string;
  ProposalLanguageCode: string;
  PropertyName: string;
  FontColorsObject: TJSONObject;
  FontColorKey: string;
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
    Root.AddPair('schemaVersion', TJSONNumber.Create(3));
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

    LayoutArray := TJSONArray.Create;
    if (Trim(ALayoutProposalFileName) <> '') and
      TFile.Exists(ALayoutProposalFileName) then
    begin
      LayoutRootValue := TJSONObject.ParseJSONValue(
        TFile.ReadAllText(ALayoutProposalFileName, TEncoding.UTF8));
      try
        if not (LayoutRootValue is TJSONObject) then
          raise ERuntimePackError.Create(
            'The layout proposal file root must be a JSON object.');
        LayoutRoot := TJSONObject(LayoutRootValue);
        ProposalApplicationId := LayoutRoot.GetValue<string>(
          'applicationId', '');
        ProposalLanguageCode := LayoutRoot.GetValue<string>(
          'languageCode', '');
        if not SameText(ProposalApplicationId, ACatalog.ApplicationId) then
          raise ERuntimePackError.Create(
            'The layout proposal belongs to a different application.');
        if not SameText(ProposalLanguageCode,
          ACatalog.Locale.LanguageCode) then
          raise ERuntimePackError.Create(
            'The layout proposal belongs to a different language.');
        LayoutItems := LayoutRoot.GetValue('proposals') as TJSONArray;
        if LayoutItems <> nil then
          for LayoutItemValue in LayoutItems do
            if LayoutItemValue is TJSONObject then
            begin
              LayoutItem := TJSONObject(LayoutItemValue);
              if not SameText(LayoutItem.GetValue<string>(
                'decision', 'pending'), 'accepted') then
                Continue;
              PropertyName := LayoutItem.GetValue<string>('propertyName', '');
              if not (SameText(PropertyName, 'Width') or
                SameText(PropertyName, 'Height') or
                SameText(PropertyName, 'WordWrap') or
                SameText(PropertyName, 'AutoSize') or
                SameText(PropertyName, 'Left') or
                SameText(PropertyName, 'Top') or
                SameText(PropertyName, 'Position.X') or
                SameText(PropertyName, 'Position.Y') or
                SameText(PropertyName, 'FontSize')) then
                Continue;
              if Trim(LayoutItem.GetValue<string>('sourceChecksum', '')) = '' then
                Continue;
              RuntimeLayoutItem := TJSONObject.Create;
              RuntimeLayoutItem.AddPair('formName',
                LayoutItem.GetValue<string>('formName', ''));
              RuntimeLayoutItem.AddPair('componentName',
                LayoutItem.GetValue<string>('componentName', ''));
              RuntimeLayoutItem.AddPair('propertyName', PropertyName);
              RuntimeLayoutItem.AddPair('originalValue',
                LayoutItem.GetValue<string>('currentValue', ''));
              RuntimeLayoutItem.AddPair('translatedValue',
                LayoutItem.GetValue<string>('proposedValue', ''));
              RuntimeLayoutItem.AddPair('sourceChecksum',
                LayoutItem.GetValue<string>('sourceChecksum', ''));
              LayoutArray.AddElement(RuntimeLayoutItem);
            end;
      finally
        LayoutRootValue.Free;
      end;
    end;
    Root.AddPair('layout', LayoutArray);

    FontColorsObject := TJSONObject.Create;
    for Entry in ACatalog.Entries do
      if (Trim(Entry.FontColor) <> '') and
        (Trim(Entry.ComponentName) <> '') then
      begin
        FontColorKey := Entry.FormName + '.' + Entry.ComponentName;
        if FontColorsObject.GetValue(FontColorKey) = nil then
          FontColorsObject.AddPair(FontColorKey, Entry.FontColor);
      end;
    Root.AddPair('fontColors', FontColorsObject);

    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

class procedure TRuntimePackBuilder.ExportToFile(
  const ACatalog: TTranslationCatalog; const AFileName: string);
begin
  ExportToFile(ACatalog, AFileName, '');
end;

class procedure TRuntimePackBuilder.ExportToFile(
  const ACatalog: TTranslationCatalog; const AFileName,
  ALayoutProposalFileName: string);
var
  DirectoryName: string;
begin
  DirectoryName := TPath.GetDirectoryName(AFileName);
  if DirectoryName <> '' then
    TDirectory.CreateDirectory(DirectoryName);
  TFile.WriteAllText(AFileName,
    Serialize(ACatalog, ALayoutProposalFileName), TEncoding.UTF8);
end;

end.
