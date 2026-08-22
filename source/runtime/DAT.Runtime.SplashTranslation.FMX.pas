unit DAT.Runtime.SplashTranslation.FMX;

{ The FireMonkey half of translating forms that appear before any manager
  exists. DAT.Runtime.SplashTranslation carries the reasoning; this carries
  the hook.

  FMX has no Screen.OnActiveFormChange - the VCL mechanism simply is not
  there - but what it has instead is better in two ways.

  It is TFormBeforeShownMessage, published through TMessageManager, and
  FMX.Forms sends it on the line immediately before the window is shown:

    TMessageManager.DefaultManager.SendMessage(nil,
      TFormBeforeShownMessage.Create(Self));
    FWinService.ShowWindow(Self);

  So the text is replaced before anything is painted, where the VCL hook fires
  on activation and can let a splash flash up in its designed language first.

  And TMessageManager is multi-subscriber, so rule 2 - never steal - costs
  nothing here. There is no single handler slot to take over and hand back;
  subscribing adds a listener and leaves every other listener untouched. }

interface

uses
  System.Messaging;

type
  TDATFMXSplashTranslation = class
  private
    class var FInstalled: Boolean;
    class var FSubscriptionId: Integer;
    { Not static, and TMessage rather than TObject: TMessageManager takes a
      method pointer of exactly this shape. Winapi.Messages declares a
      different TMessage, so this one is qualified. }
    class procedure FormBeforeShown(const ASender: TObject;
      const AMessage: System.Messaging.TMessage);
  public
    { Subscribes to TFormBeforeShownMessage. Called from initialization; safe
      to call more than once. }
    class procedure Install; static;
    class procedure Remove; static;
  end;

implementation

uses
  System.SysUtils,
  FMX.Forms,
  DAT.Runtime.LanguagePack,
  DAT.Runtime.SplashTranslation,
  DAT.Runtime.FMX;

class procedure TDATFMXSplashTranslation.FormBeforeShown(
  const ASender: TObject; const AMessage: System.Messaging.TMessage);
var
  Form: TCommonCustomForm;
  Pack: TRuntimeLanguagePack;
begin
  try
    if not TDATSplashTranslation.Active then
      Exit;
    if not (AMessage is TFormBeforeShownMessage) then
      Exit;
    Form := TFormBeforeShownMessage(AMessage).Value;
    if (Form = nil) or (Form.Name = '') then
      Exit;
    Pack := TDATSplashTranslation.PackForEarlyForms;
    if Pack = nil then
      Exit;
    { The same call a manager makes. Control state is not preserved: nothing
      has been typed into a form that has not been shown yet. }
    TFMXTranslationApplicator.ApplyToForm(Form, Pack, Form.Name, False);
  except
    { Rule 1. An untranslated splash is a blemish; an exception here is a
      startup crash, and the application is not ours to crash. }
  end;
end;

class procedure TDATFMXSplashTranslation.Install;
begin
  if FInstalled then
    Exit;
  FInstalled := True;
  FSubscriptionId := TMessageManager.DefaultManager.SubscribeToMessage(
    TFormBeforeShownMessage,
    TDATFMXSplashTranslation.FormBeforeShown);
end;

class procedure TDATFMXSplashTranslation.Remove;
begin
  if not FInstalled then
    Exit;
  FInstalled := False;
  TMessageManager.DefaultManager.Unsubscribe(
    TFormBeforeShownMessage, FSubscriptionId);
end;

initialization
  TDATFMXSplashTranslation.Install;

finalization
  { Unsubscribed explicitly. A message manager outliving a listener it still
    holds a reference to is a crash during shutdown, which is the one moment
    an application has nothing to gain from us. }
  TDATFMXSplashTranslation.Remove;
  TDATSplashTranslation.Cleanup;

end.
