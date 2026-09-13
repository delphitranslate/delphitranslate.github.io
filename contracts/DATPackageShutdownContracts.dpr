program DATPackageShutdownContracts;
{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, Winapi.Windows,
  Vcl.Forms, FMX.Forms, FMX.Platform, FMX.WebBrowser;

type
  TEventProbe = class
    Calls: Integer;
    procedure Activated(Sender: TObject);
  end;

procedure TEventProbe.Activated(Sender: TObject);
begin
  Inc(Calls);
end;

function SameHandler(const A, B: TNotifyEvent): Boolean;
begin
  Result := (TMethod(A).Code = TMethod(B).Code) and
    (TMethod(A).Data = TMethod(B).Data);
end;

procedure Require(Value: Boolean; const MessageText: string);
begin
  if not Value then
    raise Exception.Create(MessageText);
end;

var
  Probe: TEventProbe;
  Saved, Expected, Current: TNotifyEvent;
  OriginalBrowser, CurrentBrowser: IFMXWBService;
  VCLPackage, FMXPackage, DesignMarker: HMODULE;
  SplashInstalled: PBoolean;
  Index, Mode: Integer;
  PackageFolder, DesignName: string;
begin
  try
    Require(ParamCount = 1, 'Supply the folder containing the staged BPLs.');
    PackageFolder := IncludeTrailingPathDelimiter(ParamStr(1));
    Probe := TEventProbe.Create;
    Saved := Vcl.Forms.Screen.OnActiveFormChange;
    Expected := Probe.Activated;
    Vcl.Forms.Screen.OnActiveFormChange := Expected;
    Require(TPlatformServices.Current.SupportsPlatformService(IFMXWBService,
      OriginalBrowser), 'Native FMX browser service unavailable.');
    try
      for Mode := 0 to 1 do
      begin
        DesignMarker := 0;
        if Mode = 1 then
        begin
          { Map the genuine IDE module solely as a presence marker in this
            isolated test process. Do not execute its initialization. }
          DesignName := 'designide' + IntToStr(Trunc(RTLVersion * 10)) + '.bpl';
          DesignMarker := LoadLibraryEx(PChar(DesignName), 0,
            DONT_RESOLVE_DLL_REFERENCES);
          Require(DesignMarker <> 0, 'Could not map the IDE presence marker.');
        end;
        try
          for Index := 1 to 10 do
          begin
            VCLPackage := LoadPackage(PackageFolder + 'DATLanguageManagerVCLRuntime.bpl');
            try
              Current := Vcl.Forms.Screen.OnActiveFormChange;
              Require(SameHandler(Current, Expected) = (Mode = 1),
                'VCL hook did not respect runtime/IDE isolation.');
              if Assigned(Current) then Current(nil);
              FMXPackage := LoadPackage(PackageFolder + 'DATLanguageManagerFMXRuntime.bpl');
              try
                SplashInstalled := GetProcAddress(FMXPackage,
                  '@Dat@Runtime@Splashtranslation@Fmx@TDATFMXSplashTranslation@FInstalled');
                Require(SplashInstalled <> nil, 'FMX splash state export missing.');
                Require(SplashInstalled^ = (Mode = 0),
                  'FMX splash listener did not respect runtime/IDE isolation.');
                Require(TPlatformServices.Current.SupportsPlatformService(IFMXWBService,
                  CurrentBrowser), 'Browser service disappeared.');
                Require((Pointer(CurrentBrowser) = Pointer(OriginalBrowser)) = (Mode = 1),
                  'FMX browser hook did not respect runtime/IDE isolation.');
                CurrentBrowser := nil;
              finally
                UnloadPackage(FMXPackage);
              end;
              Require(TPlatformServices.Current.SupportsPlatformService(IFMXWBService,
                CurrentBrowser), 'Browser service missing after unload.');
              Require(Pointer(CurrentBrowser) = Pointer(OriginalBrowser),
                'Original browser service was not restored.');
              CurrentBrowser := nil;
            finally
              UnloadPackage(VCLPackage);
            end;
            Current := Vcl.Forms.Screen.OnActiveFormChange;
            Require(SameHandler(Current, Expected), 'Dangling VCL activation callback after unload.');
            Current(nil);
          end;
          Writeln('PASS: 10 load/unload cycles, IDE marker=', Mode = 1);
        finally
          if DesignMarker <> 0 then FreeLibrary(DesignMarker);
        end;
      end;
      Require(Probe.Calls = 40, 'Previous activation handler was not preserved.');
    finally
      Vcl.Forms.Screen.OnActiveFormChange := Saved;
      Probe.Free;
    end;
    Writeln('PASS: callback restoration, browser restoration, runtime hooks and IDE isolation.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
