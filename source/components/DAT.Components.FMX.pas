unit DAT.Components.FMX;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Messaging,
  System.SysUtils,
  System.Types,
  FMX.Forms,
  FMX.Layouts,
  FMX.TabControl,
  FMX.Types,
  FMX.WebBrowser,
  DAT.Components.Core,
  DAT.Runtime.LanguagePack;

type
  TDATScrollBoundsSubscription = record
    OriginalHandler: TOnCalcContentBoundsEvent;
  end;

  TDATBrowserLifecycleSubscription = record
    OriginalDidStartLoad: TWebBrowserDidStartLoad;
    OriginalDidFinishLoad: TWebBrowserDidFinishLoad;
    OriginalDidFailLoad: TWebBrowserDidFailLoadWithError;
    RequestedVisible: Boolean;
    WaitingForLoad: Boolean;
    LoadStartObserved: Boolean;
    LoadedGeneration: Cardinal;
    PendingGeneration: Cardinal;
  end;

  TDATTabChangeSubscription = record
    OriginalHandler: TNotifyEvent;
  end;

  TDATFMXLanguageManager = class(TDATCustomLanguageManager)
  private
    FBeforeShownSubscription: TMessageSubscriptionId;
    FReleasedSubscription: TMessageSubscriptionId;
    FAutoRefreshDynamicText: Boolean;
    FDynamicRefreshInterval: Cardinal;
    FDynamicRefreshBusy: Boolean;
    FDynamicTimer: TTimer;
    FTranslateBrowserContent: Boolean;
    FBrowserLayoutTimer: TTimer;
    FBrowserLayoutAttempts: Integer;
    FTransitionActive: Boolean;
    FTransitionGeneration: Cardinal;
    FTransitionForms: TList<TCommonCustomForm>;
    FTransitionBrowsers: TList<TCustomWebBrowser>;
    FBrowserLifecycleSubscriptions:
      TDictionary<TCustomWebBrowser, TDATBrowserLifecycleSubscription>;
    FTabChangeSubscriptions:
      TDictionary<TTabControl, TDATTabChangeSubscription>;
    FScrollBoundsSubscriptions:
      TDictionary<TCustomScrollBox, TDATScrollBoundsSubscription>;
    procedure ApplyBrowserAndScrollContracts(
      const AForm: TCommonCustomForm);
    procedure ApplyScrollBottomGutter(const AForm: TCommonCustomForm);
    procedure BrowserLayoutTimerTick(Sender: TObject);
    procedure EnsureBrowserLifecycleContracts(
      const AForm: TCommonCustomForm);
    procedure EnsureDynamicTimer;
    procedure EnsureBrowserLayoutTimer;
    procedure DynamicTimerTick(Sender: TObject);
    procedure HandleBrowserDidFailLoad(Sender: TObject);
    procedure HandleBrowserDidFinishLoad(Sender: TObject);
    procedure HandleBrowserDidStartLoad(Sender: TObject);
    procedure HandleScrollContentBounds(Sender: TObject;
      var ContentBounds: TRectF);
    procedure HandleTabChanged(Sender: TObject);
    function BrowserBelongsToForm(const ABrowser: TCustomWebBrowser;
      const AForm: TCommonCustomForm): Boolean;
    function BrowserIsOnActiveTab(
      const ABrowser: TCustomWebBrowser): Boolean;
    procedure HideFormBrowsers(const AForm: TCommonCustomForm;
      const ACaptureRequestedVisibility: Boolean);
    procedure SynchronizeBrowserVisibility(
      const AForm: TCommonCustomForm);
    procedure ScheduleBrowserLayoutRefresh;
    procedure SetAutoRefreshDynamicText(const Value: Boolean);
    procedure SetDynamicRefreshInterval(const Value: Cardinal);
    procedure SubscribeToLifecycle;
    procedure UnsubscribeFromLifecycle;
    procedure HandleBeforeShown(const Sender: TObject;
      const AMessage: TMessage);
    procedure HandleReleased(const Sender: TObject;
      const AMessage: TMessage);
  protected
    procedure BeginLanguageTransition; override;
    procedure EndLanguageTransition; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    function SupportsManagedObject(
      const AManagedObject: TObject): Boolean; override;
    function ManagedObjectInstanceName(
      const AManagedObject: TObject): string; override;
    function ExpectedFramework: string; override;
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
      write SetAutoRefreshDynamicText default False;
    property DynamicRefreshInterval: Cardinal read FDynamicRefreshInterval
      write SetDynamicRefreshInterval default 1000;
    property TranslateBrowserContent: Boolean read FTranslateBrowserContent
      write FTranslateBrowserContent default False;
  end;

implementation

uses
  System.Math,
  System.UITypes,
  FMX.Controls,
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
  DATFMXDialogManagerCount: Integer;
  DATFMXOriginalLegacyService: IFMXDialogService;
  DATFMXOriginalSyncService: IFMXDialogServiceSync;
  DATFMXOriginalAsyncService: IFMXDialogServiceAsync;
  DATFMXProxyLegacyService: IFMXDialogService;
  DATFMXProxySyncService: IFMXDialogServiceSync;
  DATFMXProxyAsyncService: IFMXDialogServiceAsync;

procedure AcquireFMXDialogTranslationService;
var
  AsyncService: IFMXDialogServiceAsync;
  LegacyService: IFMXDialogService;
  Proxy: TDATFMXDialogTranslationService;
  ProxyInterface: IFMXDialogServiceSync;
  SyncService: IFMXDialogServiceSync;
