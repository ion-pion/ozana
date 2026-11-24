MODULE Poze1;  (* POZE 1 (24 Nov 2026): a small app of its own that tries OllGL7, the pictures on the graphics card.
     Pion: "they will want fast games on mediocre hardware; so we will give them".
     Three textures made here, in Oberon, pixel by pixel:
       slot 0  a glowing ball, 64 x 64, with transparency (the sprite)
       slot 1  a little 8 x 8 cube in pixel art (Pixelat: sharp pixels, not smoothed)
       slot 2  a 512 x 512 background, the Z7 colours in waves
     Then the card draws the background over the whole screen and the sprites that fly, turn and bounce.
     Tap + and - to have 200 more or fewer (up to 4000), the number of frames a second is at the top.
     Build (the window ecran-cubn44.dex in $EULA_UNELTE):
       OLL2.Apk Motor2.Mod OllGL7.Mod Poze1.Mod "Poze 1"
   Pion & Claude, 24.11.2026 *)

  IMPORT Motor2, OllGL7, Math;

  CONST MS = 4000;

  VAR W, H, n, lCore, x0, y0: INTEGER; down, started, made: BOOLEAN;
    sx, sy, vx, vy, ang, va, sz: ARRAY MS OF REAL;
    kind: ARRAY MS OF INTEGER;
    bg, text, muted, gold, panel: INTEGER;
    seed: INTEGER;

  PROCEDURE Rnd(): REAL;   (* 0 .. 1 *)
  BEGIN seed := (seed * 75 + 74) MOD 65537   (* ZX81's: no number gets too big *)
    RETURN FLT(seed) / 65537.0
  END Rnd;

  PROCEDURE Clamp(v: INTEGER): INTEGER;
  BEGIN IF v < 0 THEN v := 0 ELSIF v > 255 THEN v := 255 END
    RETURN v
  END Clamp;

  PROCEDURE MakeBall;   (* slot 0: a ball of light, white in the middle, gold, then nothing *)
    VAR x, y, a: INTEGER; dx, dy, d: REAL;
  BEGIN
    OllGL7.Pixelat(FALSE);
    OllGL7.IncepeTextura(0, 64, 64);
    FOR y := 0 TO 63 DO
      FOR x := 0 TO 63 DO
        dx := FLT(x) - 31.5; dy := FLT(y) - 31.5; d := Math.sqrt(dx * dx + dy * dy) / 32.0;
        IF d >= 1.0 THEN OllGL7.PixelTextura(OllGL7.RGBA(0, 0, 0, 0))
        ELSE
          a := Clamp(FLOOR((1.0 - d) * (1.0 - d) * 400.0));
          OllGL7.PixelTextura(OllGL7.RGBA(255, Clamp(FLOOR(255.0 - d * 120.0)), Clamp(FLOOR(230.0 - d * 230.0)), a))
        END
      END
    END;
    OllGL7.GataTextura
  END MakeBall;

  PROCEDURE MakeCube;   (* slot 1: 8 x 8 pixel art *)
    VAR x, y, c: INTEGER;
  BEGIN
    OllGL7.Pixelat(TRUE);
    OllGL7.IncepeTextura(1, 8, 8);
    FOR y := 0 TO 7 DO
      FOR x := 0 TO 7 DO
        IF (x = 0) OR (y = 0) OR (x = 7) OR (y = 7) THEN c := OllGL7.RGB(20, 10, 40)
        ELSIF x + y < 7 THEN c := OllGL7.RGB(125, 211, 252)
        ELSIF x + y = 7 THEN c := OllGL7.RGB(240, 235, 250)
        ELSE c := OllGL7.RGB(147, 51, 234)
        END;
        OllGL7.PixelTextura(c)
      END
    END;
    OllGL7.GataTextura;
    OllGL7.Pixelat(FALSE)
  END MakeCube;

  PROCEDURE MakeBack;   (* slot 2: waves of colour, 512 x 512 *)
    VAR x, y: INTEGER; u, v, f: REAL;
  BEGIN
    OllGL7.IncepeTextura(2, 512, 512);
    FOR y := 0 TO 511 DO
      FOR x := 0 TO 511 DO
        u := FLT(x) / 512.0 * 6.2831853; v := FLT(y) / 512.0 * 6.2831853;
        f := Math.sin(u * 3.0) + Math.sin(v * 2.0 + u) + Math.sin((u + v) * 1.5);
        OllGL7.PixelTextura(OllGL7.RGB(Clamp(30 + FLOOR(f * 12.0)), Clamp(12 + FLOOR(f * 6.0)), Clamp(60 + FLOOR(f * 20.0))))
      END
    END;
    OllGL7.GataTextura
  END MakeBack;

  PROCEDURE Add(k: INTEGER);
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE (i < k) & (n < MS) DO
      sx[n] := Rnd() * FLT(W); sy[n] := Rnd() * FLT(H);
      vx[n] := (Rnd() - 0.5) * 6.0; vy[n] := (Rnd() - 0.5) * 6.0;
      ang[n] := Rnd() * 360.0; va[n] := (Rnd() - 0.5) * 8.0;
      IF Rnd() < 0.3 THEN kind[n] := 1; sz[n] := 24.0 + Rnd() * 24.0 ELSE kind[n] := 0; sz[n] := 20.0 + Rnd() * 40.0 END;
      INC(n); INC(i)
    END
  END Add;

  PROCEDURE Button(x, y, w: INTEGER; s: ARRAY OF CHAR);
  BEGIN OllGL7.Rotund2D(x, y, w, 64, 32, panel); OllGL7.Text2D(x + w DIV 2 - 9, y + 22, s, 3, text)
  END Button;

  PROCEDURE In(x, y, w, h: INTEGER): BOOLEAN;
  BEGIN RETURN (x0 >= x) & (x0 < x + w) & (y0 >= y) & (y0 < y + h)
  END In;

  PROCEDURE Frame;
    VAR i: INTEGER; p: REAL;
  BEGIN
    IF Motor2.Jos() & ~down THEN down := TRUE; x0 := Motor2.X(); y0 := Motor2.Y()
    ELSIF ~Motor2.Jos() & down THEN
      down := FALSE;
      IF In(W - 220, H - 100, 96, 64) THEN IF n >= 200 THEN n := n - 200 ELSE n := 0 END
      ELSIF In(W - 112, H - 100, 96, 64) THEN Add(200)
      END
    END;
    OllGL7.Incepe(bg);
    IF ~OllGL7.Texturi() THEN
      OllGL7.Text2D(24, 60, "POZE 1", 4, text);
      OllGL7.Text2D(24, 140, "THIS WINDOW HAS NO TEXTURES.", 2, gold);
      OllGL7.Text2D(24, 170, "PUT ECRAN-CUBN44.DEX AS ECRAN.DEX", 2, muted);
      OllGL7.Text2D(24, 196, "AND BUILD AGAIN.", 2, muted)
    ELSE
      IF ~made THEN MakeBall; MakeCube; MakeBack; made := TRUE END;
      OllGL7.Poza2D(0, 0, W, H, 2);
      p := Motor2.Pas();
      FOR i := 0 TO n - 1 DO
        sx[i] := sx[i] + vx[i] * p; sy[i] := sy[i] + vy[i] * p; ang[i] := ang[i] + va[i] * p;
        IF (sx[i] < 0.0) & (vx[i] < 0.0) OR (sx[i] > FLT(W)) & (vx[i] > 0.0) THEN vx[i] := -vx[i] END;
        IF (sy[i] < 0.0) & (vy[i] < 0.0) OR (sy[i] > FLT(H)) & (vy[i] > 0.0) THEN vy[i] := -vy[i] END;
        OllGL7.Sprite2D(sx[i], sy[i], sz[i], sz[i], ang[i], kind[i], -1)
      END;
      OllGL7.Rotund2D(12, 24, W - 24, 70, 20, panel);
      OllGL7.Text2D(28, 36, "POZE 1", 3, text);
      OllGL7.Numar2D(28, 66, n, 2, gold); OllGL7.Text2D(28 + 6 * 12, 66, "SPRITES", 2, muted);
      OllGL7.Numar2D(W DIV 2 + 40, 66, Motor2.Fps(), 2, gold); OllGL7.Text2D(W DIV 2 + 40 + 4 * 12, 66, "FPS", 2, muted);
      Button(W - 220, H - 100, 96, "-"); Button(W - 112, H - 100, 96, "+");
      OllGL7.Text2D(24, H - 78, "GL 7 . TEXTURES", 2, muted)
    END;
    OllGL7.Arata; Motor2.Arat
  END Frame;

  PROCEDURE Core(ev, val: INTEGER);
  BEGIN
    IF ev = Motor2.Scena THEN
      IF ~started THEN started := TRUE; W := Motor2.Latime(); H := Motor2.Inaltime(); Add(400) END
    ELSIF (ev = Motor2.Tick) & started THEN Frame
    END
  END Core;

BEGIN
  W := 1; H := 1; n := 0; down := FALSE; started := FALSE; made := FALSE; seed := 4228;
  bg := OllGL7.RGB(14, 4, 28); panel := OllGL7.RGBA(52, 22, 86, 255); text := OllGL7.RGB(240, 235, 250);
  muted := OllGL7.RGB(150, 140, 175); gold := OllGL7.RGB(212, 160, 23);
  lCore := Motor2.Litera("CORE", Core, {Motor2.Tick, Motor2.Scena});
  Motor2.Ruleaza
END Poze1.
