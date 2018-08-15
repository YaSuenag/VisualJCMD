{
  Copyright (C) 2018  Yasumasa Suenaga

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
}

unit DCmdForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.StdCtrls, JCmdInvoker;

type
  TDCmdDialog = class(TForm)
    Description: TLabel;
    ConfigurationTable: TStringGrid;
    OptionDescription: TLabel;
    InvokeButton: TButton;
    Result: TMemo;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ConfigurationTableSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure InvokeButtonClick(Sender: TObject);
  private
    FDCmd: TDCmd;
    FPID: string;
    AllOptions: array of ^TDCmdArgument;
  public
    property DCmd: TDCmd read FDCmd write FDCmd;
    property PID: string read FPID write FPID;
  end;

var
  DCmdDialog: TDCmdDialog;

implementation

{$R *.dfm}

procedure TDCmdDialog.ConfigurationTableSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin

  if (Length(AllOptions) >= ARow) and (AllOptions[ARow - 1] <> nil) then
    OptionDescription.Caption := AllOptions[ARow - 1].Description;

end;

procedure TDCmdDialog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TDCmdDialog.FormCreate(Sender: TObject);
begin
  ConfigurationTable.Cells[0, 0] := 'Name';
  ConfigurationTable.Cells[1, 0] := 'Value';
end;

procedure TDCmdDialog.FormShow(Sender: TObject);
var
  Index, AllIndex: Integer;
begin
  Caption := FDCmd.Command + ' (' + FDCmd.Impact + ')';
  Description.Caption := FDCmd.Description;

  SetLength(AllOptions, Length(FDCmd.Arguments) + Length(FDCmd.Options));
  ConfigurationTable.RowCount := Length(AllOptions) + 1;
  AllIndex := 0;

  for Index := 0 to Length(FDCmd.Arguments) - 1 do
    begin
      AllOptions[AllIndex] := @FDCmd.Arguments[Index];
      ConfigurationTable.Cells[0, AllIndex + 1] := FDCmd.Arguments[Index].Name;
      ConfigurationTable.Cells[1, AllIndex + 1] := FDCmd.Arguments[Index].Value;
      AllIndex := Allindex + 1;
    end;

  for Index := 0 to Length(FDCmd.Options) - 1 do
    begin
      AllOptions[AllIndex] := @FDCmd.Options[Index];
      ConfigurationTable.Cells[0, AllIndex + 1] := FDCmd.Options[Index].Name;
      ConfigurationTable.Cells[1, AllIndex + 1] := FDCmd.Options[Index].Value;
      AllIndex := Allindex + 1;
    end;

  if AllIndex > 0 then
    begin
      OptionDescription.Caption := AllOptions[ConfigurationTable.Row - 1].Description;
    end
  else
    begin
      OptionDescription.Visible := False;
      ConfigurationTable.Visible := False;
    end;

end;

procedure TDCmdDialog.InvokeButtonClick(Sender: TObject);
var
  Index: Integer;
  JCmdInvoker: TJCmdInvoker;
  Command: string;
  Args: TDCmdArgument;
begin

  for Index := 0 to Length(AllOptions) - 1 do
    begin
      AllOptions[Index].Value := ConfigurationTable.Cells[1, Index + 1];
    end;

  JCmdInvoker := TJCmdInvoker.Create(PID);
  Command := DCmd.Command;

  for Args in DCmd.Options do
    begin

      if Args.Value <> 'no default value' then
        begin
          Command := Command + ' ' + Args.Name + '="' + Args.Value + '"';
        end;

    end;

  for Args in DCmd.Arguments do
    begin

      if Args.Value <> 'no default value' then
        begin
          Command := Command + ' ' + Args.Value;
        end;

    end;

  Result.Lines.Text := string(JCmdInvoker.InvokeJCmd(Command));

  JCmdInvoker.Free;
end;

end.
