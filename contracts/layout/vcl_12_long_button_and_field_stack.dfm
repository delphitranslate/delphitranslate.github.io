object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 360
  ClientWidth = 700
  object btnEaster: TButton
    Left = 40
    Top = 180
    Width = 150
    Height = 38
    Font.Height = -13
    Caption = 'Recalculate Easter dates'
  end
  object lblHolyWeek: TLabel
    WordWrap = False
    Left = 225
    Top = 178
    Width = 185
    Height = 38
    Font.Height = -13
    Caption = 'From Maundy Thursday until Saturday:'
  end
  object edtStart: TEdit
    Left = 430
    Top = 180
    Width = 100
    Height = 32
    Text = ''
  end
  object edtEnd: TEdit
    Left = 545
    Top = 180
    Width = 100
    Height = 32
    Text = ''
  end
end
