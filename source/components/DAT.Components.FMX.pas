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
    FSizeChangedSubscription: TMessageSubscriptionId;
    FAutoRefreshDynamicText: Boolean;
    FDynamicRefreshInterval: Cardinal;
    FDynamicRefreshBusy: Boolean;
    FDynamicTimer: TTimer;
    FTranslateBrowserContent: Boolean;
    FBrowserTranslationRegistered: Boolean;
    FBrowserLifecycleTimer: TTimer;
    FBrowserLifecycleAttempts: Integer;
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
    procedure RefreshActiveTabLayouts(const AForm: TCommonCustomForm);
    procedure BrowserLifecycleTimerTick(Sender: TObject);
    procedure EnsureBrowserLifecycleContracts(
      const AForm: TCommonCustomForm);
    procedure EnsureDynamicTimer;
    procedure EnsureBrowserLifecycleTimer;
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
    procedure ScheduleBrowserLifecycleRefresh;
    procedure SetAutoRefreshDynamicText(const Value: Boolean);
    procedure SetDynamicRefreshInterval(const Value: Cardinal);
    procedure SetTranslateBrowserContent(const Value: Boolean);
    procedure SubscribeToLifecycle;
    procedure UnsubscribeFromLifecycle;
    procedure HandleBeforeShown(const Sender: TObject;
      const AMessage: TMessage);
    procedure HandleReleased(const Sender: TObject;
      const AMessage: TMessage);
    procedure HandleSizeChanged(const Sender: TObject;
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
      write SetAutoRefreshDynamicText default True;
    property DynamicRefreshInterval: Cardinal read FDynamicRefreshInterval
      write SetDynamicRefreshInterval default 1000;
    property TranslateBrowserContent: Boolean read FTranslateBrowserContent
      write SetTranslateBrowserContent default True;
  end;

implementation

uses
  System.Math,
  System.UITypes,
  FMX.Controls,
  FMX.Dialogs,
  FMX.Graphics,
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

const
  { A browser control can be created during FormShow. Keep the lifecycle
    discovery window bounded, but long enough to find a normally delayed
    native browser and connect its load/visibility events. }
  BrowserLifecycleRefreshInterval = 250;
  BrowserLifecycleMaximumAttempts = 48;

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

  { TWebBrowser sends LoadFromStrings directly to a platform-created
    ICustomBrowser.  Decorating that factory gives the translation runtime the
    complete original HTML before it is rendered.  Only visible text nodes are
    translated by DATTranslateHtmlText; tags and CSS are passed through byte
    for byte, with no JavaScript and no DOM or target-application changes. }
  IDATFMXTranslatedBrowser = interface(IInterface)
    ['{FEBE0A2D-A815-446E-A46D-9B8CBFA67379}']
    function BrowserControl: TCustomWebBrowser;
    function InnerBrowser: ICustomBrowser;
    procedure MarkTranslationStale;
    procedure RefreshTranslatedContent;
    procedure RetryPendingContent;
  end;

  TDATFMXTranslatedBrowser = class(TInterfacedObject, ICustomBrowser,
    IDATFMXTranslatedBrowser)
  private
    FBaseUrl: string;
    FContentDelivered: Boolean;
    FContentEncoding: TEncoding;
    FHasSourceContent: Boolean;
    FInner: ICustomBrowser;
    FWebBrowserControl: TCustomWebBrowser;
    FWindowsBrowserProperties: IWindowsBrowserProperties;
    FSourceContent: string;
    procedure ClearSourceContent;
    function NativeBrowserReady: Boolean;
    procedure RetryPendingContent;
    function TranslatedContent: string;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  public
    constructor Create(const AInner: ICustomBrowser);
    function BrowserControl: TCustomWebBrowser;
    function CaptureBitmap: TBitmap;
    procedure EvaluateJavaScript(const JavaScript: string);
    function GetCanGoBack: Boolean;
    function GetCanGoForward: Boolean;
    function GetEnableCaching: Boolean;
    function GetParent: TFmxObject;
    function GetURL: string;
    function GetVisible: Boolean;
    procedure GoBack;
    procedure GoForward;
    procedure GoHome;
    procedure Hide;
    function InnerBrowser: ICustomBrowser;
    procedure LoadFromStrings(const AContent: string;
      const ABaseUrl: string); overload;
    procedure LoadFromStrings(const AContent: string;
      const AContentEncoding: TEncoding;
      const ABaseUrl: string); overload;
    procedure Navigate;
    procedure MarkTranslationStale;
    procedure RefreshTranslatedContent;
    procedure Reload;
    procedure SetEnableCaching(const Value: Boolean);
    procedure SetURL(const AValue: string);
    procedure SetWebBrowserControl(const AValue: TCustomWebBrowser);
    procedure Show;
    procedure Stop;
    procedure UpdateContentFromControl;
  end;

  TDATFMXBrowserTranslationService = class(TInterfacedObject, IFMXWBService)
  private
    FOriginal: IFMXWBService;
    FWrappers: TList<IDATFMXTranslatedBrowser>;
  public
    constructor Create(const AOriginal: IFMXWBService);
    destructor Destroy; override;
    function CreateWebBrowser: ICustomBrowser;
    procedure DestroyWebBrowser(const AWebBrowser: ICustomBrowser);
    procedure RealignBrowsers;
    procedure MarkAllStale;
    procedure RefreshAll;
    procedure RefreshBrowser(const ABrowser: TCustomWebBrowser);
    procedure RetryBrowser(const ABrowser: TCustomWebBrowser);
    procedure RetryPending;
  end;

var
  DATFMXBrowserTranslationEnabledCount: Integer;
  DATFMXBrowserTranslationServiceObject: TDATFMXBrowserTranslationService;
  DATFMXOriginalBrowserService: IFMXWBService;
  DATFMXProxyBrowserService: IFMXWBService;
  DATFMXDialogManagerCount: Integer;
  DATFMXOriginalLegacyService: IFMXDialogService;
  DATFMXOriginalSyncService: IFMXDialogServiceSync;
  DATFMXOriginalAsyncService: IFMXDialogServiceAsync;
  DATFMXProxyLegacyService: IFMXDialogService;
  DATFMXProxySyncService: IFMXDialogServiceSync;
  DATFMXProxyAsyncService: IFMXDialogServiceAsync;

constructor TDATFMXTranslatedBrowser.Create(const AInner: ICustomBrowser);
begin
  inherited Create;
  if AInner = nil then
    raise EArgumentNilException.Create('An FMX browser implementation is required.');
  FInner := AInner;
  { TWinWBMediator forwards this interface from its owned native service.
    Retain it for the proxy lifetime, exactly as TCustomWebBrowser does; a
    short-lived Supports local can release that service prematurely. }
  Supports(FInner, IWindowsBrowserProperties, FWindowsBrowserProperties);
end;

function TDATFMXTranslatedBrowser.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  Result := inherited QueryInterface(IID, Obj);
  { Preserve every optional native browser interface (including Edge engine
    selection and asynchronous script evaluation) without implementing or
    invoking it ourselves. }
  if (Result <> 0) and (FInner <> nil) then
    Result := FInner.QueryInterface(IID, Obj);
end;

procedure TDATFMXTranslatedBrowser.ClearSourceContent;
begin
  FBaseUrl := '';
  FContentDelivered := False;
  FContentEncoding := nil;
  FHasSourceContent := False;
  FSourceContent := '';
end;

function TDATFMXTranslatedBrowser.BrowserControl: TCustomWebBrowser;
begin
  Result := FWebBrowserControl;
end;

function TDATFMXTranslatedBrowser.NativeBrowserReady: Boolean;
begin
  { WebView2 accepts NavigateToString only after its asynchronous native view
    exists.  Before that point FireMonkey silently discards the document.
    Other platforms do not expose this Windows-only readiness contract and
    retain their normal immediate handoff. }
  if FWindowsBrowserProperties <> nil then
    Result := not (FWindowsBrowserProperties.GetWindowsActiveEngine in
      [TWindowsActiveEngine.None, TWindowsActiveEngine.NoneYet])
  else
    Result := True;
end;

procedure TDATFMXTranslatedBrowser.RetryPendingContent;
var
  Content: string;
begin
  if not FHasSourceContent or FContentDelivered or
    not NativeBrowserReady then
    Exit;
  Content := TranslatedContent;
  if FContentEncoding = nil then
    FInner.LoadFromStrings(Content, FBaseUrl)
  else
    FInner.LoadFromStrings(Content, FContentEncoding, FBaseUrl);
  FContentDelivered := True;
end;

function TDATFMXTranslatedBrowser.TranslatedContent: string;
begin
  if DATFMXBrowserTranslationEnabledCount > 0 then
    Result := DATTranslateHtmlText(FSourceContent)
  else
    Result := FSourceContent;
end;

function TDATFMXTranslatedBrowser.CaptureBitmap: TBitmap;
begin
  Result := FInner.CaptureBitmap;
end;

procedure TDATFMXTranslatedBrowser.EvaluateJavaScript(
  const JavaScript: string);
begin
  FInner.EvaluateJavaScript(JavaScript);
end;

function TDATFMXTranslatedBrowser.GetCanGoBack: Boolean;
begin
  Result := FInner.GetCanGoBack;
end;

function TDATFMXTranslatedBrowser.GetCanGoForward: Boolean;
begin
  Result := FInner.GetCanGoForward;
end;

function TDATFMXTranslatedBrowser.GetEnableCaching: Boolean;
begin
  Result := FInner.GetEnableCaching;
end;

function TDATFMXTranslatedBrowser.GetParent: TFmxObject;
begin
  Result := FInner.GetParent;
end;

function TDATFMXTranslatedBrowser.GetURL: string;
begin
  Result := FInner.GetURL;
end;

function TDATFMXTranslatedBrowser.GetVisible: Boolean;
begin
  Result := FInner.GetVisible;
end;

procedure TDATFMXTranslatedBrowser.GoBack;
begin
  ClearSourceContent;
  FInner.GoBack;
end;

procedure TDATFMXTranslatedBrowser.GoForward;
begin
  ClearSourceContent;
  FInner.GoForward;
end;

procedure TDATFMXTranslatedBrowser.GoHome;
begin
  ClearSourceContent;
  FInner.GoHome;
end;

procedure TDATFMXTranslatedBrowser.Hide;
begin
  FInner.Hide;
end;

function TDATFMXTranslatedBrowser.InnerBrowser: ICustomBrowser;
begin
  Result := FInner;
end;

procedure TDATFMXTranslatedBrowser.LoadFromStrings(const AContent,
  ABaseUrl: string);
var
  Content: string;
begin
  FSourceContent := AContent;
  FBaseUrl := ABaseUrl;
  FContentEncoding := nil;
  FHasSourceContent := True;
  FContentDelivered := False;
  if NativeBrowserReady then
  begin
    { Keep the managed string in a named local across the interface call. }
    Content := TranslatedContent;
    FInner.LoadFromStrings(Content, ABaseUrl);
    FContentDelivered := True;
  end;
end;

procedure TDATFMXTranslatedBrowser.LoadFromStrings(const AContent: string;
  const AContentEncoding: TEncoding; const ABaseUrl: string);
var
  Content: string;
begin
  FSourceContent := AContent;
  FBaseUrl := ABaseUrl;
  { TEncoding instances passed by an application can be process-owned
    singletons such as TEncoding.UTF8. Retain the non-owning reference for a
    delayed handoff; never reconstruct and free an encoding by code page. }
  FContentEncoding := AContentEncoding;
  FHasSourceContent := True;
  FContentDelivered := False;
  if NativeBrowserReady then
  begin
    Content := TranslatedContent;
    if AContentEncoding = nil then
      FInner.LoadFromStrings(Content, ABaseUrl)
    else
      FInner.LoadFromStrings(Content, AContentEncoding, ABaseUrl);
    FContentDelivered := True;
  end;
end;

procedure TDATFMXTranslatedBrowser.Navigate;
begin
  if Trim(FInner.GetURL) <> '' then
    ClearSourceContent;
  FInner.Navigate;
end;

procedure TDATFMXTranslatedBrowser.RefreshTranslatedContent;
begin
  if not FHasSourceContent then
    Exit;
  FContentDelivered := False;
  RetryPendingContent;
end;

procedure TDATFMXTranslatedBrowser.MarkTranslationStale;
begin
  if FHasSourceContent then
    FContentDelivered := False;
end;

procedure TDATFMXTranslatedBrowser.Reload;
begin
  FInner.Reload;
end;

procedure TDATFMXTranslatedBrowser.SetEnableCaching(const Value: Boolean);
begin
  FInner.SetEnableCaching(Value);
end;

procedure TDATFMXTranslatedBrowser.SetURL(const AValue: string);
begin
  ClearSourceContent;
  FInner.SetURL(AValue);
end;

procedure TDATFMXTranslatedBrowser.SetWebBrowserControl(
  const AValue: TCustomWebBrowser);
begin
  FWebBrowserControl := AValue;
  FInner.SetWebBrowserControl(AValue);
end;

procedure TDATFMXTranslatedBrowser.Show;
begin
  FInner.Show;
end;

procedure TDATFMXTranslatedBrowser.Stop;
begin
  FInner.Stop;
end;

procedure TDATFMXTranslatedBrowser.UpdateContentFromControl;
begin
  FInner.UpdateContentFromControl;
end;

constructor TDATFMXBrowserTranslationService.Create(
  const AOriginal: IFMXWBService);
begin
  inherited Create;
  if AOriginal = nil then
    raise EArgumentNilException.Create('The FMX browser service is required.');
  FOriginal := AOriginal;
  FWrappers := TList<IDATFMXTranslatedBrowser>.Create;
end;

destructor TDATFMXBrowserTranslationService.Destroy;
begin
  FWrappers.Free;
  FOriginal := nil;
  inherited Destroy;
end;

function TDATFMXBrowserTranslationService.CreateWebBrowser: ICustomBrowser;
var
  Browser: TDATFMXTranslatedBrowser;
  BrowserContract: IDATFMXTranslatedBrowser;
begin
  Browser := TDATFMXTranslatedBrowser.Create(FOriginal.CreateWebBrowser);
  Result := Browser;
  BrowserContract := Browser;
  FWrappers.Add(BrowserContract);
end;

procedure TDATFMXBrowserTranslationService.DestroyWebBrowser(
  const AWebBrowser: ICustomBrowser);
var
  BrowserContract: IDATFMXTranslatedBrowser;
begin
  if Supports(AWebBrowser, IDATFMXTranslatedBrowser, BrowserContract) then
  begin
    FOriginal.DestroyWebBrowser(BrowserContract.InnerBrowser);
    FWrappers.Remove(BrowserContract);
  end
  else
    FOriginal.DestroyWebBrowser(AWebBrowser);
end;

procedure TDATFMXBrowserTranslationService.RealignBrowsers;
begin
  FOriginal.RealignBrowsers;
end;

procedure TDATFMXBrowserTranslationService.MarkAllStale;
var
  Browser: IDATFMXTranslatedBrowser;
  Snapshot: TArray<IDATFMXTranslatedBrowser>;
begin
  Snapshot := FWrappers.ToArray;
  for Browser in Snapshot do
    Browser.MarkTranslationStale;
end;

procedure TDATFMXBrowserTranslationService.RefreshAll;
var
  Browser: IDATFMXTranslatedBrowser;
  Snapshot: TArray<IDATFMXTranslatedBrowser>;
begin
  Snapshot := FWrappers.ToArray;
  for Browser in Snapshot do
    Browser.RefreshTranslatedContent;
end;

procedure TDATFMXBrowserTranslationService.RefreshBrowser(
  const ABrowser: TCustomWebBrowser);
var
  Browser: IDATFMXTranslatedBrowser;
  Snapshot: TArray<IDATFMXTranslatedBrowser>;
begin
  if ABrowser = nil then
    Exit;
  Snapshot := FWrappers.ToArray;
  for Browser in Snapshot do
    if Browser.BrowserControl = ABrowser then
    begin
      Browser.RefreshTranslatedContent;
      Exit;
    end;
end;

procedure TDATFMXBrowserTranslationService.RetryBrowser(
  const ABrowser: TCustomWebBrowser);
var
  Browser: IDATFMXTranslatedBrowser;
  Snapshot: TArray<IDATFMXTranslatedBrowser>;
begin
  if ABrowser = nil then
    Exit;
  Snapshot := FWrappers.ToArray;
  for Browser in Snapshot do
    if Browser.BrowserControl = ABrowser then
    begin
      Browser.RetryPendingContent;
      Exit;
    end;
end;

procedure TDATFMXBrowserTranslationService.RetryPending;
var
  Browser: IDATFMXTranslatedBrowser;
  Snapshot: TArray<IDATFMXTranslatedBrowser>;
begin
  Snapshot := FWrappers.ToArray;
  for Browser in Snapshot do
    Browser.RetryPendingContent;
end;

procedure InstallFMXBrowserTranslationService;
var
  BrowserService: IFMXWBService;
begin
  if DATFMXProxyBrowserService <> nil then
    Exit;
  if TPlatformServices.Current = nil then
    Exit;
  if not TPlatformServices.Current.SupportsPlatformService(IFMXWBService,
    BrowserService) or (BrowserService = nil) then
    Exit;
  DATFMXOriginalBrowserService := BrowserService;
  DATFMXBrowserTranslationServiceObject :=
    TDATFMXBrowserTranslationService.Create(BrowserService);
  DATFMXProxyBrowserService := DATFMXBrowserTranslationServiceObject;
  TPlatformServices.Current.RemovePlatformService(IFMXWBService);
  TPlatformServices.Current.AddPlatformService(IFMXWBService,
    DATFMXProxyBrowserService);
end;

procedure MarkFMXBrowserTranslationsStale;
begin
  if DATFMXBrowserTranslationServiceObject <> nil then
    DATFMXBrowserTranslationServiceObject.MarkAllStale;
end;

procedure RefreshFMXBrowserTranslations;
begin
  if DATFMXBrowserTranslationServiceObject <> nil then
    DATFMXBrowserTranslationServiceObject.RefreshAll;
end;

procedure RefreshFMXBrowserTranslation(
  const ABrowser: TCustomWebBrowser);
begin
  if DATFMXBrowserTranslationServiceObject <> nil then
    DATFMXBrowserTranslationServiceObject.RefreshBrowser(ABrowser);
end;

procedure RetryFMXBrowserTranslation(
  const ABrowser: TCustomWebBrowser);
begin
  if DATFMXBrowserTranslationServiceObject <> nil then
    DATFMXBrowserTranslationServiceObject.RetryBrowser(ABrowser);
end;

procedure UninstallFMXBrowserTranslationService;
var
  CurrentService: IFMXWBService;
begin
  if (DATFMXProxyBrowserService <> nil) and
    (TPlatformServices.Current <> nil) and
    TPlatformServices.Current.SupportsPlatformService(IFMXWBService,
      CurrentService) and
    (Pointer(CurrentService) = Pointer(DATFMXProxyBrowserService)) then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXWBService);
    if DATFMXOriginalBrowserService <> nil then
      TPlatformServices.Current.AddPlatformService(IFMXWBService,
        DATFMXOriginalBrowserService);
  end;
  DATFMXProxyBrowserService := nil;
  DATFMXBrowserTranslationServiceObject := nil;
  DATFMXOriginalBrowserService := nil;
