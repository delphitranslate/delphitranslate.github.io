unit DAT.Review.TextMeasurement;

{ How wide a run of text is, asked in a way the analyser can ask it.

  The layout analyser plans every size, every wrap and every font reduction
  from one number: the width a piece of text occupies when it is drawn. That
  number is the only thing in three thousand lines of planning that the
  analyser cannot work out for itself, because only the framework that draws
  the text knows how wide it comes out.

  Until this unit existed the analyser asked FireMonkey directly. That was
  correct for FireMonkey applications and quietly wrong for every other kind:
  a VCL application draws through Windows, whose metrics are its own, so the
  planning was being done with the wrong ruler and produced captions that
  overran their boxes by a little on every form.

  The seam is deliberately one function wide. A measurer answers a width for a
  run of text at a point size and weight, and nothing else; everything the
  analyser builds on top of that stays framework-neutral and shared. }

interface

uses
  DAT.Core.Types;

type
  { One question, asked of whichever framework will draw the text. }
  ITextMeasurer = interface
    ['{6F2C9A41-7B3E-4D58-9C10-2E5A8B47D3F6}']
    { Width in pixels of AText drawn on one line at APointSize, without any
      padding the control keeps around it. }
    function TextWidth(const AText: string; const APointSize: Double;
      const ABold: Boolean): Double;
  end;

  { Which measurer answers for which kind of application.

    Measurers register themselves as they are linked in, so the analyser never
    names a framework unit and no unit here depends on another. An application
    that links only one of them still measures correctly for that one, and the
    fallback keeps a review of an unrecognised project working rather than
    returning zero widths, which would read as "everything fits". }
  TTextMeasurement = class
  private
    class var FMeasurers: array [TTargetFramework] of ITextMeasurer;
  public
    class procedure SetMeasurer(const AFramework: TTargetFramework;
      const AMeasurer: ITextMeasurer); static;
    { The measurer for this framework, or the best available substitute.
      Never nil once any measurer has been linked in. }
    class function Measurer(
      const AFramework: TTargetFramework): ITextMeasurer; static;
    class function HasMeasurer(
      const AFramework: TTargetFramework): Boolean; static;
  end;

implementation

class procedure TTextMeasurement.SetMeasurer(
  const AFramework: TTargetFramework; const AMeasurer: ITextMeasurer);
begin
  FMeasurers[AFramework] := AMeasurer;
end;

class function TTextMeasurement.HasMeasurer(
  const AFramework: TTargetFramework): Boolean;
begin
  Result := FMeasurers[AFramework] <> nil;
end;

class function TTextMeasurement.Measurer(
  const AFramework: TTargetFramework): ITextMeasurer;
var
  Candidate: TTargetFramework;
begin
  Result := FMeasurers[AFramework];
  if Result <> nil then
    Exit;
  { A project whose framework was never determined, or one whose measurer was
    not linked into this application, still has to be measured with something.
    Any real measurer is closer to the truth than none, and the widths of the
    two frameworks differ by a few percent rather than by kind. }
  for Candidate := Low(TTargetFramework) to High(TTargetFramework) do
    if FMeasurers[Candidate] <> nil then
      Exit(FMeasurers[Candidate]);
  Result := nil;
end;

end.
