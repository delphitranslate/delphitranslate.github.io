unit DAT.Components.FMX;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Messaging,
  FMX.Forms,
  FMX.Types,
  DAT.Components.Core,
  DAT.Runtime.LanguagePack;

type
  TDATFMXLanguageManager = class(TDATCustomLanguageManager)
  private
    FBeforeShownSubscription: TMessageSubscriptionId;
    FReleasedSubscription: TMessageSubscriptionId;
    FAutoRefreshDynamicText: Boolean;
    FDynamicRefreshInterval: Cardinal;
    FDynamicRefreshBusy: Boolean;
    FDynamicTimer: TTimer;
    FPendingPostShowForms: TList<TCommonCustomForm>;
    FTranslateBrowserContent: Boolean;
    procedure EnsureDynamicTimer;
    procedure DynamicTimerTick(Sender: TObject);
    procedure ProcessPendingPostShowReapply;
    procedure QueuePostShowReapply(const AForm: TCommonCustomForm);
    procedure SetAutoRefreshDynamicText(const Value: Boolean);
    procedure SetDynamicRefreshInterval(const Value: Cardinal);
    procedure SubscribeToLifecycle;
    procedure UnsubscribeFromLifecycle;
    procedure HandleBeforeShown(const Sender: TObject;
      const AMessage: TMessage);
    procedure HandleReleased(const Sender: TObject;
      const AMessage: TMessage);
  protected
    procedure Loaded; override;
    function SupportsManagedObject(
      const AManagedObject: TObject): Boolean; override;
    function ManagedObjectInstanceName(
      const AManagedObject: TObject): string; override;
    function ApplyLanguagePack(const AManagedObject: TObject;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; override;
    function RestoreLanguageLayout(const AManagedObject: TObject;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; override;
    function RestoreSourceLanguage(const AManagedObject: TObject;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; override;
    procedure CollectOpenManagedObjects(
      const AObjects: TList<TObject>); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ApplyToForm(const AForm: TCommonCustomForm): Integer;
    procedure RefreshDynamicText;
  published
    property AutoRefreshDynamicText: Boolean read FAutoRefreshDynamicText
      write SetAutoRefreshDynamicText default True;
    property DynamicRefreshInterval: Cardinal read FDynamicRefreshInterval
      write SetDynamicRefreshInterval default 1000;
    property TranslateBrowserContent: Boolean read FTranslateBrowserContent
      write FTranslateBrowserContent default False;
  end;

implementation

uses
  System.Types,
  System.UITypes,
  FMX.Dialogs,
  FMX.Platform,
  DAT.Runtime.SplashTranslation,
  { Named so it is linked at all.

    Its work happens in its initialization section, and a unit no other
    unit uses is a unit the linker leaves out - so copying it into the
    component kit was not enough to make it run. It was reached only by
    its own harness, which lists it explicitly, so every test passed while
    no real application ever installed the hook. }
  DAT.Runtime.SplashTranslation.FMX,
  DAT.Runtime.TemplateRewrite.FMX,
  DAT.Runtime.FMX;

type
  { FireMonkey sends TDialogService text straight to a platform service.  No
    form or text control exists for the normal form applicator to translate,
    so the language manager decorates that service and translates only the
    message, caption, and prompt arguments before delegating. }
  TDATFMXDialogTranslationService = class(TInterfacedObject,
    IFMXDialogService, IFMXDialogServiceSync, IFMXDialogServiceAsync)
  private
    FLegacy: IFMXDialogService;
    FSync: IFMXDialogServiceSync;
    FAsync: IFMXDialogServiceAsync;
    class function TranslatedPrompts(
      const APrompts: array of string): TArray<string>; static;
  public
    constructor Create(const ALegacy: IFMXDialogService;
      const ASync: IFMXDialogServiceSync;
      const AAsync: IFMXDialogServiceAsync);
    function DialogOpenFiles(const ADialog: TOpenDialog; var AFiles: TStrings;
      AType: TDialogType = TDialogType.Standard): Boolean;
    function DialogPrint(var ACollate, APrintToFile: Boolean;
      var AFromPage, AToPage, ACopies: Integer; AMinPage, AMaxPage: Integer;
      var APrintRange: TPrintRange; AOptions: TPrintDialogOptions): Boolean;
    function PageSetupGetDefaults(var AMargin, AMinMargin: TRect;
      var APaperSize: TPointF; AUnits: TPageMeasureUnits;
      AOptions: TPageSetupDialogOptions): Boolean;
    function DialogPageSetup(var AMargin, AMinMargin: TRect;
      var APaperSize: TPointF; var AUnits: TPageMeasureUnits;
      AOptions: TPageSetupDialogOptions): Boolean;
    function DialogSaveFiles(const ADialog: TOpenDialog;
      var AFiles: TStrings): Boolean;
    function DialogPrinterSetup: Boolean;
    function MessageDialog(const AMessage: string;
      const ADialogType: TMsgDlgType; const AButtons: TMsgDlgButtons;
      const ADefaultButton: TMsgDlgBtn; const AX, AY: Integer;
      const AHelpCtx: THelpContext; const AHelpFileName: string): Integer;
      overload;
    procedure MessageDialog(const AMessage: string;
      const ADialogType: TMsgDlgType; const AButtons: TMsgDlgButtons;
      const ADefaultButton: TMsgDlgBtn; const AX, AY: Integer;
      const AHelpCtx: THelpContext; const AHelpFileName: string;
      const ACloseDialogProc: TInputCloseDialogProc); overload;
    function InputQuery(const ACaption: string;
      const APrompts: array of string; var AValues: array of string;
      const ACloseQueryFunc: TInputCloseQueryFunc = nil): Boolean; overload;
    procedure InputQuery(const ACaption: string;
      const APrompts, ADefaultValues: array of string;
      const ACloseQueryProc: TInputCloseQueryProc); overload;
    procedure ShowMessageSync(const AMessage: string);
    function MessageDialogSync(const AMessage: string;
      const ADialogType: TMsgDlgType; const AButtons: TMsgDlgButtons;
      const ADefaultButton: TMsgDlgBtn;
      const AHelpCtx: THelpContext): Integer;
    function InputQuerySync(const ACaption: string;
      const APrompts: array of string; var AValues: array of string): Boolean;
    procedure ShowMessageAsync(const AMessage: string); overload;
    procedure ShowMessageAsync(const AMessage: string;
      const ACloseDialogProc: TInputCloseDialogProc); overload;
    procedure ShowMessageAsync(const AMessage: string;
      const ACloseDialogEvent: TInputCloseDialogEvent;
      const AContext: TObject = nil); overload;
    procedure MessageDialogAsync(const AMessage: string;
      const ADialogType: TMsgDlgType; const AButtons: TMsgDlgButtons;
      const ADefaultButton: TMsgDlgBtn; const AHelpCtx: THelpContext;
      const ACloseDialogProc: TInputCloseDialogProc); overload;
    procedure MessageDialogAsync(const AMessage: string;
      const ADialogType: TMsgDlgType; const AButtons: TMsgDlgButtons;
      const ADefaultButton: TMsgDlgBtn; const AHelpCtx: THelpContext;
      const ACloseDialogEvent: TInputCloseDialogEvent;
      const AContext: TObject = nil); overload;
    procedure InputQueryAsync(const ACaption: string;
      const APrompts: array of string; const ADefaultValues: array of string;
      const ACloseQueryProc: TInputCloseQueryProc); overload;
    procedure InputQueryAsync(const ACaption: string;
      const APrompts: array of string; const ADefaultValues: array of string;
      const ACloseQueryEvent: TInputCloseQueryWithResultEvent;
      const AContext: TObject = nil); overload;
  end;

var
  DATFMXDialogTranslationService: IInterface;

procedure InstallFMXDialogTranslationService;
var
  AsyncService: IFMXDialogServiceAsync;
  LegacyService: IFMXDialogService;
  Proxy: TDATFMXDialogTranslationService;
  ProxyInterface: IFMXDialogServiceSync;
  SyncService: IFMXDialogServiceSync;
begin
  if DATFMXDialogTranslationService <> nil then
    Exit;
  TPlatformServices.Current.SupportsPlatformService(IFMXDialogService,
    LegacyService);
  TPlatformServices.Current.SupportsPlatformService(IFMXDialogServiceSync,
    SyncService);
  TPlatformServices.Current.SupportsPlatformService(IFMXDialogServiceAsync,
    AsyncService);
  if (LegacyService = nil) and (SyncService = nil) and
    (AsyncService = nil) then
    Exit;
  Proxy := TDATFMXDialogTranslationService.Create(LegacyService, SyncService,
    AsyncService);
  ProxyInterface := Proxy;
  DATFMXDialogTranslationService := ProxyInterface;
  if LegacyService <> nil then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXDialogService);
    TPlatformServices.Current.AddPlatformService(IFMXDialogService,
      Proxy as IFMXDialogService);
  end;
  if SyncService <> nil then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXDialogServiceSync);
    TPlatformServices.Current.AddPlatformService(IFMXDialogServiceSync,
      Proxy as IFMXDialogServiceSync);
  end;
  if AsyncService <> nil then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXDialogServiceAsync);
    TPlatformServices.Current.AddPlatformService(IFMXDialogServiceAsync,
      Proxy as IFMXDialogServiceAsync);
  end;
