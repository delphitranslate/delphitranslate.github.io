unit DAT.Review.TextMeasurement.FMX;

{ Text widths as FireMonkey draws them.

  This is the measurement the analyser used directly before the seam existed,
  moved here unchanged so that FireMonkey planning keeps behaving exactly as it
  did while VCL planning gains a ruler of its own. }

interface

implementation

uses
  System.Math,
  System.UITypes,
  FMX.TextLayout,
  DAT.Core.Types,
  DAT.Review.TextMeasurement;

type
  TFMXTextMeasurer = class(TInterfacedObject, ITextMeasurer)
  public
    function TextWidth(const AText: string; const APointSize: Double;
      const ABold: Boolean): Double;
  end;

function TFMXTextMeasurer.TextWidth(const AText: string;
  const APointSize: Double; const ABold: Boolean): Double;
var
  Layout: TTextLayout;
begin
  if AText = '' then
    Exit(0);
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.BeginUpdate;
    Layout.Text := AText;
    Layout.Font.Size := Max(APointSize, 9);
    { Bold text is materially wider than regular at the same size, and
      measuring it as regular reports a caption fitting a box it overruns.
      The hero banner is the plain case: measured light it fits its width,
      drawn bold it wraps to a second line inside a box built for one, and
      loses the top and bottom of both. }
    if ABold then
      Layout.Font.Style := Layout.Font.Style + [TFontStyle.fsBold];
    Layout.WordWrap := False;
    Layout.EndUpdate;
    Result := Layout.Width;
  finally
    Layout.Free;
  end;
end;

initialization
  TTextMeasurement.SetMeasurer(tfFireMonkey, TFMXTextMeasurer.Create);

end.
