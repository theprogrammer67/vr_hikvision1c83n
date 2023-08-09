unit unitBarcodeProp;

interface

uses 
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TfrBarCodeProp = class(TForm)
    cbType: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    cbCode: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    chbShowGuardChars: TCheckBox;
    chbTallGuardBars: TCheckBox;
    chbShowCode: TCheckBox;
    Label12: TLabel;
    chbAddCheckChar: TCheckBox;
    edBarNarrowToWideRatio: TEdit;
    edBarToSpaceRatio: TEdit;
    chbBearerBars: TCheckBox;
    edSupplementalCode: TEdit;
    edBarWidth: TEdit;
    cbCode128Subset: TComboBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmBarCodeProp: TfrBarCodeProp;
implementation

{$R *.DFM}

end.
