unit DAT.Provider.Types;

interface

uses
  System.SysUtils;

type
  TTranslationProvider = (
    tpDeepL,
    tpGoogle
  );

  TDeepLPlan = (
    dpFree,
    dpPro
  );

  ETranslationProviderError = class(Exception)
  private
    FStatusCode: Integer;
  public
    constructor Create(const AMessage: string;
      const AStatusCode: Integer = 0);
    property StatusCode: Integer read FStatusCode;
  end;

function TranslationProviderDisplayName(
  const AProvider: TTranslationProvider): string;
function TranslationProviderToString(
  const AProvider: TTranslationProvider): string;
function StringToTranslationProvider(
  const AValue: string): TTranslationProvider;
function DeepLPlanToString(const APlan: TDeepLPlan): string;
function StringToDeepLPlan(const AValue: string): TDeepLPlan;

implementation

constructor ETranslationProviderError.Create(
  const AMessage: string; const AStatusCode: Integer);
begin
  inherited Create(AMessage);
  FStatusCode := AStatusCode;
end;

function TranslationProviderDisplayName(
  const AProvider: TTranslationProvider): string;
begin
  case AProvider of
    tpGoogle:
      Result := 'Google Cloud Translation';
  else
    Result := 'DeepL';
  end;
end;

function TranslationProviderToString(
  const AProvider: TTranslationProvider): string;
begin
  case AProvider of
    tpGoogle:
      Result := 'google';
  else
    Result := 'deepl';
  end;
end;

function StringToTranslationProvider(
  const AValue: string): TTranslationProvider;
begin
  if SameText(AValue, 'google') then
    Result := tpGoogle
  else
    Result := tpDeepL;
end;

function DeepLPlanToString(const APlan: TDeepLPlan): string;
begin
  if APlan = dpPro then
    Result := 'pro'
  else
    Result := 'free';
end;

function StringToDeepLPlan(const AValue: string): TDeepLPlan;
begin
  if SameText(AValue, 'pro') then
    Result := dpPro
  else
    Result := dpFree;
end;

end.
