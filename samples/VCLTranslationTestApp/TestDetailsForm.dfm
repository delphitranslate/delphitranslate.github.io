object frmVCLTestDetails: TfrmVCLTestDetails
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Schedule details'
  ClientHeight = 300
  ClientWidth = 460
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 15
  object lblDetailsTitle: TLabel
    Left = 24
    Top = 20
    Width = 412
    Height = 26
    Alignment = taCenter
    AutoSize = False
    Caption = 'Schedule details'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblExplain: TLabel
    Left = 24
    Top = 56
    Width = 412
    Height = 34
    AutoSize = False
    Caption = 'These settings apply to the selected group only.'
    WordWrap = True
  end
  object grpWindow: TGroupBox
    Left = 24
    Top = 100
    Width = 412
    Height = 130
    Caption = 'Silence window'
    TabOrder = 0
    object lblStart: TLabel
      Left = 16
      Top = 30
      Width = 28
      Height = 15
      Caption = 'Start:'
    end
    object lblEnd: TLabel
      Left = 210
      Top = 30
      Width = 24
      Height = 15
      Caption = 'End:'
    end
    object edtStart: TEdit
      Left = 16
      Top = 48
      Width = 150
      Height = 23
      TabOrder = 0
      Text = '08:00'
    end
    object edtEnd: TEdit
      Left = 210
      Top = 48
      Width = 150
      Height = 23
      TabOrder = 1
      Text = '17:00'
    end
    object chkSilence: TCheckBox
      Left = 16
      Top = 88
      Width = 160
      Height = 17
      Caption = 'Silence enabled'
      TabOrder = 2
    end
  end
  object btnApply: TButton
    Left = 236
    Top = 250
    Width = 90
    Height = 30
    Caption = 'Apply'
    TabOrder = 1
    OnClick = btnApplyClick
  end
  object btnCancel: TButton
    Left = 346
    Top = 250
    Width = 90
    Height = 30
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = btnCancelClick
  end
end
