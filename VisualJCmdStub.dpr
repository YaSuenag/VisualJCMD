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

library VisualJCmdStub;

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Windows,
  Common in 'Common.pas';

{$R *.res}

type
  TEnqueueOperationFunc = function (cmd, arg1, arg2, arg3, pipename: PAnsiChar): Integer;

var
  JVM_EnqueueOperation: TEnqueueOperationFunc;


function InvokeJCmd(Args: TJCmdArgument): Integer; stdcall;
begin

  if @JVM_EnqueueOperation = nil then
    Result := -1
  else
    Result := JVM_EnqueueOperation(PAnsiChar('jcmd'), Args.Argument, nil, nil, Args.PipeName);

end;


exports
  InvokeJCmd;


var
  TempFileName: string;

procedure DllMain(Reason: Integer);
var
  TempContents: TTempFileContents;
  TempFileStream: TFileStream;
  hJVM: THandle;
begin

  if Reason = DLL_PROCESS_ATTACH then
    begin
      TempFileName := GetAddrFilePath(IntToStr(GetCurrentProcessId));
      TempContents.LibraryHInst := HInstance;
      TempContents.InvokeJCmdAddr := @InvokeJCmd;
      TempFileStream := nil;

      try
        TempFileStream := TFileStream.Create(TempFileName, fmCreate);
        TempFileStream.Write(TempContents, SizeOf(TTempFileContents));
      finally
        if TempFileStream <> nil then
          TempFileStream.Free;
      end;

      hJVM := GetModuleHandle(PChar('jvm'));
      JVM_EnqueueOperation := GetProcAddress(hJVM, PAnsiChar('JVM_EnqueueOperation'));
    end
  else if Reason = DLL_PROCESS_DETACH then
    begin
      DeleteFile(PChar(TempFileName));
    end;

end;

begin
  DllProc := DllMain;
  DllMain(DLL_PROCESS_ATTACH);
end.
