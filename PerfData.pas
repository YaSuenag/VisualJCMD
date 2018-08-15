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

unit PerfData;

interface

uses Classes, SysUtils, Winapi.Windows;


type

  TPerfDataPrologue = packed record
    Magic: Integer;
    ByteOrder: ShortInt;
    MajorVersion: ShortInt;
    MinorVersion: ShortInt;
    Accessible: ShortInt;
    Used: Integer;
    Overflow: Integer;
    ModTimeStamp: Int64;
    EntryOffset: Integer;
    NumEntries: Integer;
  end;


  TUnits = (U_None = 1, U_Bytes = 2, U_Ticks = 3, U_Events = 4, U_String = 5, U_Hertz = 6);

  TPerfDataEntry = packed record
    EntryLength: Integer;
    NameOffset: Integer;
    VectorLength: Integer;
    DataType: ShortInt;
    Flags: ShortInt;
    DataUnits: TUnits;
    DataVariability: ShortInt;
    DataOffset: Integer;
  end;


  TPerfCounterValue = record
    Name: AnsiString;
    DataUnits: TUnits;
    DataType: ShortInt;
    StringValue: AnsiString;
    LongValue: Int64;
  end;


  TPerfData = record

    private
      FPrologue: TPerfDataPrologue;

    public
      PerfCounters: array of TPerfCounterValue;

      constructor Create(const Path: string);
      property Prologue: TPerfDataPrologue read FPrologue;

      function BuildValueString(PerfCounterValue: TPerfCounterValue): String;

  end;


implementation

constructor TPerfData.Create(const Path: string);
var
  { http://qc.embarcadero.com/wc/qcmain.aspx?d=45628 }
  HPerfDataFile: THandle;
  PerfDataFileStream: THandleStream;
  idx: Integer;
  entry: TPerfDataEntry;
  EntryPos: Int64;
begin
  PerfDataFileStream := nil;
  HPerfDataFile := CreateFile(PChar(Path), GENERIC_READ,
                      FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
                        nil, OPEN_EXISTING, FILE_ATTRIBUTE_READONLY or FILE_ATTRIBUTE_TEMPORARY, FILE_FLAG_RANDOM_ACCESS);
  if HPerfDataFile = INVALID_HANDLE_VALUE then
    raise Exception.Create(Path + ': ' + SysErrorMessage(GetLastError));

  try
    PerfDataFileStream := THandleStream.Create(HPerfDataFile);
    PerfDataFileStream.ReadData(FPrologue);

    SetLength(PerfCounters, FPrologue.NumEntries);
    EntryPos := PerfDataFileStream.Seek(FPrologue.EntryOffset, TSeekOrigin.soBeginning);
    for idx := 0 to (FPrologue.NumEntries - 1) do
      begin
        PerfDataFileStream.ReadData(entry);

        PerfDataFileStream.Seek(EntryPos + entry.NameOffset, TSeekOrigin.soBeginning);
        SetLength(PerfCounters[idx].Name, entry.DataOffset - entry.NameOffset);
        PerfDataFileStream.Read(Pointer(PerfCounters[idx].Name)^, entry.DataOffset - entry.NameOffset);
        PerfCounters[idx].Name := AnsiString(Trim(string(PerfCounters[idx].Name)));

        PerfCounters[idx].DataUnits := entry.DataUnits;
        PerfCounters[idx].DataType := entry.DataType;

        PerfDataFileStream.Seek(EntryPos + entry.DataOffset, TSeekOrigin.soBeginning);
        if PerfCounters[idx].DataType = SmallInt(Ord('B')) then
          begin
            PerfDataFileStream.Seek(EntryPos + entry.DataOffset, TSeekOrigin.soBeginning);
            SetLength(PerfCounters[idx].StringValue, entry.EntryLength - entry.DataOffset);
            PerfDataFileStream.Read(Pointer(PerfCounters[idx].StringValue)^, entry.EntryLength - entry.DataOffset);
            PerfCounters[idx].StringValue := AnsiString(Trim(string(PerfCounters[idx].StringValue)));
          end
        else if PerfCounters[idx].DataType = SmallInt(Ord('J')) then
          begin
            PerfDataFileStream.ReadData(PerfCounters[idx].LongValue);
          end;

        EntryPos := PerfDataFileStream.Seek(EntryPos + entry.EntryLength, TSeekOrigin.soBeginning);
      end;

  finally
    if PerfDataFileStream <> nil then
      begin
        PerfDataFileStream.Free;
        CloseHandle(HPerfDataFile);
      end;
  end;

end;

function TPerfData.BuildValueString(PerfCounterValue: TPerfCounterValue): String;
begin

  case PerfCounterValue.DataUnits of
    U_None:   Result := IntToStr(PerfCounterValue.LongValue);
    U_Bytes:  Result := IntToStr(PerfCounterValue.LongValue) + ' bytes';
    U_Ticks:  Result := IntToStr(PerfCounterValue.LongValue) + ' ticks';
    U_Events: Result := IntToStr(PerfCounterValue.LongValue) + ' events';
    U_String: Result := string(PerfCounterValue.StringValue);
    U_Hertz:  Result := IntToStr(PerfCounterValue.LongValue) + ' Hz';
  end;

end;

end.
