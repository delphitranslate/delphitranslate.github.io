program DelphiAppTranslationStudio;

{$R *.res}

uses
  System.StartUpCopy,
  FMX.Forms,
  DAT.Studio.MainForm in 'source\studio\DAT.Studio.MainForm.pas' {frmTranslationStudio},
  DAT.Core.Types in 'source\core\DAT.Core.Types.pas',
  DAT.Core.ProjectDetection in 'source\core\DAT.Core.ProjectDetection.pas',
  DAT.Core.CatalogJson in 'source\core\DAT.Core.CatalogJson.pas',
  DAT.Core.TranslationWorkspace in 'source\core\DAT.Core.TranslationWorkspace.pas',
  DAT.Core.RuntimePack in 'source\core\DAT.Core.RuntimePack.pas',
  DAT.Scan.Types in 'source\scan\DAT.Scan.Types.pas',
  DAT.Scan.Rules in 'source\scan\DAT.Scan.Rules.pas',
  DAT.Scan.TextCodec in 'source\scan\DAT.Scan.TextCodec.pas',
  DAT.Scan.FormText in 'source\scan\DAT.Scan.FormText.pas',
  DAT.Scan.PascalResources in 'source\scan\DAT.Scan.PascalResources.pas',
  DAT.Scan.Project in 'source\scan\DAT.Scan.Project.pas',
  DAT.Scan.CatalogMerge in 'source\scan\DAT.Scan.CatalogMerge.pas',
  DAT.Validation.Catalog in 'source\validation\DAT.Validation.Catalog.pas',
  DAT.Runtime.LanguagePack in 'source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in 'source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in 'source\runtime\DAT.Runtime.Manager.pas',
  DAT.Runtime.FMX in 'source\runtime\DAT.Runtime.FMX.pas',
  DAT.Integration.Plan in 'source\integration\DAT.Integration.Plan.pas',
  DAT.Integration.Package in 'source\integration\DAT.Integration.Package.pas';

begin
  Application.Initialize;
  Application.CreateForm(TfrmTranslationStudio, frmTranslationStudio);
  Application.Run;
end.
