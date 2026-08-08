object frmVCLLifecycleMDIChild: TfrmVCLLifecycleMDIChild
  Left = 0
  Top = 0
  Caption = 'VCL MDI Child Source'
  ClientHeight = 220
  ClientWidth = 440
  FormStyle = fsMDIChild
  Position = poDefault
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnPaint = FormPaint
  OnShow = FormShow
  object lblProbe: TLabel
    Left = 24
    Top = 48
    Width = 165
    Height = 19
    Caption = 'VCL MDI child source'
    Font.Height = -16
    ParentFont = False
  end
end
