object frmVCLLifecycleMDIMain: TfrmVCLLifecycleMDIMain
  Left = 0
  Top = 0
  Caption = 'VCL MDI Main Source'
  ClientHeight = 420
  ClientWidth = 720
  FormStyle = fsMDIForm
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnPaint = FormPaint
  OnShow = FormShow
  object lblProbe: TLabel
    Left = 24
    Top = 24
    Width = 158
    Height = 19
    Caption = 'VCL MDI main source'
    Font.Height = -16
    ParentFont = False
  end
end
