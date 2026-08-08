unit DAT.Design.VCL.Register;

interface

procedure Register;

implementation

uses
  System.Classes,
  DAT.Components.VCL,
  DAT.Components.VCL.LanguageSelector;

procedure Register;
begin
  RegisterComponents('DAT Localization', [TDATVCLLanguageManager,
    TDATVCLLanguageComboBox]);
end;

end.