end;

constructor TDATFMXDialogTranslationService.Create(
  const ALegacy: IFMXDialogService; const ASync: IFMXDialogServiceSync;
  const AAsync: IFMXDialogServiceAsync);
begin
  inherited Create;
  FLegacy := ALegacy;
  FSync := ASync;
  FAsync := AAsync;
end;

class function TDATFMXDialogTranslationService.TranslatedPrompts(
  const APrompts: array of string): TArray<string>;
var
  PromptIndex: Integer;
begin
  SetLength(Result, Length(APrompts));
  for PromptIndex := 0 to High(APrompts) do
    Result[PromptIndex] := DATTranslateDynamicText(APrompts[PromptIndex]);
end;

function TDATFMXDialogTranslationService.DialogOpenFiles(
  const ADialog: TOpenDialog; var AFiles: TStrings;
  AType: TDialogType): Boolean;
begin
  Result := FLegacy.DialogOpenFiles(ADialog, AFiles, AType);
end;

function TDATFMXDialogTranslationService.DialogPrint(var ACollate,
  APrintToFile: Boolean; var AFromPage, AToPage, ACopies: Integer;
  AMinPage, AMaxPage: Integer; var APrintRange: TPrintRange;
  AOptions: TPrintDialogOptions): Boolean;
begin
  Result := FLegacy.DialogPrint(ACollate, APrintToFile, AFromPage, AToPage,
    ACopies, AMinPage, AMaxPage, APrintRange, AOptions);
