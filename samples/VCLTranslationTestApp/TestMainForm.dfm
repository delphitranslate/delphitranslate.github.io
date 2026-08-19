object frmVCLTestMain: TfrmVCLTestMain
  Left = 0
  Top = 0
  Caption = 'VCL Translation Test Application'
  ClientHeight = 620
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = mnuMain
  Position = poScreenCenter
  TextHeight = 15
  object lblTitle: TLabel
    Left = 250
    Top = 16
    Width = 400
    Height = 30
    Alignment = taCenter
    AutoSize = False
    Caption = 'Bell Schedule'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblLanguage: TLabel
    Left = 640
    Top = 62
    Width = 56
    Height = 15
    Caption = 'Language:'
  end
  object lblCustomerName: TLabel
    Left = 24
    Top = 250
    Width = 90
    Height = 15
    Caption = 'Customer name:'
  end
  object lblEmail: TLabel
    Left = 24
    Top = 300
    Width = 80
    Height = 15
    Caption = 'Email address:'
  end
  object lblDuration: TLabel
    Left = 300
    Top = 250
    Width = 90
    Height = 15
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Duration:'
  end
  object lblIntro: TLabel
    Left = 24
    Top = 196
    Width = 560
    Height = 34
    AutoSize = False
    Caption =
      'Choose a language below. Every caption on this form is translate' +
      'd from the offline language pack.'
    WordWrap = True
  end
  object lblNotes: TLabel
    Left = 24
    Top = 348
    Width = 34
    Height = 15
    Caption = 'Notes:'
  end
  object cboLanguage: TDATVCLLanguageComboBox
    Left = 702
    Top = 58
    Width = 170
    Height = 23
    Style = csDropDownList
    TabOrder = 0
    LanguageManager = DATManager
  end
  object grpSchedule: TGroupBox
    Left = 24
    Top = 62
    Width = 290
    Height = 120
    Caption = 'Schedule options'
    TabOrder = 1
    object chkEnableSchedule: TCheckBox
      Left = 16
      Top = 28
      Width = 130
      Height = 17
      Caption = 'Enable scheduling'
      TabOrder = 0
    end
    object lblScheduleNote: TLabel
      Left = 16
      Top = 54
      Width = 258
      Height = 50
      AutoSize = False
      Caption = 'Bells ring on the hour while scheduling is enabled.'
      WordWrap = True
    end
  end
  object pnlMedia: TPanel
    Left = 336
    Top = 62
    Width = 280
    Height = 120
    BevelOuter = bvLowered
    Caption = ''
    TabOrder = 2
    object btnPlay: TButton
      Left = 14
      Top = 46
      Width = 80
      Height = 30
      Caption = 'Play'
      TabOrder = 0
    end
    object btnPause: TButton
      Left = 100
      Top = 46
      Width = 80
      Height = 30
      Caption = 'Pause'
      TabOrder = 1
    end
    object btnStop: TButton
      Left = 186
      Top = 46
      Width = 80
      Height = 30
      Caption = 'Stop'
      TabOrder = 2
    end
  end
  object edtCustomerName: TEdit
    Left = 24
    Top = 268
    Width = 240
    Height = 23
    TabOrder = 3
    Text = ''
  end
  object edtEmail: TEdit
    Left = 24
    Top = 318
    Width = 240
    Height = 23
    TabOrder = 4
    Text = ''
  end
  object edtDuration: TEdit
    Left = 396
    Top = 247
    Width = 90
    Height = 23
    TabOrder = 5
    Text = ''
  end
  object memNotes: TMemo
    Left = 24
    Top = 366
    Width = 300
    Height = 90
    Lines.Strings = (
      'First scheduled item'
      'Second scheduled item')
    TabOrder = 6
  end
  object lstItems: TListBox
    Left = 340
    Top = 366
    Width = 200
    Height = 90
    ItemHeight = 15
    Items.Strings = (
      'Morning chime'
      'Evening chime'
      'Silence period')
    TabOrder = 7
  end
  object rgMode: TRadioGroup
    Left = 560
    Top = 250
    Width = 200
    Height = 110
    Caption = 'Playback mode'
    ItemIndex = 0
    Items.Strings = (
      'Play once'
      'Repeat all day'
      'Silent')
    TabOrder = 8
  end
  object lvSchedule: TListView
    Left = 24
    Top = 470
    Width = 516
    Height = 110
    Columns = <
      item
        Caption = 'Time'
        Width = 90
      end
      item
        Caption = 'Song name'
        Width = 260
      end
      item
        Caption = 'Duration'
        Width = 100
      end>
    TabOrder = 9
    ViewStyle = vsReport
  end
  object grdValues: TStringGrid
    Left = 560
    Top = 470
    Width = 312
    Height = 110
    ColCount = 3
    FixedCols = 0
    RowCount = 3
    TabOrder = 10
  end
  object btnDetails: TButton
    Left = 560
    Top = 380
    Width = 150
    Height = 30
    Caption = 'Open details'
    TabOrder = 11
    OnClick = btnDetailsClick
  end
  object btnClose: TButton
    Left = 722
    Top = 380
    Width = 150
    Height = 30
    Caption = 'Close'
    TabOrder = 12
    OnClick = btnCloseClick
  end
  object DATManager: TDATVCLLanguageManager
    ApplicationId = 'VCLTranslationTestApp'
    LanguagesFolder = 'Localization\Languages'
    SourceLanguage = 'en-US'
    Left = 812
    Top = 108
  end
  object mnuMain: TMainMenu
    Left = 748
    Top = 108
    object mnuFile: TMenuItem
      Caption = 'File'
      object mnuFileOpen: TMenuItem
        Caption = 'Open schedule'
      end
      object mnuFileSave: TMenuItem
        Caption = 'Save schedule'
      end
      object mnuFileExit: TMenuItem
        Caption = 'Exit'
        OnClick = mnuFileExitClick
      end
    end
    object mnuSettings: TMenuItem
      Caption = 'Settings'
      object mnuSettingsOptions: TMenuItem
        Caption = 'Options'
      end
      object mnuSettingsColors: TMenuItem
        Caption = 'Colors'
      end
    end
    object mnuHelp: TMenuItem
      Caption = 'Help'
      object mnuHelpAbout: TMenuItem
        Caption = 'About'
      end
    end
  end
end
