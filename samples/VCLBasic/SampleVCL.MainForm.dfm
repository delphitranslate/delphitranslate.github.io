object frmVCLSample: TfrmVCLSample
  Left = 0
  Top = 0
  Caption = 'Customer Manager'
  ClientHeight = 380
  ClientWidth = 640
  Position = poScreenCenter
  object lblHeading: TLabel
    Left = 32
    Top = 40
    Width = 227
    Height = 25
    Caption = 'Customer Account Details'
    Font.Height = -21
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblCustomerName: TLabel
    Left = 32
    Top = 96
    Width = 86
    Height = 15
    Caption = 'Customer name'
  end
  object edtCustomerName: TEdit
    Left = 32
    Top = 120
    Width = 360
    Height = 23
    Hint = 'Enter the customer'#39's full name'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    TextHint = 'Full name'
  end
  object btnSave: TButton
    Left = 416
    Top = 118
    Width = 120
    Height = 28
    Caption = '&Save Customer'
    TabOrder = 1
    OnClick = btnSaveClick
  end
  object memInstructions: TMemo
    Left = 32
    Top = 184
    Width = 504
    Height = 120
    Lines.Strings = (
      'Enter the customer information, then choose Save Customer.'
      'Fields marked as required must be completed.')
    ReadOnly = True
    TabOrder = 2
  end
  object MainMenu: TMainMenu
    Left = 568
    Top = 24
    object mnuFile: TMenuItem
      Caption = '&File'
      object mnuExit: TMenuItem
        Caption = 'E&xit'
        OnClick = mnuExitClick
      end
    end
    object mnuLanguage: TMenuItem
      Caption = '&Language'
    end
  end
end
