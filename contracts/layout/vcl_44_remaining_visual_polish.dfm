object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 1000
  ClientWidth = 1100
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object gbCaptions: TGroupBox
    Left = 20
    Top = 20
    Width = 600
    Height = 220
    object lblTo: TLabel
      Left = 145
      Top = 20
      Width = 16
      Height = 20
      Caption = 'To'
      Font.Height = -15
      ParentFont = False
    end
    object edtTo: TEdit
      Left = 100
      Top = 47
      Width = 107
      Height = 28
    end
    object lblStart: TLabel
      Left = 339
      Top = 20
      Width = 27
      Height = 20
      Caption = 'Start'
      Font.Height = -13
      ParentFont = False
    end
    object edtStart: TEdit
      Left = 300
      Top = 47
      Width = 105
      Height = 28
    end
    object lblRecipient: TLabel
      Left = 100
      Top = 110
      Width = 197
      Height = 20
      Alignment = taRightJustify
      Caption = 'Test Recipient Email Address:'
      Font.Height = -15
      ParentFont = False
      WordWrap = True
    end
    object edtRecipient: TEdit
      Left = 100
      Top = 137
      Width = 286
      Height = 28
    end
  end
  object gbMute: TGroupBox
    Left = 20
    Top = 260
    Width = 473
    Height = 77
    object lblVolume: TLabel
      Left = 21
      Top = 16
      Width = 46
      Height = 34
      Caption = 'System Volume:'
      Font.Height = -13
      ParentFont = False
      WordWrap = True
    end
    object trkVolume: TTrackBar
      Left = 85
      Top = 19
      Width = 301
      Height = 26
    end
    object btnMute: TButton
      Left = 392
      Top = 22
      Width = 65
      Height = 25
      Caption = 'Mute'
      Font.Height = -13
      ParentFont = False
    end
  end
  object gbEmailButtons: TGroupBox
    Left = 20
    Top = 360
    Width = 989
    Height = 90
    object btnSave: TButton
      Left = 648
      Top = 30
      Width = 97
      Height = 25
      Caption = 'Save Settings'
      Font.Height = -15
      ParentFont = False
    end
    object btnClose: TButton
      Left = 772
      Top = 30
      Width = 75
      Height = 25
      Caption = 'Close'
      Font.Height = -15
      ParentFont = False
    end
  end
  object gbResetButtons: TGroupBox
    Left = 20
    Top = 470
    Width = 400
    Height = 230
    object btnRecalculate: TButton
      Left = 134
      Top = 30
      Width = 129
      Height = 41
      Caption = 'Recalculate Easter and All Souls Dates'
      WordWrap = True
    end
    object btnReset: TButton
      Left = 182
      Top = 119
      Width = 81
      Height = 42
      Caption = 'Reset Funeral Date Fields'
      Font.Height = -12
      ParentFont = False
      WordWrap = True
    end
  end
  object gbParagraphs: TGroupBox
    Left = 20
    Top = 720
    Width = 900
    Height = 240
    object lblInstructions: TLabel
      Left = 20
      Top = 20
      Width = 577
      Height = 60
      Caption = 'Click on the Select Random Directory button for any directory box, select a directory'#13#10'and add dates to put it into the rotation. Dates should be in the format of month/date'#13#10'only (example: 04/27), with no year.'
      Font.Height = -15
      ParentFont = False
    end
    object lblDefaultInstructions: TLabel
      Left = 20
      Top = 100
      Width = 571
      Height = 60
      Caption = 'The default directory must be set to have random music played. If not set, no random'#13#10'music will play. If the other directories are not usable, any random music play will fall'#13#10'back to the directory in this field.'
      Font.Height = -15
      ParentFont = False
    end
  end
end
