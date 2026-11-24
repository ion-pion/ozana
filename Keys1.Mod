MODULE Keys1;  (* KEYS 1 (11 Nov 2026): the on-screen keyboard of Cubicum N, shared by the shell and the editor.
     Small and capital letters (SHIFT once = one capital, SHIFT twice = CAPS), SYM = the signs Oberon needs,
     << and >> move the cursor. The dot is next to SPACE. A hardware keyboard works too.
       Keys1.Draw(top, down, hit, x, y)   draws the keyboard at top and returns what was pressed:
         0 nothing, 8 delete, 13 enter, LEFT, RIGHT, or the character code
     Pion & Claude, 11.11.2026 *)

  IMPORT Ecran, Grafica, Text1;

  CONST KH* = 62; Height* = 5 * KH + 6; LEFT* = 1; RIGHT* = 2;
    SHIFTK = 3; SYMK = 4;

  VAR shift, caps, sym: BOOLEAN; hw, got: INTEGER; down, hitNow: BOOLEAN; mx, my: INTEGER;
    panel, gold, white, cyan, black: INTEGER;

  PROCEDURE In(x, y, w, h: INTEGER): BOOLEAN;
  BEGIN RETURN (mx >= x) & (mx < x + w) & (my >= y) & (my < y + h)
  END In;

  PROCEDURE Key(code, x, y, w: INTEGER; label: ARRAY OF CHAR; lit: BOOLEAN);
    VAR c: INTEGER;
  BEGIN
    IF (down & In(x, y, w, KH)) OR lit THEN c := gold ELSE c := panel END;
    Grafica.Dreptunghi(x + 2, y + 3, w - 4, KH - 6, c);
    IF c = gold THEN c := black ELSIF code < 32 THEN c := cyan ELSE c := white END;
    IF Text1.Len(label) * 18 > w - 8 THEN Text1.Centre(x + w DIV 2, y + KH DIV 2 - 7, label, 2, c)
    ELSE Text1.Centre(x + w DIV 2, y + KH DIV 2 - 11, label, 3, c)
    END;
    IF hitNow & In(x, y, w, KH) THEN got := code END
  END Key;

  PROCEDURE Row(s: ARRAY OF CHAR; x, y: INTEGER);
    VAR i, k: INTEGER; l: ARRAY 2 OF CHAR;
  BEGIN
    i := 0; l[1] := 0X;
    WHILE (i < LEN(s)) & (s[i] # 0X) DO
      k := ORD(s[i]);
      IF (k >= ORD("a")) & (k <= ORD("z")) & (shift OR caps) THEN k := k - 32 END;
      l[0] := CHR(k); Key(k, x + i * 54, y, 54, l, FALSE); INC(i)
    END
  END Row;

  PROCEDURE Reset*;   (* when a program gets the screen: forget keys pressed before *)
  BEGIN hw := Ecran.Citeste(16); shift := FALSE
  END Reset;

  PROCEDURE Draw*(top: INTEGER; isDown, hit: BOOLEAN; x, y: INTEGER): INTEGER;
    VAR k, u: INTEGER; r: ARRAY 12 OF CHAR;
  BEGIN
    down := isDown; hitNow := hit; mx := x; my := y; got := 0;
    Grafica.Dreptunghi(0, top - 4, Ecran.Latime(), Height + 4, black);
    IF sym THEN
      Row("()[]{};:=,", 0, top);
      Row("+-*/<>&~^|", 0, top + KH);
      r := "Q'#_@$%!?"; r[0] := 22X; Row(r, 27, top + 2 * KH);
      Key(SYMK, 0, top + 3 * KH, 81, "abc", FALSE);
      r := ".,B`0123"; r[2] := 5CX; Row(r, 81, top + 3 * KH)
    ELSE
      Row("1234567890", 0, top);
      Row("qwertyuiop", 0, top + KH);
      Row("asdfghjkl", 27, top + 2 * KH);
      IF caps THEN Key(SHIFTK, 0, top + 3 * KH, 81, "CAPS", TRUE)
      ELSE Key(SHIFTK, 0, top + 3 * KH, 81, "SHIFT", shift)
      END;
      Row("zxcvbnm", 81, top + 3 * KH)
    END;
    Key(8, 459, top + 3 * KH, Ecran.Latime() - 459, "DEL", FALSE);
    IF sym THEN Key(SYMK, 0, top + 4 * KH, 81, "ABC", TRUE) ELSE Key(SYMK, 0, top + 4 * KH, 81, "SYM", FALSE) END;
    Key(32, 81, top + 4 * KH, 162, "SPACE", FALSE);
    Key(ORD("."), 243, top + 4 * KH, 54, ".", FALSE);
    Key(LEFT, 297, top + 4 * KH, 54, "<<", FALSE);
    Key(RIGHT, 351, top + 4 * KH, 54, ">>", FALSE);
    Key(13, 405, top + 4 * KH, Ecran.Latime() - 405, "ENTER", FALSE);
    IF got = SHIFTK THEN
      IF caps THEN caps := FALSE; shift := FALSE ELSIF shift THEN caps := TRUE; shift := FALSE ELSE shift := TRUE END;
      got := 0
    ELSIF got = SYMK THEN sym := ~sym; got := 0
    ELSIF (got >= ORD("A")) & (got <= ORD("Z")) THEN shift := FALSE
    END;
    (* a real keyboard *)
    k := Ecran.Citeste(16);
    IF (k # hw) & (got = 0) THEN
      hw := k; u := Ecran.Citeste(15);
      IF (u = 10) OR (u = 13) OR (u = 1066) THEN got := 13
      ELSIF (u = 8) OR (u = 127) OR (u = 1067) THEN got := 8
      ELSIF u = 1021 THEN got := LEFT
      ELSIF u = 1022 THEN got := RIGHT
      ELSIF (u >= 32) & (u < 127) THEN got := u
      END
    END
    RETURN got
  END Draw;

BEGIN
  shift := FALSE; caps := FALSE; sym := FALSE; hw := 0;
  panel := Grafica.RGB(52, 22, 86); gold := Grafica.RGB(212, 160, 23); white := Grafica.RGB(240, 235, 250);
  cyan := Grafica.RGB(125, 211, 252); black := Grafica.RGB(10, 4, 20)
END Keys1.
