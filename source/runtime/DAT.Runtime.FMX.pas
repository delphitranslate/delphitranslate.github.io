unit DAT.Runtime.FMX;

interface

uses
  DAT.Runtime.LayoutOverrides,
  System.Generics.Collections,
  System.Types,
  { TAlignLayout is named in the snapshot below, so it belongs in the
    interface rather than only in the implementation. }
  FMX.Types,
  FMX.Forms,
  DAT.Runtime.LanguagePack;

type
  { What a control looked like before any translation touched it.

    Only the position used to be remembered, and only that could be given back.
    Everything else a translation changes - the size, the text size and colour,
    whether the control wraps or sizes itself - was changed and then had no
    record anywhere, so returning to the original language restored the words
    and left the geometry wherever the last language had put it. The run-time
    fitting makes that worse, because it resizes controls the analyser never
    wrote a rule for, and a rule is the only other thing a restore could work
    from.

    So the whole of what can be changed is kept, and it is kept as plain types
    rather than FireMonkey ones: the sets and colours are stored as ordinals so
    that this declaration costs the unit's interface nothing. }
  TDATControlSnapshot = record
    Position: TPointF;
    Size: TPointF;
    HasPosition: Boolean;
    HasTextSettings: Boolean;
    FontSize: Single;
    FontColor: Cardinal;
    WordWrap: Boolean;
    Trimming: Byte;
    StyledSettings: Byte;
    HasAutoSize: Boolean;
    AutoSize: Boolean;
    { A mirrored layout changes more than coordinates, and everything it
      changes has to be restorable. }
    Align: TAlignLayout;
    { As text, read and written through RTTI, so the snapshot does not have to
      name a set type that lives in another unit. }
    Anchors: string;
    HorzAlign: Byte;
  end;

  TFMXTranslationApplicator = class
  private
    class var FOriginalGeometry: TDictionary<string, TDATControlSnapshot>;
    class procedure RecentreSelfPlacedText(const AForm: TCommonCustomForm;
      const AFormIdentity: string); static;
    { The order each grid was designed in, remembered once, so the target
      order can be stated in terms of it rather than counted. }
    class var FDesignedColumns: TDictionary<string, TArray<string>>;
    { And the order each menu bar was designed in, for the same reason. }
    class var FDesignedMenus: TDictionary<string, TArray<string>>;
    class procedure SnapshotOriginalGeometry(const AForm: TCommonCustomForm;
      const AFormIdentity: string); static;
    class function RestoreOriginalGeometry(const AForm: TCommonCustomForm;
      const AFormIdentity: string): Integer; static;
    class function ApplyDirectionMirror(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; static;
  public
    class function ApplyToForm(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack): Integer; overload; static;
    class function ApplyToForm(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string;
      const APreserveControlState: Boolean = True;
      const AApplyLayout: Boolean = True;
      const ATranslateBrowserContent: Boolean = False): Integer; overload; static;
    { Refreshes only application-generated text. It deliberately does not
      restore geometry, fit controls, reorder menus or apply layout rules;
      those operations belong to a language change, not to a periodic check
      for a newly assigned caption. }
    class function RefreshDynamicText(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack): Integer; static;
    { Re-evaluates only RTL horizontal geometry against the live parent
      widths.  It is safe after OnShow because it does not restore designer
      sizes or positions first, and the mirror is calculated from the stored
      source coordinates rather than from an already mirrored position. }
    class function RefreshDirectionLayout(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; static;
    { Applies only the browser document layout contract.  It does not translate
      DOM text, navigate, or replace application HTML, so it is safe for every
      embedded browser whether TranslateBrowserContent is enabled or not. }
    class function RefreshBrowserLayout(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack): Integer; static;
    { Adjustments a person made while the application was running, applied
      after every rule the pack carries. They are last on purpose: an
      override is the correction of somebody who looked at the result, and
      where the planner and a person disagree the person is right. }
    class function ApplyOverrides(const AForm: TCommonCustomForm;
      const AOverrides: TLayoutOverrides;
      const AFormIdentity: string): Integer; static;
    class function ApplyLayoutToForm(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string;
      const AUseTranslatedValues: Boolean): Integer; static;
    class function RestoreSourceLanguage(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string): Integer; static;
  end;

implementation

uses
  System.Classes,
  System.Generics.Defaults,
  System.IOUtils,
  System.JSON,
  System.Math,
  System.SysUtils,
  System.StrUtils,
  System.TypInfo,
  System.UITypes,
  FMX.Controls,
  FMX.Edit,
  FMX.Grid,
  FMX.Layouts,
  FMX.Memo,
  FMX.Menus,
  FMX.Objects,
  FMX.Graphics,
  FMX.StdCtrls,
  FMX.TabControl,
  FMX.TextLayout,
  FMX.WebBrowser;

const
  { U+00AD, the break offered inside a word. }
  SoftHyphenMark = #$00AD;

type
  TBrowserTranslationRetry = class(TComponent)
  private
    FAttempts: Integer;
    FBrowser: TCustomWebBrowser;
    FScript: string;
    FTimer: TTimer;
    procedure TimerTick(Sender: TObject);
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(ABrowser: TCustomWebBrowser;
      const AScript: string); reintroduce;
  end;

const
  DATRuntimeDebugLogFileName = 'DAT_Translation_Debug_Log.txt';

procedure DATRuntimeDebugLog(const AMessage: string);
{$IFDEF DAT_RUNTIME_DEBUG_LOG}
var
  LogFileName: string;
  LogDirectory: string;
begin
  try
    LogFileName := TPath.Combine(TPath.GetTempPath,
      DATRuntimeDebugLogFileName);
    LogDirectory := TPath.GetDirectoryName(LogFileName);
    if (LogDirectory <> '') and not TDirectory.Exists(LogDirectory) then
      TDirectory.CreateDirectory(LogDirectory);
    TFile.AppendAllText(LogFileName,
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' ' + AMessage +
      sLineBreak, TEncoding.UTF8);
  except
    { Runtime diagnostics must never change target application behavior. }
  end;
end;
{$ELSE}
begin
  { Shipping applications do not write diagnostic traffic to a fixed user
    folder. Define DAT_RUNTIME_DEBUG_LOG explicitly for a diagnostic build. }
end;
{$ENDIF}

function PositionKey(const AFormIdentity: string;
  const AComponent: TComponent): string;
begin
  if (AComponent = nil) or (Trim(AComponent.Name) = '') then
    Exit('');
  Result := AFormIdentity + '.' + AComponent.Name;
end;

constructor TBrowserTranslationRetry.Create(ABrowser: TCustomWebBrowser;
  const AScript: string);
begin
  inherited Create(ABrowser);
  FBrowser := ABrowser;
  FScript := AScript;
  if FBrowser <> nil then
    FBrowser.FreeNotification(Self);
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 175;
  FTimer.OnTimer := TimerTick;
  FTimer.Enabled := True;
end;

procedure TBrowserTranslationRetry.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FBrowser) then
  begin
    FBrowser := nil;
    if FTimer <> nil then
      FTimer.Enabled := False;
  end;
end;

procedure TBrowserTranslationRetry.TimerTick(Sender: TObject);
begin
  Inc(FAttempts);
  if FBrowser = nil then
  begin
    FTimer.Enabled := False;
    Exit;
  end;
  try
    DATRuntimeDebugLog(Format(
      'Browser retry attempt %d on %s.%s; script length=%d',
      [FAttempts, FBrowser.ClassName, FBrowser.Name, Length(FScript)]));
    FBrowser.EvaluateJavaScript(FScript);
    { EvaluateJavaScript returning means the platform accepted the script.
      The script owns its small document-readiness wait from here; repeatedly
      reinjecting it creates overlapping retry trees and stalls the UI. }
    FTimer.Enabled := False;
  except
    on E: Exception do
      DATRuntimeDebugLog(Format(
        'Browser retry attempt %d failed on %s.%s: %s: %s',
        [FAttempts, FBrowser.ClassName, FBrowser.Name, E.ClassName,
        E.Message]));
  end;
  if FAttempts >= 12 then
    FTimer.Enabled := False;
end;

{ Browser text is translated inside the document because it is not exposed
  as an FMX Text or Caption property. The work must remain bounded: embedded
  browsers can contain thousands of text nodes, and a language change runs on
  the UI thread. }

function JavaScriptString(const AValue: string): string;
var
  JsonString: TJSONString;
begin
  JsonString := TJSONString.Create(AValue);
  try
    Result := JsonString.ToJSON;
  finally
    JsonString.Free;
  end;
end;

function ApplyBrowserLayoutContract(const AComponent: TComponent;
  const APack: TRuntimeLanguagePack): Integer;
var
  CssText: string;
  ScriptText: string;
begin
  Result := 0;
  if not (AComponent is TCustomWebBrowser) or (APack = nil) then
    Exit;

  { The browser document remains the application's UI.  This contract therefore
    carries no application class names, coordinates, fixed padding or fixed text
    sizes.  It observes the rendered document and changes only demonstrated
    failure states: text which actually overflows its box, a table heading whose
    rendered text start differs from the data beneath it, and a multiword heading
    which remains unnecessarily crowded on one line. }
  CssText :=
    'html,body{max-inline-size:100%}' +
    '[data-dat-fit="wrap"]{max-inline-size:100%;white-space:normal!important;' +
      'overflow-wrap:anywhere!important;word-break:normal!important}' +
    { Tables are data, not pictures.  Constraining a wide translated table to
      the viewport makes the browser squeeze the final columns until Hebrew,
      Arabic and other longer headings become one-character strips.  Keep the
      table at least as wide as its viewport, but allow its intrinsic column
      widths to exceed it and use the browser's existing horizontal scroll. }
    'img,svg,canvas{max-inline-size:100%}' +
    'table{min-inline-size:100%;max-inline-size:none;table-layout:auto}' +
    'tr{height:auto!important}' +
    'th,td{height:auto!important;min-block-size:0;white-space:normal;' +
      'overflow:visible;overflow-wrap:normal;word-break:normal}' +
    'th{hyphens:auto!important;-webkit-hyphens:auto!important}' +
    '[data-dat-heading-wrapper]{display:inline-block;box-sizing:border-box;' +
      'inline-size:min-content!important;width:min-content!important;' +
      'max-inline-size:100%;max-width:100%;margin:0;padding:0;border:0;' +
      'white-space:normal!important;overflow-wrap:break-word!important;' +
      'word-break:normal!important;hyphens:auto!important;' +
      '-webkit-hyphens:auto!important;text-align:inherit}';

  ScriptText := '(function(){var d=' +
    JavaScriptString(LowerCase(Trim(APack.TextDirection))) + ',l=' +
    JavaScriptString(Trim(APack.LanguageCode)) + ',c=' +
    JavaScriptString(CssText) +
    ';function num(v){v=parseFloat(v);return isFinite(v)?v:0;}' +
    'function norm(c){var a=c.textAlign,q=c.direction;' +
      'if(a==="start"||a==="end"||a==="center"){return a;}' +
      'if(a==="left"){return q==="rtl"?"end":"start";}' +
      'if(a==="right"){return q==="rtl"?"start":"end";}return a;}' +
    'function padStart(c){return num(c.direction==="rtl"?c.paddingRight:c.paddingLeft);}' +
    'function setPadStart(e,c,v){var p=c.direction==="rtl"?' +
      '"padding-right":"padding-left";' +
      'e.style.setProperty(p,v+"px","important");}' +
    'function setLogicalAlign(e,c,v){if(v==="start"){' +
      'v=c.direction==="rtl"?"right":"left";}else if(v==="end"){' +
      'v=c.direction==="rtl"?"left":"right";}' +
      'if(v==="left"||v==="right"||v==="center"){' +
      'e.style.setProperty("text-align",v,"important");}}' +
    'function firstTextStart(e,c){var w,n,s,k,r,b,x;' +
      'if(!e){return 0;}x=e.getBoundingClientRect();' +
      'try{w=document.createTreeWalker(e,4,null,false);while(n=w.nextNode()){' +
      's=String(n.nodeValue||"");k=s.search(/\S/);if(k<0){continue;}' +
      'r=document.createRange();r.setStart(n,k);r.setEnd(n,Math.min(k+1,s.length));' +
      'b=r.getBoundingClientRect();if(b.width||b.height){return c.direction==="rtl"?' +
      'x.right-b.right:b.left-x.left;}}}catch(q){}return padStart(c);}' +
    'function wrapHeading(h){var a="data-dat-heading-wrapped",w,t;' +
      'if(!h){return;}t=String(h.textContent||"").trim();' +
      'w=h.querySelector("[data-dat-heading-wrapper]");' +
      'if(!/\S\s+\S/.test(t)){return;}if(!w&&!h.querySelector(' +
      '"button,a,input,select,textarea")){w=document.createElement("span");' +
      'w.setAttribute("data-dat-heading-wrapper","");while(h.firstChild){' +
      'w.appendChild(h.firstChild);}h.appendChild(w);h.setAttribute(a,"1");}' +
      '}' +
    'function cellAt(t,col){var rs=t.tBodies,i,j,p,x,s,first=null;' +
      'for(i=0;i<rs.length;i++){for(j=0;j<rs[i].rows.length;j++){' +
      'p=0;for(x=0;x<rs[i].rows[j].cells.length;x++){' +
      's=rs[i].rows[j].cells[x].colSpan||1;if(col>=p&&col<p+s){' +
      'if(!first){first=rs[i].rows[j].cells[x];}' +
      'if(String(rs[i].rows[j].cells[x].textContent||"").trim()){return rs[i].rows[j].cells[x];}' +
      'break;}p+=s;}}}return first;}' +
    'function resetFont(e){var a="data-dat-original-inline-font",v;' +
      'if(!e.hasAttribute(a)){v=e.style.fontSize;e.setAttribute(a,v?v:"!");}' +
      'v=e.getAttribute(a);if(v==="!"){e.style.removeProperty("font-size");}' +
      'else{e.style.fontSize=v;}}' +
    'function overflowing(e){return e.clientWidth>0&&e.clientHeight>0&&' +
      '(e.scrollWidth>e.clientWidth+1||e.scrollHeight>e.clientHeight+1);}' +
    'function fit(e){var z,m;resetFont(e);e.removeAttribute("data-dat-fit");' +
      'if(!overflowing(e)){return;}e.setAttribute("data-dat-fit","wrap");' +
      'if(!overflowing(e)){return;}z=num(getComputedStyle(e).fontSize);' +
      'm=Math.max(8,z*.8);while(z-.5>=m&&overflowing(e)){' +
      'z-=.5;e.style.fontSize=z+"px";}}' +
    'function alignTable(t){var r,hs,h,c,hc,cc,ca,hp,cp,col=0,i;' +
      'if(!t.tHead||!t.tHead.rows.length||!t.tBodies.length){return;}' +
      'r=t.tHead.rows[t.tHead.rows.length-1];hs=r.cells;' +
      'for(i=0;i<hs.length;i++){h=hs[i];c=cellAt(t,col);col+=h.colSpan||1;' +
      'if(c){cc=getComputedStyle(c);' +
      'ca=norm(cc);if(ca==="start"||ca==="end"){' +
      'setLogicalAlign(h,cc,ca);setPadStart(h,cc,padStart(cc));}' +
      'wrapHeading(h);hc=getComputedStyle(h);cp=firstTextStart(c,cc);' +
      'hp=firstTextStart(h,hc);if(ca==="start"||ca==="end"){' +
      'setPadStart(h,cc,Math.max(0,padStart(hc)+cp-hp));}}fit(h);}}' +
    'function run(){var h=document.documentElement,b=document.body,s,n,i;' +
    'if(!h){return;}h.setAttribute("dir",d);if(l){h.setAttribute("lang",l);}' +
    'if(h.getAttribute("data-dat-layout-language")!==l){' +
      'h.setAttribute("data-dat-layout-language",l);h.scrollTop=0;' +
      'if(b){b.scrollTop=0;}}' +
    'h.style.direction=d;if(b){b.setAttribute("dir",d);b.style.direction=d;' +
    'b.style.textAlign="start";}s=document.getElementById("dat-runtime-layout-contract");' +
    'if(!s&&document.head){s=document.createElement("style");' +
    's.id="dat-runtime-layout-contract";document.head.appendChild(s);}' +
    'if(s){s.textContent=c;}' +
    'n=document.querySelectorAll("h1,h2,h3,h4,h5,h6,p,li,dt,dd,caption,figcaption,' +
      'button,[role=button],[role=columnheader],[role=note]");' +
    'for(i=0;i<n.length;i++){fit(n[i]);}' +
    'n=document.querySelectorAll("table");for(i=0;i<n.length;i++){alignTable(n[i]);}}' +
    'if(document.readyState==="loading"){' +
    'document.addEventListener("DOMContentLoaded",function(){run();' +
    'requestAnimationFrame(run);window.setTimeout(run,120);window.setTimeout(run,450);},' +
    '{once:true});}else{run();requestAnimationFrame(run);window.setTimeout(run,120);' +
    'window.setTimeout(run,450);}})();';
  try
    TCustomWebBrowser(AComponent).EvaluateJavaScript(ScriptText);
    Result := 1;
  except
    on E: Exception do
      DATRuntimeDebugLog(Format(
        'Browser layout contract deferred on %s.%s: %s: %s',
        [AComponent.ClassName, AComponent.Name, E.ClassName, E.Message]));
  end;
end;

function ApplyBrowserText(const AComponent: TComponent;
  const APack: TRuntimeLanguagePack): Integer;
var
  Candidate: string;
  Key: string;
  NeedsRetry: Boolean;
  Pairs: TStringList;
  PairMap: TDictionary<string, string>;
  Script: TStringBuilder;
  ScriptText: string;
  SourceText: string;
  TranslatedText: string;

  procedure LogKnownBrowserTerm(const ASourceText: string);
  var
    LogTranslation: string;
  begin
    LogTranslation := '';
    if APack.TryTranslateSource(ASourceText, LogTranslation) or
      APack.TryTranslateDynamicText(ASourceText, LogTranslation) then
      DATRuntimeDebugLog(Format('Browser term "%s" -> "%s"',
        [ASourceText, LogTranslation]))
    else
      DATRuntimeDebugLog(Format('Browser term "%s" has no runtime translation',
        [ASourceText]));
  end;

  procedure AddBrowserPair(const ASourceText, ATranslatedText: string);
  begin
    if (Trim(ASourceText) = '') or (Trim(ATranslatedText) = '') or
      SameText(ASourceText, ATranslatedText) then
      Exit;
    if not PairMap.ContainsKey(ASourceText) then
      PairMap.Add(ASourceText, ATranslatedText);
  end;
begin
  Result := 0;
  if not (AComponent is TCustomWebBrowser) then
    Exit;
  PairMap := TDictionary<string, string>.Create;
  Pairs := TStringList.Create;
  Pairs.Sorted := True;
  Pairs.Duplicates := dupIgnore;
  Script := TStringBuilder.Create;
  try
    DATRuntimeDebugLog(Format('ApplyBrowserText start: %s.%s language=%s',
      [AComponent.ClassName, AComponent.Name, APack.LanguageCode]));
    for Key in APack.Sources.Keys do
      if APack.Strings.TryGetValue(Key, TranslatedText) then
      begin
        SourceText := APack.Sources[Key];
        AddBrowserPair(SourceText, TranslatedText);
      end;
    for Candidate in APack.SourceStrings.Keys do
    begin
      TranslatedText := APack.SourceStrings[Candidate];
      AddBrowserPair(Candidate, TranslatedText);
    end;
    for Candidate in APack.SourceTemplates.Keys do
    begin
      TranslatedText := APack.SourceTemplates[Candidate];
      { Format strings belong to code, not browser text nodes. }
      if (Pos('%', Candidate) = 0) and (Pos('%', TranslatedText) = 0) and
        (Trim(Candidate) <> '') and (Trim(TranslatedText) <> '') then
        AddBrowserPair(Candidate, TranslatedText);
    end;
    LogKnownBrowserTerm('Time');
    LogKnownBrowserTerm('Type');
    for Candidate in PairMap.Keys do
      Pairs.Add(JavaScriptString(Candidate) + ',' +
        JavaScriptString(PairMap[Candidate]));
    if Pairs.Count = 0 then
    begin
      DATRuntimeDebugLog('ApplyBrowserText stopped: no browser text pairs.');
      Exit;
    end;
    { Build a dictionary once, then each DOM text node is one lookup. The old
      nested loop compared every node with every pack string and multiplied
      that work again through two independent forty-pass retry loops. }
    Script.Append('(function(){var a=[');
    for Candidate in Pairs do
    begin
      if Script.Chars[Script.Length - 1] <> '[' then
        Script.Append(',');
      Script.Append('[').Append(Candidate).Append(']');
    end;
    Script.Append('],p=Object.create(null),i,d=')
      .Append(JavaScriptString(LowerCase(Trim(APack.TextDirection))))
      .Append(';for(i=0;i<a.length;i++){p[a[i][0]]=a[i][1];}')
      .Append('function trim(s){return String(s).replace(/^\\s+|\\s+$/g,"");}')
      .Append('function contract(){var h=document.documentElement,b=document.body;if(h){h.setAttribute("dir",d);h.style.direction=d;}if(b){b.setAttribute("dir",d);b.style.direction=d;b.style.textAlign="start";}}')
      .Append('function apply(n){var c=0,v,l,r,ch,t;if(!n){return 0;}if(n.nodeType===1&&/^(SCRIPT|STYLE|TEMPLATE|NOSCRIPT|CODE|PRE|TEXTAREA)$/i.test(n.nodeName)){return 0;}if(n.nodeType===3){v=n.nodeValue;t=trim(v);if(Object.prototype.hasOwnProperty.call(p,t)){l=(v.match(/^\\s*/)||[""])[0];r=(v.match(/\\s*$/)||[""])[0];n.nodeValue=l+p[t]+r;c++;}return c;}ch=n.firstChild;while(ch){c+=apply(ch);ch=ch.nextSibling;}return c;}')
      .Append('function run(){if(!document.body){return 0;}contract();return apply(document.body);}var tries=0;function retry(){try{if(document.body){run();return;}}catch(e){}tries++;if(tries<20){window.setTimeout(retry,150);}}retry();})();');
    ScriptText := Script.ToString;
    DATRuntimeDebugLog(Format(
      'ApplyBrowserText executing: pairs=%d script length=%d',
      [Pairs.Count, Length(ScriptText)]));
    NeedsRetry := False;
    try
      TCustomWebBrowser(AComponent).EvaluateJavaScript(ScriptText);
    except
      on E: Exception do
      begin
        NeedsRetry := True;
        DATRuntimeDebugLog(Format(
          'ApplyBrowserText immediate EvaluateJavaScript failed on %s.%s: %s: %s',
          [AComponent.ClassName, AComponent.Name, E.ClassName, E.Message]));
      end;
    end;
    if NeedsRetry then
      TBrowserTranslationRetry.Create(TCustomWebBrowser(AComponent),
        ScriptText);
    Result := Pairs.Count;
  finally
    Script.Free;
    Pairs.Free;
    PairMap.Free;
  end;
end;

{ Text settings, reached the way FireMonkey means them to be reached.

  TTextControl is only one of the two families of text control. A TLabel, and
  everything else built on TPresentedTextControl, descends from the other and
  is not a TTextControl at all: the compiler will not even permit the two to be
  compared directly. Written against a TComponent the test compiles happily and
  is simply False for every label, which is what it had been doing here.

  The cost of that was invisible and large. Wrapping, text size and font colour
  are the three properties this unit sets through the class, so for labels -
  most of the text on any form - they were never set. The analyser would decide
  a caption needed to be a point smaller, the rule would be written into the
  pack, the runtime would read it, and nothing whatever would happen. Both
  families implement ITextSettings, so ask for the interface. }
function AsTextSettings(const AComponent: TComponent;
  out ASettings: ITextSettings): Boolean;
begin
  Result := Supports(AComponent, ITextSettings, ASettings) and
    Assigned(ASettings) and Assigned(ASettings.TextSettings);
end;

function ApplyFontColorsToForm(const AForm: TCommonCustomForm;
  const APack: TRuntimeLanguagePack; const AFormIdentity: string): Integer;
var
  Component: TComponent;
  ColorText: string;
  ComponentKey: string;
  ComponentName: string;
  ComponentTextSettings: ITextSettings;
  ParsedColor: TAlphaColor;

  function FindOwnedComponent(const ARoot: TComponent;
    const AName: string): TComponent;
  var
    Index: Integer;
  begin
    Result := nil;
    if ARoot = nil then
      Exit;
    if SameText(ARoot.Name, AName) then
      Exit(ARoot);
    for Index := 0 to ARoot.ComponentCount - 1 do
    begin
      Result := FindOwnedComponent(ARoot.Components[Index], AName);
      if Result <> nil then
        Exit;
    end;
  end;

  function TryParseColor(const AValue: string; out AColor: TAlphaColor): Boolean;
  var
    HexValue: string;
    NumberValue: UInt64;
  begin
    HexValue := Trim(AValue);
    if SameText(HexValue, 'claWhite') then
      AColor := TAlphaColorRec.White
    else if SameText(HexValue, 'claBlack') then
      AColor := TAlphaColorRec.Black
    else if SameText(HexValue, 'claRed') then
      AColor := TAlphaColorRec.Red
    else if SameText(HexValue, 'claGreen') then
      AColor := TAlphaColorRec.Green
    else if SameText(HexValue, 'claBlue') then
      AColor := TAlphaColorRec.Blue
    else
    begin
      if StartsText('x', HexValue) then
        Delete(HexValue, 1, 1);
      if StartsText('$', HexValue) then
        Delete(HexValue, 1, 1);
      Result := TryStrToUInt64('$' + HexValue, NumberValue) and
        (Length(HexValue) <= 8);
      if Result then
        AColor := TAlphaColor(NumberValue)
      else
        Exit(False);
    end;
    Result := True;
  end;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  for ComponentKey in APack.FontColors.Keys do
  begin
    if not StartsText(AFormIdentity + '.', ComponentKey) then
      Continue;
    ComponentName := Copy(ComponentKey, Length(AFormIdentity) + 2, MaxInt);
    Component := FindOwnedComponent(AForm, ComponentName);
    if not AsTextSettings(Component, ComponentTextSettings) then
      Continue;
    ColorText := APack.FontColors[ComponentKey];
    try
      if not TryParseColor(ColorText, ParsedColor) then
        Continue;
      ComponentTextSettings.StyledSettings :=
        ComponentTextSettings.StyledSettings - [TStyledSetting.FontColor];
      ComponentTextSettings.TextSettings.FontColor := ParsedColor;
      Inc(Result);
    except
      // Optional styling metadata must never block translation.
    end;
  end;
end;

{ Word wrap on an FMX text control lives in TextSettings, and while
  TStyledSetting.Other stays in StyledSettings the platform style supplies
  wrapping and trimming instead of the assigned values. Setting the published
  WordWrap property alone therefore appears to succeed and changes nothing:
  the control keeps rendering one styled line and trims it with an ellipsis.
  Take the setting out of style control, then assign it, and stop trimming so
  a control that has been given a fixed width shows its text on several lines
  rather than clipping it. }
{ Which edge the text sits against.

  FireMonkey has no BiDiMode and no FlipChildren, so under a right-to-left
  language this is the whole of what the framework contributes and the planner
  does everything else. StyledSettings has to give up HorzAlign first or the
  style puts it straight back. }
{ Anchors as the designer would write them, through RTTI. }
function ReadAnchorsText(const AComponent: TComponent): string;
var
  PropertyInfo: PPropInfo;
begin
  Result := '';
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'Anchors');
  if PropertyInfo <> nil then
    Result := GetSetProp(AComponent, PropertyInfo, True);
end;

procedure WriteAnchorsText(const AComponent: TComponent;
  const AValue: string);
var
  PropertyInfo: PPropInfo;
begin
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'Anchors');
  if PropertyInfo <> nil then
    try
      SetSetProp(AComponent, PropertyInfo, AValue);
    except
      { A control with no anchors of that shape is left as it is. }
    end;
end;

function ApplyHorzAlignSetting(const AComponent: TComponent;
  const AValue: string): Boolean;
var
  Settings: ITextSettings;
  Alignment: TTextAlign;
begin
  Result := False;
  if not AsTextSettings(AComponent, Settings) then
    Exit;
  if MatchText(Trim(AValue), ['Leading', 'TTextAlign.Leading',
    'taLeftJustify']) then
    Alignment := TTextAlign.Leading
  else if MatchText(Trim(AValue), ['Trailing', 'TTextAlign.Trailing',
    'taRightJustify']) then
    Alignment := TTextAlign.Trailing
  else if MatchText(Trim(AValue), ['Center', 'Centre', 'TTextAlign.Center',
    'taCenter']) then
    Alignment := TTextAlign.Center
  else
    Exit;
  Settings.StyledSettings := Settings.StyledSettings -
    [TStyledSetting.Other];
  if Settings.TextSettings.HorzAlign <> Alignment then
  begin
    Settings.TextSettings.HorzAlign := Alignment;
    Result := True;
  end;
end;

function ApplyWordWrapSetting(const AComponent: TComponent;
  const AValue: Boolean): Boolean;
var
  Settings: ITextSettings;
begin
  Result := False;
  if not AsTextSettings(AComponent, Settings) then
    Exit;
  Settings.StyledSettings := Settings.StyledSettings -
    [TStyledSetting.Other];
  if Settings.TextSettings.WordWrap <> AValue then
  begin
    Settings.TextSettings.WordWrap := AValue;
    Result := True;
  end;
  if AValue and (Settings.TextSettings.Trimming <> TTextTrimming.None) then
  begin
    Settings.TextSettings.Trimming := TTextTrimming.None;
    Result := True;
  end;
end;

{ Font size is style-controlled in the same way wrapping is: while
  TStyledSetting.Size remains, the platform style supplies the size and an
  assignment is quietly ignored. Take it out of style control before setting
  it, or a caption asked to shrink keeps rendering at its designed size and
  overflows exactly as before. }
function ApplyFontSizeSetting(const AComponent: TComponent;
  const AValue: Single): Boolean;
var
  Settings: ITextSettings;
begin
  Result := False;
  if (AValue <= 0) or not AsTextSettings(AComponent, Settings) then
    Exit;
  Settings.StyledSettings := Settings.StyledSettings -
    [TStyledSetting.Size];
  if not SameValue(Settings.TextSettings.Font.Size, AValue, 0.01) then
  begin
    Settings.TextSettings.Font.Size := AValue;
    Result := True;
  end;
end;

{ Reordering a grid's columns for a language that reads the other way.

  The VCL half of this works on a TCollection and moves TCollectionItems.
  FireMonkey has neither: a TColumn is a child object of the grid and its
  place is its Index among the grid's children. The reasoning is identical
  and the mechanics are not, which is the usual shape of parity between these
  two frameworks.

  As on the VCL side the order is stated rather than toggled. The designed
  order is captured the first time a grid is seen, the target is recomputed
  from it on every call, and the columns are moved to match - so applying
  twice is indistinguishable from applying once. }
{ The menu bar reads in the language's direction.

  The VCL half of this had to fight the framework: VCL mirrors a menu only
  through TMenu.DoBiDiModeChanged, which gives up unless the machine itself is
  Middle Eastern, and the flag it sets governs how submenus cascade rather
  than the order of the bar. The order had to be reversed by hand there.

  FireMonkey needs no such argument, because it offers no such flag - there is
  nothing that claims to mirror a menu and does something else. A TMenuItem is
  a child object of the menu and its place is its Index, so reversing the bar
  means moving the items, which is what the VCL side ended up doing anyway.

  Stated rather than toggled, for the same reason as everywhere else here: the
  designed order is captured once and the target recomputed from it, so a form
  translated twice looks like a form translated once. }
{ TMainMenu hands its items back as TFmxObject rather than TMenuItem, and
  both the name and the position live at that level, so there is nothing to
  gain by casting down. }
{ Entry fields a right-to-left reader is going to type into.

  The VCL half of this sets BiDiMode to bdRightToLeft, which moves the caret
  to the edge the reader starts from. FireMonkey has no BiDiMode at all, so
  the same outcome is reached by the only lever it offers: the field's text
  alignment. A field left aligned under Arabic puts the first character
  somebody types at the far end of the box from where they are looking.

  Captions are deliberately not touched here. Their alignment is decided by
  the planner, which knows where each one sits and what it labels; overruling
  that at run time would undo a decision made with the whole form in view.
  A field is different - it has a caret rather than a position in a sentence,
  and where the caret starts is a property of the reader, not the layout. }
function IsFMXInputControl(const AObject: TFmxObject): Boolean;
begin
  { TComboEdit and the list controls live in units this one does not use,
    and pulling them in for a type test would widen what every application
    links. The two that matter are here; anything else keeps the alignment
    the planner gave it. }
  Result := (AObject is TCustomEdit) or (AObject is TCustomMemo);
end;

function FMXInputRequiresLeftToRight(const AObject: TFmxObject): Boolean;
const
  TechnicalNameParts: array[0..13] of string = (
    'email', 'mail', 'url', 'uri', 'path', 'file', 'folder', 'directory',
    'host', 'port', 'server', 'user', 'password', 'ip');
var
  NamePart: string;
  NameText: string;
  ValueText: string;
begin
  Result := False;
  if AObject = nil then
    Exit;
  NameText := LowerCase(AObject.Name);
  for NamePart in TechnicalNameParts do
    if ContainsText(NameText, NamePart) then
      Exit(True);
  if AObject is TCustomEdit then
    ValueText := TCustomEdit(AObject).Text
  else if AObject is TCustomMemo then
    ValueText := TCustomMemo(AObject).Text
  else
    ValueText := '';
  ValueText := Trim(ValueText);
  Result := ContainsText(ValueText, '@') or ContainsText(ValueText, '://') or
    ContainsText(ValueText, ':\') or ContainsText(ValueText, '\\') or
    StartsText('.\', ValueText) or StartsText('www.', ValueText);
end;

function FMXApplyInputReadingOrder(const AForm: TCommonCustomForm;
  const ARightToLeft: Boolean): Integer;
var
  Applied: Integer;

  procedure Walk(const AObject: TFmxObject);
  var
    ColumnIndex: Integer;
    Grid: TCustomGrid;
    Index: Integer;
    Settings: TTextSettings;
    Desired: TTextAlign;
  begin
    if AObject = nil then
      Exit;
    if IsFMXInputControl(AObject) and
      Supports(AObject, ITextSettings) then
    begin
      Settings := (AObject as ITextSettings).TextSettings;
      if Settings <> nil then
      begin
        if ARightToLeft and not FMXInputRequiresLeftToRight(AObject) then
          Desired := TTextAlign.Trailing
        else
          Desired := TTextAlign.Leading;
        if Settings.HorzAlign <> Desired then
        begin
          { The style puts its own alignment back unless the setting is taken
            out of its hands first - the same trap as WordWrap above. }
          Settings.HorzAlign := Desired;
          Inc(Applied);
        end;
      end;
    end;
    { A grid creates its cell editor only when editing begins, after this walk
      has completed. The editor copies its reading alignment from the active
      column, so set the column rather than trying to find a transient editor
      that does not exist yet. This is the FireMonkey equivalent of giving a
      VCL TCustomGrid the full input BiDiMode. }
    if AObject is TCustomGrid then
    begin
      Grid := TCustomGrid(AObject);
      if ARightToLeft then
        Desired := TTextAlign.Trailing
      else
        Desired := TTextAlign.Leading;
      for ColumnIndex := 0 to Grid.ColumnCount - 1 do
        if Grid.Columns[ColumnIndex].HorzAlign <> Desired then
        begin
          Grid.Columns[ColumnIndex].HorzAlign := Desired;
          Inc(Applied);
        end;
    end;
    { Designer controls belong to the form/component ownership tree. Their
      visual Parent/Children tree is independent and may not include them at
      this point in form creation, so walking Children can miss every edit and
      grid while still making the layout look mirrored. }
    for Index := 0 to AObject.ComponentCount - 1 do
      if AObject.Components[Index] is TFmxObject then
        Walk(TFmxObject(AObject.Components[Index]));
  end;

begin
  Applied := 0;
  Walk(AForm);
  Result := Applied;
end;

function FMXMenuIdentity(const AItem: TFmxObject): string;
begin
  Result := Trim(AItem.Name);
  if Result <> '' then
    Exit;
  Result := '#' + IntToStr(AItem.Index);
end;

function FMXMainMenuOf(const AForm: TCommonCustomForm;
  out AMenu: TMainMenu): Boolean;
var
  Index: Integer;
  Child: TFmxObject;
begin
  AMenu := nil;
  Result := False;
  if AForm = nil then
    Exit;
  for Index := 0 to AForm.ChildrenCount - 1 do
  begin
    Child := AForm.Children[Index];
    if Child is TMainMenu then
    begin
      AMenu := TMainMenu(Child);
      Exit(AMenu.ItemsCount > 1);
    end;
  end;
end;

function FMXDesignedMenuOrder(const AMenu: TMainMenu;
  const AKey: string): TArray<string>;
var
  Index: Integer;
  Item: TFmxObject;
begin
  if TFMXTranslationApplicator.FDesignedMenus.TryGetValue(AKey, Result) then
    Exit;
  SetLength(Result, AMenu.ItemsCount);
  for Index := 0 to AMenu.ItemsCount - 1 do
  begin
    Item := AMenu.Items[Index];
    Result[Index] := FMXMenuIdentity(Item);
  end;
  TFMXTranslationApplicator.FDesignedMenus.AddOrSetValue(AKey, Result);
end;

function FMXApplyMenuOrder(const AForm: TCommonCustomForm;
  const AFormIdentity: string; const AReversed: Boolean): Boolean;
var
  Menu: TMainMenu;
  Designed, Target, Identities: TArray<string>;
  Items: TArray<TFmxObject>;
  Used: TArray<Boolean>;
  Index, Scan: Integer;
begin
  Result := False;
  if not FMXMainMenuOf(AForm, Menu) then
    Exit;
  Designed := FMXDesignedMenuOrder(Menu, AFormIdentity);
  if Length(Designed) <> Menu.ItemsCount then
    Exit;

  SetLength(Target, Length(Designed));
  for Index := 0 to High(Designed) do
    if AReversed then
      Target[Index] := Designed[High(Designed) - Index]
    else
      Target[Index] := Designed[Index];

  { By reference, because setting Index moves everything else. }
  SetLength(Items, Menu.ItemsCount);
  SetLength(Identities, Menu.ItemsCount);
  SetLength(Used, Menu.ItemsCount);
  for Index := 0 to Menu.ItemsCount - 1 do
  begin
    Items[Index] := Menu.Items[Index];
    Identities[Index] := FMXMenuIdentity(Items[Index]);
  end;

  for Index := 0 to High(Target) do
    for Scan := 0 to High(Items) do
    begin
      if Used[Scan] or (Identities[Scan] <> Target[Index]) then
        Continue;
      if Items[Scan].Index <> Index then
      begin
        Items[Scan].Index := Index;
        Result := True;
      end;
      Used[Scan] := True;
      Break;
    end;
end;

function FMXColumnIdentity(const AColumn: TColumn): string;
begin
  { Prefer the designer identity, which survives translation. Runtime-created
    unnamed columns use their object identity for the lifetime of that grid;
    a translated header cannot identify itself because changing it would make
    the next ordering pass unable to find the same column. }
  Result := Trim(AColumn.Name);
  if Result <> '' then
    Exit;
  Result := '#' + IntToHex(NativeUInt(AColumn), SizeOf(Pointer) * 2);
end;

function FMXGridOf(const AComponent: TComponent;
  out AGrid: TCustomGrid): Boolean;
begin
  AGrid := nil;
  Result := AComponent is TCustomGrid;
  if Result then
  begin
    AGrid := TCustomGrid(AComponent);
    Result := AGrid.ColumnCount > 1;
  end;
end;

function FMXDesignedColumnOrder(const AComponent: TComponent;
  const AKey: string): TArray<string>;
var
  Grid: TCustomGrid;
  Index: Integer;
begin
  if TFMXTranslationApplicator.FDesignedColumns.TryGetValue(AKey, Result) then
    Exit;
  SetLength(Result, 0);
  if not FMXGridOf(AComponent, Grid) then
    Exit;
  SetLength(Result, Grid.ColumnCount);
  for Index := 0 to Grid.ColumnCount - 1 do
    Result[Index] := FMXColumnIdentity(Grid.Columns[Index]);
  TFMXTranslationApplicator.FDesignedColumns.AddOrSetValue(AKey, Result);
end;

function FMXApplyColumnOrder(const AComponent: TComponent;
  const AKey: string; const AReversed: Boolean): Boolean;
var
  Grid: TCustomGrid;
  Designed, Target, Identities: TArray<string>;
  Columns: TArray<TColumn>;
  Used: TArray<Boolean>;
  Index, Scan: Integer;
begin
  Result := False;
  if not FMXGridOf(AComponent, Grid) then
    Exit;
  Designed := FMXDesignedColumnOrder(AComponent, AKey);
  if Length(Designed) <> Grid.ColumnCount then
    { The grid was rebuilt behind us, so the designed order no longer
      describes it. Leaving it alone is the only safe answer. }
    Exit;

  SetLength(Target, Length(Designed));
  for Index := 0 to High(Designed) do
    if AReversed then
      Target[Index] := Designed[High(Designed) - Index]
    else
      Target[Index] := Designed[Index];

  { Held by reference before anything moves: setting Index shifts every other
    column, so a position noted a moment ago names a different one. }
  SetLength(Columns, Grid.ColumnCount);
  SetLength(Identities, Grid.ColumnCount);
  SetLength(Used, Grid.ColumnCount);
  for Index := 0 to Grid.ColumnCount - 1 do
  begin
    Columns[Index] := Grid.Columns[Index];
    Identities[Index] := FMXColumnIdentity(Columns[Index]);
  end;

  for Index := 0 to High(Target) do
    for Scan := 0 to High(Columns) do
    begin
      if Used[Scan] or (Identities[Scan] <> Target[Index]) then
        Continue;
      if Columns[Scan].Index <> Index then
      begin
        Columns[Scan].Index := Index;
        Result := True;
      end;
      Used[Scan] := True;
      Break;
    end;
end;

function TrySetLayoutProperty(const AComponent: TComponent;
  const APropertyName, AValue: string): Boolean;
var
  FloatValue: Extended;
  IntegerValue: Int64;
  OrdinalValue: NativeInt;
  PropertyInfo: PPropInfo;
begin
  Result := False;
  if (AComponent is TControl) and
    (SameText(APropertyName, 'Left') or
     SameText(APropertyName, 'Top') or
     SameText(APropertyName, 'Position.X') or
     SameText(APropertyName, 'Position.Y')) then
  begin
    if not TryStrToFloat(AValue, FloatValue, TFormatSettings.Invariant) or
      (FloatValue < -100000) or (FloatValue > 100000) then
      Exit;
    if SameText(APropertyName, 'Left') or
      SameText(APropertyName, 'Position.X') then
      TControl(AComponent).Position.X := FloatValue
    else
      TControl(AComponent).Position.Y := FloatValue;
    Exit(True);
  end;
  { Wrapping must go through TextSettings and leave style control, otherwise
    the assignment is accepted and then ignored at paint time. This matters
    most when AutoSize has just been switched off: without real wrapping the
    control keeps its assigned width and clips the translated text. }
  if SameText(APropertyName, 'WordWrap') and
    Supports(AComponent, ITextSettings) then
  begin
    ApplyWordWrapSetting(AComponent, SameText(AValue, 'True'));
    Exit(True);
  end;
  { Which edge the text sits against. FireMonkey keeps it on TextSettings and
    guards it with StyledSettings in exactly the way wrapping and font size
    are guarded, so it is routed the same way: assigned directly it is
    accepted and then overwritten from the style at paint time. }
  if MatchText(APropertyName, ['TextSettings.HorzAlign', 'HorzAlign']) and
    Supports(AComponent, ITextSettings) then
  begin
    Result := ApplyHorzAlignSetting(AComponent, AValue);
    Exit;
  end;
  if SameText(APropertyName, 'FontSize') and
    Supports(AComponent, ITextSettings) then
  begin
    if not TryStrToFloat(AValue, FloatValue, TFormatSettings.Invariant) or
      (FloatValue <= 0) or (FloatValue > 400) then
      Exit;
    ApplyFontSizeSetting(AComponent, FloatValue);
    Exit(True);
  end;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName);
  if PropertyInfo = nil then
    Exit;
  if PropertyInfo.PropType^.Kind = tkFloat then
  begin
    if not TryStrToFloat(AValue, FloatValue, TFormatSettings.Invariant) or
      (FloatValue < 0) or (FloatValue > 100000) then
      Exit;
    SetFloatProp(AComponent, PropertyInfo, FloatValue);
    Exit(True);
  end;
  if PropertyInfo.PropType^.Kind in [tkInteger, tkInt64] then
  begin
    if not TryStrToInt64(AValue, IntegerValue) or
      (IntegerValue < 0) or (IntegerValue > 100000) then
      Exit;
    OrdinalValue := IntegerValue;
    SetOrdProp(AComponent, PropertyInfo, OrdinalValue);
    Exit(True);
  end;
  if PropertyInfo.PropType^.Kind = tkEnumeration then
  begin
    if SameText(AValue, 'True') then
      OrdinalValue := 1
    else if SameText(AValue, 'False') then
      OrdinalValue := 0
    else
    begin
      { A named value: Align becomes Right for a mirrored layout. }
      OrdinalValue := GetEnumValue(PropertyInfo.PropType^, AValue);
      if OrdinalValue < 0 then
        Exit;
    end;
    SetOrdProp(AComponent, PropertyInfo, OrdinalValue);
    Exit(True);
  end;
  { Anchors is a set rather than a single value. }
  if PropertyInfo.PropType^.Kind = tkSet then
  begin
    try
      SetSetProp(AComponent, PropertyInfo, AValue);
    except
      Exit(False);
    end;
    Exit(True);
  end;
end;

function ApplyGridText(const AFormIdentity: string;
  const AComponent: TComponent; const APack: TRuntimeLanguagePack): Integer;
var
  ColumnIndex: Integer;
  CurrentText: string;
  GridKey: string;
  StringDictionary: TDictionary<string, string>;
  StringPairs: TArray<TPair<string, string>>;
  TranslatedText: string;

  procedure TryGetHeaderTranslation(const AIndex: Integer;
    const ACurrentText: string; out AText: string);
  var
    Prefix: string;
    PairIndex: Integer;
  begin
    AText := ACurrentText;
    Prefix := Format('%s.%s.Columns[%d].Header.', [AFormIdentity,
      AComponent.Name, AIndex]);
    for PairIndex := 0 to Length(StringPairs) - 1 do
      if StartsText(Prefix, StringPairs[PairIndex].Key) then
      begin
        AText := StringPairs[PairIndex].Value;
        Exit;
      end;
    Prefix := Format('%s.%s.Columns.Header.%d.', [AFormIdentity,
      AComponent.Name, AIndex]);
    for PairIndex := 0 to Length(StringPairs) - 1 do
      if StartsText(Prefix, StringPairs[PairIndex].Key) then
      begin
        AText := StringPairs[PairIndex].Value;
        Exit;
      end;
    APack.TryTranslateDynamicText(ACurrentText, AText);
  end;
begin
  Result := 0;
  if not (AComponent is TCustomGrid) then
    Exit;
  StringDictionary := APack.Strings;
  StringPairs := StringDictionary.ToArray;
  for ColumnIndex := 0 to TCustomGrid(AComponent).ColumnCount - 1 do
  begin
    CurrentText := TCustomGrid(AComponent).Columns[ColumnIndex].Header;
    TranslatedText := CurrentText;
    GridKey := Format('%s.%s.Columns.Header.%d', [AFormIdentity,
      AComponent.Name, ColumnIndex]);
    if not APack.TryGetText(GridKey, TranslatedText) then
      GridKey := Format('%s.%s.Columns[%d].Header', [AFormIdentity,
        AComponent.Name, ColumnIndex]);
    if not APack.TryGetText(GridKey, TranslatedText) then
      TryGetHeaderTranslation(ColumnIndex, CurrentText, TranslatedText);
    if (TranslatedText = CurrentText) and
       APack.TryTranslateSource(CurrentText, TranslatedText) then
      { Header columns are not always owned as ordinary TComponent children;
        the source-text fallback keeps their exact catalog translation. }
      ;
    if (TranslatedText <> '') and (TranslatedText <> CurrentText) then
    begin
      { Break marks taken out on the way in.

        A heading is offered soft hyphens so a long word can break, and a
        heading never wraps, so the offer is never taken. DirectWrite
        renders the mark as nothing, which is why this shows on the VCL
        side and not here - but a mark that can only ever do harm is not
        worth carrying on either framework, and a heading narrow enough
        to break at one would break mid-word. }
      TCustomGrid(AComponent).Columns[ColumnIndex].Header :=
        StringReplace(TranslatedText, SoftHyphenMark, '',
          [rfReplaceAll]);
      Inc(Result);
    end;
    { The cells are deliberately left alone.

      A column heading is interface text: the application chose those words and
      they mean the same thing in every language. What sits under the heading is
      the application's data - user-entered values, file names, identifiers and
      rows read from a database - and it belongs to whoever entered it, not to
      us. A stored value can also be a marker the application matches by name.

      Translating them corrupted the grid twice over. The words on screen were
      wrong, and because the substitution has no reliable inverse the rows did
      not come back when the original language was chosen again: the developer
      saw Spanish song titles in an English application with no way to undo it. }
  end;
end;

function ApplyConservativeTextFit(const AForm: TCommonCustomForm;
  const APack: TRuntimeLanguagePack; const AFormIdentity: string): Integer;
const
  HorizontalPadding = 10;
  MinimumReadableFontSize = 8;
  MaximumButtonWidth = 360;
  MinimumLabelWidth = 42;
  MaximumLabelWidth = 420;
  MinimumLabelHeight = 22;
  MaximumLabelHeight = 120;
var
  ComponentIndex: Integer;

  function MeasuredTextWidth(const AText: string; const AFont: TFont): Single;
  var
    CleanText: string;
    Layout: TTextLayout;
  begin
    CleanText := Trim(AText);
    if CleanText = '' then
      Exit(0);
    if AFont = nil then
      Exit(Length(CleanText) * 7.4 + 20);
    Layout := TTextLayoutManager.DefaultTextLayout.Create;
    try
      Layout.BeginUpdate;
      Layout.Text := CleanText;
      Layout.Font := AFont;
      Layout.WordWrap := False;
      Layout.EndUpdate;
      Result := Layout.Width + 20;
    finally
      Layout.Free;
    end;
  end;

  function ParentClientWidth(const AControl: TControl): Single;
  begin
    Result := 0;
    if AControl = nil then
      Exit;
    if (AControl.Parent <> nil) and (AControl.Parent is TControl) then
      Result := TControl(AControl.Parent).Width
    else if AForm <> nil then
      Result := AForm.Width;
  end;

  function RightEdge(const AControl: TControl): Single;
  begin
    if AControl = nil then
      Exit(0);
    Result := AControl.Position.X + AControl.Width;
  end;

  function BottomEdge(const AControl: TControl): Single;
  begin
    if AControl = nil then
      Exit(0);
    Result := AControl.Position.Y + AControl.Height;
  end;

  function VerticalOverlap(const ALeft, ARight: TControl): Single;
  begin
    if (ALeft = nil) or (ARight = nil) then
      Exit(0);
    Result := Min(BottomEdge(ALeft), BottomEdge(ARight)) -
      Max(ALeft.Position.Y, ARight.Position.Y);
    if Result < 0 then
      Result := 0;
  end;

  function AvailableWidthToParentRight(const AControl: TControl): Single;
  var
    ParentWidth: Single;
  begin
    Result := AControl.Width;
    ParentWidth := ParentClientWidth(AControl);
    if ParentWidth > 0 then
      Result := Max(MinimumLabelWidth,
        ParentWidth - AControl.Position.X - HorizontalPadding);
  end;

  function NearestSameRowRightEdgeLimit(const AControl: TControl): Single;
  var
    Candidate: TComponent;
    CandidateControl: TControl;
    CandidateIndex: Integer;
    CandidateLeft: Single;
    BestLeft: Single;
  begin
    Result := AvailableWidthToParentRight(AControl);
    BestLeft := MaxSingle;
    for CandidateIndex := 0 to AForm.ComponentCount - 1 do
    begin
      Candidate := AForm.Components[CandidateIndex];
      if (Candidate = AControl) or not (Candidate is TControl) then
        Continue;
      CandidateControl := TControl(Candidate);
      if (CandidateControl.Parent <> AControl.Parent) or
        (CandidateControl.Align <> TAlignLayout.None) or
        not CandidateControl.Visible then
        Continue;
      CandidateLeft := CandidateControl.Position.X;
      if (CandidateLeft <= AControl.Position.X + 2) or
        (CandidateLeft >= BestLeft) then
        Continue;
      if VerticalOverlap(AControl, CandidateControl) < 4 then
        Continue;
      BestLeft := CandidateLeft;
    end;
    if BestLeft < MaxSingle then
      Result := Max(MinimumLabelWidth, BestLeft - AControl.Position.X -
        HorizontalPadding);
  end;

  function SetBooleanPropertyIfSupported(const AComponent: TComponent;
    const APropertyName: string; const AValue: Boolean): Boolean;
  var
    NewValue: NativeInt;
    PropertyInfo: PPropInfo;
  begin
    Result := False;
    PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName,
      [tkEnumeration]);
    if PropertyInfo = nil then
      Exit;
    if AValue then
      NewValue := 1
    else
      NewValue := 0;
    if GetOrdProp(AComponent, PropertyInfo) <> NewValue then
    begin
      SetOrdProp(AComponent, PropertyInfo, NewValue);
      Result := True;
    end;
  end;

  function SetWordWrapIfSupported(const AComponent: TComponent): Boolean;
  begin
    Result := ApplyWordWrapSetting(AComponent, True) or
      SetBooleanPropertyIfSupported(AComponent, 'WordWrap', True);
  end;

  function DisableAutoSizeIfSupported(const AComponent: TComponent): Boolean;
  begin
    Result := SetBooleanPropertyIfSupported(AComponent, 'AutoSize', False);
  end;

  function FitWrappedHeight(const AText: string; const AFont: TFont;
    const AWidth: Single; const AMinimumHeight, AMaximumHeight: Single): Single;
  var
    Lines: Integer;
  begin
    Lines := Ceil(MeasuredTextWidth(AText, AFont) / Max(40, AWidth));
    Result := Min(AMaximumHeight, Max(AMinimumHeight, Lines * 18 + 6));
  end;

  function ComponentDisplayText(const AComponent: TComponent): string;
  begin
    Result := '';
    if AComponent is TLabel then
      Result := TLabel(AComponent).Text
    else if AComponent is TButton then
      Result := TButton(AComponent).Text
    else if AComponent is TCheckBox then
      Result := TCheckBox(AComponent).Text
    else if AComponent is TTextControl then
      Result := TTextControl(AComponent).Text;
  end;

  function ComponentFont(const AComponent: TComponent): TFont;
  begin
    Result := nil;
    if AComponent is TLabel then
      Result := TLabel(AComponent).Font
    else if AComponent is TButton then
      Result := TButton(AComponent).Font
    else if AComponent is TCheckBox then
      Result := TCheckBox(AComponent).Font
    else if AComponent is TTextControl then
      Result := TTextControl(AComponent).Font;
  end;

  function IsProseBodyLabel(const AComponent: TComponent;
    const AControl: TControl; const AText: string): Boolean;
  begin
    { Long explanatory copy is not a compact caption.  It must retain the
      designer's readable type size and use the width deliberately provided
      by the form.  Treating prose as a heading previously clamped a
      1180-pixel body label to 420 pixels and then reduced it to 8 points.
      The contract is deliberately based on content and geometry, never on a
      language code, so it applies equally to every long translation. }
    Result := (AComponent is TLabel) and
      (Length(Trim(AText)) >= 80) and
      ((AControl.Width >= 360) or (AControl.Height >= 44) or
       (Pos(sLineBreak, AText) > 0));
  end;

  function HasExplicitLayoutRule(const AComponent: TComponent): Boolean;
  var
    Rule: TRuntimeLayoutRule;
  begin
    Result := False;
    if (APack = nil) or (AComponent = nil) or (Trim(AComponent.Name) = '') then
      Exit;
    { Only an accepted geometry/wrapping decision suppresses measured fitting.
      Direction-only and legacy font rules do not prove that translated text
      fits.  In particular, they must not prevent buttons from acquiring the
      padding their rendered caption requires. }
    for Rule in APack.LayoutRules do
      if SameText(Rule.FormName, AFormIdentity) and
        SameText(Rule.ComponentName, AComponent.Name) and
        not SameText(Trim(Rule.OriginalValue),
          Trim(Rule.TranslatedValue)) and
        (SameText(Rule.PropertyName, 'Width') or
         SameText(Rule.PropertyName, 'Height') or
         SameText(Rule.PropertyName, 'Position.X') or
         SameText(Rule.PropertyName, 'Position.Y') or
         (SameText(Rule.PropertyName, 'WordWrap') and
          SameText(Trim(Rule.TranslatedValue), 'True'))) then
        Exit(True);
  end;

  function FitButton(const AComponent: TComponent; const AControl: TControl;
    const AText: string): Integer;
  var
    CaptionWidth: Single;
    Font: TFont;
    FontSize: Single;
    MaxWidth: Single;
    NeededWidth: Single;
    NewHeight: Single;
    NewWidth: Single;
  begin
    Result := 0;
    Font := ComponentFont(AComponent);
    CaptionWidth := MeasuredTextWidth(AText, Font);
    NeededWidth := CaptionWidth + HorizontalPadding;
    MaxWidth := Min(MaximumButtonWidth,
      NearestSameRowRightEdgeLimit(AControl));
    { Preserve compact designer-authored controls (including media transport
      buttons). Grow only when the measured caption needs it. }
    NewWidth := Min(MaxWidth, Max(AControl.Width, NeededWidth));
    if NewWidth > AControl.Width + 4 then
    begin
      AControl.Width := NewWidth;
      Inc(Result);
    end;
    if (CaptionWidth > AControl.Width - HorizontalPadding) and
      (Font <> nil) and (Font.Size > MinimumReadableFontSize) then
    begin
      FontSize := Max(MinimumReadableFontSize,
        Font.Size * ((AControl.Width - HorizontalPadding) / CaptionWidth));
      if ApplyFontSizeSetting(AComponent, FontSize) then
      begin
        Inc(Result);
        CaptionWidth := MeasuredTextWidth(AText, ComponentFont(AComponent));
      end;
    end;
    if CaptionWidth > AControl.Width - HorizontalPadding then
    begin
      if SetWordWrapIfSupported(AComponent) then
        Inc(Result);
      NewHeight := FitWrappedHeight(AText, ComponentFont(AComponent),
        AControl.Width, AControl.Height, 56);
      if NewHeight > AControl.Height + 2 then
      begin
        AControl.Height := NewHeight;
        Inc(Result);
      end;
    end;
  end;

  function FitCheckBox(const AComponent: TComponent; const AControl: TControl;
    const AText: string): Integer;
  var
    MaxWidth: Single;
    NeededHeight: Single;
    NeededWidth: Single;
    NewWidth: Single;
  begin
    Result := 0;
    NeededWidth := MeasuredTextWidth(AText, ComponentFont(AComponent)) + 22;
    MaxWidth := Min(MaximumLabelWidth,
      NearestSameRowRightEdgeLimit(AControl));
    NewWidth := Min(MaxWidth, Max(AControl.Width, NeededWidth));
    if NewWidth > AControl.Width + 4 then
    begin
      AControl.Width := NewWidth;
      Inc(Result);
    end;
    if AControl.Width > MaxWidth + 2 then
    begin
      AControl.Width := MaxWidth;
      Inc(Result);
    end;
    if NeededWidth > AControl.Width + 8 then
    begin
      if SetWordWrapIfSupported(AComponent) then
        Inc(Result);
      NeededHeight := FitWrappedHeight(AText, ComponentFont(AComponent),
        AControl.Width, MinimumLabelHeight, MaximumLabelHeight);
      if NeededHeight > AControl.Height + 2 then
      begin
        AControl.Height := NeededHeight;
        Inc(Result);
      end;
    end;
  end;

  function FitLabel(const AComponent: TComponent; const AControl: TControl;
    const AText: string): Integer;
  var
    HasRightNeighbor: Boolean;
    Font: TFont;
    FontSize: Single;
    MaxWidth: Single;
    NeededHeight: Single;
    NeededWidth: Single;
    NewWidth: Single;
    ParentWidth: Single;
    RightLimitedWidth: Single;
  begin
    Result := 0;
    Font := ComponentFont(AComponent);
    NeededWidth := MeasuredTextWidth(AText, Font);
    ParentWidth := ParentClientWidth(AControl);
    RightLimitedWidth := NearestSameRowRightEdgeLimit(AControl);
    HasRightNeighbor := RightLimitedWidth < AvailableWidthToParentRight(AControl) - 1;

    if IsProseBodyLabel(AComponent, AControl, AText) then
    begin
      { Prose keeps its authored font size.  It wraps within the actual
        available row width, rather than the compact-label width ceiling. }
      if DisableAutoSizeIfSupported(AComponent) then
        Inc(Result);
      if SetWordWrapIfSupported(AComponent) then
        Inc(Result);
      MaxWidth := Max(MinimumLabelWidth, RightLimitedWidth);
      if AControl.Width > MaxWidth + 2 then
      begin
        AControl.Width := MaxWidth;
        Inc(Result);
      end;
      NeededHeight := FitWrappedHeight(AText, Font, AControl.Width,
        AControl.Height, MaximumLabelHeight);
      if NeededHeight > AControl.Height + 2 then
      begin
        AControl.Height := NeededHeight;
        Inc(Result);
      end;
      Exit;
    end;

    MaxWidth := Min(MaximumLabelWidth, RightLimitedWidth);
    if ParentWidth > 0 then
      MaxWidth := Min(MaxWidth, ParentWidth - AControl.Position.X -
        HorizontalPadding);
    MaxWidth := Max(MinimumLabelWidth, MaxWidth);

    if (NeededWidth <= AControl.Width + 6) and
      (RightEdge(AControl) <= AControl.Position.X + MaxWidth + 1) then
      Exit;

    if DisableAutoSizeIfSupported(AComponent) then
      Inc(Result);
    if SetWordWrapIfSupported(AComponent) then
      Inc(Result);

    if HasRightNeighbor then
      NewWidth := MaxWidth
    else
      NewWidth := Min(MaxWidth, Max(AControl.Width, NeededWidth));
    NewWidth := Max(MinimumLabelWidth, NewWidth);

    if Abs(AControl.Width - NewWidth) > 2 then
    begin
      AControl.Width := NewWidth;
      Inc(Result);
    end;

    { A heading should first use the width that is safely available and then
      reduce its type only as far as a readable floor.  Wrapping remains the
      final fallback.  This contract is based on measured text and neighbours,
      not on a language name, so every longer translation receives the same
      treatment. }
    if (NeededWidth > AControl.Width - HorizontalPadding) and
      (Font <> nil) and (Font.Size > MinimumReadableFontSize) then
    begin
      FontSize := Max(MinimumReadableFontSize,
        Font.Size * ((AControl.Width - HorizontalPadding) / NeededWidth));
      if ApplyFontSizeSetting(AComponent, FontSize) then
        Inc(Result);
    end;

    NeededHeight := FitWrappedHeight(AText, ComponentFont(AComponent),
      AControl.Width, MinimumLabelHeight, MaximumLabelHeight);
    if NeededHeight > AControl.Height + 2 then
    begin
      AControl.Height := NeededHeight;
      Inc(Result);
    end;
  end;

  function HorizontalOverlapRatio(const ALeft, ARight: TControl): Single;
  var
    MinWidth: Single;
    OverlapWidth: Single;
  begin
    OverlapWidth := Min(RightEdge(ALeft), RightEdge(ARight)) -
      Max(ALeft.Position.X, ARight.Position.X);
    if OverlapWidth <= 0 then
      Exit(0);
    MinWidth := Min(ALeft.Width, ARight.Width);
    if MinWidth <= 0 then
      Exit(0);
    Result := OverlapWidth / MinWidth;
  end;

  { A control that grows taller (because its translated text wrapped to more
    lines) can push its own bottom edge into whatever control was originally
    resting directly beneath it. This does not rearrange the form: it only
    shifts a control that was already touching the grown control's original
    bottom edge, straight down by exactly the growth amount, preserving the
    original gap. It recurses so a short stack (label -> field -> note, all
    touching) moves together, but never touches a control that was not
    already adjacent. }
  function CascadeStackedGrowth(const AControl: TControl; const AOldBottom,
    ADelta: Single; const AVisited: TList<TControl>): Integer;
  const
    StackTouchTolerance = 6;
    MinimumHorizontalOverlapRatio = 0.2;
  var
    Candidate: TComponent;
    CandidateControl: TControl;
    CandidateIndex: Integer;
    CandidateOldBottom: Single;
  begin
    Result := 0;
    for CandidateIndex := 0 to AForm.ComponentCount - 1 do
    begin
      Candidate := AForm.Components[CandidateIndex];
      if (Candidate = AControl) or not (Candidate is TControl) then
        Continue;
      CandidateControl := TControl(Candidate);
      if AVisited.IndexOf(CandidateControl) >= 0 then
        Continue;
      if (CandidateControl.Parent <> AControl.Parent) or
        (CandidateControl.Align <> TAlignLayout.None) or
        not CandidateControl.Visible then
        Continue;
      if Abs(CandidateControl.Position.Y - AOldBottom) > StackTouchTolerance then
        Continue;
      if HorizontalOverlapRatio(AControl, CandidateControl) <
        MinimumHorizontalOverlapRatio then
        Continue;
      AVisited.Add(CandidateControl);
      CandidateOldBottom := BottomEdge(CandidateControl);
      CandidateControl.Position.Y := CandidateControl.Position.Y + ADelta;
      Inc(Result);
      Inc(Result, CascadeStackedGrowth(CandidateControl, CandidateOldBottom,
        ADelta, AVisited));
    end;
  end;

  function FitComponent(const AComponent: TComponent): Integer;
  var
    Control: TControl;
    CurrentText: string;
    GrowthDelta: Single;
    Key: string;
    OldBottom: Single;
    PackText: string;
    Visited: TList<TControl>;

    function TextCameFromPack: Boolean;
    var
      SourcePair: TPair<string, string>;
    begin
      Result := False;
      if Trim(AComponent.Name) <> '' then
      begin
        Key := AFormIdentity + '.' + AComponent.Name + '.Text';
        if APack.TryGetText(Key, PackText) and
          (Trim(PackText) = CurrentText) then
          Exit(True);
        Key := AFormIdentity + '.' + AComponent.Name + '.Caption';
        if APack.TryGetText(Key, PackText) and
          (Trim(PackText) = CurrentText) then
          Exit(True);
      end;
      for SourcePair in APack.SourceStrings do
        if Trim(SourcePair.Value) = CurrentText then
          Exit(True);
    end;
  begin
    Result := 0;
    if not (AComponent is TControl) then
      Exit;
    Control := TControl(AComponent);
    if (Control.Align <> TAlignLayout.None) or not Control.Visible then
      Exit;
    if not ((AComponent is TLabel) or (AComponent is TButton) or
      (AComponent is TCheckBox) or (AComponent is TTextControl)) then
      Exit;
    if HasExplicitLayoutRule(AComponent) and not (AComponent is TButton) then
      Exit;
    CurrentText := Trim(ComponentDisplayText(AComponent));
    if CurrentText = '' then
      Exit;
    if not TextCameFromPack then
      Exit;

    OldBottom := BottomEdge(Control);
    if AComponent is TButton then
      Result := FitButton(AComponent, Control, CurrentText)
    else if AComponent is TCheckBox then
      Result := FitCheckBox(AComponent, Control, CurrentText)
    else if AComponent is TLabel then
      Result := FitLabel(AComponent, Control, CurrentText);

    GrowthDelta := BottomEdge(Control) - OldBottom;
    if GrowthDelta > 1 then
    begin
      Visited := TList<TControl>.Create;
      try
        Visited.Add(Control);
        Inc(Result, CascadeStackedGrowth(Control, OldBottom, GrowthDelta,
          Visited));
      finally
        Visited.Free;
      end;
    end;
  end;

  function IsInputLikeControl(const AComponent: TComponent): Boolean;
  begin
    Result :=
      (AComponent is TCustomEdit) or
      ContainsText(AComponent.ClassName, 'Combo') or
      ContainsText(AComponent.ClassName, 'Date') or
      ContainsText(AComponent.ClassName, 'Time') or
      ContainsText(AComponent.ClassName, 'Spin') or
      ContainsText(AComponent.ClassName, 'Number');
  end;

  function SameTightRow(const ALeft, ARight: TControl): Boolean;
  var
    LeftCenter: Single;
    RightCenter: Single;
  begin
    LeftCenter := ALeft.Position.Y + ALeft.Height / 2;
    RightCenter := ARight.Position.Y + ARight.Height / 2;
    Result := Abs(LeftCenter - RightCenter) <=
      Max(12, Max(ALeft.Height, ARight.Height) * 0.65);
  end;

  function ApplyLabelInputGuards: Integer;
  const
    FieldGap = 8;
    MinimumReadableLabelWidth = 60;
  var
    Candidate: TComponent;
    CandidateControl: TControl;
    Component: TComponent;
    ComponentControl: TControl;
    ComponentIndex: Integer;
    CandidateIndex: Integer;
    BestField: TControl;
    BestFieldLeft: Single;
    NewHeight: Single;
    NewWidth: Single;
    TextValue: string;
  begin
    Result := 0;
    for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    begin
      Component := AForm.Components[ComponentIndex];
      if not (Component is TLabel) or not (Component is TControl) then
        Continue;
      if HasExplicitLayoutRule(Component) then
        Continue;
      ComponentControl := TControl(Component);
      if (ComponentControl.Align <> TAlignLayout.None) or
        not ComponentControl.Visible then
        Continue;
      TextValue := Trim(ComponentDisplayText(Component));
      if TextValue = '' then
        Continue;

      BestField := nil;
      BestFieldLeft := MaxSingle;
      for CandidateIndex := 0 to AForm.ComponentCount - 1 do
      begin
        Candidate := AForm.Components[CandidateIndex];
        if (Candidate = Component) or not IsInputLikeControl(Candidate) or
          not (Candidate is TControl) then
          Continue;
        CandidateControl := TControl(Candidate);
        if (CandidateControl.Parent <> ComponentControl.Parent) or
          (CandidateControl.Align <> TAlignLayout.None) or
          not CandidateControl.Visible then
          Continue;
        if CandidateControl.Position.X <= ComponentControl.Position.X then
          Continue;
        if not SameTightRow(ComponentControl, CandidateControl) then
          Continue;
        if CandidateControl.Position.X < BestFieldLeft then
        begin
          BestField := CandidateControl;
          BestFieldLeft := CandidateControl.Position.X;
        end;
      end;

      if BestField = nil then
        Continue;
      NewWidth := BestField.Position.X - ComponentControl.Position.X - FieldGap;
      if NewWidth < MinimumReadableLabelWidth then
        Continue;
      if RightEdge(ComponentControl) > BestField.Position.X - FieldGap then
      begin
        if DisableAutoSizeIfSupported(Component) then
          Inc(Result);
        if SetWordWrapIfSupported(Component) then
          Inc(Result);
        if Abs(ComponentControl.Width - NewWidth) > 2 then
        begin
          ComponentControl.Width := NewWidth;
          Inc(Result);
        end;
        NewHeight := FitWrappedHeight(TextValue, ComponentFont(Component),
          ComponentControl.Width, MinimumLabelHeight, MaximumLabelHeight);
        if NewHeight > ComponentControl.Height + 2 then
        begin
          ComponentControl.Height := NewHeight;
          Inc(Result);
        end;
      end;
    end;
  end;

  function FitContainer(const AComponent: TComponent): Integer;
  const
    BottomPadding = 12;
  var
    Child: TFmxObject;
    ChildControl: TControl;
    ChildIndex: Integer;
    Container: TControl;
    GrowthDelta: Single;
    MaximumBottom: Single;
    OldBottom: Single;
    RequiredHeight: Single;
    Visited: TList<TControl>;
  begin
    Result := 0;
    if not (AComponent is TControl) then
      Exit;
    Container := TControl(AComponent);
    if (Container.Align <> TAlignLayout.None) or
      not Container.Visible or (Container.ChildrenCount = 0) or
      not ((AComponent is TRectangle) or (AComponent is TLayout) or
        ContainsText(AComponent.ClassName, 'Panel') or
        ContainsText(AComponent.ClassName, 'GroupBox')) then
      Exit;
    MaximumBottom := 0;
    for ChildIndex := 0 to Container.ChildrenCount - 1 do
    begin
      Child := Container.Children[ChildIndex];
      if not (Child is TControl) then
        Continue;
      ChildControl := TControl(Child);
      if not ChildControl.Visible or
        (ChildControl.Align in [TAlignLayout.Client, TAlignLayout.Contents]) then
        Continue;
      MaximumBottom := Max(MaximumBottom,
        ChildControl.Position.Y + ChildControl.Height);
    end;
    RequiredHeight := MaximumBottom + BottomPadding;
    if RequiredHeight <= Container.Height + 1 then
      Exit;
    OldBottom := BottomEdge(Container);
    Container.Height := RequiredHeight;
    Inc(Result);
    GrowthDelta := BottomEdge(Container) - OldBottom;
    if GrowthDelta > 1 then
    begin
      Visited := TList<TControl>.Create;
      try
        Visited.Add(Container);
        Inc(Result, CascadeStackedGrowth(Container, OldBottom, GrowthDelta,
          Visited));
      finally
        Visited.Free;
      end;
    end;
  end;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    Inc(Result, FitComponent(AForm.Components[ComponentIndex]));
  Inc(Result, ApplyLabelInputGuards);
  { Several passes allow an inner text group to grow its card and that card to
    grow the outer scrollable content area. The pass count is fixed, so there
    is no event-driven or language-switch layout loop. }
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    Inc(Result, FitContainer(AForm.Components[ComponentIndex]));
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    Inc(Result, FitContainer(AForm.Components[ComponentIndex]));
end;
function EditableTextComponent(const AComponent: TComponent): Boolean;
begin
  Result := ((AComponent is TCustomEdit) and
    not TCustomEdit(AComponent).ReadOnly) or
    ((AComponent is TCustomMemo) and
    not TCustomMemo(AComponent).ReadOnly);
end;

function ComponentKey(const AFormIdentity: string;
  const AForm, AComponent: TComponent;
  const APropertyName: string): string;
begin
  if AComponent = AForm then
    Result := AFormIdentity + '.' + APropertyName
  else
    Result := AFormIdentity + '.' + AComponent.Name + '.' + APropertyName;
end;

{ A grid heading, whichever way it arrived, carries no break marks.

  A translation of a long word is offered soft hyphens so it can break, and
  prose is right to keep them. A heading is not prose: it never wraps, so the
  offer is never taken, and what is left is a mark the text engine still has to
  do something with. GDI draws it, which is how an Italian heading came to read
  "Data di ripro-du-zione" on the screen.

  Only headings are stripped. A wrapping paragraph still needs its break
  points. }
function HeadingWithoutBreakMarks(const APropertyName,
  AText: string): string;
begin
  if SameText(APropertyName, 'Header') then
    Result := StringReplace(AText, SoftHyphenMark, '', [rfReplaceAll])
  else
    Result := AText;
end;

function ApplyTextProperty(const AFormIdentity: string;
  const AForm, AComponent: TComponent;
  const APropertyName: string; const APack: TRuntimeLanguagePack;
  const APreserveControlState: Boolean): Boolean;
var
  PropertyInfo: PPropInfo;
  CurrentText: string;
  Key: string;
  NextText: string;
  Pass: Integer;
  SourceText: string;
  TranslatedText: string;
begin
  Result := False;
  if APreserveControlState and SameText(APropertyName, 'Text') and
    EditableTextComponent(AComponent) then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName,
    [tkString, tkLString, tkWString, tkUString]);
  if PropertyInfo = nil then
    Exit;
  CurrentText := GetStrProp(AComponent, PropertyInfo);
  Key := ComponentKey(AFormIdentity, AForm, AComponent, APropertyName);
  if APack.TryGetText(Key, TranslatedText) then
  begin
    if TranslatedText = CurrentText then
      Exit;
    { Preserve live application data that has replaced a designer placeholder
      before this form was discovered, as commonly happens on splash screens. }
    if APack.TryGetSource(Key, SourceText) and
      (StringReplace(CurrentText, SoftHyphenMark, '', [rfReplaceAll]) <>
       StringReplace(SourceText, SoftHyphenMark, '', [rfReplaceAll])) then
      Exit;
    SetStrProp(AComponent, PropertyInfo,
      HeadingWithoutBreakMarks(APropertyName, TranslatedText));
    Result := True;
  end;
  if Result then
    Exit;
  TranslatedText := CurrentText;
  for Pass := 1 to 64 do
  begin
    if not APack.TryTranslateDynamicText(TranslatedText, NextText) or
      (NextText = TranslatedText) then
      Break;
    TranslatedText := NextText;
  end;
  if TranslatedText <> CurrentText then
  begin
    SetStrProp(AComponent, PropertyInfo,
      HeadingWithoutBreakMarks(APropertyName, TranslatedText));
    Result := True;
  end;
