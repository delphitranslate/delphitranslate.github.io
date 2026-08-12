program StudioFormSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.StrUtils,
  System.SysUtils,
  System.UITypes,
  FMX.Types,
  FMX.Forms,
  DAT.Studio.MainForm in '..\..\source\studio\DAT.Studio.MainForm.pas'
    {frmTranslationStudio},
  DAT.Studio.SetupWizard in '..\..\source\studio\DAT.Studio.SetupWizard.pas'
    {frmSetupWizard},
  DAT.Studio.LocalizationReview in '..\..\source\studio\DAT.Studio.LocalizationReview.pas'
    {frmLocalizationReview};

procedure TestLocalizationReview;
var
  ReviewForm: TfrmLocalizationReview;
begin
  ReviewForm := TfrmLocalizationReview.Create(nil);
  try
    if ReviewForm.Position <> TFormPosition.ScreenCenter then
      raise Exception.Create('Localization Review is not centered.');
    if ReviewForm.ReviewTabs.TabCount <> 4 then
      raise Exception.Create('Localization Review does not have four review areas.');
    if not Assigned(ReviewForm.btnGeneratePackage.OnClick) or
       not Assigned(ReviewForm.btnSaveGlossary.OnClick) or
       not Assigned(ReviewForm.btnSaveDecision.OnClick) or
       not Assigned(ReviewForm.btnUseSuggestion.OnClick) or
       not Assigned(ReviewForm.btnApproveHighConfidence.OnClick) or
       not Assigned(ReviewForm.btnRejectSuggestion.OnClick) then
      raise Exception.Create('A Localization Review action is not designer-wired.');
    if not ReviewForm.memAudit.ReadOnly or
       not ReviewForm.memProposalDetail.ReadOnly or
       not ReviewForm.memSuggestionDetail.ReadOnly then
      raise Exception.Create('Localization audit output must remain read-only.');
  finally
    ReviewForm.Free;
  end;
end;

procedure TestSetupWizard;
var
  Wizard: TfrmSetupWizard;
begin
  Wizard := TfrmSetupWizard.Create(nil);
  try
    if Wizard.BorderStyle <> TFmxFormBorderStyle.None then
      raise Exception.Create('The Setup Wizard is not borderless.');
    if Wizard.Position <> TFormPosition.ScreenCenter then
      raise Exception.Create('The Setup Wizard is not centered.');
    if Wizard.WizardTabs.TabCount <> 8 then
      raise Exception.Create('The Setup Wizard does not have eight steps.');
    if not Assigned(Wizard.dlgOpenProject) then
      raise Exception.Create('The Setup Wizard project dialog is missing.');
    if not Assigned(Wizard.btnCopyApplicationId.OnClick) or
       not Wizard.edtApplicationId.ReadOnly then
      raise Exception.Create(
        'The detected Application ID is not exposed safely by the Wizard.');
    if (Wizard.cboWorkflowMode.Items.Count <> 3) or
       not Assigned(Wizard.cboWorkflowMode.OnChange) then
      raise Exception.Create('The new/update translation workflow is not available.');
    if not Assigned(Wizard.btnLocalizationReview.OnClick) then
      raise Exception.Create('Localization Review is not connected to the Wizard.');
    if (Pos('Required:', Wizard.chkUnderstandManualStep.Text) <> 1) or
       (Wizard.lblManualConfirmationRequired.Text = '') then
      raise Exception.Create('The required manual-phase confirmation is not explained.');
    if not Assigned(Wizard.btnFinishLocalizationReview.OnClick) then
      raise Exception.Create('The finished Wizard cannot reopen Localization Review.');
    if Wizard.cboTargetLanguage.Items.Count < 35 then
      raise Exception.Create('The wizard target-language list is incomplete.');
    if not Wizard.edtApiKey.Password then
      raise Exception.Create('The wizard API-key field is not masked.');
    if not Assigned(Wizard.btnBrowseProject.OnClick) or
       not Assigned(Wizard.btnRunScan.OnClick) or
       not Assigned(Wizard.btnTestConnection.OnClick) or
       not Assigned(Wizard.btnRunDeployment.OnClick) then
      raise Exception.Create('A primary wizard action is not designer-wired.');
    if Wizard.chkCreateBackup.Enabled or
       not Wizard.chkCreateBackup.IsChecked then
      raise Exception.Create(
        'The Wizard safety backup is not mandatory.');
    if ContainsText(Wizard.memComponentInstructions.Text, 'optionally') then
      raise Exception.Create(
        'The Wizard still describes the visible language selector as optional.');
    if Wizard.memScanResults.WordWrap then
      raise Exception.Create('Wizard scan rows must not wrap over one another.');
    if Wizard.memCommands.WordWrap then
      raise Exception.Create('PowerShell deployment commands must not wrap.');
    if Wizard.btnBack.Position.Y + Wizard.btnBack.Height > Wizard.ClientHeight then
      raise Exception.Create('Wizard navigation extends below the form.');
    if Wizard.ContentCard.Position.X + Wizard.ContentCard.Width >
       Wizard.BodyLayout.Width + 1 then
      raise Exception.Create('Wizard content extends beyond its body layout.');
  finally
    Wizard.Free;
  end;