end;

function TDATFMXDialogTranslationService.PageSetupGetDefaults(
  var AMargin, AMinMargin: TRect; var APaperSize: TPointF;
  AUnits: TPageMeasureUnits; AOptions: TPageSetupDialogOptions): Boolean;
begin
  Result := FLegacy.PageSetupGetDefaults(AMargin, AMinMargin, APaperSize,
    AUnits, AOptions);
end;

function TDATFMXDialogTranslationService.DialogPageSetup(
  var AMargin, AMinMargin: TRect; var APaperSize: TPointF;
  var AUnits: TPageMeasureUnits;
  AOptions: TPageSetupDialogOptions): Boolean;
begin
  Result := FLegacy.DialogPageSetup(AMargin, AMinMargin, APaperSize, AUnits,
    AOptions);
end;

function TDATFMXDialogTranslationService.DialogSaveFiles(
  const ADialog: TOpenDialog; var AFiles: TStrings): Boolean;
begin
  Result := FLegacy.DialogSaveFiles(ADialog, AFiles);
end;

function TDATFMXDialogTranslationService.DialogPrinterSetup: Boolean;
begin
  Result := FLegacy.DialogPrinterSetup;
end;

function TDATFMXDialogTranslationService.MessageDialog(
  const AMessage: string; const ADialogType: TMsgDlgType;
  const AButtons: TMsgDlgButtons; const ADefaultButton: TMsgDlgBtn;
  const AX, AY: Integer; const AHelpCtx: THelpContext;
  const AHelpFileName: string): Integer;
begin
  Result := FLegacy.MessageDialog(DATTranslateDynamicText(AMessage),
    ADialogType, AButtons, ADefaultButton, AX, AY, AHelpCtx, AHelpFileName);
end;

procedure TDATFMXDialogTranslationService.MessageDialog(
  const AMessage: string; const ADialogType: TMsgDlgType;
  const AButtons: TMsgDlgButtons; const ADefaultButton: TMsgDlgBtn;
  const AX, AY: Integer; const AHelpCtx: THelpContext;
  const AHelpFileName: string;
  const ACloseDialogProc: TInputCloseDialogProc);
begin
  FLegacy.MessageDialog(DATTranslateDynamicText(AMessage), ADialogType,
    AButtons, ADefaultButton, AX, AY, AHelpCtx, AHelpFileName,
    ACloseDialogProc);
end;

function TDATFMXDialogTranslationService.InputQuery(const ACaption: string;
  const APrompts: array of string; var AValues: array of string;
  const ACloseQueryFunc: TInputCloseQueryFunc): Boolean;