end;

function ApplyStringCollection(const AFormIdentity: string;
  const AForm, AComponent: TComponent;
  const APropertyName, AKeyPropertyName: string;
  const APack: TRuntimeLanguagePack;
  const APreserveControlState: Boolean): Integer;
var
  ChangeEventInfo: PPropInfo;
  EmptyChangeEvent: TMethod;
  ItemIndexInfo: PPropInfo;
  SavedChangeEvent: TMethod;
  SavedItemIndex: NativeInt;
  PropertyInfo: PPropInfo;
  StringObject: TObject;
begin
  Result := 0;
  if APreserveControlState and SameText(APropertyName, 'Lines') and
    EditableTextComponent(AComponent) then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName, [tkClass]);
  if PropertyInfo = nil then
    Exit;
  StringObject := GetObjectProp(AComponent, PropertyInfo);
  if StringObject is TStrings then
  begin
    ItemIndexInfo := GetPropInfo(AComponent.ClassInfo, 'ItemIndex',
      [tkInteger, tkInt64]);
    if APreserveControlState and (ItemIndexInfo <> nil) then
      SavedItemIndex := GetOrdProp(AComponent, ItemIndexInfo)
    else
      SavedItemIndex := -1;

    ChangeEventInfo := GetPropInfo(AComponent.ClassInfo, 'OnChange', [tkMethod]);
    if ChangeEventInfo <> nil then
    begin
      SavedChangeEvent := GetMethodProp(AComponent, ChangeEventInfo);
      EmptyChangeEvent.Code := nil;
      EmptyChangeEvent.Data := nil;
      SetMethodProp(AComponent, ChangeEventInfo, EmptyChangeEvent);
    end;
    try
      Result := APack.ReadIndexedStrings(
        ComponentKey(AFormIdentity, AForm, AComponent, AKeyPropertyName),
        TStrings(StringObject));
      if APreserveControlState and (Result > 0) and
        (ItemIndexInfo <> nil) and
        (SavedItemIndex >= -1) and
        (SavedItemIndex < TStrings(StringObject).Count) then
        SetOrdProp(AComponent, ItemIndexInfo, SavedItemIndex);
    finally
      if ChangeEventInfo <> nil then
        SetMethodProp(AComponent, ChangeEventInfo, SavedChangeEvent);
    end;
  end;
