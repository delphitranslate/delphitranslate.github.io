unit DAT.Design.FMX.Register;

interface

procedure Register;

implementation

uses
  System.Classes,
  DAT.Components.FMX,
  DAT.Components.FMX.LanguageSelector;

procedure Register;
begin
  RegisterComponents('DAT Localization', [TDATFMXLanguageManager,
    TDATFMXLanguageComboBox]);
end;

end.
