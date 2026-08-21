unit code_positioned_control_is_left_alone_fmx;

{ The FireMonkey twin of the VCL contract beside it.

  FireMonkey spells the property Position.X rather than Left, and that is the
  whole of the difference: the unit being read is Pascal either way, so one
  reading serves both frameworks. lblOrdinary is again left unmentioned, so it
  must still be laid out normally. }

interface

uses
  FMX.Forms, FMX.StdCtrls;

type
  TContractForm = class(TForm)
    lblHeading: TLabel;
    lblOrdinary: TLabel;
    procedure FormShow(Sender: TObject);
  end;

implementation

procedure TContractForm.FormShow(Sender: TObject);
begin
  lblHeading.Position.X := (ClientWidth - lblHeading.Width) / 2;
end;

end.