end;

function RestoreSourceTextProperty(const AFormIdentity: string;
  const AForm, AComponent: TComponent; const APropertyName: string;
  const APack: TRuntimeLanguagePack): Boolean;
var
  CurrentText: string;
  Key: string;
  PropertyInfo: PPropInfo;
  RestoredText: string;
  SourceText: string;
  TranslatedText: string;
begin
  Result := False;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName,
    [tkString, tkLString, tkWString, tkUString]);
  if PropertyInfo = nil then
    Exit;
  Key := ComponentKey(AFormIdentity, AForm, AComponent, APropertyName);
  if not APack.TryGetSource(Key, SourceText) then
    Exit;
  CurrentText := GetStrProp(AComponent, PropertyInfo);
  if CurrentText = SourceText then
    Exit;
  if APack.TryGetText(Key, TranslatedText) and
    (StringReplace(CurrentText, SoftHyphenMark, '', [rfReplaceAll]) =
     StringReplace(TranslatedText, SoftHyphenMark, '', [rfReplaceAll])) then
    RestoredText := SourceText
  else if not APack.TryRestoreDynamicText(CurrentText, RestoredText) then
    Exit;
  SetStrProp(AComponent, PropertyInfo, RestoredText);
  Result := True;
end;

function RestoreSourceStringCollection(const AFormIdentity: string;
  const AForm, AComponent: TComponent; const APropertyName,
  AKeyPropertyName: string; const APack: TRuntimeLanguagePack): Integer;
