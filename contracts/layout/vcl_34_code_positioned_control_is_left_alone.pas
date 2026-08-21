unit vcl_34_code_positioned_control_is_left_alone;

{ The Pascal unit beside the fixture form. It exists so the planner can read
  it, exactly as it reads the unit beside a real form.

  lblHeading is centred here, in code, the way Carillon centres its own main
  heading. lblOrdinary is not touched, so it must still be laid out normally -
  otherwise a contract that passed by disabling the planner entirely would look
  the same as one that passed correctly. }

interface

uses
  Vcl.Forms, Vcl.StdCtrls;

type
  TContractForm = class(TForm)
    lblHeading: TLabel;
    lblOrdinary: TLabel;
    procedure FormShow(Sender: TObject);
  end;

implementation

procedure TContractForm.FormShow(Sender: TObject);
begin
  lblHeading.Left := (Screen.Width - lblHeading.Width) div 2;
end;

end.