end;

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
  BrowserDiscovered: Boolean;
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
        BrowserDiscovered := True;
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
  BrowserDiscovered := False;
  Visited := TDictionary<TComponent, Boolean>.Create;
  try
    Visit(AForm);
  finally
    Visited.Free;
  end;
  { A browser created after the form's initial lifecycle notification needs
    its own complete refresh window. Without this reset, it inherits only the
    few attempts left from the form and its first document can miss the
    lifecycle contract permanently. }
  if BrowserDiscovered then
    ScheduleBrowserLifecycleRefresh;
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
  { Native WebViews must not be made visible while their FMX form is still
    being constructed. The completed-document handoff in EndLanguageTransition
    restores the active browser after the owning form exists. }
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
  ScheduleBrowserLifecycleRefresh;
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
  FormIdentity: string;
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
  { The application's tab-change handler has now completed. It may have run a
    responsive source layout, so restore the active RTL mirror immediately
    from the stable source snapshot before the next frame is presented. }
  if (ActivePack <> nil) and
    SameText(Trim(ActivePack.TextDirection), 'rtl') and
    WasAppliedInCurrentGeneration(Form) then
  begin
    FormIdentity := ResolveFormIdentity(Form, Form.Name);
    TFMXTranslationApplicator.RefreshDirectionLayout(Form, ActivePack,
      FormIdentity);
  end;
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
        { Hidden reports remain marked stale after a language change. Refresh
          only the report the user has just activated; an application handler
          that already supplied a new source document makes this a no-op. }
        RetryFMXBrowserTranslation(Browser);
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
  ScheduleBrowserLifecycleRefresh;
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
      if not AForm.Visible then
        Browser.Visible := False
      else if not BrowserIsOnActiveTab(Browser) then
        Browser.Visible := False
      else if FTransitionActive then
        Browser.Visible := False
      else if BrowserSubscription.WaitingForLoad then
      begin
        if ((BrowserSubscription.LoadedGeneration = Generation) and
          not BrowserSubscription.LoadStartObserved) or
          (FBrowserLifecycleAttempts > 0) then
        begin
          { The first post-transition lifecycle tick is also the deterministic
            fallback for native hosts that omit DidFinishLoad after a complete
            LoadFromStrings handoff. This runs only after the owning form is
            visible and normal FMX painting has resumed. }
          BrowserSubscription.LoadedGeneration := Generation;
          BrowserSubscription.WaitingForLoad := False;
          BrowserSubscription.PendingGeneration := 0;
          BrowserSubscription.LoadStartObserved := False;
          Browser.Visible := BrowserSubscription.RequestedVisible;
        end
        else
        begin
          { LoadFromStrings receives a complete translated document before
            navigation starts.  Do not make visibility depend on an optional
            native completion callback: some WebView hosts omit it and would
            otherwise leave the active report permanently blank. }
          Browser.Visible := BrowserSubscription.RequestedVisible;
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
  FAutoRefreshDynamicText := True;
  FDynamicRefreshInterval := 1000;
  FTranslateBrowserContent := True;
  if not (csDesigning in ComponentState) then
  begin
    Inc(DATFMXBrowserTranslationEnabledCount);
    FBrowserTranslationRegistered := True;
  end;
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
  ScrollBox: TCustomScrollBox;
  Subscription: TDATScrollBoundsSubscription;
  TabControl: TTabControl;
  TabSubscription: TDATTabChangeSubscription;