var
  ChangeEventInfo: PPropInfo;
  EmptyChangeEvent: TMethod;
  Index: Integer;
  ItemIndexInfo: PPropInfo;
  Key: string;
  Prefix: string;
  PropertyInfo: PPropInfo;
  SavedChangeEvent: TMethod;
  SavedItemIndex: NativeInt;
  StringObject: TObject;
  SourceText: string;
begin
  Result := 0;
  if SameText(APropertyName, 'Lines') and EditableTextComponent(AComponent) then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName, [tkClass]);
  if PropertyInfo = nil then
    Exit;
  StringObject := GetObjectProp(AComponent, PropertyInfo);
  if not (StringObject is TStrings) then
    Exit;
  ItemIndexInfo := GetPropInfo(AComponent.ClassInfo, 'ItemIndex',
    [tkInteger, tkInt64]);
  if ItemIndexInfo <> nil then
    SavedItemIndex := GetOrdProp(AComponent, ItemIndexInfo)
  else
    SavedItemIndex := -1;
  ChangeEventInfo := GetPropInfo(AComponent.ClassInfo, 'OnChange', [tkMethod]);
  if ChangeEventInfo <> nil then
  begin
    SavedChangeEvent := GetMethodProp(AComponent, ChangeEventInfo);
    EmptyChangeEvent.Code := nil;
    EmptyChangeEvent.Data := nil;
    SetMethodProp(AComponent, ChangeEventInfo, EmptyChangeEvent);
  end;
  Prefix := ComponentKey(AFormIdentity, AForm, AComponent,
    AKeyPropertyName) + '.';
  try
    TStrings(StringObject).BeginUpdate;
    try
      for Index := 0 to TStrings(StringObject).Count - 1 do
      begin
        Key := Prefix + Index.ToString;
        if APack.TryGetSource(Key, SourceText) and
          (TStrings(StringObject)[Index] <> SourceText) then
        begin
          TStrings(StringObject)[Index] := SourceText;
          Inc(Result);
        end;
      end;
    finally
      TStrings(StringObject).EndUpdate;
    end;
    if (ItemIndexInfo <> nil) and (SavedItemIndex >= -1) and
      (SavedItemIndex < TStrings(StringObject).Count) then
      SetOrdProp(AComponent, ItemIndexInfo, SavedItemIndex);
  finally
    if ChangeEventInfo <> nil then
      SetMethodProp(AComponent, ChangeEventInfo, SavedChangeEvent);
  end;