begin
  if DATFMXDialogManagerCount > 0 then
  begin
    Inc(DATFMXDialogManagerCount);
    Exit;
  end;
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
  DATFMXOriginalLegacyService := LegacyService;
  DATFMXOriginalSyncService := SyncService;
  DATFMXOriginalAsyncService := AsyncService;
  DATFMXProxySyncService := ProxyInterface;
  if LegacyService <> nil then
    DATFMXProxyLegacyService := Proxy as IFMXDialogService;
  if AsyncService <> nil then
    DATFMXProxyAsyncService := Proxy as IFMXDialogServiceAsync;
  if LegacyService <> nil then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXDialogService);
    TPlatformServices.Current.AddPlatformService(IFMXDialogService,
      DATFMXProxyLegacyService);
  end;
  if SyncService <> nil then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXDialogServiceSync);
    TPlatformServices.Current.AddPlatformService(IFMXDialogServiceSync,
      DATFMXProxySyncService);
  end;
  if AsyncService <> nil then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXDialogServiceAsync);
    TPlatformServices.Current.AddPlatformService(IFMXDialogServiceAsync,
      DATFMXProxyAsyncService);
  end;
  DATFMXDialogManagerCount := 1;
end;

procedure ReleaseFMXDialogTranslationService;
var
  CurrentAsync: IFMXDialogServiceAsync;
  CurrentLegacy: IFMXDialogService;
  CurrentSync: IFMXDialogServiceSync;
begin
  if DATFMXDialogManagerCount = 0 then
    Exit;
  Dec(DATFMXDialogManagerCount);
  if DATFMXDialogManagerCount > 0 then
    Exit;

  if (DATFMXProxyLegacyService <> nil) and
    TPlatformServices.Current.SupportsPlatformService(IFMXDialogService,
      CurrentLegacy) and
    (Pointer(CurrentLegacy) = Pointer(DATFMXProxyLegacyService)) then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXDialogService);
    if DATFMXOriginalLegacyService <> nil then
      TPlatformServices.Current.AddPlatformService(IFMXDialogService,
        DATFMXOriginalLegacyService);
  end;
  if (DATFMXProxySyncService <> nil) and
    TPlatformServices.Current.SupportsPlatformService(IFMXDialogServiceSync,
      CurrentSync) and
    (Pointer(CurrentSync) = Pointer(DATFMXProxySyncService)) then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXDialogServiceSync);
    if DATFMXOriginalSyncService <> nil then
      TPlatformServices.Current.AddPlatformService(IFMXDialogServiceSync,
        DATFMXOriginalSyncService);
  end;
  if (DATFMXProxyAsyncService <> nil) and
    TPlatformServices.Current.SupportsPlatformService(IFMXDialogServiceAsync,
      CurrentAsync) and
    (Pointer(CurrentAsync) = Pointer(DATFMXProxyAsyncService)) then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXDialogServiceAsync);
    if DATFMXOriginalAsyncService <> nil then
      TPlatformServices.Current.AddPlatformService(IFMXDialogServiceAsync,
        DATFMXOriginalAsyncService);
  end;
  DATFMXProxyLegacyService := nil;
  DATFMXProxySyncService := nil;
  DATFMXProxyAsyncService := nil;
  DATFMXOriginalLegacyService := nil;
  DATFMXOriginalSyncService := nil;
  DATFMXOriginalAsyncService := nil;
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

{$WARN SYMBOL_DEPRECATED OFF}
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
{$WARN SYMBOL_DEPRECATED ON}

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

function TDATFMXLanguageManager.BrowserBelongsToForm(
  const ABrowser: TCustomWebBrowser;
  const AForm: TCommonCustomForm): Boolean;
begin
  Result := (ABrowser <> nil) and (AForm <> nil) and
    (ABrowser.Root <> nil) and (ABrowser.Root.GetObject = AForm);
  if not Result and (ABrowser <> nil) then
    Result := ABrowser.Owner = AForm;
end;

function TDATFMXLanguageManager.BrowserIsOnActiveTab(
  const ABrowser: TCustomWebBrowser): Boolean;
var
  Ancestor: TFmxObject;
  TabItem: TTabItem;
begin
  Result := ABrowser <> nil;
  if not Result then
    Exit;
  Ancestor := ABrowser.Parent;
  while Ancestor <> nil do
  begin
    if (Ancestor is TControl) and not TControl(Ancestor).Visible then
      Exit(False);
    if Ancestor is TTabItem then
    begin
      TabItem := TTabItem(Ancestor);
      if (TabItem.Parent is TTabControl) and
        (TTabControl(TabItem.Parent).ActiveTab <> TabItem) then
        Exit(False);
    end;
    Ancestor := Ancestor.Parent;
  end;
end;

procedure TDATFMXLanguageManager.EnsureBrowserLifecycleContracts(
  const AForm: TCommonCustomForm);
