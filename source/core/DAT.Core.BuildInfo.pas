unit DAT.Core.BuildInfo;

{ Which build this is, in one place.

  The label used to be a constant declared separately in the main form and in
  the Setup Wizard, with an identical copy of the function that stamps the
  build time beside each of them. Two copies of a fact is one copy too many -
  it is the same rule this codebase applies to the allowed-property list and to
  everything else - and the label had in any case gone four days stale while
  the executable moved on without it. A window that says one build while
  running another sends a bug report to the wrong place.

  Two different things are reported here, and the difference matters:

    - **The label** is hand-set. It is the release number a person chooses, and
      somebody has to remember to change it. Bumping it is the one manual step,
      and it is deliberately manual because only a person knows whether a
      change is worth a new number.

    - **The stamp** is read from the executable's own file date at run time. It
      cannot go stale, it needs nobody to remember anything, and it is the
      answer to "is this actually the binary that was just built". When the
      label and the stamp disagree by days, the stamp is the one to trust.

  Both are shown together for that reason. }

interface

const
  { Public release version, selected by the developer rather than inferred
    from the executable timestamp. }
  StudioBuildLabel = 'Version 1.0.0';

{ ' (built 2026-08-22 14:41)', taken from the executable's file date, or an
  empty string if that cannot be read. }
function StudioBuildStamp: string;

{ The two together, which is what a caption should show. }
function StudioBuildDescription: string;

implementation

uses
  System.SysUtils;

function StudioBuildStamp: string;
var
  BuiltAt: TDateTime;
begin
  if FileAge(ParamStr(0), BuiltAt) then
    Result := ' (built ' + FormatDateTime('yyyy-mm-dd hh:nn', BuiltAt) + ')'
  else
    Result := '';
end;

function StudioBuildDescription: string;
begin
  Result := StudioBuildLabel + StudioBuildStamp;
end;

end.