end;

class function TFMXTranslationApplicator.ApplyToForm(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack): Integer;
begin
  if AForm = nil then
    raise EArgumentNilException.Create('An FMX form is required.');
  Result := ApplyToForm(AForm, APack, AForm.Name, True);
end;

{ True when this component publishes AutoSize, with its current value. It is
  reached through run-time type information because the property belongs to
  several unrelated classes rather than to a common ancestor. }
function TryReadAutoSize(const AComponent: TComponent;
  out AValue: Boolean): Boolean;
var
  PropertyInfo: PPropInfo;
begin
  Result := False;
  if AComponent = nil then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'AutoSize');
  if (PropertyInfo = nil) or
    (PropertyInfo.PropType^.Kind <> tkEnumeration) then
    Exit;
  AValue := GetOrdProp(AComponent, PropertyInfo) <> 0;
  Result := True;
end;

procedure WriteAutoSize(const AComponent: TComponent; const AValue: Boolean);
var
  PropertyInfo: PPropInfo;
begin
  if AComponent = nil then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'AutoSize');
  if (PropertyInfo = nil) or
    (PropertyInfo.PropType^.Kind <> tkEnumeration) then
    Exit;
  SetOrdProp(AComponent, PropertyInfo, Ord(AValue));
end;

class procedure TFMXTranslationApplicator.SnapshotOriginalGeometry(
  const AForm: TCommonCustomForm; const AFormIdentity: string);