var
  Prompts: TArray<string>;
begin
  Prompts := TranslatedPrompts(APrompts);
  Result := FLegacy.InputQuery(DATTranslateDynamicText(ACaption), Prompts,
    AValues, ACloseQueryFunc);
end;

procedure TDATFMXDialogTranslationService.InputQuery(const ACaption: string;
  const APrompts, ADefaultValues: array of string;
  const ACloseQueryProc: TInputCloseQueryProc);
var
  Prompts: TArray<string>;
begin
  Prompts := TranslatedPrompts(APrompts);
  FLegacy.InputQuery(DATTranslateDynamicText(ACaption), Prompts,
    ADefaultValues, ACloseQueryProc);
end;

procedure TDATFMXDialogTranslationService.ShowMessageSync(
  const AMessage: string);
begin
  FSync.ShowMessageSync(DATTranslateDynamicText(AMessage));
end;

function TDATFMXDialogTranslationService.MessageDialogSync(
  const AMessage: string; const ADialogType: TMsgDlgType;
  const AButtons: TMsgDlgButtons; const ADefaultButton: TMsgDlgBtn;
  const AHelpCtx: THelpContext): Integer;
begin
  Result := FSync.MessageDialogSync(DATTranslateDynamicText(AMessage),
    ADialogType, AButtons, ADefaultButton, AHelpCtx);
end;

function TDATFMXDialogTranslationService.InputQuerySync(
  const ACaption: string; const APrompts: array of string;
  var AValues: array of string): Boolean;
var
  Prompts: TArray<string>;
begin
  Prompts := TranslatedPrompts(APrompts);
  Result := FSync.InputQuerySync(DATTranslateDynamicText(ACaption), Prompts,
    AValues);
end;

procedure TDATFMXDialogTranslationService.ShowMessageAsync(
  const AMessage: string);
begin
  FAsync.ShowMessageAsync(DATTranslateDynamicText(AMessage));
end;

procedure TDATFMXDialogTranslationService.ShowMessageAsync(
  const AMessage: string; const ACloseDialogProc: TInputCloseDialogProc);
begin
  FAsync.ShowMessageAsync(DATTranslateDynamicText(AMessage),
    ACloseDialogProc);
end;

procedure TDATFMXDialogTranslationService.ShowMessageAsync(
  const AMessage: string; const ACloseDialogEvent: TInputCloseDialogEvent;
  const AContext: TObject);
begin
  FAsync.ShowMessageAsync(DATTranslateDynamicText(AMessage),
    ACloseDialogEvent, AContext);
end;

procedure TDATFMXDialogTranslationService.MessageDialogAsync(
  const AMessage: string; const ADialogType: TMsgDlgType;
  const AButtons: TMsgDlgButtons; const ADefaultButton: TMsgDlgBtn;
  const AHelpCtx: THelpContext;
  const ACloseDialogProc: TInputCloseDialogProc);
begin
  FAsync.MessageDialogAsync(DATTranslateDynamicText(AMessage), ADialogType,
    AButtons, ADefaultButton, AHelpCtx, ACloseDialogProc);
end;

procedure TDATFMXDialogTranslationService.MessageDialogAsync(
  const AMessage: string; const ADialogType: TMsgDlgType;
  const AButtons: TMsgDlgButtons; const ADefaultButton: TMsgDlgBtn;
  const AHelpCtx: THelpContext;
  const ACloseDialogEvent: TInputCloseDialogEvent;
  const AContext: TObject);
begin
  FAsync.MessageDialogAsync(DATTranslateDynamicText(AMessage), ADialogType,
    AButtons, ADefaultButton, AHelpCtx, ACloseDialogEvent, AContext);
end;

procedure TDATFMXDialogTranslationService.InputQueryAsync(
  const ACaption: string; const APrompts: array of string;
  const ADefaultValues: array of string;
  const ACloseQueryProc: TInputCloseQueryProc);
var
  Prompts: TArray<string>;
begin
  Prompts := TranslatedPrompts(APrompts);
  FAsync.InputQueryAsync(DATTranslateDynamicText(ACaption), Prompts,
    ADefaultValues, ACloseQueryProc);
end;

procedure TDATFMXDialogTranslationService.InputQueryAsync(
  const ACaption: string; const APrompts: array of string;
  const ADefaultValues: array of string;
  const ACloseQueryEvent: TInputCloseQueryWithResultEvent;
  const AContext: TObject);
var
  Prompts: TArray<string>;
