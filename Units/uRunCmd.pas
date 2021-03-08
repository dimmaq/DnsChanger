unit uRunCmd;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Types,
  System.DateUtils,
  Winapi.Windows
  //
  ;

const
  CMD_READ_INTERVAL = 1000;

type
  TRunCmd = class(TThread)
  private
    FCmd: string;
    FProcess: THandle;

    FStdOutBuf: AnsiString;
    FStdOutList: TStringList;
    FStrOutNewLine: Boolean;

    function StartCmd: Boolean;

    procedure AddStrOut(const ABuf: AnsiString);
  public
    constructor Create(const ACmd: string; const AOnDone: TNotifyEvent);
    destructor Destroy; override;
    property StdOut: TStringList read FStdOutList;
  protected
    procedure Execute; override;
  end;


implementation

uses
  System.Math,
  //
//  System.AnsiStrings,
  AcedCommon, AcedStrings,
  //

  uStringUtils, uGlobalFunctions;

function StrReadLn(var ABuf: AnsiString; out AOutLine: AnsiString): Boolean;
begin
  Result := (ABuf <> '') and (ABuf[Length(ABuf)] = #10);
  AOutLine := StrCut(ABuf, [#10]);
  Result := Result or (ABuf <> '')
end;

{ TSshThread }

constructor TRunCmd.Create(const ACmd: string; const AOnDone: TNotifyEvent);
begin
  FCmd := ACmd;
  inherited Create(True);

  FStdOutBuf := '';
  FStdOutList := TStringList.Create;
  FStrOutNewLine := True;

  OnTerminate := AOnDone
end;

destructor TRunCmd.Destroy;
begin
  FStdOutList.Free;
  inherited;
end;

procedure TRunCmd.AddStrOut(const ABuf: AnsiString);
var z: AnsiString;

  procedure AddLine;
  var s,ss: string;
  begin
    s := string(z);
    s := s.TrimRight([#13]);

    if FStrOutNewLine then
    begin
      FStdOutList.Add(s)
    end
    else
    begin
      if FStdOutList.Count = 0 then
      begin
        FStdOutList.Add(s)
      end
      else
      begin
        ss := FStdOutList[FStdOutList.Count - 1] + s;
        FStdOutList[FStdOutList.Count - 1] := ss;
      end;
    end;
  end;

begin
  FStdOutBuf := FStdOutBuf + ABuf;

  while StrReadLn(FStdOutBuf, z) do
  begin
    AddLine();
    FStrOutNewLine := True
  end;
  if z <> '' then
  begin
    AddLine();
    FStrOutNewLine := False
  end
end;

procedure TRunCmd.Execute;
begin
  StartCmd()
end;


function TRunCmd.StartCmd: Boolean;
const
  CReadBuffer = 900;
var
  saSecurity: TSecurityAttributes;
  hRead: THandle;
  hWrite: THandle;
  suiStartup: TStartupInfo;
  piProcess: TProcessInformation;
  pBuffer: array[0..CReadBuffer] of AnsiChar;
  dRead: DWord;
  dRunning: DWord;
  l_bol: BOOL;
begin
  Result := False;
  FProcess := INVALID_HANDLE_VALUE;
  saSecurity.nLength := SizeOf(TSecurityAttributes);
  saSecurity.bInheritHandle := True;
  saSecurity.lpSecurityDescriptor := nil;

  if CreatePipe(hRead, hWrite, @saSecurity, 0) then
  begin
    try
      FillChar(suiStartup, SizeOf(TStartupInfo), #0);
      suiStartup.cb := SizeOf(TStartupInfo);
      suiStartup.hStdInput := hRead;
      suiStartup.hStdOutput := hWrite;
      suiStartup.hStdError := hWrite;
      suiStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
      suiStartup.wShowWindow := SW_HIDE;

      l_bol := CreateProcess(nil, PChar(FCmd), @saSecurity,
        @saSecurity, True, NORMAL_PRIORITY_CLASS,
        nil, nil, suiStartup, piProcess);

      try
        if l_bol then
        begin
          FProcess := piProcess.hProcess;
          repeat
            dRunning := WaitForSingleObject(piProcess.hProcess, CMD_READ_INTERVAL);
            if Terminated then
              Break;
            repeat
              if Terminated then
                Break;

              dRead := 0;
              if not PeekNamedPipe(hRead, nil, 0, nil, @dRead, nil) then
                Break;
              if dRead = 0 then
                Break;
              if dRead > CReadBuffer then
                dRead := CReadBuffer;
              ReadFile(hRead, pBuffer[0], dRead, dRead, nil);
              pBuffer[dRead] := #0;
              OemToAnsi(pBuffer, pBuffer);
              AddStrOut(PAnsiChar(@pBuffer[0]));
            until (dRead < CReadBuffer);
          until (dRunning <> WAIT_TIMEOUT) or (Terminated);
          AddStrOut(#10);
          TerminateProcess(piProcess.hProcess, 0);
          FProcess := INVALID_HANDLE_VALUE;
          Result := True;
        end
      finally
        CloseHandle(piProcess.hProcess);
        CloseHandle(piProcess.hThread);
      end
    finally
      CloseHandle(hRead);
      CloseHandle(hWrite);
    end;
  end;
end;

end.
