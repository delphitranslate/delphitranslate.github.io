unit DAT.Design.FMX.Register;

interface

procedure Register;

implementation

uses
  System.Classes,
  DAT.Components.FMX;

procedure Register;
begin
  RegisterComponents('DAT Localization', [TDATFMXLanguageManager]);
end;

end.