begin
  Prompts := TranslatedPrompts(APrompts);
  FAsync.InputQueryAsync(DATTranslateDynamicText(ACaption), Prompts,
    ADefaultValues, ACloseQueryEvent, AContext);
end;

constructor TDATFMXLanguageManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPendingPostShowForms := TList<TCommonCustomForm>.Create;
  if not (csDesigning in ComponentState) then
    InstallFMXDialogTranslationService;
  FAutoRefreshDynamicText := True;
  FDynamicRefreshInterval := 1000;
  FTranslateBrowserContent := False;
  if not (csDesigning in ComponentState) then
    SubscribeToLifecycle;
end;

destructor TDATFMXLanguageManager.Destroy;
begin
  UnsubscribeFromLifecycle;
  if FDynamicTimer <> nil then
  begin
    FDynamicTimer.Enabled := False;
    FDynamicTimer.OnTimer := nil;
  end;
  FDynamicTimer.Free;
  FDynamicTimer := nil;
  FPendingPostShowForms.Free;
  FPendingPostShowForms := nil;
  inherited Destroy;
end;

procedure TDATFMXLanguageManager.DynamicTimerTick(Sender: TObject);
begin
  if FDynamicRefreshBusy then
    Exit;
  FDynamicRefreshBusy := True;
  try
    ProcessPendingPostShowReapply;
    RefreshDynamicText;
  finally
    FDynamicRefreshBusy := False;
  end;
end;

procedure TDATFMXLanguageManager.ProcessPendingPostShowReapply;
var
  Form: TCommonCustomForm;
begin
  if FPendingPostShowForms = nil then
    Exit;
  while FPendingPostShowForms.Count > 0 do
  begin
    Form := FPendingPostShowForms[0];
    FPendingPostShowForms.Delete(0);
    if (Form <> nil) and not (csDestroying in Form.ComponentState) and
      (ActivePack <> nil) then
      TFMXTranslationApplicator.RefreshDirectionLayout(Form, ActivePack,
        ManagedObjectInstanceName(Form));
  end;
  EnsureDynamicTimer;
end;

procedure TDATFMXLanguageManager.QueuePostShowReapply(
  const AForm: TCommonCustomForm);
begin
  if (AForm = nil) or (FPendingPostShowForms = nil) then
    Exit;
  if FPendingPostShowForms.IndexOf(AForm) < 0 then
    FPendingPostShowForms.Add(AForm);
  EnsureDynamicTimer;
  if FDynamicTimer <> nil then
  begin
    { TFormBeforeShownMessage precedes the platform window, OnShow, and the
      form's final alignment pass.  A one-shot timer runs immediately after
      that sequence, when inactive tab scroll boxes have their real client
      width and application responsive code has finished. }
    FDynamicTimer.Interval := 1;
    FDynamicTimer.Enabled := True;
  end;
end;

