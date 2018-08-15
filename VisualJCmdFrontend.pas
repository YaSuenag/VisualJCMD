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

unit VisualJCmdFrontend;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, IOUtils, Types, RegularExpressions, PerfData,
  Vcl.ComCtrls, System.AnsiStrings, Common, JCmdinvoker, DCmdForm;

type
  TMain = class(TForm)
    VMList: TStringGrid;
    PerfCounterTree: TTreeView;
    DCmdList: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure VMListSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure DCmdListDblClick(Sender: TObject);
  private
    DCmds: array of TDCmd;

    function GetHSPerfDataDir: string;
    function ProcessNodes(Parent: TTreeNode; Name: TStringList): TTreeNode;
    procedure AddPerfCountersToTreeView(PID: string);
  public

  end;

var
  Main: TMain;

const UNLEN = 256; { https://msdn.microsoft.com/en-us/library/cc761107.aspx }


implementation

{$R *.dfm}

function TMain.GetHSPerfDataDir;
var
  UserLen: Cardinal;
  UserPtr: array[0..UNLEN] of WideChar;
begin
  UserLen := UNLEN + 1;
  GetUserName(UserPtr, UserLen);
  Result := TPath.Combine(TPath.GetTempPath, 'hsperfdata_' + string(UserPtr));
end;

procedure TMain.DCmdListDblClick(Sender: TObject);
var
  DCmdDialog: TDCmdDialog;
begin

  if Length(DCmds) < 1 then
    Exit;

  DCmdDialog := TDCmdDialog.Create(Application);
  DCmdDialog.DCmd := DCmds[DCmdList.Row - 1];
  DCmdDialog.PID := VMList.Cells[0, VMList.Row];
  DCmdDialog.Show;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  regex: TRegEx;
  pids: TStringDynArray;
  index: Integer;
  PerfData: TPerfData;
  PerfCounterValue: TPerfCounterValue;
  DummyBool: Boolean;
begin
  VMList.Cells[0, 0] := 'PID';
  VMList.Cells[1, 0] := 'Main Class';

  DCmdList.Cells[0, 0] := 'Command';
  DCmdList.Cells[1, 0] := 'Impact';
  DCmdList.Cells[2, 0] := 'Description';

  regex := TRegEx.Create('^\d+$');
  pids := TDirectory.GetFiles(GetHSPerfDataDir, TSearchOption.soTopDirectoryOnly,
            function(const Path: string; const SearchRec: TSearchRec): Boolean
              begin
                Result := regex.IsMatch(SearchRec.Name);
              end
          );
  VMList.RowCount := Length(pids) + 1;

  for index := 0 to Length(pids) - 1 do
    begin
      VMList.Cells[0, index + 1] := TPath.GetFileName(pids[index]);
      PerfData := TPerfData.Create(pids[index]);

      for PerfCounterValue in PerfData.PerfCounters do
        begin
          if PerfCounterValue.Name = 'sun.rt.javaCommand' then
            begin
              VMList.Cells[1, index + 1] := string(PerfCounterValue.StringValue);
              break;
            end;
        end;

    end;

  VMListSelectCell(nil, 1, 1, DummyBool);
end;

function TMain.ProcessNodes(Parent: TTreeNode; Name: TStringList): TTreeNode;
var
  Index: Integer;
  EntryName: string;
  ChildNode: TTreeNode;
begin

  if Parent = nil then
    begin
      for Index := 0 to PerfCounterTree.Items.Count - 1 do
        begin
          if (PerfCounterTree.Items[Index].Level = 0) and (PerfCounterTree.Items[Index].Text = Name[0]) then
            begin
              Parent := PerfCounterTree.Items[Index];
            end;
        end;
    end;


  if Parent = nil then
    begin
      Parent := PerfCounterTree.Items.Add(nil, Name[0]);
    end;

  EntryName := Name[Parent.Level + 1];
  ChildNode := Parent.getFirstChild;
  while ChildNode <> nil do
    begin

      if ChildNode.Text = EntryName then
        break;

      ChildNode := Parent.GetNextChild(ChildNode);
    end;

  if ChildNode = nil then
    begin
      ChildNode := PerfCounterTree.Items.AddChild(Parent, EntryName);
    end;

  Result := ChildNode;

  if Name.Count > (ChildNode.Level + 1) then
    Result := ProcessNodes(ChildNode, Name);

end;

procedure TMain.AddPerfCountersToTreeView(PID: string);
var
  PerfData: TPerfData;
  list: TStringList;
  PerfCounterValue: TPerfCounterValue;
  LeafNode: TTreeNode;
begin
  PerfData := TPerfData.Create(TPath.Combine(GetHSPerfDataDir, PID));
  list := TStringList.Create;
  list.Delimiter := '.';
  parent := nil;

  PerfCounterTree.Items.BeginUpdate;
  for PerfCounterValue in PerfData.PerfCounters do
    begin
      list.DelimitedText := string(PerfCounterValue.Name);
      LeafNode := ProcessNodes(nil, list);
      PerfCounterTree.Items.AddChildObject(LeafNode, PerfData.BuildValueString(PerfCounterValue), @PerfCounterValue);
    end;
  PerfCounterTree.Items.EndUpdate;

  list.Free;
end;

procedure TMain.VMListSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var
  PID: string;
  JCmdInvoker: TJCmdInvoker;
  JCmdList: TStringList;
  Cnt: Integer;
begin
  PerfCounterTree.Items.Clear;

  if VMList.Cells[0, ARow] = '' then
    exit;

  PID := VMList.Cells[0, ARow];
  AddPerfCountersToTreeView(PID);

  JCmdList := TStringList.Create;
  JCmdInvoker := TJCmdInvoker.Create(PID);
  JCmdList.Text := string(JCmdInvoker.InvokeJCmd('help'));

  if JCmdList.Count >= 3 then
    begin
      SetLength(DCmds, JCmdList.Count - 2);
      DCmdList.RowCount := JCmdList.Count - 3;

      // Skip header and footer lines
      for Cnt := 2 to JCmdList.Count - 3 do
        begin
          DCmds[Cnt - 2] := ParseDCmdDefinitionFromJCmdHelp(string(JCmdInvoker.InvokeJCmd('help ' + JCmdList[Cnt])));

          DCmdList.Cells[0, Cnt - 1] := DCmds[Cnt - 2].Command;
          DCmdList.Cells[1, Cnt - 1] := DCmds[Cnt - 2].Impact;
          DCmdList.Cells[2, Cnt - 1] := DCmds[Cnt - 2].Description;
        end;
    end;

  JCmdInvoker.Free;
  JCmdList.Free;
end;

end.
