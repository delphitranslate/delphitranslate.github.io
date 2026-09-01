program StudioFormSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.StrUtils,
  System.SysUtils,
  System.Types,
  System.UITypes,
  FMX.Types,
  FMX.Forms,
  FMX.Controls,
  FMX.TabControl,
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

{ Every control on a wizard page must sit inside the page, with room to spare.

  The height a page actually has is settled at run time and is nothing like the
  figure the form file records: the tab control fills its card, so both the
  card's stored height and the tab's are stale the moment the form is built.
  Pages were laid out against those stale figures and the overflow stayed
  invisible until a button turned up cut off along the bottom edge on screen.
  Measure the tab control that is actually there.

  Everything here is done in absolute coordinates. A TTabItem's own Height is
  the height of its tab button, not of the page, and its Controls collection
  holds that button's furniture rather than the page content, which is
  reparented into a layout of the tab control's own. Comparing absolute
  positions sidesteps all of it and stays correct however the content is
  nested. }
procedure RequirePageContentFits(const AWizard: TfrmSetupWizard);
const
  RequiredMargin = 12;

  function PageOf(const AControl: TControl): TTabItem;
  var
    Walk: TFmxObject;
  begin
    Result := nil;
    Walk := AControl.Parent;
    while Assigned(Walk) do
    begin
      if Walk is TTabItem then
        Exit(TTabItem(Walk));
      Walk := Walk.Parent;
    end;
  end;

var
  Index: Integer;
  Child: TControl;
  Page: TTabItem;
  Bottom, Allowed: Double;
  Checked: Integer;
begin
  Allowed := AWizard.WizardTabs.LocalToAbsolute(
    TPointF.Create(0, AWizard.WizardTabs.Height)).Y - RequiredMargin;
  Checked := 0;
  for Index := 0 to AWizard.ComponentCount - 1 do
  begin
    if not (AWizard.Components[Index] is TControl) then
      Continue;
    Child := TControl(AWizard.Components[Index]);
    if Child.Align <> TAlignLayout.None then
      Continue;
    Page := PageOf(Child);
    if Page = nil then
      Continue;
    Inc(Checked);
    Bottom := Child.LocalToAbsolute(TPointF.Create(0, Child.Height)).Y;
    if Bottom > Allowed then
      raise Exception.CreateFmt(
        'Wizard page "%s": %s reaches %.0f, past the %.0f a page has ' +
        '(a %d margin inside the tab control).',
        [Page.Text, Child.Name, Bottom, Allowed, RequiredMargin]);
  end;
  { A check that examines nothing passes for the wrong reason. }
  if Checked < 40 then
    raise Exception.CreateFmt(
      'Only %d wizard page controls were examined; the walk is not finding ' +
      'the page content.', [Checked]);
end;