procedure TDATFMXLanguageManager.EnsureDynamicTimer;
begin
  if (csDesigning in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  if FDynamicTimer = nil then
  begin
    FDynamicTimer := TTimer.Create(nil);
    FDynamicTimer.OnTimer := DynamicTimerTick;
  end;
  FDynamicTimer.Interval := FDynamicRefreshInterval;
  FDynamicTimer.Enabled := FAutoRefreshDynamicText and
    (FDynamicRefreshInterval > 0);
end;

procedure TDATFMXLanguageManager.Loaded;
begin
  inherited Loaded;
  EnsureDynamicTimer;
end;

procedure TDATFMXLanguageManager.RefreshDynamicText;
var
  Form: TObject;
  Forms: TList<TObject>;
begin
  if not Initialized or (ActivePack = nil) then
    Exit;
  Forms := TList<TObject>.Create;
  try
    CollectOpenManagedObjects(Forms);
    for Form in Forms do
    begin
      TFMXTranslationApplicator.RefreshDynamicText(
        TCommonCustomForm(Form), ActivePack);
      { Text the application built for itself, which no property this
        applicator sets ever carried. VCL catches this at the window; FMX
        has no message to catch, so it is corrected here instead. }
      TDATFMXTemplateRewrite.RefreshCaption(TCommonCustomForm(Form),
        ActivePack);
    end;
  finally
    Forms.Free;
  end;
end;

procedure TDATFMXLanguageManager.SetAutoRefreshDynamicText(
  const Value: Boolean);
begin
  FAutoRefreshDynamicText := Value;
  EnsureDynamicTimer;
end;

procedure TDATFMXLanguageManager.SetDynamicRefreshInterval(
  const Value: Cardinal);
begin
  FDynamicRefreshInterval := Value;
  EnsureDynamicTimer;
end;

function TDATFMXLanguageManager.ApplyLanguagePack(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  { The manager is now doing the work, so the startup hook that covered
    forms appearing before any manager existed - a splash, typically - stops.
    It inferred its settings from the shipping defaults; this component was
    told them, and being told beats inferring. }
  TDATSplashTranslation.StandDown;
  Result := TFMXTranslationApplicator.ApplyToForm(
    TCommonCustomForm(AManagedObject), APack, AFormIdentity,
    PreserveControlState, True, FTranslateBrowserContent);
end;

function TDATFMXLanguageManager.RestoreLanguageLayout(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  Result := TFMXTranslationApplicator.ApplyLayoutToForm(
    TCommonCustomForm(AManagedObject), APack, AFormIdentity, False);
end;

function TDATFMXLanguageManager.RestoreSourceLanguage(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  Result := TFMXTranslationApplicator.RestoreSourceLanguage(
    TCommonCustomForm(AManagedObject), APack, AFormIdentity);
end;

function TDATFMXLanguageManager.ApplyToForm(
  const AForm: TCommonCustomForm): Integer;
begin
  Result := ApplyToManagedObject(AForm);
end;

procedure TDATFMXLanguageManager.CollectOpenManagedObjects(
  const AObjects: TList<TObject>);
var
  Form: TCommonCustomForm;
  FormIndex: Integer;
begin
  if Screen = nil then
    Exit;
  for FormIndex := 0 to Screen.FormCount - 1 do
  begin
    Form := Screen.Forms[FormIndex];
    if (Form <> nil) and (TranslateHiddenForms or Form.Visible) and
      (AObjects.IndexOf(Form) < 0) then
      AObjects.Add(Form);
  end;
  for FormIndex := 0 to Screen.PopupFormCount - 1 do
  begin
    Form := Screen.PopupForms[FormIndex];
    if (Form <> nil) and (TranslateHiddenForms or Form.Visible) and
      (AObjects.IndexOf(Form) < 0) then
      AObjects.Add(Form);
  end;
end;

procedure TDATFMXLanguageManager.HandleBeforeShown(const Sender: TObject;
  const AMessage: TMessage);
var
  Form: TCommonCustomForm;
begin
  if AutoTranslateNewForms and (AMessage is TFormBeforeShownMessage) then
  begin
    Form := TFormBeforeShownMessage(AMessage).Value;
    ReapplyToManagedObject(Form);
    QueuePostShowReapply(Form);
  end;
end;

procedure TDATFMXLanguageManager.HandleReleased(const Sender: TObject;
  const AMessage: TMessage);
begin
  if Sender is TCommonCustomForm then
  begin
    if FPendingPostShowForms <> nil then
      FPendingPostShowForms.Remove(TCommonCustomForm(Sender));
    RemoveManagedObject(Sender);
  end;
end;

function TDATFMXLanguageManager.ManagedObjectInstanceName(
  const AManagedObject: TObject): string;
begin
  Result := TCommonCustomForm(AManagedObject).Name;
end;

procedure TDATFMXLanguageManager.SubscribeToLifecycle;
begin
  if FBeforeShownSubscription = 0 then
    FBeforeShownSubscription :=
      TMessageManager.DefaultManager.SubscribeToMessage(
        TFormBeforeShownMessage, HandleBeforeShown);
  if FReleasedSubscription = 0 then
    FReleasedSubscription :=
      TMessageManager.DefaultManager.SubscribeToMessage(
        TFormReleasedMessage, HandleReleased);
end;

function TDATFMXLanguageManager.SupportsManagedObject(
  const AManagedObject: TObject): Boolean;
begin
  Result := AManagedObject is TCommonCustomForm;
end;

procedure TDATFMXLanguageManager.UnsubscribeFromLifecycle;
begin
  if FBeforeShownSubscription <> 0 then
  begin
    TMessageManager.DefaultManager.Unsubscribe(
      TFormBeforeShownMessage, FBeforeShownSubscription);
    FBeforeShownSubscription := 0;
  end;
  if FReleasedSubscription <> 0 then
  begin
    TMessageManager.DefaultManager.Unsubscribe(
      TFormReleasedMessage, FReleasedSubscription);
    FReleasedSubscription := 0;
  end;
end;

initialization
  RegisterClass(TDATFMXLanguageManager);

finalization
  UnregisterClass(TDATFMXLanguageManager);

end.