var
  ComponentIndex: Integer;

  procedure SnapshotTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    Control: TControl;
    Key: string;
    Settings: ITextSettings;
    Snapshot: TDATControlSnapshot;
    StyledSettings: TStyledSettings;
  begin
    if AComponent = nil then
      Exit;
    Key := PositionKey(AFormIdentity, AComponent);
    { Taken once, before the first language is applied. A second language must
      not overwrite it, or the original would quietly become whichever
      translation happened to run first. }
    if (Key <> '') and (AComponent is TControl) and
      not FOriginalGeometry.ContainsKey(Key) then
    begin
      Control := TControl(AComponent);
      Snapshot := Default(TDATControlSnapshot);
      { An aligned control is placed by its parent, so its position is not ours
        to remember or to give back. Its size still is. }
      Snapshot.HasPosition := Control.Align = TAlignLayout.None;
      Snapshot.Position := TPointF.Create(Control.Position.X,
        Control.Position.Y);
      Snapshot.Size := TPointF.Create(Control.Width, Control.Height);
      Snapshot.HasTextSettings := AsTextSettings(AComponent, Settings);
      if Snapshot.HasTextSettings then
      begin
        Snapshot.FontSize := Settings.TextSettings.Font.Size;
        Snapshot.FontColor := Cardinal(Settings.TextSettings.FontColor);
        Snapshot.WordWrap := Settings.TextSettings.WordWrap;
        Snapshot.Trimming := Byte(Settings.TextSettings.Trimming);
        StyledSettings := Settings.StyledSettings;
        Snapshot.StyledSettings := Byte(StyledSettings);
      end;
      Snapshot.HasAutoSize := TryReadAutoSize(AComponent, Snapshot.AutoSize);
      Snapshot.Align := Control.Align;
      Snapshot.Anchors := ReadAnchorsText(AComponent);
      if Snapshot.HasTextSettings then
        Snapshot.HorzAlign := Byte(Settings.TextSettings.HorzAlign);
      FOriginalGeometry.Add(Key, Snapshot);
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
      SnapshotTree(AComponent.Components[ChildIndex]);
  end;
begin
  if (AForm = nil) or (FOriginalGeometry = nil) then
    Exit;
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    SnapshotTree(AForm.Components[ComponentIndex]);
end;

class function TFMXTranslationApplicator.RestoreOriginalGeometry(
  const AForm: TCommonCustomForm; const AFormIdentity: string): Integer;
var
  ComponentIndex: Integer;
  Restored: Integer;

  procedure RestoreTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    Control: TControl;
    Key: string;
    Settings: ITextSettings;
    Snapshot: TDATControlSnapshot;
    StyledSettings: TStyledSettings;
  begin
    if AComponent = nil then
      Exit;
    Key := PositionKey(AFormIdentity, AComponent);
    if (Key <> '') and (AComponent is TControl) and
      FOriginalGeometry.TryGetValue(Key, Snapshot) then
    begin
      Control := TControl(AComponent);
      { Order matters here for the same reason it matters when applying. A
        control that sizes itself will not accept a width, so automatic sizing
        is switched off first and put back at the end; and the text settings go
        on before the size, because both the size and the wrapping are read
        when the control lays its text out. }
      if Snapshot.HasAutoSize then
        WriteAutoSize(AComponent, False);
      if Snapshot.HasTextSettings and AsTextSettings(AComponent, Settings) then
      begin
        StyledSettings := TStyledSettings(Snapshot.StyledSettings);
        Settings.StyledSettings := StyledSettings;
        Settings.TextSettings.Font.Size := Snapshot.FontSize;
        Settings.TextSettings.FontColor := TAlphaColor(Snapshot.FontColor);
        Settings.TextSettings.WordWrap := Snapshot.WordWrap;
        Settings.TextSettings.Trimming := TTextTrimming(Snapshot.Trimming);
        Settings.TextSettings.HorzAlign := TTextAlign(Snapshot.HorzAlign);
        Inc(Restored);
      end;
      if not SameValue(Control.Width, Snapshot.Size.X, 0.5) or
        not SameValue(Control.Height, Snapshot.Size.Y, 0.5) then
      begin
        Control.SetBounds(Control.Position.X, Control.Position.Y,
          Snapshot.Size.X, Snapshot.Size.Y);
        Inc(Restored);
      end;
      if Snapshot.HasPosition and
        (not SameValue(Control.Position.X, Snapshot.Position.X, 0.5) or
         not SameValue(Control.Position.Y, Snapshot.Position.Y, 0.5)) then
      begin
        Control.Position.X := Snapshot.Position.X;
        Control.Position.Y := Snapshot.Position.Y;
        Inc(Restored);
      end;
      { The mirror, undone. }
      if Control.Align <> Snapshot.Align then
      begin
        Control.Align := Snapshot.Align;
        Inc(Restored);
      end;
      if (Snapshot.Anchors <> '') and
        (ReadAnchorsText(AComponent) <> Snapshot.Anchors) then
      begin
        WriteAnchorsText(AComponent, Snapshot.Anchors);
        Inc(Restored);
      end;
      if Snapshot.HasAutoSize then
        WriteAutoSize(AComponent, Snapshot.AutoSize);
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
      RestoreTree(AComponent.Components[ChildIndex]);
  end;
begin
  Result := 0;
  if (AForm = nil) or (FOriginalGeometry = nil) then
    Exit;
  Restored := 0;
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    RestoreTree(AForm.Components[ComponentIndex]);
  Result := Restored;
end;