var
  Visited: TDictionary<TComponent, Boolean>;

  procedure Visit(const AComponent: TComponent);
  var
    Browser: TCustomWebBrowser;
    BrowserSubscription: TDATBrowserLifecycleSubscription;
    ChildIndex: Integer;
    FMXObject: TFmxObject;
    ExpectedFail: TWebBrowserDidFailLoadWithError;
    ExpectedFinish: TWebBrowserDidFinishLoad;
    ExpectedStart: TWebBrowserDidStartLoad;
    ExpectedTabChange: TNotifyEvent;
    TabControl: TTabControl;
    TabSubscription: TDATTabChangeSubscription;
  begin
    if (AComponent = nil) or Visited.ContainsKey(AComponent) then
      Exit;
    Visited.Add(AComponent, True);
    if AComponent is TCustomWebBrowser then
    begin
      Browser := TCustomWebBrowser(AComponent);
      if not FBrowserLifecycleSubscriptions.TryGetValue(Browser,
        BrowserSubscription) then
      begin
        BrowserSubscription := Default(TDATBrowserLifecycleSubscription);
        BrowserSubscription.OriginalDidStartLoad := Browser.OnDidStartLoad;
        BrowserSubscription.OriginalDidFinishLoad := Browser.OnDidFinishLoad;
        BrowserSubscription.OriginalDidFailLoad :=
          Browser.OnDidFailLoadWithError;
        BrowserSubscription.RequestedVisible := Browser.Visible;
        BrowserSubscription.LoadedGeneration := Generation;
        FBrowserLifecycleSubscriptions.Add(Browser, BrowserSubscription);
        Browser.FreeNotification(Self);
      end;
      ExpectedStart := HandleBrowserDidStartLoad;
      if (TMethod(Browser.OnDidStartLoad).Code <>
          TMethod(ExpectedStart).Code) or
        (TMethod(Browser.OnDidStartLoad).Data <>
          TMethod(ExpectedStart).Data) then
      begin
        BrowserSubscription.OriginalDidStartLoad := Browser.OnDidStartLoad;
        Browser.OnDidStartLoad := ExpectedStart;
      end;
      ExpectedFinish := HandleBrowserDidFinishLoad;
      if (TMethod(Browser.OnDidFinishLoad).Code <>
          TMethod(ExpectedFinish).Code) or
        (TMethod(Browser.OnDidFinishLoad).Data <>
          TMethod(ExpectedFinish).Data) then
      begin
        BrowserSubscription.OriginalDidFinishLoad := Browser.OnDidFinishLoad;
        Browser.OnDidFinishLoad := ExpectedFinish;
      end;
      ExpectedFail := HandleBrowserDidFailLoad;
      if (TMethod(Browser.OnDidFailLoadWithError).Code <>
          TMethod(ExpectedFail).Code) or
        (TMethod(Browser.OnDidFailLoadWithError).Data <>
          TMethod(ExpectedFail).Data) then
      begin
        BrowserSubscription.OriginalDidFailLoad :=
          Browser.OnDidFailLoadWithError;
        Browser.OnDidFailLoadWithError := ExpectedFail;
      end;
      FBrowserLifecycleSubscriptions.AddOrSetValue(Browser,
        BrowserSubscription);
    end
    else if AComponent is TTabControl then
    begin
      TabControl := TTabControl(AComponent);
      if not FTabChangeSubscriptions.TryGetValue(TabControl,
        TabSubscription) then
      begin
        TabSubscription.OriginalHandler := TabControl.OnChange;
        FTabChangeSubscriptions.Add(TabControl, TabSubscription);
        TabControl.FreeNotification(Self);
      end;
      ExpectedTabChange := HandleTabChanged;
      if (TMethod(TabControl.OnChange).Code <>
          TMethod(ExpectedTabChange).Code) or
        (TMethod(TabControl.OnChange).Data <>
          TMethod(ExpectedTabChange).Data) then
      begin
        TabSubscription.OriginalHandler := TabControl.OnChange;
        TabControl.OnChange := ExpectedTabChange;
        FTabChangeSubscriptions.AddOrSetValue(TabControl,
          TabSubscription);
      end;
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
      Visit(AComponent.Components[ChildIndex]);
    { Runtime-created FMX controls are not required to share the form's
      Owner. Walk the visual tree as well as the ownership tree so browser
      and tab contracts also cover those controls. Visited prevents the two
      traversals from applying a contract twice. }
    if AComponent is TFmxObject then
    begin
      FMXObject := TFmxObject(AComponent);
      for ChildIndex := 0 to FMXObject.ChildrenCount - 1 do
        if FMXObject.Children[ChildIndex] is TComponent then
          Visit(TComponent(FMXObject.Children[ChildIndex]));
    end;
  end;
begin
  if (AForm = nil) or (csDestroying in ComponentState) then
    Exit;
  Visited := TDictionary<TComponent, Boolean>.Create;
  try
    Visit(AForm);
  finally
    Visited.Free;
  end;
end;

procedure TDATFMXLanguageManager.HideFormBrowsers(
  const AForm: TCommonCustomForm;
  const ACaptureRequestedVisibility: Boolean);
var
  Browser: TCustomWebBrowser;
  Browsers: TArray<TCustomWebBrowser>;
  BrowserSubscription: TDATBrowserLifecycleSubscription;
begin
  if FBrowserLifecycleSubscriptions = nil then
    Exit;
  Browsers := FBrowserLifecycleSubscriptions.Keys.ToArray;
  for Browser in Browsers do
    if BrowserBelongsToForm(Browser, AForm) and
      FBrowserLifecycleSubscriptions.TryGetValue(Browser,
        BrowserSubscription) then
    begin
      if ACaptureRequestedVisibility and Browser.Visible then
        BrowserSubscription.RequestedVisible := True;
      Browser.Visible := False;
      FBrowserLifecycleSubscriptions.AddOrSetValue(Browser,
        BrowserSubscription);
      if (FTransitionBrowsers <> nil) and
        (FTransitionBrowsers.IndexOf(Browser) < 0) then
        FTransitionBrowsers.Add(Browser);
    end;
