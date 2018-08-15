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

unit JCmdInvoker;

interface

uses System.SysUtils, System.IOUtils, System.Classes, WinAPI.Windows, Vcl.Forms, Common, System.RegularExpressions;

type

  TJCmdInvoker = class

    private
      PipeName: AnsiString;
      hPipe: THandle;
      hProcess: THandle;
      hKernel32: THandle;
      TempContents: TTempFileContents;

    protected
      procedure StartRemoteThread(EntryPoint, Argument: Pointer);

    public
      constructor Create(PID: string);
      destructor Free;
      function InvokeJCmd(Argument: string): AnsiString;

  end;

  TDCmdArgument = record
    Name: string;
    IsOptional: Boolean;
    Description: string;
    DataType: string;
    Value: string;
  end;

  TDCmd = record
    Command: string;
    Description: string;
    Impact: string;
    Arguments: array of TDCmdArgument;
    Options: array of TDCmdArgument;
  end;

function ParseDCmdDefinitionFromJCmdHelp(HelpString: string): TDCmd;

implementation

var
  StubDllName: AnsiString;


constructor TJCmdInvoker.Create(PID: string);
var
  GUID: TGUID;
  RemoteMemory, LoadLibraryAddr: Pointer;
  nWrite: NativeUInt;
  TempFileStream: TFileStream;
begin
  hKernel32 := GetModuleHandle(PChar('kernel32'));
  LoadLibraryAddr := GetProcAddress(hKernel32, PAnsiChar('LoadLibraryA'));
  StubDllName := AnsiString(TPath.Combine(TPath.GetDirectoryName(Application.ExeName), 'VisualJCmdStub.dll'));

  CreateGUID(GUID);
  PipeName := AnsiString('\\.\pipe\visualjcmd_' + GUIDToString(GUID));
  hPipe := CreateNamedPipe(PChar(string(PipeName)), PIPE_ACCESS_INBOUND or FILE_FLAG_OVERLAPPED, PIPE_TYPE_BYTE or PIPE_READMODE_BYTE, 1, 128, 8192, NMPWAIT_USE_DEFAULT_WAIT, nil);

  hProcess := OpenProcess(PROCESS_ALL_ACCESS, FALSE, StrToInt(PID));

  // Load VisualJCmdStub.dll to target VM
  RemoteMemory := VirtualAllocEx(hProcess, nil, Length(StubDllName) + 1, MEM_COMMIT, PAGE_READWRITE);
  WriteProcessMemory(hProcess, RemoteMemory, PAnsiChar(StubDllName), Length(StubDllName), nWrite);
  StartRemoteThread(LoadLibraryAddr, RemoteMemory);
  VirtualFreeEx(hProcess, RemoteMemory, 0, MEM_RELEASE);

  // Get InvokeJCmd() address in VisualJCmdStub.dll on target VM
  TempFileStream := nil;
  try
    TempFileStream := TFileStream.Create(GetAddrFilePath(PID), fmOpenRead);
    TempFileStream.Read(TempContents, SizeOf(TTempFileContents));
  finally
    if TempFileStream <> nil then
      TempFileStream.Free;
  end;

end;

destructor TJCmdInvoker.Free;
var
  FreeLibraryAddr: Pointer;
begin
  FreeLibraryAddr := GetProcAddress(hKernel32, PAnsiChar('FreeLibrary'));
  StartRemoteThread(FreeLibraryAddr, Pointer(TempContents.LibraryHInst));

  CloseHandle(hPipe);
  CloseHandle(hProcess);
end;

function TJCmdInvoker.InvokeJCmd(Argument: string): AnsiString;
var
  RemoteJCmdArgument: TJCmdArgument;
  nWrite: NativeUInt;
  nRead: Cardinal;
  RemoteMemory: Pointer;
  Buf: array [0..8191] of AnsiChar;
  MemoryStream: TMemoryStream;
  Overlapped: TOverlapped;