begin
  UnsubscribeFromLifecycle;
  FTransitionActive := False;
  if FBrowserTranslationRegistered then
  begin
    if DATFMXBrowserTranslationEnabledCount > 0 then
      Dec(DATFMXBrowserTranslationEnabledCount);
    FBrowserTranslationRegistered := False;
  end;
  if not (csDesigning in ComponentState) then
    ReleaseFMXDialogTranslationService;
  if FDynamicTimer <> nil then
  begin
    FDynamicTimer.Enabled := False;
    FDynamicTimer.OnTimer := nil;
  end;
  FDynamicTimer.Free;
  FDynamicTimer := nil;
  if FBrowserLifecycleTimer <> nil then
  begin
    FBrowserLifecycleTimer.Enabled := False;
    FBrowserLifecycleTimer.OnTimer := nil;
  end;
  FBrowserLifecycleTimer.Free;
  FBrowserLifecycleTimer := nil;
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
  ApplyScrollBottomGutter(AForm);
  RefreshActiveTabLayouts(AForm);
end;

procedure TDATFMXLanguageManager.RefreshActiveTabLayouts(
  const AForm: TCommonCustomForm);
var
  Visited: TDictionary<TComponent, Boolean>;

  procedure Visit(const AComponent: TComponent);
  var
    ActiveTab: TTabItem;
    ChildIndex: Integer;
    OriginalChange: TNotifyEvent;
    TabControl: TTabControl;
  begin
    if (AComponent = nil) or Visited.ContainsKey(AComponent) then
      Exit;
    Visited.Add(AComponent, True);
    if AComponent is TTabControl then
    begin
      TabControl := TTabControl(AComponent);
      ActiveTab := TabControl.ActiveTab;
      if ActiveTab <> nil then
      begin
        { FMX can retain the selected tab while leaving its presentation
          hidden after the entire control tree changes reading direction.
          Reselect the same page without publishing a user navigation event;
          this rebuilds the tab presentation immediately instead of waiting
          for the user to visit another page and come back. }
        OriginalChange := TabControl.OnChange;
        TabControl.OnChange := nil;
        try
          TabControl.ActiveTab := nil;
          TabControl.ActiveTab := ActiveTab;
        finally
          TabControl.OnChange := OriginalChange;
        end;
      end;
      TabControl.Repaint;
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
      { RTL mirroring may leave a vertical scroll box with a horizontal
        viewport offset even though its restored LTR children are back at
        their designed coordinates.  The content is then entirely offscreen
        until a tab change happens to realign the box.  These containers are
        vertically scrolling contracts, so X always belongs at the origin;
        preserve Y so a language switch does not lose the reader's place. }
      if not SameValue(ScrollBox.ViewportPosition.X, 0, 0.01) then
        ScrollBox.ViewportPosition := TPointF.Create(0,
          ScrollBox.ViewportPosition.Y);
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
  if FBrowserLifecycleTimer <> nil then
    FBrowserLifecycleTimer.Enabled := False;
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

procedure TDATFMXLanguageManager.BrowserLifecycleTimerTick(Sender: TObject);
var
  Browser: TCustomWebBrowser;
  Browsers: TArray<TCustomWebBrowser>;
  Form: TObject;
  FormIdentity: string;
  Forms: TList<TObject>;
  ManagedForm: TCommonCustomForm;
begin
  if (ActivePack = nil) or (csDestroying in ComponentState) then
  begin
    FBrowserLifecycleTimer.Enabled := False;
    Exit;
  end;
  Inc(FBrowserLifecycleAttempts);
  Forms := TList<TObject>.Create;
  try
    CollectOpenManagedObjects(Forms);
    for Form in Forms do
    begin
      ManagedForm := TCommonCustomForm(Form);
      { The first bounded post-show/post-transition tick runs after FormShow,
        including any responsive layout the application performs there. It
        closes the lifecycle gap that exists before the first normal resize
        or tab change without adding a permanent layout timer. }
      if (FBrowserLifecycleAttempts = 1) and
        SameText(Trim(ActivePack.TextDirection), 'rtl') and
        WasAppliedInCurrentGeneration(ManagedForm) then
      begin
        FormIdentity := ResolveFormIdentity(ManagedForm, ManagedForm.Name);
        TFMXTranslationApplicator.RefreshDirectionLayout(ManagedForm,
          ActivePack, FormIdentity);
      end;
      ApplyBrowserAndScrollContracts(ManagedForm);
      if FBrowserLifecycleSubscriptions <> nil then
      begin
        Browsers := FBrowserLifecycleSubscriptions.Keys.ToArray;
        for Browser in Browsers do
          if BrowserBelongsToForm(Browser, ManagedForm) and
            BrowserIsOnActiveTab(Browser) then
            RetryFMXBrowserTranslation(Browser);
      end;
      SynchronizeBrowserVisibility(ManagedForm);
    end;
  finally
    Forms.Free;
  end;
  if FBrowserLifecycleAttempts >= BrowserLifecycleMaximumAttempts then
    FBrowserLifecycleTimer.Enabled := False;
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

procedure TDATFMXLanguageManager.EnsureBrowserLifecycleTimer;
begin
  if (csDesigning in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  if FBrowserLifecycleTimer = nil then
  begin
    FBrowserLifecycleTimer := TTimer.Create(nil);
    FBrowserLifecycleTimer.Interval := BrowserLifecycleRefreshInterval;
    FBrowserLifecycleTimer.OnTimer := BrowserLifecycleTimerTick;
  end;
end;

procedure TDATFMXLanguageManager.EndLanguageTransition;
var
  Browser: TCustomWebBrowser;
  BrowserSubscription: TDATBrowserLifecycleSubscription;
  Form: TCommonCustomForm;
begin
  try
    { Mark every captured source document for the new generation, but do not
      synchronously translate hidden reports. The active report is refreshed
      below; each hidden report refreshes when its tab becomes active. This
      keeps language selection proportional to what the user can see while
      preserving the application-authored HTML and CSS byte for byte. }
    MarkFMXBrowserTranslationsStale;
    if FTransitionForms <> nil then
      for Form in FTransitionForms do
        if Form <> nil then
        begin
          EnsureBrowserLifecycleContracts(Form);
          ApplyBrowserAndScrollContracts(Form);
        end;
  finally
    { Application callbacks may request a browser visible after starting an
      asynchronous navigation. Capture that request, but finish the FMX scene
      transition with native surfaces hidden. The post-transition lifecycle
      tick restores only the active report and supplies the deterministic
      fallback when a native host omits DidFinishLoad. }
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
            RetryFMXBrowserTranslation(Browser);
            if BrowserSubscription.LoadedGeneration <> Generation then
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
          Form.Invalidate;
    { Prevent attempts left by an earlier lifecycle pass from satisfying the
      deferred-load fallback during transition teardown itself. }
    FBrowserLifecycleAttempts := 0;
    FTransitionActive := False;
    if FTransitionForms <> nil then
      for Form in FTransitionForms do
        if Form <> nil then
          SynchronizeBrowserVisibility(Form);
    FreeAndNil(FTransitionBrowsers);
    FreeAndNil(FTransitionForms);
  end;
  FTransitionGeneration := 0;
  ScheduleBrowserLifecycleRefresh;
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

procedure TDATFMXLanguageManager.SetTranslateBrowserContent(
  const Value: Boolean);
begin
  if FTranslateBrowserContent = Value then
    Exit;
  FTranslateBrowserContent := Value;
  if csDesigning in ComponentState then
    Exit;
  if Value and not FBrowserTranslationRegistered then
  begin
    InstallFMXBrowserTranslationService;
    Inc(DATFMXBrowserTranslationEnabledCount);
    FBrowserTranslationRegistered := True;
  end
  else if not Value and FBrowserTranslationRegistered then
  begin
    if DATFMXBrowserTranslationEnabledCount > 0 then
      Dec(DATFMXBrowserTranslationEnabledCount);
    FBrowserTranslationRegistered := False;
  end;
  RefreshFMXBrowserTranslations;
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
    ScheduleBrowserLifecycleRefresh;
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

procedure TDATFMXLanguageManager.HandleSizeChanged(const Sender: TObject;
  const AMessage: TMessage);
var
  Form: TCommonCustomForm;
  FormIdentity: string;
begin
  if not Initialized or (ActivePack = nil) or
    not SameText(Trim(ActivePack.TextDirection), 'rtl') or
    not (AMessage is TSizeChangedMessage) or
    not (Sender is TCommonCustomForm) then
    Exit;
  Form := TCommonCustomForm(Sender);
  { FMX sends this message after the form's own Resize event. That ordering is
    the universal contract needed here: the application first performs its
    ordinary responsive LTR layout, then the language manager mirrors the
    resulting live-width coordinate spaces. The generation gate leaves
    excluded and not-yet-translated forms entirely alone. }
  if not WasAppliedInCurrentGeneration(Form) then
    Exit;
  FormIdentity := ResolveFormIdentity(Form, Form.Name);
  TFMXTranslationApplicator.RefreshDirectionLayout(Form, ActivePack,
    FormIdentity);
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

procedure TDATFMXLanguageManager.ScheduleBrowserLifecycleRefresh;
begin
  EnsureBrowserLifecycleTimer;
  if FBrowserLifecycleTimer = nil then
    Exit;
  FBrowserLifecycleAttempts := 0;
  FBrowserLifecycleTimer.Enabled := True;
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
  if FSizeChangedSubscription = 0 then
    FSizeChangedSubscription :=
      TMessageManager.DefaultManager.SubscribeToMessage(
        TSizeChangedMessage, HandleSizeChanged);
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
  if FSizeChangedSubscription <> 0 then
  begin
    TMessageManager.DefaultManager.Unsubscribe(
      TSizeChangedMessage, FSizeChangedSubscription);
    FSizeChangedSubscription := 0;
  end;
end;

initialization
  { FMX.WebBrowser has already registered the native factory because this
    unit uses it. Decorate that factory before any application form is
    streamed; never replace it from a component constructor. }
  InstallFMXBrowserTranslationService;
  RegisterClass(TDATFMXLanguageManager);

finalization
  UninstallFMXBrowserTranslationService;
  UnregisterClass(TDATFMXLanguageManager);

end.