procedure TestSetupWizard;
var
  Index: Integer;
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
    for Index := 0 to Wizard.WizardTabs.TabCount - 1 do
      if SameText(Wizard.WizardTabs.Tabs[Index].Text, 'Component') then
        raise Exception.Create(
          'The instruction-only Delphi Component page is still in the Wizard.');
    if not Assigned(Wizard.dlgOpenProject) then
      raise Exception.Create('The Setup Wizard project dialog is missing.');
    if not Assigned(Wizard.btnCopyApplicationId.OnClick) or
       not Wizard.edtApplicationId.ReadOnly then
      raise Exception.Create(
        'The detected Application ID is not exposed safely by the Wizard.');
    if (Wizard.cboWorkflowMode.Items.Count <> 3) or
       not Assigned(Wizard.cboWorkflowMode.OnChange) then
      raise Exception.Create('The new/update translation workflow is not available.');
    { Localization Review is reopened from code when final processing reaches
      that point, which is the path the developer actually travels. A hidden,
      disabled button wired to the same handler sat on the completion page for
      a long time and nothing ever showed or enabled it, so it offered nobody
      anything; it has been removed rather than finished. Restore a check here
      if a visible entry point is ever added. }
    if Wizard.cboTargetLanguage.Items.Count < 35 then
      raise Exception.Create('The wizard target-language list is incomplete.');
    if Wizard.cboTargetLanguage.Items.IndexOf(
       'Pashto (Afghanistan) [ps-AF]') < 0 then
      raise Exception.Create(
        'The wizard target-language list omits a supported RTL language.');
    if Wizard.cboTargetLanguage.ItemIndex <> -1 then
      raise Exception.Create(
        'The wizard must not silently default a new project to one target language.');
    if not Wizard.edtApiKey.Password then
      raise Exception.Create('The wizard API-key field is not masked.');
    if (Wizard.cboProvider.Items.Count <> 2) or
       (Wizard.cboProvider.Items[0] <> 'DeepL') then
      raise Exception.Create(
        'The Wizard does not present DeepL as the recommended provider.');
    if not Assigned(Wizard.btnBrowseProject.OnClick) or
       not Assigned(Wizard.btnRunScan.OnClick) or
       not Assigned(Wizard.btnTestConnection.OnClick) then
      raise Exception.Create('A primary wizard action is not designer-wired.');
    if not Assigned(Wizard.btnAddDeploymentDestination.OnClick) or
       not Assigned(Wizard.btnRemoveDeploymentDestination.OnClick) or
       not Assigned(Wizard.lstDeploymentDestinations.OnChange) then
      raise Exception.Create(
        'The Wizard deployment-destination controls are not designer-wired.');
    if Wizard.chkCreateBackup.Enabled or
       not Wizard.chkCreateBackup.IsChecked then
      raise Exception.Create(
        'The Wizard safety backup is not mandatory.');
    if Wizard.memScanResults.WordWrap then
      raise Exception.Create('Wizard scan rows must not wrap over one another.');
    if Wizard.memProgress.Height < 250 then
      raise Exception.Create(
        'The completion progress memo did not receive the reclaimed space.');
    if not Wizard.btnNext.Default or not Wizard.btnCancel.Cancel then
      raise Exception.Create(
        'The Wizard does not provide standard Enter/Escape actions.');
    if Wizard.btnBack.Position.Y + Wizard.btnBack.Height > Wizard.ClientHeight then
      raise Exception.Create('Wizard navigation extends below the form.');
    if Wizard.ContentCard.Position.X + Wizard.ContentCard.Width >
       Wizard.BodyLayout.Width + 1 then
      raise Exception.Create('Wizard content extends beyond its body layout.');
    RequirePageContentFits(Wizard);
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
      { The form appends the build label to its caption when it is created,
        so an equality check here failed from the moment build labels were
        introduced and went unnoticed because this program had already stopped
        compiling. Check the parts that are meant to hold still. }
      if not StartsText('Delphi App Translation Studio',
        frmTranslationStudio.Caption) then
        raise Exception.Create('The main form caption is incorrect.');
      if not ContainsText(frmTranslationStudio.Caption, 'Build ') then
        raise Exception.Create('The main form caption omits the build label.');
      { Opens at the size it was drawn, not filling the screen.

        It used to start maximized, which made it tower over the windows
        of the application being translated - the two are looked at side
        by side, and a full-screen tool beside a normal-sized form is
        awkward to work with. The designed size is 1220 by 760 and the
        form is centred, so this asserts the state rather than the size:
        the size belongs in the Object Inspector where it can be changed,
        the decision not to maximize is what must not drift back. }
      if frmTranslationStudio.WindowState <> TWindowState.wsNormal then
        raise Exception.Create('The Studio should open at its designed size rather than maximized.');
      if (frmTranslationStudio.LanguagePageCard.Align <>
          TAlignLayout.Client) or
         (frmTranslationStudio.GlossaryPageCard.Align <>
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
         (frmTranslationStudio.cboTargetLanguage.Items.Count < 40) or
         (frmTranslationStudio.cboGlossaryLanguage.Items.Count < 40) then
        raise Exception.Create('The built-in language selection list is incomplete.');
      if (frmTranslationStudio.cboSourceLanguage.Items.IndexOf(
          'Pashto (Afghanistan) [ps-AF]') < 0) or
         (frmTranslationStudio.cboTargetLanguage.Items.IndexOf(
          'Pashto (Afghanistan) [ps-AF]') < 0) or
         (frmTranslationStudio.cboGlossaryLanguage.Items.IndexOf(
          'Pashto (Afghanistan) [ps-AF]') < 0) then
        raise Exception.Create(
          'The built-in language lists omit a supported RTL language.');
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
      if not Assigned(frmTranslationStudio.mnuFileExit.OnClick) or
         not Assigned(frmTranslationStudio.btnOperationCancel.OnClick) or
         not Assigned(frmTranslationStudio.btnMaintenanceCancel.OnClick) or
         not frmTranslationStudio.btnMaintenanceCancel.Cancel then
        raise Exception.Create(
          'Exit or visible operation cancellation is not designer-wired.');
      if not Assigned(frmTranslationStudio.cboGlossaryLanguage.OnChange) or
         not Assigned(frmTranslationStudio.lstGlossaryTerms.OnChange) or
         not Assigned(frmTranslationStudio.btnGlossaryNew.OnClick) or
         not Assigned(frmTranslationStudio.btnGlossaryAddUpdate.OnClick) or
         not Assigned(frmTranslationStudio.btnGlossaryDelete.OnClick) or
         not Assigned(frmTranslationStudio.btnGlossaryCancelChanges.OnClick) or
         not Assigned(frmTranslationStudio.btnGlossarySave.OnClick) or
         not Assigned(frmTranslationStudio.btnGlossaryApply.OnClick) then
        raise Exception.Create(
          'The Maintenance Studio glossary actions are not designer-wired.');
      if frmTranslationStudio.btnGlossaryApply.Position.Y +
           frmTranslationStudio.btnGlossaryApply.Height >=
           frmTranslationStudio.GlossaryPageCard.Height then
        raise Exception.Create(
          'The glossary actions extend below the workflow page.');
      if frmTranslationStudio.lblNavigationSettings.Position.Y +
           frmTranslationStudio.lblNavigationSettings.Height >=
           frmTranslationStudio.NavigationCard.Height then
        raise Exception.Create(
          'The expanded workflow ladder extends below its navigation card.');
      if frmTranslationStudio.OperationCard.Visible then
        raise Exception.Create(
          'The operation progress card must start hidden.');
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
          'Prepare / Update Target Project' then
        raise Exception.Create(
          'The recommended target-project automation action is not displayed.');
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
         not frmTranslationStudio.lblNavigationGlossary.HitTest or
         not frmTranslationStudio.lblNavigationValidation.HitTest or
         not frmTranslationStudio.lblNavigationExport.HitTest or
         not frmTranslationStudio.lblNavigationIntegration.HitTest or
         not frmTranslationStudio.lblNavigationSettings.HitTest then
        raise Exception.Create(
          'One or more workflow labels cannot receive mouse clicks.');
      if not Assigned(
        frmTranslationStudio.lblNavigationLanguages.OnClick) or
         not Assigned(
        frmTranslationStudio.lblNavigationGlossary.OnClick) or
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
      { The Studio opens on the intro chooser, and every workflow page stays
        hidden until a workflow is picked. This test predates that screen and
        was driving the navigation labels against it, which is why it reported
        the Languages page as broken. Pick the Maintenance Studio workflow the
        way a person would, then exercise the navigation. }
      frmTranslationStudio.btnIntroMaintenance.OnClick(
        frmTranslationStudio.btnIntroMaintenance);
      frmTranslationStudio.lblNavigationLanguages.OnClick(
        frmTranslationStudio.lblNavigationLanguages);
      if not frmTranslationStudio.LanguagePageCard.Visible then
        raise Exception.Create(
          'The Languages workflow label did not activate its page.');
      frmTranslationStudio.lblNavigationGlossary.OnClick(
        frmTranslationStudio.lblNavigationGlossary);
      if not frmTranslationStudio.GlossaryPageCard.Visible then
        raise Exception.Create(
          'The Glossary workflow label did not activate its page.');
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
