unit uParser;

{$mode objfpc}{$H+}

interface

uses
 // windows,
  Classes,
  SysUtils,
  uVar;

function pkgDivade(var in_Pkg: string): string;
function pkgParse(in_pkg : string) : TPackage;

implementation

function pkgDivade(var in_Pkg: string): string;
var i: integer;
begin
  if Pos(#15, in_Pkg) <> 0 then result := 'BREAK';
  Delete(in_pkg, 1, 1);
  if Pos(#15, in_pkg) = 0 then
     result := 'BREAK'
  else begin
    i := Pos(#15, in_pkg) - 1;
    result := Copy(in_pkg, 1, i);
    Delete(in_pkg, 1, i);
  end;
end;

function pkgParse(in_pkg : string) : TPackage;
var i, k     : integer;
    s, frase : string;
    frases   : array [0..127] of string;
begin
  result.pkID:=High(word);
  if in_pkg = 'BREAK' then Exit;
  k := 0;
  if length(in_pkg) <= 0 then Exit;

  for I := 1 to Length(in_pkg) do
    begin
      s := copy(in_pkg, i, 1);
      if s <> #6 then frase := frase + s
         else
           begin
             frases[k] := frase;
             inc(k);
             frase := '';
           end;
    end;
  frases[k] := frase;
  inc(k);
  result.pkID := StrToInt(frases[0]);
  for i := 1 to k - 1 do
      result.pkVars[i - 1] := frases[i];
end;



end.

