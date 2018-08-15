program VisualJCmd;

uses
  Vcl.Forms,
  VisualJCmdFrontend in 'VisualJCmdFrontend.pas' {Main},
  PerfData in 'PerfData.pas',
  Common in 'Common.pas',
  JCmdInvoker in 'JCmdInvoker.pas',
  DCmdForm in 'DCmdForm.pas' {DCmdDialog};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMain, Main);
  Application.CreateForm(TDCmdDialog, DCmdDialog);
  Application.Run;
end.
