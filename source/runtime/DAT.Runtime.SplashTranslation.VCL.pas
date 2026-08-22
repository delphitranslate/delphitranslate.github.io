unit DAT.Runtime.SplashTranslation.VCL;

{ The VCL half of translating forms that appear before any manager exists.
  DAT.Runtime.SplashTranslation carries the reasoning; this carries the hook.

  VCL offers Screen.OnActiveFormChange, which fires when a form becomes
  active. It is a single slot the host application may already be using, so
  the previous handler is kept and called - installing this has to be
  invisible to code that was there first.

  It fires on activation, which is after the window is on screen, so a VCL
  splash can show for an instant in the language it was designed in before the
  text changes. FMX can do better because its hook runs before the window is
  shown at all; VCL has nothing equivalent that does not involve patching the
  framework, and a brief flicker is not worth that. }

interface

uses
  System.Classes;

type
  TDATVCLSplashTranslation = class
  private
    class var FInstalled: Boolean;
    class var FPreviousHandler: TNotifyEvent;
    { Not static: Screen.OnActiveFormChange is a method pointer, and a class
      method satisfies one where a plain procedure does not. }
    class procedure ActiveFormChanged(Sender: TObject);
    class procedure TranslateActiveForm; static;
  public
    { Chains onto Screen.OnActiveFormChange. Called from initialization; safe
      to call more than once. }
    class procedure Install; static;
  end;

implementation

uses
  System.SysUtils,
  Vcl.Forms,
  DAT.Runtime.LanguagePack,
  DAT.Runtime.SplashTranslation,
  DAT.Runtime.VCL;

class procedure TDATVCLSplashTranslation.TranslateActiveForm;
var
  Form: TCustomForm;
  Pack: TRuntimeLanguagePack;
begin
  if not TDATSplashTranslation.Active then
    Exit;
  Form := Screen.ActiveCustomForm;
  if (Form = nil) or (Form.Name = '') then
    Exit;
  Pack := TDATSplashTranslation.PackForEarlyForms;
  if Pack = nil then
    Exit;
  { The same call a manager makes. Control state is not preserved: nothing has
    been typed into a form that has only just appeared, and asking to preserve
    it would mean reading properties off controls mid-construction. }
  TVCLTranslationApplicator.ApplyToForm(Form, Pack, Form.Name, False);
end;

class procedure TDATVCLSplashTranslation.ActiveFormChanged(Sender: TObject);
begin
  try
    TranslateActiveForm;
  except
    { Rule 1. An untranslated splash is a blemish; an exception here is a
      startup crash, and the application is not ours to crash. }
  end;
  if Assigned(FPreviousHandler) then
    FPreviousHandler(Sender);
end;

class procedure TDATVCLSplashTranslation.Install;
begin
  if FInstalled or (Screen = nil) then
    Exit;
  FInstalled := True;
  FPreviousHandler := Screen.OnActiveFormChange;
  Screen.OnActiveFormChange := TDATVCLSplashTranslation.ActiveFormChanged;
end;

initialization
  TDATVCLSplashTranslation.Install;

finalization
  TDATSplashTranslation.Cleanup;

end.
