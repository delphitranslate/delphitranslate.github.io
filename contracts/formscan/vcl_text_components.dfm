object frmVclCoverage: TForm
  Caption = 'Coverage form'
  object pnlHeader: TPanel
    Caption = 'Panel used as a header'
  end
  object tbrMain: TToolBar
    Caption = 'Main toolbar'
    object btnNewRecord: TToolButton
      Caption = 'New record'
    end
  end
  object stbStatus: TStatusBar
    Panels = <
      item
        Text = 'Ready'
      end
      item
        Text = 'No document loaded'
      end>
  end
  object lvFiles: TListView
    Columns = <
      item
        Caption = 'File name'
      end
      item
        Caption = 'Size on disk'
      end>
  end
  object lblAfterCollection: TLabel
    Caption = 'Drawn after the collections'
  end
  object tabMain: TTabControl
    Tabs.Strings = (
      'First tab'
      'Second tab')
  end
  object edSearch: TButtonedEdit
    TextHint = 'Search the catalogue'
  end
  object lnkHelp: TLinkLabel
    Caption = 'Open the help topic'
  end
  object lblLast: TLabel
    Caption = 'Last control on the form'
  end
end
