program DelphiAppTranslationStudio;

{$R *.res}

uses
  System.StartUpCopy,
  FMX.Forms,
  DAT.Studio.MainForm in 'source\studio\DAT.Studio.MainForm.pas' {frmTranslationStudio},
  DAT.Studio.SetupWizard in 'source\studio\DAT.Studio.SetupWizard.pas' {frmSetupWizard},
  DAT.Studio.LocalizationReview in 'source\studio\DAT.Studio.LocalizationReview.pas' {frmLocalizationReview},
  DAT.Core.Types in 'source\core\DAT.Core.Types.pas',
  DAT.Core.ProjectDetection in 'source\core\DAT.Core.ProjectDetection.pas',
  DAT.Core.CatalogJson in 'source\core\DAT.Core.CatalogJson.pas',
  DAT.Core.TranslationWorkspace in 'source\core\DAT.Core.TranslationWorkspace.pas',
  DAT.Core.RuntimePack in 'source\core\DAT.Core.RuntimePack.pas',
  DAT.Core.Terminology in 'source\core\DAT.Core.Terminology.pas',
  DAT.Core.Glossary in 'source\core\DAT.Core.Glossary.pas',
  DAT.Review.Localization in 'source\review\DAT.Review.Localization.pas',
  DAT.Scan.Types in 'source\scan\DAT.Scan.Types.pas',
  DAT.Scan.Rules in 'source\scan\DAT.Scan.Rules.pas',
  DAT.Scan.Context in 'source\scan\DAT.Scan.Context.pas',
  DAT.Scan.Quality in 'source\scan\DAT.Scan.Quality.pas',
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
  DAT.Integration.Package in 'source\integration\DAT.Integration.Package.pas',
  DAT.Integration.MenuResource in 'source\integration\DAT.Integration.MenuResource.pas',
  DAT.Integration.BuildDeploy in 'source\integration\DAT.Integration.BuildDeploy.pas',
  DAT.Integration.ComponentPackage in 'source\integration\DAT.Integration.ComponentPackage.pas',
  DAT.Provider.Types in 'source\provider\DAT.Provider.Types.pas',
  DAT.Provider.Settings in 'source\provider\DAT.Provider.Settings.pas',
  DAT.Provider.CredentialStore in 'source\provider\DAT.Provider.CredentialStore.pas',
  DAT.Provider.Client in 'source\provider\DAT.Provider.Client.pas',
  DAT.Studio.Translation in 'source\studio\DAT.Studio.Translation.pas';

begin
  Application.Initialize;
  InitializeStudioTranslation;
  Application.CreateForm(TfrmTranslationStudio, frmTranslationStudio);
  Application.Run;
end.
