unit DAT.Review.TextMeasurement.GDI;

{ Text widths as Windows draws them, which is how a VCL application draws.

  A VCL control paints its caption through the Windows graphics layer, so the
  width that matters for planning a VCL layout is the width Windows reports.
  This asks Windows directly rather than through Vcl.Graphics, for one
  practical reason: the Studio that runs the analyser is itself a FireMonkey
  application, and pulling the VCL framework into it to borrow a canvas would
  mean linking two frameworks into one executable for the sake of a single
  measurement. The call underneath a VCL canvas is the one made here.

  The typeface is the one Windows hands to ordinary application windows, which
  is what a VCL control uses when its font is left at the default. The analyser
  does not record a typeface per control, so this is the honest choice; a
  control that overrides its font is measured with the right size and weight
  and the default face, which is close enough to plan from and far closer than
  measuring with the wrong framework entirely. }

interface

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.Math,
  DAT.Core.Types,
  DAT.Review.TextMeasurement;

const
  { The resolution a form file's coordinates are expressed in. }
  DesignTimeDotsPerInch = 96;

type
  TGDITextMeasurer = class(TInterfacedObject, ITextMeasurer)
  public
    function TextWidth(const AText: string; const APointSize: Double;
      const ABold: Boolean): Double;
  end;

{ The face Windows uses for text inside ordinary windows. Falls back to a face
  that has shipped with every supported version if the metrics are refused. }
function DefaultInterfaceFaceName: string;
var
  Metrics: TNonClientMetrics;
begin
  Result := 'Segoe UI';
  FillChar(Metrics, SizeOf(Metrics), 0);
  Metrics.cbSize := SizeOf(Metrics);
  if SystemParametersInfo(SPI_GETNONCLIENTMETRICS, SizeOf(Metrics),
    @Metrics, 0) then
    if Metrics.lfMessageFont.lfFaceName[0] <> #0 then
      Result := Metrics.lfMessageFont.lfFaceName;
end;

function TGDITextMeasurer.TextWidth(const AText: string;
  const APointSize: Double; const ABold: Boolean): Double;
var
  DeviceContext: HDC;
  Description: TLogFont;
  Font: HFONT;
  PreviousFont: HGDIOBJ;
  Extent: TSize;
  PointSize: Double;
  FaceName: string;
begin
  Result := 0;
  if AText = '' then
    Exit;
  PointSize := APointSize;
  if PointSize <= 0 then
    PointSize := 9;

  { A memory device context carries the same font metrics as the screen without
    needing a window to draw into. }
  DeviceContext := CreateCompatibleDC(0);
  if DeviceContext = 0 then
    Exit;
  try
    FillChar(Description, SizeOf(Description), 0);
    { Negative height asks for a font whose character height is this many
      pixels, which is how a point size is expressed to Windows. }
    { Ninety-six, deliberately, rather than this screen's resolution. A form
      file records its geometry in the pixels of the machine it was designed
      on, and that is what the analyser is reasoning about; measuring against a
      display scaled to a hundred and twenty-five percent would report every
      caption a quarter wider than the box it was drawn to fit, and the plan
      would grow controls to solve a problem that exists only on this monitor. }
    Description.lfHeight := -MulDiv(Round(PointSize), DesignTimeDotsPerInch, 72);
    if ABold then
      Description.lfWeight := FW_BOLD
    else
      Description.lfWeight := FW_NORMAL;
    Description.lfCharSet := DEFAULT_CHARSET;
    Description.lfQuality := CLEARTYPE_QUALITY;
    FaceName := DefaultInterfaceFaceName;
    StrPLCopy(Description.lfFaceName, FaceName,
      Length(Description.lfFaceName) - 1);

    Font := CreateFontIndirect(Description);
    if Font = 0 then
      Exit;
    try
      PreviousFont := SelectObject(DeviceContext, Font);
      try
        if GetTextExtentPoint32(DeviceContext, PChar(AText), Length(AText),
          Extent) then
          Result := Extent.cx;
      finally
        SelectObject(DeviceContext, PreviousFont);
      end;
    finally
      DeleteObject(Font);
    end;
  finally
    DeleteDC(DeviceContext);
  end;
end;

initialization
  TTextMeasurement.SetMeasurer(tfVCL, TGDITextMeasurer.Create);

end.