end;

procedure TDATFMXLanguageManager.HandleBrowserDidStartLoad(
  Sender: TObject);
var
  Browser: TCustomWebBrowser;
  BrowserSubscription: TDATBrowserLifecycleSubscription;
  OriginalHandler: TWebBrowserDidStartLoad;
begin
  if not (Sender is TCustomWebBrowser) then
    Exit;
  Browser := TCustomWebBrowser(Sender);
  if not FBrowserLifecycleSubscriptions.TryGetValue(Browser,
    BrowserSubscription) then
    Exit;
  OriginalHandler := BrowserSubscription.OriginalDidStartLoad;
  if Browser.Visible then
    BrowserSubscription.RequestedVisible := True;
  BrowserSubscription.WaitingForLoad := True;
  BrowserSubscription.LoadStartObserved := True;
  if FTransitionActive then
    BrowserSubscription.PendingGeneration := FTransitionGeneration
  else
    BrowserSubscription.PendingGeneration := Generation;
  Browser.Visible := False;
  FBrowserLifecycleSubscriptions.AddOrSetValue(Browser,
    BrowserSubscription);
  if Assigned(OriginalHandler) then
    OriginalHandler(Sender);
end;

procedure TDATFMXLanguageManager.HandleBrowserDidFinishLoad(
  Sender: TObject);
var
  Browser: TCustomWebBrowser;
  BrowserSubscription: TDATBrowserLifecycleSubscription;
  Form: TCommonCustomForm;
  OriginalHandler: TWebBrowserDidFinishLoad;