begin
  RemoteJCmdArgument.Argument := VirtualAllocEx(hProcess, nil, Length(Argument) + 1, MEM_COMMIT, PAGE_READWRITE);
  WriteProcessMemory(hProcess, RemoteJCmdArgument.Argument, PAnsiChar(AnsiString(Argument)), Length(Argument), nWrite);
  RemoteJCmdArgument.PipeName := VirtualAllocEx(hProcess, nil, Length(PipeName) + 1, MEM_COMMIT, PAGE_READWRITE);
  WriteProcessMemory(hProcess, RemoteJCmdArgument.PipeName, PAnsiChar(PipeName), Length(PipeName), nWrite);
  RemoteMemory := VirtualAllocEx(hProcess, nil, SizeOf(TJCmdArgument), MEM_COMMIT, PAGE_READWRITE);
  WriteProcessMemory(hProcess, RemoteMemory, @RemoteJCmdArgument, SizeOf(TJCmdArgument), nWrite);

  ZeroMemory(@Overlapped, SizeOf(TOverlapped));
  ConnectNamedPipe(hPipe, @Overlapped);
  StartRemoteThread(TempContents.InvokeJCmdAddr, RemoteMemory);

  VirtualFreeEx(hProcess, RemoteMemory, 0, MEM_RELEASE);
  VirtualFreeEx(hProcess, RemoteJCmdArgument.Argument, 0, MEM_RELEASE);
  VirtualFreeEx(hProcess, RemoteJCmdArgument.PipeName, 0, MEM_RELEASE);

  // Read JCmd result
  WaitForSingleObject(hPipe, INFINITE);
  MemoryStream := TMemoryStream.Create;
  repeat
    ReadFile(hPipe, Buf, 8192, nRead, nil);
    MemoryStream.Write(Buf, nRead);
  until nRead = 0;
  SetLength(Result, MemoryStream.Size);
  MemoryStream.Position := 0;
  MemoryStream.Read(Pointer(Result)^, MemoryStream.Size);
  MemoryStream.Free;
  DisconnectNamedPipe(hPipe);
end;

procedure TJCmdInvoker.StartRemoteThread(EntryPoint, Argument: Pointer);
var
  hRemoteThread: THandle;
  RemoteThreadId: Cardinal;
begin
  hRemoteThread := CreateRemoteThread(hProcess, nil, 0, EntryPoint, Argument, 0, RemoteThreadId);
  WaitForSingleObject(hRemoteThread, INFINITE);
  CloseHandle(hRemoteThread);
end;

function ParseDCmdArgumentDefinitionFromJCmdHelp(HelpString: string): TDCmdArgument;
var
  Match: TMatch;
begin
  Match := TRegEx.Match(HelpString, '^(.+?) : (\[optional\] )?(.+) \((.+?), (.+?)\)$');

  Result.Name := Match.Groups.Item[1].Value;
  Result.IsOptional := Match.Groups.Item[2].Length > 0;
  Result.Description := Match.Groups.Item[3].Value;
  Result.DataType := Match.Groups.Item[4].Value;
  Result.Value := Match.Groups.Item[5].Value;
end;

function ParseDCmdDefinitionFromJCmdHelp(HelpString: string): TDCmd;
var
  list, Args, Opts: TStringList;
  CurrentList: ^TStringList;
  Cnt: Integer;
  Buf: string;
begin
  list := TStringList.Create;
  list.Text := HelpString;

  Result.Command := list[1];
  Result.Description := list[2];

  Result.Impact := TRegEx.Match(list[4], '^Impact: ([^:]+):?.*$')
                         .Groups
                         .Item[1]
                         .Value;

  Args := TStringList.Create;
  Opts := TStringList.Create;
  CurrentList := nil;
  for Cnt := 5 to list.Count - 1 do
    begin
      Buf := Trim(list[Cnt]);

      if Length(Buf) = 0 then
        continue
      else if Buf = 'Arguments:' then
        CurrentList := @Args
      else if Buf.StartsWith('Options:') then
        CurrentList := @Opts
      else if CurrentList <> nil then
        CurrentList.Add(Buf);

    end;

  SetLength(Result.Arguments, Args.Count);
  for Cnt := 0 to Args.Count - 1 do
    begin
      Result.Arguments[Cnt] := ParseDCmdArgumentDefinitionFromJCmdHelp(Args[Cnt]);
    end;

  SetLength(Result.Options, Opts.Count);
  for Cnt := 0 to Opts.Count - 1 do
    begin
      Result.Options[Cnt] := ParseDCmdArgumentDefinitionFromJCmdHelp(Opts[Cnt]);
    end;

  Args.Free;
  Opts.Free;

  list.Free;
end;

end.
