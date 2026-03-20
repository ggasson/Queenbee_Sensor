{-----------------------------------------------------------------------------
  Create_Universal_Pulse_Input.pas
  Builds a single-channel 24V universal (PNP/NPN) pulse input schematic sheet.

  NOTE:
  - This script places *generic* components with Designators + Comments.
  - You should later set each component’s LibReference / footprint to your library parts.
  - Wiring is left as net labels; you can wire visually or extend the script to draw wires.
-----------------------------------------------------------------------------}

procedure PlaceNetLabel(SchDoc : ISch_Document; const NetName : string; X, Y : Integer);
var
  NL : ISch_NetLabel;
begin
  NL := SchServer.SchObjectFactory(eNetLabel, eCreate_Default);
  NL.Text := NetName;
  NL.Location := Point(X, Y);
  SchDoc.AddSchObject(NL);
end;

procedure PlaceGenericComponent(SchDoc : ISch_Document;
  const Des, Comment, LibRef : string; X, Y : Integer);
var
  C : ISch_Component;
begin
  C := SchServer.SchObjectFactory(eSchComponent, eCreate_Default);
  C.Designator.Text := Des;
  C.Comment.Text := Comment;

  { Optional: if you know your library reference, set it here }
  if LibRef <> '' then
    C.LibReference := LibRef;

  C.Location := Point(X, Y);
  SchDoc.AddSchObject(C);
end;

procedure BuildSheet;
var
  WS    : IWorkspace;
  Prj   : IProject;
  SchDoc: ISch_Document;

  { Coordinates are in mils*? Altium uses internal units; Point(X,Y) is in coord units.
    You may need to adjust spacing based on your grid/units settings. }
  X0, Y0 : Integer;

begin
  WS := GetWorkspace;
  if WS = nil then exit;

  { Create a new schematic document }
  SchDoc := SchServer.CreateNewDocument('SCH');
  if SchDoc = nil then exit;

  { Open it }
  Client.OpenDocument('SCH', SchDoc.DM_FileName);
  Client.ShowDocument(SchDoc);

  SchServer.ProcessControl.PreProcess(SchDoc, '');

  try
    X0 := 1000;
    Y0 := 1000;

    { J1 - 3 pin field terminal }
    PlaceGenericComponent(SchDoc, 'J1', 'FIELD_TERMINAL_3P (+24V_F, SIG, 0V_F)', '',
                          X0, Y0);

    { Input protection + filter }
    PlaceGenericComponent(SchDoc, 'TVS1', 'SMBJ33A', '',
                          X0+1400, Y0-200);

    PlaceGenericComponent(SchDoc, 'R1', '10k', '',
                          X0+1400, Y0+200);

    PlaceGenericComponent(SchDoc, 'C1', '2.2nF', '',
                          X0+2000, Y0+600);

    { Divider }
    PlaceGenericComponent(SchDoc, 'R2', '1.0M', '',
                          X0+2600, Y0+200);

    PlaceGenericComponent(SchDoc, 'R3', '200k', '',
                          X0+2600, Y0+700);

    { VREF divider from +5V_F }
    PlaceGenericComponent(SchDoc, 'R4', '150k', '',
                          X0+4200, Y0-200);

    PlaceGenericComponent(SchDoc, 'R5', '100k', '',
                          X0+4200, Y0+300);

    { Comparator }
    PlaceGenericComponent(SchDoc, 'U1', 'Comparator (LMV331/TLV1701)', '',
                          X0+5200, Y0+250);

    { Hysteresis resistor }
    PlaceGenericComponent(SchDoc, 'R6', '4.7M (hysteresis)', '',
                          X0+6400, Y0+250);

    { Digital isolator }
    PlaceGenericComponent(SchDoc, 'U2', 'Digital Isolator (ISO7721/ADuM1201)', '',
                          X0+7600, Y0+250);

    { Net labels (field side) }
    PlaceNetLabel(SchDoc, '+24V_F',    X0+200,  Y0-500);
    PlaceNetLabel(SchDoc, 'SIG',       X0+200,  Y0-200);
    PlaceNetLabel(SchDoc, '0V_F',      X0+200,  Y0+100);

    PlaceNetLabel(SchDoc, 'SENSE_RAW', X0+1800, Y0+200);
    PlaceNetLabel(SchDoc, 'SENSE',     X0+3000, Y0+450);
    PlaceNetLabel(SchDoc, 'VREF',      X0+4500, Y0+80);

    PlaceNetLabel(SchDoc, '+5V_F',     X0+4000, Y0-600);

    PlaceNetLabel(SchDoc, 'ISO_IN',    X0+7100, Y0+250);
    PlaceNetLabel(SchDoc, 'ISO_OUT',   X0+8400, Y0+250);

    { MCU side net label }
    PlaceNetLabel(SchDoc, 'MCU_GPIO',  X0+9000, Y0+250);

    { Notes }
    PlaceGenericComponent(SchDoc, 'NOTE1',
      'Connect +24V_F/SIG/0V_F in parallel with existing PLC/sensor wiring. Divider load ~20uA @24V.',
      '',
      X0, Y0+1400);

  finally
    SchServer.ProcessControl.PostProcess(SchDoc, '');
    SchDoc.GraphicallyInvalidate;
  end;
end;

begin
  BuildSheet;
end.
