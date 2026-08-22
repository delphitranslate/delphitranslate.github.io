unit DAT.Runtime.TemplateRewrite.FMX;

{ The FireMonkey half of translating text the application built for itself.
  DAT.Runtime.TemplateRewrite carries the recognising; this carries the reach.

  The mechanism differs from VCL's, and the difference is worth stating rather
  than papering over.

  VCL catches the text in transit. Every caption set on a VCL window arrives
  as WM_SETTEXT before anything is painted, so the English can be replaced on
  the way past and is never drawn. FireMonkey has no equivalent: a form's
  caption goes to a platform service, not through a window procedure the
  application can stand in front of, and there is no message to intercept.

  So FMX corrects rather than intercepts. The manager already runs a dynamic
  text timer - it is the one piece of this that FMX had first and VCL did not
  - and each tick now offers the caption to the rewriter. The result is the
  same text, arrived at a different way, with one honest consequence: an
  application that rewrites its caption on its own timer can show the source
  language briefly before the next tick corrects it. VCL cannot flicker here;
  FMX can, between one tick and the next.

  Reducing the refresh interval narrows that window and costs a pass over the
  open forms each time. That trade belongs to whoever is configuring the
  manager, which is why it is a published property rather than a constant. }

interface

uses
  FMX.Forms,
  DAT.Runtime.LanguagePack;

type
  TDATFMXTemplateRewrite = class
  public
    { Offers the form's caption to the rewriter, and assigns it back only if
      it changed. Returns True when something was rewritten.

      Assigning an unchanged caption would be harmless in itself but would
      make every tick a change as far as the framework is concerned, which is
      how a timer turns into a repaint loop. }
    class function RefreshCaption(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  DAT.Runtime.TemplateRewrite;

class function TDATFMXTemplateRewrite.RefreshCaption(
  const AForm: TCommonCustomForm;
  const APack: TRuntimeLanguagePack): Boolean;
var
  Rewritten: string;
begin
  Result := False;
  if (AForm = nil) or (APack = nil) then
    Exit;
  try
    if not TDATTemplateRewriter.Rewrite(AForm.Caption, APack, Rewritten) then
      Exit;
    if Rewritten = AForm.Caption then
      Exit;
    AForm.Caption := Rewritten;
    Result := True;
  except
    { A caption is not worth an exception escaping into a timer, where it
      would surface as a failure of whatever the application was doing. }
  end;
end;

end.