end;

begin
  try
    Application.Initialize;
    TestLocalizationReview;
    TestSetupWizard;
    frmTranslationStudio := TfrmTranslationStudio.Create(nil);
    try
      if frmTranslationStudio.Caption <>
        'Delphi App Translation Studio' then
        raise Exception.Create('The main form caption is incorrect.');
      if frmTranslationStudio.WindowState <> TWindowState.wsMaximized then
        raise Exception.Create('The Studio is not configured to start maximized.');
      if (frmTranslationStudio.LanguagePageCard.Align <>
          TAlignLayout.Client) or
         (frmTranslationStudio.ValidationPageCard.Align <>
          TAlignLayout.Client) or
         (frmTranslationStudio.ExportPageCard.Align <>
          TAlignLayout.Client) or
         (frmTranslationStudio.IntegrationPageCard.Align <>
          TAlignLayout.Client) or
         (frmTranslationStudio.SettingsPageCard.Align <>
          TAlignLayout.Client) then
        raise Exception.Create('One or more workflow pages do not fill the workspace.');
      if not (TAnchorKind.akBottom in
        frmTranslationStudio.lstCatalogEntries.Anchors) or
         not (TAnchorKind.akBottom in
        frmTranslationStudio.memTranslatedText.Anchors) then
        raise Exception.Create('The translation work areas do not resize vertically.');
      if (frmTranslationStudio.cboSourceLanguage.Items.Count < 40) or
         (frmTranslationStudio.cboTargetLanguage.Items.Count < 40) then
        raise Exception.Create('The built-in language selection list is incomplete.');
      if not frmTranslationStudio.edtProviderApiKey.Password then
        raise Exception.Create('The provider API key field is not masked.');
      if frmTranslationStudio.cboTranslationProvider.Items.Count <> 2 then
        raise Exception.Create('The provider list is incomplete.');
      if not Assigned(frmTranslationStudio.btnExportCatalogCsv.OnClick) or
         not Assigned(frmTranslationStudio.btnImportCatalogCsv.OnClick) then
        raise Exception.Create('The CSV interchange controls are not wired.');
      if not Assigned(frmTranslationStudio.btnGuidedSetup.OnClick) or
         (frmTranslationStudio.btnGuidedSetup.Text <> 'Start Setup Wizard') then
        raise Exception.Create('The recommended Setup Wizard action is unavailable.');
      if not Assigned(
        frmTranslationStudio.chkRuntimeWiringConfirmed.OnChange) then
        raise Exception.Create(
          'The runtime wiring confirmation is not designer-wired.');
      if not Assigned(frmTranslationStudio.btnCompleteReset.OnClick) then
        raise Exception.Create(
          'The Complete Reset control is not designer-wired.');
      if not Assigned(frmTranslationStudio.btnAcceptSuggestion.OnClick) then
        raise Exception.Create(
          'The translation suggestion action is not designer-wired.');
      if not Assigned(
           frmTranslationStudio.btnMarkTranslationReviewed.OnClick) or
         not Assigned(frmTranslationStudio.btnApproveTranslation.OnClick) then
        raise Exception.Create(
          'The linguistic review actions are not designer-wired.');
      if not Assigned(frmTranslationStudio.btnReviewAllTranslations.OnClick) or
         not Assigned(frmTranslationStudio.btnApproveAllReviewed.OnClick) then
        raise Exception.Create(
          'The catalog-wide review actions are not designer-wired.');
      if not Assigned(frmTranslationStudio.lblCatalogPathValue.OnClick) or
         not frmTranslationStudio.lblCatalogPathValue.HitTest then
        raise Exception.Create(
          'The catalog path is not an active folder link.');
      if not Assigned(frmTranslationStudio.lstValidationIssues.OnDblClick) then
        raise Exception.Create(
          'Validation issues cannot navigate to catalog entries.');
      if not Assigned(frmTranslationStudio.btnTranslateMissing.OnClick) or
         (frmTranslationStudio.btnTranslateMissing.Text <>
          'Translate Automatically') then
        raise Exception.Create(
          'The provider translation action is not configured correctly.');
      if not Assigned(frmTranslationStudio.btnSaveProviderKey.OnClick) or
         not Assigned(
           frmTranslationStudio.btnTestProviderConnection.OnClick) or
         not Assigned(frmTranslationStudio.btnRemoveProviderKey.OnClick) then
        raise Exception.Create(
          'The provider credential actions are not designer-wired.');
      if not frmTranslationStudio.memIntegrationDiff.ReadOnly then
        raise Exception.Create(
          'The exact integration review must remain read-only.');
      if not Assigned(frmTranslationStudio.lstIntegrationPlan.OnChange) or
         not Assigned(
           frmTranslationStudio.chkIntegrationReviewConfirmed.OnChange) then
        raise Exception.Create(
          'The exact integration-review controls are not designer-wired.');
      if (frmTranslationStudio.cboIntegrationMode.Items.Count <> 2) or
         (frmTranslationStudio.cboIntegrationMode.ItemIndex <> 0) or
         not Assigned(frmTranslationStudio.cboIntegrationMode.OnChange) then
        raise Exception.Create(
          'Component Integration is not the designer-wired default mode.');
      if frmTranslationStudio.btnGenerateIntegrationPackage.Text <>
          'Generate Component Kit' then
        raise Exception.Create(
          'The recommended component-kit action is not displayed.');
      if not Assigned(
           frmTranslationStudio.btnOpenDesignPackageLocation.OnClick) or
         not frmTranslationStudio.btnOpenDesignPackageLocation.Visible or
         not Assigned(
           frmTranslationStudio.btnOpenComponentKitFolder.OnClick) or
         not frmTranslationStudio.btnOpenComponentKitFolder.Visible then
        raise Exception.Create(
          'The manual package-location actions are not available.');
      if (frmTranslationStudio.lstScanResults.ItemHeight < 20) or
         (frmTranslationStudio.lstCatalogEntries.ItemHeight < 20) or
         (frmTranslationStudio.lstValidationIssues.ItemHeight < 20) or
         (frmTranslationStudio.lstIntegrationPlan.ItemHeight < 20) then
        raise Exception.Create(
          'A scrolling result list does not have a stable row height.');
      if frmTranslationStudio.btnTranslateMissing.Position.Y <
           frmTranslationStudio.lblCatalogPathValue.Position.Y +
           frmTranslationStudio.lblCatalogPathValue.Height + 6 then
        raise Exception.Create(
          'The catalog path overlaps the translation action row.');
      if frmTranslationStudio.lstCatalogEntries.Position.Y <
           frmTranslationStudio.btnTranslateMissing.Position.Y +
           frmTranslationStudio.btnTranslateMissing.Height + 6 then
        raise Exception.Create(
          'The translation action row overlaps the catalog entries.');
      if frmTranslationStudio.btnApplyIntegration.Visible or
         frmTranslationStudio.chkIntegrationReviewConfirmed.Visible or
         frmTranslationStudio.chkBuildAfterIntegration.Visible then
        raise Exception.Create(
          'Source-mutation controls are visible in Component Integration mode.');
      if frmTranslationStudio.lstIntegrationPlan.Position.Y <
           frmTranslationStudio.btnBuildIntegrationPlan.Position.Y +
           frmTranslationStudio.btnBuildIntegrationPlan.Height + 30 then
        raise Exception.Create(
          'The integration plan is too close to the planning controls.');
      if frmTranslationStudio.btnCompleteReset.Position.Y +
         frmTranslationStudio.btnCompleteReset.Height >=
         frmTranslationStudio.lstIntegrationPlan.Position.Y then
        raise Exception.Create(
          'The Complete Reset control overlaps the integration plan.');
      if (frmTranslationStudio.cboBuildPlatform.Items.Count <> 2) or
         (frmTranslationStudio.cboBuildConfiguration.Items.Count <> 2) or
         (frmTranslationStudio.cboBuildPlatform.ItemIndex < 0) or
         (frmTranslationStudio.cboBuildConfiguration.ItemIndex < 0) then
        raise Exception.Create(
          'The target build/deploy selections are not configured.');
      if frmTranslationStudio.chkBuildAfterIntegration.IsChecked then
        raise Exception.Create(
          'Automatic target build/deploy must remain opt-in.');
      if frmTranslationStudio.memIntegrationDiff.Position.X <
           frmTranslationStudio.lstIntegrationPlan.Position.X +
           frmTranslationStudio.lstIntegrationPlan.Width + 24 then
        raise Exception.Create(
          'The integration plan and exact-change areas are too close.');
      if frmTranslationStudio.memIntegrationDiff.Position.Y <
           frmTranslationStudio.lblIntegrationDiffTitle.Position.Y +
           frmTranslationStudio.lblIntegrationDiffTitle.Height + 6 then
        raise Exception.Create(
          'The exact-change title is too close to its review area.');
      if frmTranslationStudio.btnApplyIntegration.Enabled then
        raise Exception.Create(
          'Integration Apply was enabled before exact review confirmation.');
      if frmTranslationStudio.dlgImportCatalogCsv.DefaultExt <> 'csv' then
        raise Exception.Create('The CSV import dialog is not configured.');
      if frmTranslationStudio.dlgExportCatalogCsv.DefaultExt <> 'csv' then
        raise Exception.Create('The CSV export dialog is not configured.');
      if not frmTranslationStudio.lblNavigationProject.HitTest or
         not frmTranslationStudio.lblNavigationScan.HitTest or
         not frmTranslationStudio.lblNavigationLanguages.HitTest or
         not frmTranslationStudio.lblNavigationValidation.HitTest or
         not frmTranslationStudio.lblNavigationExport.HitTest or
         not frmTranslationStudio.lblNavigationIntegration.HitTest or
         not frmTranslationStudio.lblNavigationSettings.HitTest then
        raise Exception.Create(
          'One or more workflow labels cannot receive mouse clicks.');
      if not Assigned(
        frmTranslationStudio.lblNavigationLanguages.OnClick) or
         not Assigned(
        frmTranslationStudio.lblNavigationValidation.OnClick) or
         not Assigned(
        frmTranslationStudio.lblNavigationExport.OnClick) or
         not Assigned(
        frmTranslationStudio.lblNavigationIntegration.OnClick) or
         not Assigned(
        frmTranslationStudio.lblNavigationSettings.OnClick) then
        raise Exception.Create(
          'One or more workflow labels have no click event.');
      if not frmTranslationStudio.lblExportPathValue.HitTest or
         not Assigned(frmTranslationStudio.lblExportPathValue.OnClick) or
         (frmTranslationStudio.lblExportPathValue.TextSettings.Font.Size < 14) then
        raise Exception.Create(
          'The exported runtime-pack path is not a readable active link.');
      frmTranslationStudio.lblNavigationLanguages.OnClick(
        frmTranslationStudio.lblNavigationLanguages);
      if not frmTranslationStudio.LanguagePageCard.Visible then
        raise Exception.Create(
          'The Languages workflow label did not activate its page.');
      frmTranslationStudio.lblNavigationSettingsClick(nil);
      if not frmTranslationStudio.SettingsPageCard.Visible then
        raise Exception.Create(
          'The Provider Settings workflow page did not activate.');
      Writeln('Studio FMX form creation and streaming passed.');
    finally
      frmTranslationStudio.Free;
      frmTranslationStudio := nil;
    end;
  except
    on E: Exception do
    begin
      Writeln('Studio FMX form smoke test failed: ', E.Message);
      Halt(1);
    end;
  end;
end.
