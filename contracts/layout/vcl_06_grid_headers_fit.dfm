object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 260
  ClientWidth = 760
  object grdSchedule: TStringGrid
    Left = 40
    Top = 50
    Width = 680
    Height = 150
    object colTime: TStringColumn
      Title.Caption = 'Time'
      Width = 72
    end
    object colType: TStringColumn
      Title.Caption = 'Type'
      Width = 72
    end
  end
end