begin
  if not (Sender is TCustomWebBrowser) then
    Exit;
  Browser := TCustomWebBrowser(Sender);
  if not FBrowserLifecycleSubscriptions.TryGetValue(Browser,
    BrowserSubscription) then
    Exit;
  OriginalHandler := BrowserSubscription.OriginalDidFinishLoad;
  if Assigned(OriginalHandler) then
    OriginalHandler(Sender);
  if not FBrowserLifecycleSubscriptions.TryGetValue(Browser,
    BrowserSubscription) then
    Exit;
  { OnDidFinishLoad is the first point at which the document's actual cells,
    computed padding and overflow are available.  Apply the measured contract
    before exposing the native browser surface.  This is independent of the
    host application's form names, CSS classes and coordinates. }
  Form := nil;
  if (Browser.Root <> nil) and
    (Browser.Root.GetObject is TCommonCustomForm) then
    Form := TCommonCustomForm(Browser.Root.GetObject)
  else if Browser.Owner is TCommonCustomForm then
    Form := TCommonCustomForm(Browser.Owner);
  if (Form <> nil) and (ActivePack <> nil) then
    TFMXTranslationApplicator.RefreshBrowserLayout(Form, ActivePack);
  if BrowserSubscription.PendingGeneration <> 0 then
    BrowserSubscription.LoadedGeneration :=
      BrowserSubscription.PendingGeneration
  else if FTransitionActive then
    BrowserSubscription.LoadedGeneration := FTransitionGeneration
  else
    BrowserSubscription.LoadedGeneration := Generation;
  BrowserSubscription.PendingGeneration := 0;
  BrowserSubscription.WaitingForLoad := False;
  BrowserSubscription.LoadStartObserved := False;
  Browser.Visible := not FTransitionActive and
    BrowserSubscription.RequestedVisible and
    (BrowserSubscription.LoadedGeneration = Generation) and
    BrowserIsOnActiveTab(Browser);
  FBrowserLifecycleSubscriptions.AddOrSetValue(Browser,
    BrowserSubscription);
  ScheduleBrowserLayoutRefresh;
end;

procedure TDATFMXLanguageManager.HandleBrowserDidFailLoad(
  Sender: TObject);
var
  Browser: TCustomWebBrowser;
  BrowserSubscription: TDATBrowserLifecycleSubscription;
  OriginalHandler: TWebBrowserDidFailLoadWithError;
begin
  if not (Sender is TCustomWebBrowser) then
    Exit;
  Browser := TCustomWebBrowser(Sender);
  if not FBrowserLifecycleSubscriptions.TryGetValue(Browser,
    BrowserSubscription) then
    Exit;
  OriginalHandler := BrowserSubscription.OriginalDidFailLoad;
  if Assigned(OriginalHandler) then
    OriginalHandler(Sender);
  if not FBrowserLifecycleSubscriptions.TryGetValue(Browser,
    BrowserSubscription) then
    Exit;
  BrowserSubscription.PendingGeneration := 0;
  BrowserSubscription.WaitingForLoad := False;
  BrowserSubscription.LoadStartObserved := False;
  BrowserSubscription.LoadedGeneration := Generation;
  Browser.Visible := not FTransitionActive and
    BrowserSubscription.RequestedVisible and
    BrowserIsOnActiveTab(Browser);
  FBrowserLifecycleSubscriptions.AddOrSetValue(Browser,
    BrowserSubscription);
end;

procedure TDATFMXLanguageManager.HandleTabChanged(Sender: TObject);
var
  Browser: TCustomWebBrowser;
  Browsers: TArray<TCustomWebBrowser>;
  BrowserSubscription: TDATBrowserLifecycleSubscription;
  Form: TCommonCustomForm;
  OriginalHandler: TNotifyEvent;
  TabControl: TTabControl;
  TabSubscription: TDATTabChangeSubscription;
begin
  if not (Sender is TTabControl) then
    Exit;
  TabControl := TTabControl(Sender);
  if not FTabChangeSubscriptions.TryGetValue(TabControl,
    TabSubscription) then
    Exit;
  OriginalHandler := TabSubscription.OriginalHandler;
  Form := nil;
  if (TabControl.Root <> nil) and
    (TabControl.Root.GetObject is TCommonCustomForm) then
    Form := TCommonCustomForm(TabControl.Root.GetObject);
  if Form <> nil then
  begin
    EnsureBrowserLifecycleContracts(Form);
    HideFormBrowsers(Form, True);
  end;
  if Assigned(OriginalHandler) then
    OriginalHandler(Sender);
  if Form = nil then
    Exit;
  EnsureBrowserLifecycleContracts(Form);
  Browsers := FBrowserLifecycleSubscriptions.Keys.ToArray;
  for Browser in Browsers do
    if BrowserBelongsToForm(Browser, Form) and
      FBrowserLifecycleSubscriptions.TryGetValue(Browser,
        BrowserSubscription) then
    begin
      if Browser.Visible then
        BrowserSubscription.RequestedVisible := True;
      if BrowserIsOnActiveTab(Browser) then
      begin
        if BrowserSubscription.LoadedGeneration = Generation then
        begin
          BrowserSubscription.WaitingForLoad := False;
          Browser.Visible := BrowserSubscription.RequestedVisible;
        end
        else
        begin
          BrowserSubscription.WaitingForLoad := True;
          if BrowserSubscription.PendingGeneration = 0 then
            BrowserSubscription.PendingGeneration := Generation;
          Browser.Visible := False;
        end;
      end
      else
        Browser.Visible := False;
      FBrowserLifecycleSubscriptions.AddOrSetValue(Browser,
        BrowserSubscription);
    end;
  ScheduleBrowserLayoutRefresh;
end;

procedure TDATFMXLanguageManager.SynchronizeBrowserVisibility(
  const AForm: TCommonCustomForm);
var
  Browser: TCustomWebBrowser;
  Browsers: TArray<TCustomWebBrowser>;
  BrowserSubscription: TDATBrowserLifecycleSubscription;
begin
  if FBrowserLifecycleSubscriptions = nil then
    Exit;
  Browsers := FBrowserLifecycleSubscriptions.Keys.ToArray;
  for Browser in Browsers do
    if BrowserBelongsToForm(Browser, AForm) and
      FBrowserLifecycleSubscriptions.TryGetValue(Browser,
        BrowserSubscription) then
    begin
      if not BrowserIsOnActiveTab(Browser) then
        Browser.Visible := False
      else if FTransitionActive then
        Browser.Visible := False
      else if BrowserSubscription.WaitingForLoad then
      begin
        if (BrowserSubscription.LoadedGeneration = Generation) and
          not BrowserSubscription.LoadStartObserved then
        begin
          BrowserSubscription.WaitingForLoad := False;
          BrowserSubscription.PendingGeneration := 0;
          Browser.Visible := BrowserSubscription.RequestedVisible;
        end
        else
        begin
          { Never turn elapsed time into proof that an asynchronous browser
            contains the current language. If a host does not navigate or
            does not report completion, keep the native surface hidden. A
            blank page is recoverable; exposing a stale language frame is
            the transition defect this contract exists to prevent. }
          Browser.Visible := False;
        end;
      end
      else
        Browser.Visible := BrowserSubscription.RequestedVisible and
          (BrowserSubscription.LoadedGeneration = Generation);
      FBrowserLifecycleSubscriptions.AddOrSetValue(Browser,
        BrowserSubscription);
    end;
end;

constructor TDATFMXLanguageManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBrowserLifecycleSubscriptions :=
    TDictionary<TCustomWebBrowser,
      TDATBrowserLifecycleSubscription>.Create;
  FTabChangeSubscriptions :=
    TDictionary<TTabControl, TDATTabChangeSubscription>.Create;
  if not (csDesigning in ComponentState) then
    AcquireFMXDialogTranslationService;
  FAutoRefreshDynamicText := False;
  FDynamicRefreshInterval := 1000;
  FTranslateBrowserContent := False;
  if not (csDesigning in ComponentState) then
    SubscribeToLifecycle;
end;

destructor TDATFMXLanguageManager.Destroy;
var
  Browser: TCustomWebBrowser;
  BrowserSubscription: TDATBrowserLifecycleSubscription;
  CurrentHandler: TOnCalcContentBoundsEvent;
  CurrentBrowserFail: TWebBrowserDidFailLoadWithError;
  CurrentBrowserFinish: TWebBrowserDidFinishLoad;
  CurrentBrowserStart: TWebBrowserDidStartLoad;
  CurrentTabChange: TNotifyEvent;
  ExpectedBrowserFail: TWebBrowserDidFailLoadWithError;
  ExpectedBrowserFinish: TWebBrowserDidFinishLoad;
  ExpectedBrowserStart: TWebBrowserDidStartLoad;
  ExpectedHandler: TOnCalcContentBoundsEvent;
  ExpectedTabChange: TNotifyEvent;
  Form: TCommonCustomForm;
  ScrollBox: TCustomScrollBox;
  Subscription: TDATScrollBoundsSubscription;
  TabControl: TTabControl;
  TabSubscription: TDATTabChangeSubscription;
begin
  UnsubscribeFromLifecycle;
  FTransitionActive := False;
  if not (csDesigning in ComponentState) then
    ReleaseFMXDialogTranslationService;
  if FDynamicTimer <> nil then
  begin
    FDynamicTimer.Enabled := False;
    FDynamicTimer.OnTimer := nil;
  end;
  FDynamicTimer.Free;
  FDynamicTimer := nil;
  if FBrowserLayoutTimer <> nil then
  begin
    FBrowserLayoutTimer.Enabled := False;
    FBrowserLayoutTimer.OnTimer := nil;
  end;
  FBrowserLayoutTimer.Free;
  FBrowserLayoutTimer := nil;
  if FTransitionForms <> nil then
    for Form in FTransitionForms do
      if Form <> nil then
        Form.EndUpdate;
  FTransitionBrowsers.Free;
  FTransitionBrowsers := nil;
  FTransitionForms.Free;
  FTransitionForms := nil;
  if FBrowserLifecycleSubscriptions <> nil then
  begin
    ExpectedBrowserStart := HandleBrowserDidStartLoad;
    ExpectedBrowserFinish := HandleBrowserDidFinishLoad;
    ExpectedBrowserFail := HandleBrowserDidFailLoad;
    for Browser in FBrowserLifecycleSubscriptions.Keys do
      if (Browser <> nil) and
        FBrowserLifecycleSubscriptions.TryGetValue(Browser,
          BrowserSubscription) then
      begin
        CurrentBrowserStart := Browser.OnDidStartLoad;
        if (TMethod(CurrentBrowserStart).Code =
            TMethod(ExpectedBrowserStart).Code) and
          (TMethod(CurrentBrowserStart).Data =
            TMethod(ExpectedBrowserStart).Data) then
          Browser.OnDidStartLoad :=
            BrowserSubscription.OriginalDidStartLoad;
        CurrentBrowserFinish := Browser.OnDidFinishLoad;
        if (TMethod(CurrentBrowserFinish).Code =
            TMethod(ExpectedBrowserFinish).Code) and
          (TMethod(CurrentBrowserFinish).Data =
            TMethod(ExpectedBrowserFinish).Data) then
          Browser.OnDidFinishLoad :=
            BrowserSubscription.OriginalDidFinishLoad;
        CurrentBrowserFail := Browser.OnDidFailLoadWithError;
        if (TMethod(CurrentBrowserFail).Code =
            TMethod(ExpectedBrowserFail).Code) and
          (TMethod(CurrentBrowserFail).Data =
            TMethod(ExpectedBrowserFail).Data) then
          Browser.OnDidFailLoadWithError :=
            BrowserSubscription.OriginalDidFailLoad;
        Browser.Visible := BrowserSubscription.RequestedVisible and
          BrowserIsOnActiveTab(Browser);
      end;
  end;
  FBrowserLifecycleSubscriptions.Free;
  FBrowserLifecycleSubscriptions := nil;
  if FTabChangeSubscriptions <> nil then
  begin
    ExpectedTabChange := HandleTabChanged;
    for TabControl in FTabChangeSubscriptions.Keys do
      if (TabControl <> nil) and
        FTabChangeSubscriptions.TryGetValue(TabControl,
          TabSubscription) then
      begin
        CurrentTabChange := TabControl.OnChange;
        if (TMethod(CurrentTabChange).Code =
            TMethod(ExpectedTabChange).Code) and
          (TMethod(CurrentTabChange).Data =
            TMethod(ExpectedTabChange).Data) then
          TabControl.OnChange := TabSubscription.OriginalHandler;
      end;
  end;
  FTabChangeSubscriptions.Free;
  FTabChangeSubscriptions := nil;
  if FScrollBoundsSubscriptions <> nil then
  begin
    ExpectedHandler := HandleScrollContentBounds;
    for ScrollBox in FScrollBoundsSubscriptions.Keys do
      if ScrollBox <> nil then
      begin
        CurrentHandler := ScrollBox.OnCalcContentBounds;
        if (TMethod(CurrentHandler).Code = TMethod(ExpectedHandler).Code) and
          (TMethod(CurrentHandler).Data = TMethod(ExpectedHandler).Data) and
          FScrollBoundsSubscriptions.TryGetValue(ScrollBox, Subscription) then
          ScrollBox.OnCalcContentBounds := Subscription.OriginalHandler;
      end;
  end;
  FScrollBoundsSubscriptions.Free;
  FScrollBoundsSubscriptions := nil;
  inherited Destroy;
end;

procedure TDATFMXLanguageManager.ApplyBrowserAndScrollContracts(
  const AForm: TCommonCustomForm);
begin
  if (AForm = nil) or (ActivePack = nil) then
    Exit;
  EnsureBrowserLifecycleContracts(AForm);
  TFMXTranslationApplicator.RefreshBrowserLayout(AForm, ActivePack);
  ApplyScrollBottomGutter(AForm);
end;

procedure TDATFMXLanguageManager.ApplyScrollBottomGutter(
  const AForm: TCommonCustomForm);
const
  BottomGutter = 18;
var
  Visited: TDictionary<TComponent, Boolean>;

  procedure Visit(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    ScrollBox: TCustomScrollBox;
    Subscription: TDATScrollBoundsSubscription;
  begin
    if (AComponent = nil) or Visited.ContainsKey(AComponent) then
      Exit;
    Visited.Add(AComponent, True);
    if AComponent is TCustomScrollBox then
    begin
      ScrollBox := TCustomScrollBox(AComponent);
      { Keep the desired gutter visible in the Object Inspector when the
        application already exposes this runtime-created control there. }
      if ScrollBox.Padding.Bottom < BottomGutter then
        ScrollBox.Padding.Bottom := BottomGutter;
      if FScrollBoundsSubscriptions = nil then
        FScrollBoundsSubscriptions :=
          TDictionary<TCustomScrollBox,
            TDATScrollBoundsSubscription>.Create;
      if not FScrollBoundsSubscriptions.ContainsKey(ScrollBox) then
      begin
        Subscription.OriginalHandler := ScrollBox.OnCalcContentBounds;
        FScrollBoundsSubscriptions.Add(ScrollBox, Subscription);
        ScrollBox.FreeNotification(Self);
        ScrollBox.OnCalcContentBounds := HandleScrollContentBounds;
      end;
      ScrollBox.RealignContent;
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
      Visit(AComponent.Components[ChildIndex]);
  end;
begin
  if AForm = nil then
    Exit;
  Visited := TDictionary<TComponent, Boolean>.Create;
  try
    Visit(AForm);
  finally
    Visited.Free;
  end;
end;

procedure TDATFMXLanguageManager.BeginLanguageTransition;
var
  Form: TCommonCustomForm;
  ManagedObject: TObject;
  ManagedObjects: TList<TObject>;
begin
  if (csDesigning in ComponentState) or
    (csDestroying in ComponentState) then
    Exit;
  if FBrowserLayoutTimer <> nil then
    FBrowserLayoutTimer.Enabled := False;
  FreeAndNil(FTransitionBrowsers);
  FreeAndNil(FTransitionForms);
  FTransitionBrowsers := TList<TCustomWebBrowser>.Create;
  FTransitionForms := TList<TCommonCustomForm>.Create;
  FTransitionActive := True;
  FTransitionGeneration := Generation + 1;
  if FTransitionGeneration = 0 then
    Inc(FTransitionGeneration);
  ManagedObjects := TList<TObject>.Create;
  try
    try
      CollectManagedObjects(ManagedObjects);
      for ManagedObject in ManagedObjects do
        if ManagedObject is TCommonCustomForm then
        begin
          Form := TCommonCustomForm(ManagedObject);
          EnsureBrowserLifecycleContracts(Form);
          { A native WebView is not painted by the FMX scene graph. Hide it
            before locking the form so no queued native frame can escape the
            language transaction. }
          HideFormBrowsers(Form, True);
          Form.BeginUpdate;
          FTransitionForms.Add(Form);
          Form.FreeNotification(Self);
        end;
    except
      { A half-started transition must never leave a form update-locked or a
        native browser hidden.  Reuse the normal cleanup path, then surface
        the original exception to the manager's failure policy. }
      EndLanguageTransition;
      raise;
    end;
  finally
    ManagedObjects.Free;
  end;
end;

procedure TDATFMXLanguageManager.BrowserLayoutTimerTick(Sender: TObject);
var
  Form: TObject;
  Forms: TList<TObject>;
begin
  if (ActivePack = nil) or (csDestroying in ComponentState) then
  begin
    FBrowserLayoutTimer.Enabled := False;
    Exit;
  end;
  Inc(FBrowserLayoutAttempts);
  Forms := TList<TObject>.Create;
  try
    CollectOpenManagedObjects(Forms);
    for Form in Forms do
    begin
      ApplyBrowserAndScrollContracts(TCommonCustomForm(Form));
      SynchronizeBrowserVisibility(TCommonCustomForm(Form));
    end;
  finally
    Forms.Free;
  end;
  if FBrowserLayoutAttempts >= 6 then
    FBrowserLayoutTimer.Enabled := False;
end;

procedure TDATFMXLanguageManager.DynamicTimerTick(Sender: TObject);
begin
  if FDynamicRefreshBusy then
    Exit;
  FDynamicRefreshBusy := True;
  try
    RefreshDynamicText;
  finally
    FDynamicRefreshBusy := False;
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

procedure TDATFMXLanguageManager.EnsureBrowserLayoutTimer;
begin
  if (csDesigning in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  if FBrowserLayoutTimer = nil then
  begin
    FBrowserLayoutTimer := TTimer.Create(nil);
    FBrowserLayoutTimer.Interval := 180;
    FBrowserLayoutTimer.OnTimer := BrowserLayoutTimerTick;
  end;
end;

procedure TDATFMXLanguageManager.EndLanguageTransition;
var
  Browser: TCustomWebBrowser;
  BrowserSubscription: TDATBrowserLifecycleSubscription;
  Form: TCommonCustomForm;
begin
  try
    if FTransitionForms <> nil then
      for Form in FTransitionForms do
        if Form <> nil then
        begin
          EnsureBrowserLifecycleContracts(Form);
          ApplyBrowserAndScrollContracts(Form);
        end;
  finally
    { Application callbacks may request a browser visible after starting an
      asynchronous navigation. Capture that request, but keep the native
      surface hidden before the FMX scene lock is released, and until the
      current generation reports completion. }
    if (FTransitionBrowsers <> nil) and
      (FBrowserLifecycleSubscriptions <> nil) then
      for Browser in FTransitionBrowsers do
        if (Browser <> nil) and
          FBrowserLifecycleSubscriptions.TryGetValue(Browser,
            BrowserSubscription) then
        begin
          if Browser.Visible then
            BrowserSubscription.RequestedVisible := True;
          Browser.Visible := False;
          if BrowserIsOnActiveTab(Browser) then
          begin
            if FTranslateBrowserContent and
              not BrowserSubscription.LoadStartObserved then
            begin
              BrowserSubscription.LoadedGeneration := Generation;
              BrowserSubscription.WaitingForLoad := False;
              BrowserSubscription.PendingGeneration := 0;
            end
            else if BrowserSubscription.LoadedGeneration <> Generation then
            begin
              BrowserSubscription.WaitingForLoad := True;
              if BrowserSubscription.PendingGeneration = 0 then
                BrowserSubscription.PendingGeneration := Generation;
            end;
          end;
          FBrowserLifecycleSubscriptions.AddOrSetValue(Browser,
            BrowserSubscription);
        end;
    if FTransitionForms <> nil then
      for Form in FTransitionForms do
        if Form <> nil then
        begin
          Form.EndUpdate;
          Form.Invalidate;
        end;
    FTransitionActive := False;
    if FTransitionForms <> nil then
      for Form in FTransitionForms do
        if Form <> nil then
          SynchronizeBrowserVisibility(Form);
    FreeAndNil(FTransitionBrowsers);
    FreeAndNil(FTransitionForms);
  end;
  FTransitionGeneration := 0;
  ScheduleBrowserLayoutRefresh;
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
  ApplyScrollBottomGutter(TCommonCustomForm(AManagedObject));
end;

function TDATFMXLanguageManager.ExpectedFramework: string;
begin
  Result := 'FireMonkey';
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
    EnsureBrowserLifecycleContracts(Form);
    { FormCreate has completed by this notification, while controls created
      by FormShow can appear immediately afterward. The bounded refresh finds
      both groups without polling for the life of the application. }
    ScheduleBrowserLayoutRefresh;
  end;
end;

procedure TDATFMXLanguageManager.HandleReleased(const Sender: TObject;
  const AMessage: TMessage);
begin
  if Sender is TCommonCustomForm then
  begin
    if FTransitionForms <> nil then
      FTransitionForms.Remove(TCommonCustomForm(Sender));
    RemoveManagedObject(Sender);
  end;
end;

procedure TDATFMXLanguageManager.HandleScrollContentBounds(Sender: TObject;
  var ContentBounds: TRectF);
const
  BottomGutter = 18;
var
  Child: TControl;
  ChildIndex: Integer;
  Content: TScrollContent;
  DesiredBottom: Single;
  ScrollBox: TCustomScrollBox;
  Subscription: TDATScrollBoundsSubscription;
begin
  if (Sender is TCustomScrollBox) and
    (FScrollBoundsSubscriptions <> nil) then
  begin
    ScrollBox := TCustomScrollBox(Sender);
    if FScrollBoundsSubscriptions.TryGetValue(ScrollBox, Subscription) and
      Assigned(Subscription.OriginalHandler) then
      Subscription.OriginalHandler(Sender, ContentBounds);
  end;
  if not (Sender is TCustomScrollBox) then
    Exit;
  ScrollBox := TCustomScrollBox(Sender);
  Content := nil;
  if ScrollBox is TScrollBox then
    Content := TScrollBox(ScrollBox).Content
  else if ScrollBox is TVertScrollBox then
    Content := TVertScrollBox(ScrollBox).Content
  else if ScrollBox is THorzScrollBox then
    Content := THorzScrollBox(ScrollBox).Content
  else if ScrollBox is TFramedScrollBox then
    Content := TFramedScrollBox(ScrollBox).Content;
  if Content = nil then
    Exit;
  DesiredBottom := ContentBounds.Bottom;
  for ChildIndex := 0 to Content.ControlsCount - 1 do
  begin
    Child := Content.Controls[ChildIndex];
    if Child.Visible then
      DesiredBottom := Max(DesiredBottom,
        Child.ConvertLocalPointTo(Child.ParentControl,
          Child.LocalRect.BottomRight).Y + BottomGutter);
  end;
  if ContentBounds.Bottom < DesiredBottom then
    ContentBounds.Bottom := DesiredBottom;
end;

function TDATFMXLanguageManager.ManagedObjectInstanceName(
  const AManagedObject: TObject): string;
begin
  Result := TCommonCustomForm(AManagedObject).Name;
end;

procedure TDATFMXLanguageManager.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation <> opRemove then
    Exit;
  if (FTransitionBrowsers <> nil) and
    (AComponent is TCustomWebBrowser) then
    FTransitionBrowsers.Remove(TCustomWebBrowser(AComponent));
  if (FBrowserLifecycleSubscriptions <> nil) and
    (AComponent is TCustomWebBrowser) then
    FBrowserLifecycleSubscriptions.Remove(TCustomWebBrowser(AComponent));
  if (FTabChangeSubscriptions <> nil) and
    (AComponent is TTabControl) then
    FTabChangeSubscriptions.Remove(TTabControl(AComponent));
  if (FTransitionForms <> nil) and
    (AComponent is TCommonCustomForm) then
    FTransitionForms.Remove(TCommonCustomForm(AComponent));
  if (FScrollBoundsSubscriptions <> nil) and
    (AComponent is TCustomScrollBox) then
    FScrollBoundsSubscriptions.Remove(TCustomScrollBox(AComponent));
end;

procedure TDATFMXLanguageManager.ScheduleBrowserLayoutRefresh;
begin
  EnsureBrowserLayoutTimer;
  if FBrowserLayoutTimer = nil then
    Exit;
  FBrowserLayoutAttempts := 0;
  FBrowserLayoutTimer.Enabled := True;
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