class function TFMXTranslationApplicator.ApplyDirectionMirror(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
const
  TransportWords: array[0..12] of string = (
    'play', 'pause', 'stop', 'rewind', 'forward', 'record', 'eject',
    'skip', 'previous', 'next', 'seek', 'replay', 'shuffle');
var
  Rule: TRuntimeLayoutRule;
  MirrorEnabled: Boolean;

  function IsApplicationControl(const AControl: TControl): Boolean;
  begin
    Result := (AControl <> nil) and (Trim(AControl.Name) <> '') and
      (AForm.FindComponent(AControl.Name) = AControl) and
      { A tab item is a page selected and positioned by its tab control. Its
        contents mirror, but moving the page itself fights the framework. }
      not ContainsText(AControl.ClassName, 'TabItem');
  end;

  function IsTransport(const AControl: TControl): Boolean;
  var
    SourceText: string;
    Word: string;
  begin
    Result := False;
    if (AControl = nil) or
      (not ContainsText(AControl.ClassName, 'Button')) then
      Exit;
    SourceText := '';
    if not APack.TryGetSource(AFormIdentity + '.' + AControl.Name + '.Text',
      SourceText) then
      APack.TryGetSource(AFormIdentity + '.' + AControl.Name + '.Caption',
        SourceText);
    for Word in TransportWords do
      if ContainsText(AControl.Name, Word) or
        ContainsText(SourceText, Word) then
        Exit(True);
  end;

  procedure MirrorParent(const AParent: TFmxObject;
    const ASerializedWidth: Single);
  var
    Child: TFmxObject;
    ChildIndex: Integer;
    Control: TControl;
    Ancestor: TFmxObject;
    EffectiveWidth: Single;
    GeometryResolved: Boolean;
    HasEdgeChild: Boolean;
    LargestChildRight: Single;
    MinimumPositiveInset: Single;
    MirroredLeft: Single;
    SourceLeft: Single;
    GroupLeft, GroupRight, MirroredGroupLeft: Single;
    TransportControls: TList<TControl>;

    function DesignedLeft(const AControl: TControl): Single;
    var
      Snapshot: TDATControlSnapshot;
    begin
      Result := AControl.Position.X;
      if (FOriginalGeometry <> nil) and
        FOriginalGeometry.TryGetValue(
          PositionKey(AFormIdentity, AControl), Snapshot) and
        Snapshot.HasPosition then
        Result := Snapshot.Position.X;
    end;

    function DesignedWidth(const AControl: TControl): Single;
    var
      Snapshot: TDATControlSnapshot;
    begin
      Result := AControl.Width;
      if (FOriginalGeometry <> nil) and
        FOriginalGeometry.TryGetValue(
          PositionKey(AFormIdentity, AControl), Snapshot) and
        (Snapshot.Size.X > 0) then
        Result := Snapshot.Size.X;
    end;

    function SnapshotWidth(const AObject: TFmxObject): Single;
    var
      Snapshot: TDATControlSnapshot;
    begin
      Result := 0;
      if (AObject is TControl) and (FOriginalGeometry <> nil) and
        FOriginalGeometry.TryGetValue(
          PositionKey(AFormIdentity, TControl(AObject)), Snapshot) then
        Result := Snapshot.Size.X;
    end;
  begin
    if AParent = nil then
      Exit;
    EffectiveWidth := Max(ASerializedWidth, SnapshotWidth(AParent));
    { A TTabItem can retain its small designer placeholder width while its
      tab control supplies the real client area.  An aligned content parent
      has the same relationship after responsive layout. }
    if (AParent is TControl) and
      ((TControl(AParent).Align in [TAlignLayout.Client,
        TAlignLayout.Contents]) or ContainsText(AParent.ClassName, 'TabItem'))
      and (TControl(AParent).ParentControl <> nil) and
      (TControl(AParent).ParentControl.Width > EffectiveWidth) then
      EffectiveWidth := TControl(AParent).ParentControl.Width;
    { Every child position is expressed in its immediate visual parent's
      coordinate space.  Never widen an ordinary nested parent to an
      ancestor's snapshot width: doing that mirrors the nested children into
      coordinates outside their own container.  The two measured fallbacks
      below remain responsible for framework-managed tab placeholders. }

    { Preserve the visible content gutter when a designer-sized control ends
      on, or a rounding pixel beyond, its parent's opposite edge.  FMX form
      resources commonly contain a one-pixel disagreement between a live tab
      client width and a card width.  The literal mirror of that geometry is
      zero or negative and makes the RTL card touch the window edge even though
      its LTR peer has a deliberate leading inset.

      The smallest positive designer inset among ordinary siblings is the
      parent's content gutter.  It is used only as a lower bound for controls
      that themselves began at or beyond that gutter; true edge-to-edge
      controls at X=0 remain edge-to-edge. }
    MinimumPositiveInset := MaxSingle;
    HasEdgeChild := False;
    LargestChildRight := 0;
    for ChildIndex := 0 to AParent.ChildrenCount - 1 do
    begin
      Child := AParent.Children[ChildIndex];
      if Child is TControl then
      begin
        Control := TControl(Child);
        SourceLeft := DesignedLeft(Control);
        if IsApplicationControl(Control) and
          (Control.Align = TAlignLayout.None) and
          (SourceLeft <= 0.5) then
          HasEdgeChild := True;
        if IsApplicationControl(Control) and
          (Control.Align = TAlignLayout.None) and
          (SourceLeft > 0.5) and
          (SourceLeft < MinimumPositiveInset) then
          MinimumPositiveInset := SourceLeft;
        if IsApplicationControl(Control) and
          (SourceLeft + DesignedWidth(Control) > LargestChildRight) then
          LargestChildRight := SourceLeft + DesignedWidth(Control);
      end;
    end;
    if HasEdgeChild or (MinimumPositiveInset = MaxSingle) then
      MinimumPositiveInset := 0;

    { A run-time scroll box on an inactive tab can still report the tab's
      narrow header/placeholder width.  Its child cards, however, retain the
      full tab-client geometry.  When those facts disagree, resolve the live
      width from the owning tab control before mirroring or fitting anything.
      This is deliberately based on FMX ownership and measured geometry, not
      on an application or component name. }
    if LargestChildRight > EffectiveWidth + 0.5 then
    begin
      Ancestor := AParent.Parent;
      while Ancestor <> nil do
      begin
        if Ancestor is TTabControl then
        begin
          EffectiveWidth := Max(EffectiveWidth,
            TTabControl(Ancestor).Width);
          EffectiveWidth := Max(EffectiveWidth, SnapshotWidth(Ancestor));
          Break;
        end;
        Ancestor := Ancestor.Parent;
      end;
    end;

    { During FMX startup an inactive tab can temporarily report every level
      of its page and scroll hierarchy as 8 or 50 pixels wide.  Those values
      are framework placeholders, not usable layout bounds.  Never turn that
      transient state into permanent card geometry: retain the designer
      position and width until the manager's post-show pass can resolve the
      real tab client width. }
    GeometryResolved := (EffectiveWidth > 1) and
      (LargestChildRight <= EffectiveWidth + MinimumPositiveInset + 1);

    TransportControls := TList<TControl>.Create;
    try
      for ChildIndex := 0 to AParent.ChildrenCount - 1 do
      begin
        Child := AParent.Children[ChildIndex];
        if Child is TControl then
        begin
          Control := TControl(Child);
          if IsApplicationControl(Control) and
            (Control.Align = TAlignLayout.None) and IsTransport(Control) then
            TransportControls.Add(Control);
        end;
      end;

      { Transport icons describe a machine direction, not a reading
        direction. Move their block to the mirrored side while preserving the
        designed order inside that block. }
      if GeometryResolved and (EffectiveWidth > 0) and
        (TransportControls.Count > 0) then
      begin
        GroupLeft := DesignedLeft(TransportControls[0]);
        GroupRight := GroupLeft + DesignedWidth(TransportControls[0]);
        for Control in TransportControls do
        begin
          SourceLeft := DesignedLeft(Control);
          if SourceLeft < GroupLeft then
            GroupLeft := SourceLeft;
          if SourceLeft + DesignedWidth(Control) > GroupRight then
            GroupRight := SourceLeft + DesignedWidth(Control);
        end;
        MirroredGroupLeft := EffectiveWidth - GroupRight;
        for Control in TransportControls do
        begin
          SourceLeft := DesignedLeft(Control);
          Control.Position.X := MirroredGroupLeft +
            (SourceLeft - GroupLeft);
          Inc(Result);
        end;
      end;

      for ChildIndex := 0 to AParent.ChildrenCount - 1 do
      begin
        Child := AParent.Children[ChildIndex];
        if Child is TControl then
        begin
          Control := TControl(Child);
          if IsApplicationControl(Control) and
            (Control.Align = TAlignLayout.None) and
            (TransportControls.IndexOf(Control) < 0) and
            GeometryResolved and
            (EffectiveWidth > 0) then
          begin
            SourceLeft := DesignedLeft(Control);
            if (MinimumPositiveInset > 0) and
              (SourceLeft >= MinimumPositiveInset) and
              (EffectiveWidth > 2 * MinimumPositiveInset) and
              (DesignedWidth(Control) <= EffectiveWidth +
                MinimumPositiveInset + 1) and
              (DesignedWidth(Control) > EffectiveWidth -
                (2 * MinimumPositiveInset)) then
              Control.Width := EffectiveWidth -
                (2 * MinimumPositiveInset);
            MirroredLeft := EffectiveWidth -
              (SourceLeft + Control.Width);
            Control.Position.X := MirroredLeft;
            Inc(Result);
          end;
        end;
      end;

      { Coordinates are relative to the immediate visual parent. Mirroring
        every level against that level's live width handles nested panels,
        tab pages and run-time controls without absolute form coordinates. }
      for ChildIndex := 0 to AParent.ChildrenCount - 1 do
      begin
        Child := AParent.Children[ChildIndex];
        if Child is TControl then
          MirrorParent(Child, TControl(Child).Width)
        else
          MirrorParent(Child, EffectiveWidth);
      end;
    finally
      TransportControls.Free;
    end;
  end;

begin
  Result := 0;
  if (AForm = nil) or (APack = nil) or
    not SameText(Trim(APack.TextDirection), 'rtl') then
    Exit;
  MirrorEnabled := False;
  for Rule in APack.LayoutRules do
    if SameText(Rule.FormName, AFormIdentity) and
      SameText(Rule.PropertyName, 'MirrorChildren') and
      SameText(Trim(Rule.TranslatedValue), 'True') then
    begin
      MirrorEnabled := True;
      Break;
    end;
  if MirrorEnabled then
    MirrorParent(AForm, AForm.ClientWidth);
end;

class function TFMXTranslationApplicator.RefreshDirectionLayout(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
var
  FormIdentity: string;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  FormIdentity := Trim(AFormIdentity);
  if FormIdentity = '' then
    FormIdentity := AForm.Name;
  { Include controls an application created during FormCreate, but never
    replace a source snapshot already taken before translation. }
  SnapshotOriginalGeometry(AForm, FormIdentity);
  Result := ApplyDirectionMirror(AForm, APack, FormIdentity);
end;

class function TFMXTranslationApplicator.RefreshBrowserLayout(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack): Integer;
var
  Visited: TDictionary<TComponent, Boolean>;

  procedure Visit(const AComponent: TComponent);
  var
    ChildIndex: Integer;
  begin
    if (AComponent = nil) or Visited.ContainsKey(AComponent) then
      Exit;
    Visited.Add(AComponent, True);
    Inc(Result, ApplyBrowserLayoutContract(AComponent, APack));
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
      Visit(AComponent.Components[ChildIndex]);
  end;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  Visited := TDictionary<TComponent, Boolean>.Create;
  try
    Visit(AForm);
  finally
    Visited.Free;
  end;
end;

class function TFMXTranslationApplicator.RestoreSourceLanguage(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
const
  TextProperties: array[0..4] of string = (
    'Caption', 'Text', 'Hint', 'TextPrompt', 'Header');
  StringProperties: array[0..1] of string = ('Items', 'Lines');
var
  ComponentIndex: Integer;
  FormIdentity: string;
  PropertyName: string;

  procedure RestoreComponentTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    ColumnIndex: Integer;
    CurrentText: string;
    SourceText: string;
    PropertyName: string;
  begin
    if AComponent = nil then
      Exit;
    for PropertyName in TextProperties do
      if RestoreSourceTextProperty(FormIdentity, AForm, AComponent,
        PropertyName, APack) then
        Inc(Result);
    for PropertyName in StringProperties do
      Inc(Result, RestoreSourceStringCollection(FormIdentity, AForm,
        AComponent, PropertyName, PropertyName + '.Strings', APack));
    if AComponent is TCustomGrid then
    begin
      for ColumnIndex := 0 to TCustomGrid(AComponent).ColumnCount - 1 do
      begin
        CurrentText := TCustomGrid(AComponent).Columns[ColumnIndex].Header;
        if APack.TryRestoreDynamicText(CurrentText, SourceText) then
        begin
          TCustomGrid(AComponent).Columns[ColumnIndex].Header := SourceText;
          Inc(Result);
        end;
        { Nothing to restore: the cells were never translated. See the note
          beside the applying pass. }
      end;
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
      RestoreComponentTree(AComponent.Components[ChildIndex]);
  end;

begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  FormIdentity := Trim(AFormIdentity);
  if FormIdentity = '' then
    FormIdentity := AForm.Name;
  for PropertyName in TextProperties do
    if RestoreSourceTextProperty(FormIdentity, AForm, AForm, PropertyName,
      APack) then
      Inc(Result);
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    RestoreComponentTree(AForm.Components[ComponentIndex]);
  Inc(Result, ApplyLayoutToForm(AForm, APack, FormIdentity, False));
  { Last, and after the text is back. The rules above can only speak for
    controls the analyser wrote a rule for, and their idea of the original is
    whatever the form file said when it was scanned. The snapshot is the form
    as it actually was, covers every control, and therefore has the final word
    - including over anything the run-time fitting changed on a control no rule
    mentions, which nothing else can undo. It is applied after the text because
    a control that sizes itself resizes when its text changes. }
  Inc(Result, RestoreOriginalGeometry(AForm, FormIdentity));
end;

{ A caption the application centred itself stays centred.

  The FireMonkey counterpart of the VCL pass of the same name, and it exists
  for the same reason: a heading positioned by the program rather than by the
  designer must not be moved by the analyser, but the arithmetic that placed
  it used the width the caption had before it was translated. Leaving the
  position alone while the width changes underneath it leaves the heading as
  far off centre as the translation is longer.

  Nothing decides to centre anything here either. A control whose snapshot
  sits centred in its parent was centred by somebody, and the same arithmetic
  is redone with the width the caption now has. }
class procedure TFMXTranslationApplicator.RecentreSelfPlacedText(
  const AForm: TCommonCustomForm; const AFormIdentity: string);
const
  CentreTolerance = 12;
var
  Component: TComponent;
  Control: TControl;
  LargeCentredLabel: Boolean;
  ParentWidth: Single;
  Snapshot: TDATControlSnapshot;
  WasCentre, Wanted: Single;
begin
  if (AForm = nil) or (FOriginalGeometry = nil) then
    Exit;
  for Component in AForm do
  begin
    if not ((Component is TLayout) or (Component is TPanel) or
      (Component is TLabel)) or
      (Component.Name = '') then
      Continue;
    Control := TControl(Component);
    if not FOriginalGeometry.TryGetValue(
      AFormIdentity + '.' + Component.Name, Snapshot) then
      Continue;
    if not Snapshot.HasPosition then
      Continue;
    if Control.ParentControl <> nil then
      ParentWidth := Control.ParentControl.Width
    else if Control.Parent is TCommonCustomForm then
      ParentWidth := TCommonCustomForm(Control.Parent).ClientWidth
    else
      Continue;
    if ParentWidth <= 0 then
      Continue;
    LargeCentredLabel := (Component is TLabel) and
      Snapshot.HasTextSettings and
      (TTextAlign(Snapshot.HorzAlign) = TTextAlign.Center) and
      (Snapshot.FontSize >= 16);
    if LargeCentredLabel then
      TLabel(Component).TextSettings.HorzAlign := TTextAlign.Center;
    WasCentre := Snapshot.Position.X + Snapshot.Size.X / 2;
    if not LargeCentredLabel and
      (Abs(WasCentre - ParentWidth / 2) > CentreTolerance) then
      Continue;
    if (Abs(Control.Width - Snapshot.Size.X) < 0.5) and
      (Abs(Control.Position.X - Snapshot.Position.X) < 0.5) then
      Continue;
    Wanted := (ParentWidth - Control.Width) / 2;
    if Wanted < 0 then
      Wanted := 0;
    Control.Position.X := Wanted;
  end;
end;


class function TFMXTranslationApplicator.ApplyToForm(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string;
  const APreserveControlState, AApplyLayout,
  ATranslateBrowserContent: Boolean): Integer;
const
  TextProperties: array[0..4] of string = (
    'Caption', 'Text', 'Hint', 'TextPrompt', 'Header');
  StringProperties: array[0..1] of string = ('Items', 'Lines');
var
  ComponentIndex: Integer;
  FormIdentity: string;
  LayoutComponent: TComponent;
  LayoutRule: TRuntimeLayoutRule;
  PropertyName: string;
  SavedFocusedControl: IControl;
  VisitedComponents: TDictionary<TComponent, Boolean>;

  procedure ApplyComponentTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    LocalPropertyName: string;
    LocalSavedSelLength: Integer;
    LocalSavedSelStart: Integer;
  begin
    if (AComponent = nil) or VisitedComponents.ContainsKey(AComponent) then
      Exit;
    VisitedComponents.Add(AComponent, True);
    LocalSavedSelStart := -1;
    LocalSavedSelLength := -1;
    if APreserveControlState and (AComponent is TCustomEdit) then
    begin
      LocalSavedSelStart := TCustomEdit(AComponent).SelStart;
      LocalSavedSelLength := TCustomEdit(AComponent).SelLength;
    end
    else if APreserveControlState and (AComponent is TCustomMemo) then
    begin
      LocalSavedSelStart := TCustomMemo(AComponent).SelStart;
      LocalSavedSelLength := TCustomMemo(AComponent).SelLength;
    end;
    try
      for LocalPropertyName in TextProperties do
        if ApplyTextProperty(FormIdentity, AForm, AComponent,
          LocalPropertyName, APack, APreserveControlState) then
          Inc(Result);
      for LocalPropertyName in StringProperties do
        Inc(Result, ApplyStringCollection(FormIdentity, AForm, AComponent,
          LocalPropertyName, LocalPropertyName + '.Strings', APack,
          APreserveControlState));
      Inc(Result, ApplyGridText(FormIdentity, AComponent, APack));
      { Browser geometry is a layout concern even when application HTML owns
        all of its text.  Keep this independent of the opt-in DOM translation
        pass so tables and headings remain readable in every language. }
      Inc(Result, ApplyBrowserLayoutContract(AComponent, APack));
      { Evaluating script in a platform browser can block the FMX UI thread for
        seconds, especially when several browser controls have already been
        created on inactive tabs. Generated HTML has the keyed
        DATTranslateText/DATTranslateHtmlText contract, so DOM post-processing
        is an explicit compatibility option rather than a cost every
        application pays on every language switch. }
      if ATranslateBrowserContent then
        Inc(Result, ApplyBrowserText(AComponent, APack));
      for ChildIndex := 0 to AComponent.ComponentCount - 1 do
        ApplyComponentTree(AComponent.Components[ChildIndex]);
    finally
      if LocalSavedSelStart >= 0 then
        if AComponent is TCustomEdit then
        begin
          TCustomEdit(AComponent).SelStart := LocalSavedSelStart;
          TCustomEdit(AComponent).SelLength := LocalSavedSelLength;
        end
        else if AComponent is TCustomMemo then
        begin
          TCustomMemo(AComponent).SelStart := LocalSavedSelStart;
          TCustomMemo(AComponent).SelLength := LocalSavedSelLength;
        end;
    end;
  end;
begin
  if AForm = nil then
    raise EArgumentNilException.Create('An FMX form is required.');
  if APack = nil then
    Exit(0);
  FormIdentity := Trim(AFormIdentity);
  if FormIdentity = '' then
    FormIdentity := AForm.Name;
  SnapshotOriginalGeometry(AForm, FormIdentity);
  { Back to the form as it was drawn before anything is applied, exactly as
    the VCL applicator does.

    Without this each language inherits whatever the last one changed, and a
    rule that simply is not present in the new pack has nothing to undo it.
    Going from Hebrew to Spanish left the Spanish form still mirrored: the
    Spanish pack says nothing about Align because Spanish needs nothing said,
    and silence cannot put an edge back. }
  RestoreOriginalGeometry(AForm, FormIdentity);
  { Grid header keys are positional in the pack. Restore the designed column
    order before applying those keys so a repeated RTL apply cannot attach a
    heading to a different data column. }
  for LayoutRule in APack.LayoutRules do
    if SameText(LayoutRule.FormName, FormIdentity) and
      SameText(LayoutRule.PropertyName, 'ColumnOrder') then
    begin
      LayoutComponent := AForm.FindComponent(LayoutRule.ComponentName);
      if LayoutComponent <> nil then
        FMXApplyColumnOrder(LayoutComponent,
          FormIdentity + '.' + LayoutRule.ComponentName, False);
    end;
  { The menu bar, in the direction the language reads.

    Both directions go through the one call, so a form returning to its
    source language is put back rather than left wherever it happened to
    be. The VCL side does the same thing for the same reason, by different
    means - it has a framework flag to work around, and this does not. }
  FMXApplyMenuOrder(AForm, FormIdentity,
    SameText(Trim(APack.TextDirection), 'rtl'));
  if APreserveControlState then
    SavedFocusedControl := AForm.Focused;

  Result := 0;
  VisitedComponents := TDictionary<TComponent, Boolean>.Create;
  try
    for PropertyName in TextProperties do
      if ApplyTextProperty(FormIdentity, AForm, AForm, PropertyName,
        APack, APreserveControlState) then
        Inc(Result);
    for ComponentIndex := 0 to AForm.ComponentCount - 1 do
      ApplyComponentTree(AForm.Components[ComponentIndex]);
    if AApplyLayout then
      Inc(Result, ApplyLayoutToForm(AForm, APack, FormIdentity, True));
    { Keep this fitting pass deliberately narrow: no source edits, no movement,
      and no broad rearrangement. It only gives translated labels/buttons a
      little breathing room when the text already came from the language pack. }
    Inc(Result, ApplyConservativeTextFit(AForm, APack, FormIdentity));
    Inc(Result, ApplyFontColorsToForm(AForm, APack, FormIdentity));
    { Position only after every translated size is final. The mirror uses live
      parent widths, so it remains correct on maximised, DPI-scaled and
      responsive forms instead of replaying design-time coordinates. }
    Inc(Result, ApplyDirectionMirror(AForm, APack, FormIdentity));
    { Last, because it reads the widths every pass above settled. }
    RecentreSelfPlacedText(AForm, FormIdentity);
    { Where the caret starts, which is the reader's property rather than the
      layout's. VCL reaches this through BiDiMode; FireMonkey has none, so it
      is reached through the field or grid column alignment. It must follow
      layout application because a pack can also carry the designed alignment
      and would otherwise overwrite the active language's input direction. }
    Inc(Result, FMXApplyInputReadingOrder(AForm,
      SameText(Trim(APack.TextDirection), 'rtl')));
  finally
    VisitedComponents.Free;
    if APreserveControlState and (SavedFocusedControl <> nil) then
      AForm.Focused := SavedFocusedControl;
  end;
end;

class function TFMXTranslationApplicator.RefreshDynamicText(
  const AForm: TCommonCustomForm;
  const APack: TRuntimeLanguagePack): Integer;
const
  TextProperties: array[0..4] of string = (
    'Caption', 'Text', 'Hint', 'TextPrompt', 'Header');

  procedure RefreshTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    CurrentText: string;
    NextText: string;
    Pass: Integer;
    PropertyInfo: PPropInfo;
    PropertyName: string;
    TranslatedText: string;
  begin
    if AComponent = nil then
      Exit;
    for PropertyName in TextProperties do
    begin
      if SameText(PropertyName, 'Text') and
        EditableTextComponent(AComponent) then
        Continue;
      PropertyInfo := GetPropInfo(AComponent.ClassInfo, PropertyName,
        [tkString, tkLString, tkWString, tkUString]);
      if PropertyInfo = nil then
        Continue;
      CurrentText := GetStrProp(AComponent, PropertyInfo);
      if CurrentText = '' then
        Continue;
      TranslatedText := CurrentText;
      for Pass := 1 to 64 do
      begin
        if not APack.TryTranslateDynamicText(TranslatedText, NextText) or
          (NextText = TranslatedText) then
          Break;
        TranslatedText := NextText;
      end;
      if TranslatedText <> CurrentText then
      begin
        SetStrProp(AComponent, PropertyInfo,
          HeadingWithoutBreakMarks(PropertyName, TranslatedText));
        Inc(Result);
      end;
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
      RefreshTree(AComponent.Components[ChildIndex]);
  end;

begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  RefreshTree(AForm);
end;

class function TFMXTranslationApplicator.ApplyOverrides(
  const AForm: TCommonCustomForm; const AOverrides: TLayoutOverrides;
  const AFormIdentity: string): Integer;
var
  Index: Integer;
  Entry: TLayoutOverride;
  Found: TComponent;
  Control: TControl;
begin
  Result := 0;
  if (AForm = nil) or (AOverrides = nil) then
    Exit;
  for Index := 0 to AOverrides.Items.Count - 1 do
  begin
    Entry := AOverrides.Items[Index];
    if not SameText(Entry.FormName, AFormIdentity) then
      Continue;
    Found := AForm.FindComponent(Entry.ComponentName);
    if not (Found is TControl) then
      Continue;
    Control := TControl(Found);
    { Font size first, for the same reason as under the VCL: it moves
      the bounds of a control that sizes itself. }
    if Entry.HasFontSize and (Entry.FontSize > 0) then
      if ApplyFontSizeSetting(Control, Entry.FontSize) then
        Inc(Result);
    { The same two decisions as the VCL, in FireMonkey's spelling. }
    if Entry.HasSize then
    begin
      Control.Size.Size := TSizeF.Create(Entry.Width, Entry.Height);
      Inc(Result);
    end;
    if Entry.HasPosition then
    begin
      Control.Position.X := Entry.Left;
      Control.Position.Y := Entry.Top;
      Inc(Result);
    end;
  end;
end;

class function TFMXTranslationApplicator.ApplyLayoutToForm(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string;
  const AUseTranslatedValues: Boolean): Integer;
const
  { Order matters. AutoSize must be cleared before any width or height is
    assigned, because an auto-sizing FMX text control recomputes its own
    bounds from a single line of text and discards an assigned Width.
    WordWrap follows, so the height that is applied afterwards describes
    wrapped text. Positions are applied last, once every control has its
    final size. }
  OrderedLayoutProperties: array[0..10] of string = (
    'AutoSize', 'FontSize', 'WordWrap',
    { Mirroring, before the geometry, for the same reason as under the VCL. }
    'TextSettings.HorzAlign', 'Align',
    'Width', 'Height', 'Position.X', 'Position.Y',
    'Anchors',
    { Column order last of all, as under the VCL: every width above names a
      column by the index it was designed at. }
    'ColumnOrder');
var
  CandidateRule: TRuntimeLayoutRule;
  Component: TComponent;
  CurrentText: string;
  CurrentNumber: Extended;
  OrderedProperty: string;
  Rule: TRuntimeLayoutRule;
  CandidateNumber: Extended;
  Superseded: Boolean;
  SourceText: string;
  TextKey: string;
  TextPropertyInfo: PPropInfo;
  TranslatedText: string;
  Value: string;

  function IsSafeRuntimeLayoutProperty(const APropertyName: string): Boolean;
  begin
    Result := IsRuntimeLayoutProperty(APropertyName);
  end;

  function HasEnablingWrapRule(const AComponentName: string): Boolean;
  var
    WrapRule: TRuntimeLayoutRule;
  begin
    Result := False;
    for WrapRule in APack.LayoutRules do
      if SameText(WrapRule.FormName, AFormIdentity) and
        SameText(WrapRule.ComponentName, AComponentName) and
        SameText(WrapRule.PropertyName, 'WordWrap') and
        SameText(Trim(WrapRule.OriginalValue), 'False') and
        SameText(Trim(WrapRule.TranslatedValue), 'True') then
        Exit(True);
  end;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  { The review analyser resolves sizes and positions together against one
    planned model, so the rules for a form describe a single coherent layout.
    Applying only part of that model is what leaves controls overlapping:
    a width means nothing while AutoSize is still on, and a widened control
    still collides with its neighbour unless the neighbour also moves. }
  for OrderedProperty in OrderedLayoutProperties do
  for Rule in APack.LayoutRules do
  begin
    if not SameText(Rule.FormName, AFormIdentity) then
      Continue;
    if not SameText(Rule.PropertyName, OrderedProperty) then
      Continue;
    if not IsSafeRuntimeLayoutProperty(Rule.PropertyName) then
      Continue;
    { A catalog can contain more than one proposal for the same property
      when several translated entries share a control. For dimensions, keep
      the largest safe proposal instead of allowing a later smaller proposal
      to undo the required expansion. }
    Superseded := False;
    if (SameText(Rule.PropertyName, 'Width') or
        SameText(Rule.PropertyName, 'Height')) and
       TryStrToFloat(Rule.TranslatedValue, CurrentNumber,
         TFormatSettings.Invariant) then
      for CandidateRule in APack.LayoutRules do
        if SameText(CandidateRule.FormName, Rule.FormName) and
           SameText(CandidateRule.ComponentName, Rule.ComponentName) and
           SameText(CandidateRule.PropertyName, Rule.PropertyName) and
           TryStrToFloat(CandidateRule.TranslatedValue, CandidateNumber,
             TFormatSettings.Invariant) and
           (CandidateNumber > CurrentNumber) then
        begin
          Superseded := True;
          Break;
        end;
    if Superseded then
      Continue;
    if SameText(Rule.ComponentName, AFormIdentity) or
      SameText(Rule.ComponentName, AForm.Name) or
      (Trim(Rule.ComponentName) = '') then
      Component := AForm
    else
      Component := AForm.FindComponent(Rule.ComponentName);
    if Component = nil then
      Continue;
    { Compatibility contract for packs produced before layout stabilization.
      These automatic rules are not authoritative user layout decisions:
      - never disable wrapping requested by the designer;
      - never apply a blanket translated font reduction;
      - never edge-align a push-button caption;
      - never freeze geometry owned by an aligned framework control. }
    if AUseTranslatedValues then
    begin
      if SameText(Rule.PropertyName, 'WordWrap') and
        SameText(Trim(Rule.OriginalValue), 'True') and
        SameText(Trim(Rule.TranslatedValue), 'False') then
        Continue;
      if SameText(Rule.PropertyName, 'AutoSize') and
        SameText(Trim(Rule.OriginalValue), 'True') and
        SameText(Trim(Rule.TranslatedValue), 'False') and
        not HasEnablingWrapRule(Rule.ComponentName) then
        Continue;
      if SameText(Rule.PropertyName, 'FontSize') then
      begin
        { A generated reduction is never a universal layout decision.  A
          reviewed increase may accompany an explicit wrap plan, for example
          an accessibility layout that deliberately uses larger type. }
        if not HasEnablingWrapRule(Rule.ComponentName) then
          Continue;
        if TryStrToFloat(Rule.OriginalValue, CurrentNumber,
          TFormatSettings.Invariant) and
          TryStrToFloat(Rule.TranslatedValue, CandidateNumber,
          TFormatSettings.Invariant) and
          (CandidateNumber < CurrentNumber) then
          Continue;
      end;
      if (Component is TButton) and
        SameText(Rule.PropertyName, 'TextSettings.HorzAlign') then
        Continue;
      if (Component is TControl) and
        (TControl(Component).Align <> TAlignLayout.None) and
        (SameText(Rule.PropertyName, 'Width') or
         SameText(Rule.PropertyName, 'Height') or
         SameText(Rule.PropertyName, 'Position.X') or
         SameText(Rule.PropertyName, 'Position.Y')) then
        Continue;
    end;
    if AUseTranslatedValues and (Component <> AForm) then
    begin
      TextKey := AFormIdentity + '.' + Component.Name + '.Text';
      TextPropertyInfo := GetPropInfo(Component.ClassInfo, 'Text',
        [tkString, tkLString, tkWString, tkUString]);
      if (TextPropertyInfo = nil) or
        not APack.TryGetSource(TextKey, SourceText) or
        not APack.TryGetText(TextKey, TranslatedText) then
      begin
        TextKey := AFormIdentity + '.' + Component.Name + '.Caption';
        TextPropertyInfo := GetPropInfo(Component.ClassInfo, 'Caption',
          [tkString, tkLString, tkWString, tkUString]);
      end;
      if (TextPropertyInfo <> nil) and APack.TryGetSource(TextKey, SourceText)
        and APack.TryGetText(TextKey, TranslatedText) then
      begin
        CurrentText := GetStrProp(Component, TextPropertyInfo);
        if (CurrentText <> SourceText) and (CurrentText <> TranslatedText) then
          Continue;
      end;
    end;
    if AUseTranslatedValues then
      Value := Rule.TranslatedValue
    else
      Value := Rule.OriginalValue;
    if SameText(Rule.PropertyName, 'ColumnOrder') then
    begin
      { Both directions through one call: asking for the designed order is
        as much an instruction as asking for the reverse of it. }
      if FMXApplyColumnOrder(Component,
        AFormIdentity + '.' + Component.Name,
        SameText(Trim(Value), 'reversed')) then
        Inc(Result);
    end
    else if TrySetLayoutProperty(Component, Rule.PropertyName, Value) then
      Inc(Result);
  end;
end;

initialization
  TFMXTranslationApplicator.FOriginalGeometry :=
    TDictionary<string, TDATControlSnapshot>.Create;
  TFMXTranslationApplicator.FDesignedColumns :=
    TDictionary<string, TArray<string>>.Create;
  TFMXTranslationApplicator.FDesignedMenus :=
    TDictionary<string, TArray<string>>.Create;

finalization
  TFMXTranslationApplicator.FOriginalGeometry.Free;
  TFMXTranslationApplicator.FOriginalGeometry := nil;
  TFMXTranslationApplicator.FDesignedColumns.Free;
  TFMXTranslationApplicator.FDesignedColumns := nil;
  TFMXTranslationApplicator.FDesignedMenus.Free;
  TFMXTranslationApplicator.FDesignedMenus := nil;

end.
