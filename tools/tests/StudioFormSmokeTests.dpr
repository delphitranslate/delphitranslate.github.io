program StudioFormSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.UITypes,
  FMX.Types,
  FMX.Forms,
  DAT.Studio.MainForm in '..\..\source\studio\DAT.Studio.MainForm.pas'
    {frmTranslationStudio};

begin
  try
    Application.Initialize;
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
      if not Assigned(
        frmTranslationStudio.chkRuntimeWiringConfirmed.OnChange) then
        raise Exception.Create(
          'The runtime wiring confirmation is not designer-wired.');
      if not Assigned(frmTranslationStudio.btnAcceptSuggestion.OnClick) then
        raise Exception.Create(
          'The translation suggestion action is not designer-wired.');
      if not Assigned(
           frmTranslationStudio.btnMarkTranslationReviewed.OnClick) or
         not Assigned(frmTranslationStudio.btnApproveTranslation.OnClick) then
        raise Exception.Create(
          'The linguistic review actions are not designer-wired.');
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
