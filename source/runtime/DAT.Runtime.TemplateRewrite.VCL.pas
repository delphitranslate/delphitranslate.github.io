unit DAT.Runtime.TemplateRewrite.VCL;

{ Catching a caption on its way to the window.

  An application that rebuilds its own title bar on a timer overwrites
  anything this product writes there. Re-writing it back afterwards is a race
  nobody wins: the application posts English, we post the translation, and the
  user watches them alternate.

  So the text is caught in transit instead. Every caption an application sets
  arrives at the window as WM_SETTEXT, before anything is painted. Replacing
  the text carried by that message means the English is never on screen at
  all - there is nothing to flicker, because only one version is ever drawn.

  The interceptor is a component owned by the form, which is what keeps it
  simple:

    - it is found again through FindComponent rather than a dictionary this
      unit would have to keep in step with forms being destroyed;
    - it goes when the form goes, with no notification handling and no
      collection to mutate while a form is being torn down;
    - and its destructor puts the original window procedure back, so if it is
      removed while the window is still alive nothing is left pointing at it.

  What this cannot reach: a TLabel's Caption is not a window and sends no
  message. Only text belonging to a window - a form's caption, a button's -
  passes this way. Everything else stays with the ordinary property path. }

interface

uses
  System.Classes,
  Vcl.Forms,
  DAT.Runtime.LanguagePack;

type
  TDATVCLTemplateIntercept = class
  public
    { Installs on the form if it is not there already, and points it at the
      pack now in force. Safe to call on every apply, which is how the pack
      stays current. }
    class procedure Install(const AForm: TCustomForm;
      const APack: TRuntimeLanguagePack); static;
    { Stops intercepting. The form keeps whatever caption it has. }
    class procedure Remove(const AForm: TCustomForm); static;
  end;

implementation

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  Vcl.Controls,
  DAT.Runtime.TemplateRewrite;

const
  InterceptorName = 'DATTemplateIntercept';

type
  TFormInterceptor = class(TComponent)
  private
    FForm: TCustomForm;
    FPreviousWindowProc: TWndMethod;
    FPack: TRuntimeLanguagePack;
    procedure InterceptWindowProc(var AMessage: TMessage);
  public
    constructor CreateFor(const AForm: TCustomForm);
    destructor Destroy; override;
    property Pack: TRuntimeLanguagePack read FPack write FPack;
  end;

constructor TFormInterceptor.CreateFor(const AForm: TCustomForm);
begin
  inherited Create(AForm);
  Name := InterceptorName;
  FForm := AForm;
  FPreviousWindowProc := AForm.WindowProc;
  AForm.WindowProc := InterceptWindowProc;
end;

destructor TFormInterceptor.Destroy;
begin
  { Put back what was there. If this is running because the form is being
    destroyed the window is going anyway; if it is running because
    interception was turned off, the form carries on with its own procedure. }
  if (FForm <> nil) and Assigned(FPreviousWindowProc) then
    FForm.WindowProc := FPreviousWindowProc;
  inherited Destroy;
end;

procedure TFormInterceptor.InterceptWindowProc(var AMessage: TMessage);
var
  Incoming: string;
  Rewritten: string;
begin
  if (AMessage.Msg = WM_SETTEXT) and (FPack <> nil) and
    (AMessage.LParam <> 0) then
  begin
    try
      Incoming := PChar(AMessage.LParam);
      if TDATTemplateRewriter.Rewrite(Incoming, FPack, Rewritten) then
      begin
        { Rewritten is a local and stays alive across the call below, which is
          the whole reason the original procedure is invoked here rather than
          after the if. }
        AMessage.LParam := LPARAM(PChar(Rewritten));
        FPreviousWindowProc(AMessage);
        Exit;
      end;
    except
      { A caption is not worth an exception escaping into a window procedure,
        where it would surface as a failure of whatever the application was
        doing at the time. Fall through and let the original text pass. }
    end;
  end;
  FPreviousWindowProc(AMessage);
end;

class procedure TDATVCLTemplateIntercept.Install(const AForm: TCustomForm;
  const APack: TRuntimeLanguagePack);
var
  Existing: TComponent;
begin
  if (AForm = nil) or (APack = nil) then
    Exit;
  Existing := AForm.FindComponent(InterceptorName);
  if Existing is TFormInterceptor then
  begin
    TFormInterceptor(Existing).Pack := APack;
    Exit;
  end;
  if Existing <> nil then
    Exit;
  TFormInterceptor.CreateFor(AForm).Pack := APack;
end;

class procedure TDATVCLTemplateIntercept.Remove(const AForm: TCustomForm);
var
  Existing: TComponent;
begin
  if AForm = nil then
    Exit;
  Existing := AForm.FindComponent(InterceptorName);
  if Existing is TFormInterceptor then
    Existing.Free;
end;

end.
