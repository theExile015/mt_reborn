unit uAdd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  EPS = 0.000001;

  pi      = 3.141592654;
  rad2deg = 57.29578049;
  deg2rad = 0.017453292;

type
  zglTLine = record
    x0, y0, x1, y1 : single;
  end;

  zglTCircle  = record
    cX, cY, Radius : single;
  end;

function line( x0, y0, x1, y1 : single ) : zglTLine;
function Circle( x, y, r : single) : zglTCircle;
function Distance( x0, y0, x1, y1 : single) : single;
function InSector( dir: byte; angle : single) : boolean;

function ArcTan2( dx, dy : Single ) : Single;
function m_Angle( x1, y1, x2, y2 : Single ) : Single;
function col2d_LineVsCircle( const Line : zglTLine; const Circle : zglTCircle ) : Boolean;

implementation

function line( x0, y0, x1, y1 : single ) : zglTLine;
begin
  result.x0:= x0;
  result.y0:= y0;
  result.x1:= x1;
  result.y1:= y1;
end;

function Circle( x, y, r : single) : zglTCircle;
begin
  result.cX:= x;
  result.cY:= y;
  result.Radius:=r;
end;

function Distance( x0, y0, x1, y1 : single) : single;
begin
  result := sqrt( sqr( x1 - x0 ) + sqr ( y1 - y0 ) );
end;

function InSector( dir: byte; angle : single) : boolean;
var aD: integer;
begin
  result := false;
  aD := round( (360 - angle) / 45 ) + 3;
  if aD > 7 then aD := aD - 8;
  if abs( dir - aD ) <= 1 then result := true;
  if ( dir = 0 ) and ( aD = 7 ) then result := true;
  if ( dir = 7 ) and ( aD = 0 ) then result := true;
end;

function ArcTan2( dx, dy : Single ) : Single;
begin
  Result := abs( ArcTan( dy / dx ) * ( 180 / pi ) );
end;

function m_Angle( x1, y1, x2, y2 : Single ) : Single;
  var
    dx, dy : Single;
begin
  dx := ( X1 - X2 );
  dy := ( Y1 - Y2 );

  if dx = 0 Then
    begin
      if dy > 0 Then
        Result := 90
      else
        Result := 270;
      exit;
    end;

  if dy = 0 Then
    begin
      if dx > 0 Then
        Result := 0
      else
        Result := 180;
      exit;
    end;

  if ( dx < 0 ) and ( dy > 0 ) Then
    Result := 180 - ArcTan2( dx, dy )
  else
    if ( dx < 0 ) and ( dy < 0 ) Then
      Result := 180 + ArcTan2( dx, dy )
    else
      if ( dx > 0 ) and ( dy < 0 ) Then
        Result := 360 - ArcTan2( dx, dy )
      else
        Result := ArcTan2( dx, dy )
end;

function col2d_LineVsCircle( const Line : zglTLine; const Circle : zglTCircle ) : Boolean;
  var
    p1, p2  : array[ 0..1 ] of Single;
    dx, dy  : Single;
    a, b, c : Single;
begin
  p1[ 0 ] := Line.x0 - Circle.cX;
  p1[ 1 ] := Line.y0 - Circle.cY;
  p2[ 0 ] := Line.x1 - Circle.cX;
  p2[ 1 ] := Line.y1 - Circle.cY;

  dx := p2[ 0 ] - p1[ 0 ];
  dy := p2[ 1 ] - p1[ 1 ];

  a := sqr( dx ) + sqr( dy );
  b := ( p1[ 0 ] * dx + p1[ 1 ] * dy ) * 2;
  c := sqr( p1[ 0 ] ) + sqr( p1[ 1 ] ) - sqr( Circle.Radius );

  if -b < 0 Then
    Result := c < 0
  else
    if -b < a * 2 Then
      Result := a * c * 4 - sqr( b )  < 0
    else
      Result := a + b + c < 0;
end;

end.

