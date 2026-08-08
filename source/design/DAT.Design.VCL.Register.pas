unit DAT.Design.VCL.Register;

interface

procedure Register;

implementation

uses
  System.Classes,
  DAT.Components.VCL;

procedure Register;
begin
  RegisterComponents('DAT Localization', [TDATVCLLanguageManager]);
end;

end.
