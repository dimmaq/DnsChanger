program DnsChanger;

uses
  Vcl.Forms,
  uMainForm in 'Units\uMainForm.pas' {MainForm},
  uRunCmd in 'Units\uRunCmd.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
