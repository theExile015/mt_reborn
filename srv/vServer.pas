program vServer;

{$mode objfpc}{$H+}

uses
  syncobjs,
  cthreads,
  SysUtils,
  lNet,
  lCommon,
  Crt,
  vVar,
  vNetCore,
  vServerLog,
  udb, uPkgProcessor, uCharManager;

begin
try
  Randomize;
  CS := TCriticalSection.Create;
  DB_Init;
  TCP := TLTCPTest.Create;
  TCP.Run;
finally
  DB_Free;
  TCP.Free;
  CS.Free;
end;
end.

