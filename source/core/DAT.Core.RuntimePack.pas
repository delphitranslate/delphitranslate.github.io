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
  System.Classes,
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  DAT.Core.AtomicFile,
  DAT.Core.Hyphenation,
  DAT.Runtime.LanguagePack,
  DAT.Validation.Catalog;

class function TRuntimePackBuilder.SourceCatalogChecksum(
  const ACatalog: TTranslationCatalog): string;
var
  Entry: TTranslationEntry;
  Index: Integer;
  SourceLines: TStringList;
  SourceText: string;
begin
  SourceLines := TStringList.Create;
  try
    SourceLines.CaseSensitive := True;
    SourceLines.Sorted := True;
    SourceLines.Duplicates := dupError;
    for Entry in ACatalog.Entries do
      if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
        (Entry.TextOwnership <> tokSuspicious) and
        not (Entry.Status in [tsExcluded, tsObsolete]) then
        SourceLines.Add(Entry.Key + '=' + Entry.SourceChecksum);
    SourceText := '';
    for Index := 0 to SourceLines.Count - 1 do
      SourceText := SourceText + SourceLines[Index] + #10;
    Result := LowerCase(THashSHA2.GetHashString(SourceText));
  finally
    SourceLines.Free;
  end;
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
  DisplayText: string;
  Entry: TTranslationEntry;
  LanguageObject: TJSONObject;
  LocaleObject: TJSONObject;
  Root: TJSONObject;
  StringsObject: TJSONObject;
  SourceStrings: TDictionary<string, string>;
  SourceStringKeys: TDictionary<string, string>;
  SourceStringsObject: TJSONObject;
  SourceTemplates: TDictionary<string, string>;
  SourceTemplateKeys: TDictionary<string, string>;
  SourceTemplatesObject: TJSONObject;
  SourcesObject: TJSONObject;
  TemplatesObject: TJSONObject;
  ExistingText: string;
  ExistingKey: string;
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
  Hyphenation: TDATHyphenationDictionary;
  IsSourceLanguage: Boolean;

  { A caption goes into the pack with a soft hyphen at every point its
    language allows a break.

    German builds one word where English uses three, and a single word cannot
    wrap: there is no space in Benachrichtigungseinstellungen for a label or a
    column heading to break at, so it is simply cut off. A soft hyphen is
    invisible unless the line actually breaks there, so marking the breaks
    costs nothing where the text already fits and rescues it where it does
    not.

    Only captions are marked. A format string is left exactly as it was
    written: its text goes on to be filled with data, may be compared or
    parsed, and a stray character inside it is a defect rather than a
    kindness. }
  { And only where a break could ever be taken.

    A soft hyphen is invisible until the line breaks at it - on a control that
    wraps. On one that does not, the mark is never used and never invisible:
    GDI draws it as an ordinary hyphen. So a button read "Sch-lie-ssen", a
    heading read "West-minster-Glockens-piel", and a column heading read "Data
    di ripro-du-zione", none of which any translator wrote.

    A button has one line by construction. So does a menu item, a window
    title, and a grid column heading. A hint is sized by the tooltip around
    it and never runs out of room. None of them can use a break mark, so none
    of them are given one; what is left is the case the marks were added for,
    which is a long compound inside a label or a memo that has to wrap. }
  function AcceptsBreakMarks(const AEntry: TTranslationEntry): Boolean;
  var
    ClassName, PropertyName: string;
  begin
    ClassName := AEntry.ComponentClassName;
    PropertyName := AEntry.PropertyName;
    Result := False;
    { A tooltip grows to fit; it never needs to break a word. }
    if SameText(PropertyName, 'Hint') then
      Exit;
    { A grid heading is one line whatever is offered. }
    if ContainsText(PropertyName, 'Column') or
      ContainsText(PropertyName, 'Title') or
      ContainsText(PropertyName, 'Header') then
      Exit;
    if ContainsText(ClassName, 'Button') or
      ContainsText(ClassName, 'MenuItem') or
      ContainsText(ClassName, 'Column') or
      ContainsText(ClassName, 'Form') then
      Exit;
    Result := True;
  end;

  function ForDisplay(const AText: string;
    const AEntry: TTranslationEntry): string;
  begin
    if IsSourceLanguage or (Hyphenation = nil) or
      not AcceptsBreakMarks(AEntry) then
      Exit(AText);
    Result := Hyphenation.HyphenateText(AText);
  end;

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

  IsSourceLanguage := SameText(ACatalog.Locale.LanguageCode,
    ACatalog.SourceLanguage);
  if IsSourceLanguage then
    Hyphenation := nil
  else
    Hyphenation := TDATHyphenation.Load(ACatalog.Locale.LanguageCode);

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
    SourceStringKeys := TDictionary<string, string>.Create;
    SourceTemplates := TDictionary<string, string>.Create;
    SourceTemplateKeys := TDictionary<string, string>.Create;
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
                DisplayText := ForDisplay(Entry.TranslatedText, Entry);
                StringsObject.AddPair(Entry.Key, DisplayText);
                if (Trim(SourceText) <> '') and
                  (Trim(Entry.TranslatedText) <> '') then
                begin
                  if SourceStrings.TryGetValue(SourceText, ExistingText) and
                    not SameText(ExistingText, DisplayText) then
                  begin
                    SourceStringKeys.TryGetValue(SourceText, ExistingKey);
                    { A source-only browser lookup cannot distinguish two
                      controls that carry the same source words.  Pick one
                      canonical translation by stable key so every pack is
                      complete and regeneration never depends on catalog
                      insertion order. }
                    if CompareText(Entry.Key, ExistingKey) < 0 then
                    begin
                      SourceStrings[SourceText] := DisplayText;
                      SourceStringKeys[SourceText] := Entry.Key;
                    end;
                  end
                  else if not SourceStrings.ContainsKey(SourceText) then
                  begin
                    SourceStrings.Add(SourceText, DisplayText);
                    SourceStringKeys.Add(SourceText, Entry.Key);
                  end;
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
                  begin
                    SourceTemplateKeys.TryGetValue(SourceText, ExistingKey);
                    if CompareText(Entry.Key, ExistingKey) < 0 then
                    begin
                      SourceTemplates[SourceText] := Entry.TranslatedText;
                      SourceTemplateKeys[SourceText] := Entry.Key;
                    end;
                  end
                  else if not SourceTemplates.ContainsKey(SourceText) then
                  begin
                    SourceTemplates.Add(SourceText, Entry.TranslatedText);
                    SourceTemplateKeys.Add(SourceText, Entry.Key);
                  end;
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
      SourceTemplateKeys.Free;
      SourceTemplates.Free;
      SourceStringKeys.Free;
      SourceStrings.Free;
    end;
    Root.AddPair('strings', StringsObject);
    Root.AddPair('templates', TemplatesObject);
    Root.AddPair('sourceStrings', SourceStringsObject);
    Root.AddPair('sourceTemplates', SourceTemplatesObject);
    Root.AddPair('sources', SourcesObject);

    LayoutArray := TJSONArray.Create;
    if not IsSourceLanguage and
      (Trim(ALayoutProposalFileName) <> '') and
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
              { The one list, in DAT.Runtime.LanguagePack. A copy of it lived
                here and quietly dropped every alignment and column-order
                decision the planner had made. }
              if not IsRuntimeLayoutProperty(PropertyName) then
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
    Hyphenation.Free;
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
  TAtomicTextFile.WriteAllText(AFileName,
    Serialize(ACatalog, ALayoutProposalFileName), TEncoding.UTF8,
    procedure(const AText: string)
    var
      ValidationPack: TRuntimeLanguagePack;
    begin
      ValidationPack := TRuntimeLanguagePack.LoadFromJson(AText);
      ValidationPack.Free;
    end);
end;

end.
