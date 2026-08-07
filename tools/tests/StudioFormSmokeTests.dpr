program StudioFormSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
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
        raise Exception.Create('The Provider Settings workflow page did not activate.');
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
