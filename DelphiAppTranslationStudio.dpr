program DelphiAppTranslationStudio;

uses
  System.StartUpCopy,
  FMX.Forms,
  DAT.Studio.MainForm in 'source\studio\DAT.Studio.MainForm.pas' {frmTranslationStudio},
  DAT.Core.Types in 'source\core\DAT.Core.Types.pas',
  DAT.Core.ProjectDetection in 'source\core\DAT.Core.ProjectDetection.pas',
  DAT.Core.CatalogJson in 'source\core\DAT.Core.CatalogJson.pas';

begin
  Application.Initialize;
  Application.CreateForm(TfrmTranslationStudio, frmTranslationStudio);
  Application.Run;
end.
