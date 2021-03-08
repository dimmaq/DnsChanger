unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls;

type
  TMainForm = class(TForm)
    cbInterfaceList: TComboBox;
    Êàðòû: TLabel;
    btnInterfaceListReload: TBitBtn;
    lblCurDns: TLabel;
    Timer1: TTimer;
    Memo1: TMemo;
    Edit1: TEdit;
    Label1: TLabel;
    Button1: TButton;
    lblTimer: TLabel;
    procedure btnInterfaceListReloadClick(Sender: TObject);
    procedure cbInterfaceListChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FLastChangeTime: TDateTime;
    FCurDnsIndex: Integer;
    procedure InterfaceListParser(ASender: TObject);
    procedure InterfaceDnsParser(ASender: TObject);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  RegularExpressions, dateutils,
  //
  uRunCmd;

procedure TMainForm.btnInterfaceListReloadClick(Sender: TObject);
begin
  TRunCmd.Create('netsh interface ipv4 show dns', InterfaceListParser).Start;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  FCurDnsIndex := -1;
  FLastChangeTime := 0;
  Timer1.Enabled := not Timer1.Enabled;
end;

procedure TMainForm.cbInterfaceListChange(Sender: TObject);
begin
  if cbInterfaceList.ItemIndex = -1 then
  begin
    lblCurDns.Caption := '';
    Exit;
  end;
  lblCurDns.Caption := '*** ÎÁÍÎÂËÅÍÈÅ ***';
  TRunCmd.Create('netsh interface ipv4 show dns name="'+cbInterfaceList.Text+'"', InterfaceDnsParser).Start;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  btnInterfaceListReloadClick(nil);
end;

procedure TMainForm.InterfaceDnsParser(ASender: TObject);
begin
  lblCurDns.Caption := (ASender as TRunCmd).StdOut.Text;
  TRunCmd.Create('ipconfig /flushdns', nil).Start;
end;

procedure TMainForm.InterfaceListParser(ASender: TObject);
var
  sl: TStringList;
  z: string;
  re: TRegEx;
  ok: TMatch;
begin
  cbInterfaceList.Clear;
  sl := (ASender as TRunCmd).StdOut;
  re := TRegEx.Create('^[^\s].+"(.+)"$');
  for z in sl do
  begin
    ok := re.Match(z);
    if ok.Success then
      cbInterfaceList.Items.Add(ok.Groups.Item[1].Value)
  end;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var
  dns, z: string;
begin
  if  Now() >= IncMinute(FLastChangeTime, StrToIntDef(Edit1.Text, 1))  then
  begin
    if (FCurDnsIndex < 0) or (Memo1.Lines.Count <= FCurDnsIndex) then
      FCurDnsIndex := 0;
    dns := Memo1.Lines[FCurDnsIndex];
    FCurDnsIndex := FCurDnsIndex +1;
    FLastChangeTime := Now();
    z := 'netsh interface ipv4 set dns name="'+cbInterfaceList.Text+'" static ' + dns;
    TRunCmd.Create(z, cbInterfaceListChange).Start;
    lblCurDns.Caption := '*** ÎÁÍÎÂËÅÍÈÅ ***';
  end;
  lblTimer.Caption := SecondsBetween(Now(), IncMinute(FLastChangeTime, StrToIntDef(Edit1.Text, 1))).ToString
end;

end.
