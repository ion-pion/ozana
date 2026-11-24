MODULE Desk6;  (* DESK 6t (24 Nov 2026, Pixipogo 49): ABOUT 49 (Nora 18: share, private tabs, saved pages).
   DESK 6s (24 Nov 2026, Pixipogo 48): ABOUT 48 (Nora 17: tabs and downloads of any size).
   DESK 6r (24 Nov 2026, Pixipogo 47): ABOUT 47 (Nora 16: NewPipe and the films given freely, Filme 1).
   DESK 6q (24 Nov 2026, Pixipogo 46): ABOUT 46 (Nora 15: YouTube and TikTok in the window into the whole web).
   DESK 6p (24 Nov 2026, Pixipogo 45): ABOUT 45 (Nora 14, Pic 6: smoother pictures).
   DESK 6o (24 Nov 2026, Pixipogo 44): ABOUT 44 (pictures on the graphics card: OllGL7, Pic5, Nora 13).
   DESK 6n (24 Nov 2026, Pixipogo 43): the browser is NORA again (Pion: "take out chick"); ABOUT 43.
   DESK 6m (23 Nov 2026, Pixipogo 42): only ABOUT changes (PIXIPOGO 42, NORACHICK 11, PIC 3).
   DESK 6l (23 Nov 2026, Pixipogo 41): only ABOUT changes (PIXIPOGO 41, NORACHICK 10).
   DESK 6k (23 Nov 2026, Pixipogo 39): only ABOUT changes (PIXIPOGO 39, NORACHICK 9).
   DESK 6j (23 Nov 2026, Pixipogo 38): only ABOUT changes (PIXIPOGO 38, NORACHICK 8, PIC 2).
   DESK 6i (23 Nov 2026, Pixipogo 37): only ABOUT changes (PIXIPOGO 37, NORACHICK 7, PIC 1).
   DESK 6h (23 Nov 2026, Pixipogo 36): only ABOUT changes (PIXIPOGO 36, NORACHICK 6).
   DESK 6g (23 Nov 2026, Pixipogo 35): only ABOUT changes (PIXIPOGO 35, NORACHICK 5).
   DESK 6f (23 Nov 2026, Pixipogo 34): NORACHICK the browser sits in the dock next to ARIEL, where ECHO
     was (Pion: "the button should sit in the bottom bar next to synth; just take the player out and move it").
     ECHO stays in THE COURT. NoraChick is own program 16 there too (action 21, icon 23: a globe).
   DESK 6e (21 Nov 2026, Pixipogo 30): QUINCE the notebook (action 19, icon 21, and the icon of .txt) and
     CERES the recorder (action 20, icon 22); .amr is a sound too.
   DESK 6d (20 Nov 2026, Cubicum N 28): JUNO, the films (action 18), icon 20 (a strip of film), and the
     icon of video files.
   DESK 6c (20 Nov 2026, Cubicum N 27): the system is PIXIPOGO (tab, ABOUT, the messages).
  DESK 6b (20 Nov 2026, Cubicum N 24): two more fairies, PHILOMEL music (action 16) and PEASEBLOSSOM books
     (action 17), their icons (18 a note, 19 a book) and the icons of sound files and of .pdf.
   DESK 6 (20 Nov 2026, Cubicum N 19): the court of Oberon. Pion: "Oberon still needs fairies ... let all the
     programs have fairy names". ARIEL synth, ECHO player, OBERON shell, MAB canvas, COBWEB files, TITANIA settings,
     PUCK tasks, MUSTARDSEED calc, MOTH clock, IRIS images, ROBIN help; APPS is THE COURT. Under each name, small,
     what it does. FairyName and Job give them to the other screens.
   DESK 5 (20 Nov 2026, Cubicum N 18): the new tools in APPS (TASKS, CALC, CLOCK, IMAGES, HELP), their icons,
     and the actions 11..15 for them.
   DESK 4 (19 Nov 2026, Cubicum N 17): with 121 apps on the host the icons ate every triangle of the frame
     and the title and the tabs were gone: now OllGL6 (40000 triangles) and each icon takes less detail when the frame
     fills up (32, 16, 8 squares, then only its colour), so the header and the bars always have room. An icon not read yet
     is a grey square.
   DESK 3 (19 Nov 2026, Cubicum N 16): the host's icons at 32 x 32 (Gazda2), drawn with runs of close
     colours; BYZ7 and INSTALL open the terminal activity of their app.
   DESK 2 (19 Nov 2026, Cubicum N 15): Desk 1 plus SETTINGS (accent colour, boot animation, the cube that
     turns by itself, FPS; ABOUT) kept in desk.cfg, FILES in the dock, and one list of actions for all screens:
     -1 HOME, 1 SYNTH, 2 PLAYER, 3 SHELL, 4 APPS, 5 CANVAS, 6 FILES, 7 SETTINGS, 8 BOOT again, 10 RUN the chosen program,
     11 TASKS, 12 CALC, 13 CLOCK, 14 IMAGES, 15 HELP.
   DESK 1 (19 Nov 2026): the desktop of Cubicum N 14. Pion: "I want Cubicum N to look like a
     professional operating system (even if it is only a game)".
   The status bar (clock, the host, battery), the clock on the home screen, the dock (SYNTH, PLAYER, SHELL, APPS)
   and the APPS drawer with three tabs:
     CUBICUM N  its own programs, the tools (INSTALL = Crisalida, BYZ7) and the programs in the cube (.mod, .z7)
     JAHBALON   Pion's apps on the host (ro.jahbalon...)
     ANDROID    every other app of the host
   The host comes from Gazda1; with no host (bare metal) the last two tabs say so.
   Pion & Claude, 19.11.2026 *)

  IMPORT OllGL6, Gazda4, Fs2, Fisier;

  CONST
    NI = 300;   (* items in the drawer *)
    kHead = 0; kOwn = 1; kTool = 2; kProg = 3; kHost = 4;   (* kinds of items *)
    BAR* = 40;   (* height of the status bar *)

  VAR
    W, H, tab, nIt, scroll0, x0, y0, sMax, tMsg: INTEGER;
    scroll: ARRAY 3 OF INTEGER;
    down, moved, asked: BOOLEAN;
    itK, itV: ARRAY NI OF INTEGER;   (* kind, value: own program number, host app number, file number *)
    itX, itY: ARRAY NI OF INTEGER;
    chosen: ARRAY 40 OF CHAR;
    msg: ARRAY 60 OF CHAR;
    frames, accent, sTop: INTEGER; spin, boot, fps: BOOLEAN;
    sw0, sDown: BOOLEAN;
    bg*, surface*, surface2*, edge*, text*, muted*, gold*, cyan, green*, red*, violet, dark*: INTEGER;

  (* ---------- little helpers ---------- *)

  PROCEDURE Len(s: ARRAY OF CHAR): INTEGER;
    VAR n: INTEGER;
  BEGIN n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END
    RETURN n
  END Len;

  PROCEDURE Copy(s: ARRAY OF CHAR; VAR d: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) & (i < LEN(d) - 1) DO d[i] := s[i]; INC(i) END; d[i] := 0X
  END Copy;

  PROCEDURE AccentOf(k: INTEGER): INTEGER;
    VAR c: INTEGER;
  BEGIN
    IF k = 1 THEN c := OllGL6.RGB(56, 189, 248) ELSIF k = 2 THEN c := OllGL6.RGB(74, 222, 128)
    ELSIF k = 3 THEN c := OllGL6.RGB(167, 139, 250) ELSIF k = 4 THEN c := OllGL6.RGB(244, 114, 182)
    ELSE c := OllGL6.RGB(212, 160, 23)
    END
    RETURN c
  END AccentOf;

  PROCEDURE Save;   (* the settings, in desk.cfg *)
    VAR h: INTEGER;
  BEGIN
    h := Fisier.Creeaza("desk.cfg");
    IF h >= 0 THEN
      Fisier.Scrie(h, 68); Fisier.Scrie(h, accent); Fisier.Scrie(h, ORD(spin)); Fisier.Scrie(h, ORD(boot)); Fisier.Scrie(h, ORD(fps));
      Fisier.Gata(h)
    END
  END Save;

  PROCEDURE Load;
    VAR h: INTEGER;
  BEGIN
    h := Fisier.Deschide("desk.cfg");
    IF h >= 0 THEN
      IF Fisier.Citeste(h) = 68 THEN
        accent := Fisier.Citeste(h); spin := Fisier.Citeste(h) = 1; boot := Fisier.Citeste(h) = 1; fps := Fisier.Citeste(h) = 1;
        IF (accent < 0) OR (accent > 4) THEN accent := 0 END
      END;
      Fisier.Gata(h)
    END;
    gold := AccentOf(accent)
  END Load;

  PROCEDURE Spin*(): BOOLEAN; BEGIN RETURN spin END Spin;
  PROCEDURE BootOn*(): BOOLEAN; BEGIN RETURN boot END BootOn;
  PROCEDURE ShowFps*(): BOOLEAN; BEGIN RETURN fps END ShowFps;
  PROCEDURE Accent*(): INTEGER; BEGIN RETURN gold END Accent;

  PROCEDURE Centre*(cx, y: INTEGER; s: ARRAY OF CHAR; m, c: INTEGER);
  BEGIN OllGL6.Text2D(cx - (Len(s) * 6 * m - m) DIV 2, y, s, m, c)
  END Centre;

  PROCEDURE Right*(rx, y: INTEGER; s: ARRAY OF CHAR; m, c: INTEGER);
  BEGIN OllGL6.Text2D(rx - (Len(s) * 6 * m - m), y, s, m, c)
  END Right;

  PROCEDURE Two(n: INTEGER; VAR s: ARRAY OF CHAR; VAR k: INTEGER);   (* n as two digits at s[k] *)
  BEGIN s[k] := CHR(ORD("0") + n DIV 10 MOD 10); s[k + 1] := CHR(ORD("0") + n MOD 10); k := k + 2; s[k] := 0X
  END Two;

  PROCEDURE Add(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN k := Len(s); i := 0; WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END; s[k] := 0X
  END Add;

  PROCEDURE AddN(VAR s: ARRAY OF CHAR; n: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k, j: INTEGER;
  BEGIN
    k := 0; IF n < 0 THEN n := 0 END;
    REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    j := Len(s); WHILE (k > 0) & (j < LEN(s) - 1) DO DEC(k); s[j] := d[k]; INC(j) END; s[j] := 0X
  END AddN;

  PROCEDURE Fit(VAR s: ARRAY OF CHAR; n: INTEGER);   (* at most n letters; a long name ends in a dot *)
    VAR k: INTEGER;
  BEGIN
    IF Len(s) > n THEN
      k := n - 1; WHILE (k > 1) & (s[k - 1] = " ") DO DEC(k) END;
      s[k] := "."; s[k + 1] := 0X
    END
  END Fit;

  PROCEDURE Say*(s: ARRAY OF CHAR);   (* a message at the bottom for a moment *)
  BEGIN Copy(s, msg); tMsg := 90
  END Say;

  PROCEDURE Ends(VAR s: ARRAY OF CHAR; e: ARRAY OF CHAR): BOOLEAN;
    VAR n, m, i: INTEGER; ok: BOOLEAN;
  BEGIN
    n := Len(s); m := Len(e); ok := n > m; i := 0;
    WHILE ok & (i < m) DO IF s[n - m + i] # e[i] THEN ok := FALSE END; INC(i) END
    RETURN ok
  END Ends;

  (* ---------- the status bar ---------- *)

  PROCEDURE Status*;   (* the bar at the top of every screen *)
    VAR s: ARRAY 24 OF CHAR; k, b, fill, c: INTEGER;
  BEGIN
    OllGL6.Dreptunghi2D(0, 0, W, BAR, dark);
    s[0] := 0X; k := 0;
    IF Gazda4.HasClock() THEN Two(Gazda4.Clock(3), s, k); s[k] := ":"; INC(k); Two(Gazda4.Clock(4), s, k) ELSE s := "--:--" END;
    OllGL6.Text2D(16, 13, s, 2, text);
    Gazda4.System(s); Centre(W DIV 2, 16, s, 1, muted);
    b := Gazda4.Battery();
    IF b >= 0 THEN
      c := text; IF b <= 15 THEN c := red ELSIF Gazda4.Charging() THEN c := green END;
      OllGL6.Rotund2D(W - 46, 12, 30, 16, 3, muted); OllGL6.Rotund2D(W - 44, 14, 26, 12, 2, dark);
      OllGL6.Dreptunghi2D(W - 16, 17, 3, 6, muted);
      fill := 24 * b DIV 100; IF fill < 1 THEN fill := 1 END;
      OllGL6.Dreptunghi2D(W - 43, 15, fill, 10, c);
      s[0] := 0X; AddN(s, b); Add(s, "%"); Right(W - 54, 13, s, 2, c)
    END
  END Status;

  (* ---------- icons ---------- *)

  PROCEDURE Near(a, b: INTEGER): BOOLEAN;   (* two colours of an icon that can be one rectangle *)
    VAR d: INTEGER;
  BEGIN
    a := a + 16777216; b := b + 16777216;
    d := ABS(a MOD 256 - b MOD 256) + ABS(a DIV 256 MOD 256 - b DIV 256 MOD 256) + ABS(a DIV 65536 MOD 256 - b DIV 65536 MOD 256)
    RETURN d <= 36
  END Near;

  PROCEDURE HostIcon(i, x, y, sz: INTEGER);   (* the host's own icon of app i, 32 x 32 in sz x sz *)
    VAR r, b, i0, c, p, st, free: INTEGER;
  BEGIN
    free := OllGL6.Liber2D();
    IF ~Gazda4.IconReady(i) THEN OllGL6.Rotund2D(x + 4, y + 4, sz - 8, sz - 8, sz DIV 5, surface2)   (* still coming *)
    ELSIF free < 5000 THEN   (* the frame is almost full: only the colour of its middle *)
      c := Gazda4.Pixel(i, Gazda4.IC DIV 2, Gazda4.IC DIV 2); IF c = 0 THEN c := edge END;
      OllGL6.Rotund2D(x + 4, y + 4, sz - 8, sz - 8, sz DIV 5, c)
    ELSE
      IF free > 20000 THEN st := 1 ELSIF free > 11000 THEN st := 2 ELSE st := 4 END;
      p := sz DIV Gazda4.IC * st;
      r := 0;
      WHILE r < Gazda4.IC DO
        b := 0;
        WHILE b < Gazda4.IC DO
          c := Gazda4.Pixel(i, b, r);
          IF c # 0 THEN
            i0 := b; b := b + st;
            WHILE (b < Gazda4.IC) & (Gazda4.Pixel(i, b, r) # 0) & Near(Gazda4.Pixel(i, b, r), c) DO b := b + st END;
            OllGL6.Dreptunghi2D(x + i0 * p DIV st, y + r * p DIV st, (b - i0) * p DIV st, p, c)
          ELSE b := b + st
          END
        END;
        r := r + st
      END
    END
  END HostIcon;

  PROCEDURE Cos8(k: INTEGER): REAL;   (* the 8 directions *)
    VAR r: REAL;
  BEGIN
    k := k MOD 8;
    IF k = 0 THEN r := 1.0 ELSIF (k = 1) OR (k = 7) THEN r := 0.7071 ELSIF (k = 2) OR (k = 6) THEN r := 0.0
    ELSIF (k = 3) OR (k = 5) THEN r := -0.7071 ELSE r := -1.0 END
    RETURN r
  END Cos8;

  PROCEDURE Sin8(k: INTEGER): REAL;
  BEGIN RETURN Cos8(k + 6)
  END Sin8;

  PROCEDURE Glyph*(kind, x, y, sz: INTEGER);   (* the drawn icons of Cubicum N: 0 synth 1 player 2 shell 3 apps 4 canvas
                                                  5 install 6 byz7 7 .mod 8 .z7 9 files 10 settings 11 .z7c 12 text
                                                  13 tasks 14 calc 15 clock 16 images (and a picture file) 17 help
                                                  18 music (and a sound file) 19 books (and a .pdf) 20 films (and a video)
                                                  21 notes (and a .txt) 22 the recorder 23 the web (NoraChick) *)
    VAR k, u, c: INTEGER;
  BEGIN
    u := sz DIV 8;
    IF kind = 0 THEN c := gold ELSIF kind = 1 THEN c := green ELSIF kind = 2 THEN c := dark ELSIF kind = 3 THEN c := violet
    ELSIF kind = 4 THEN c := cyan ELSIF kind = 5 THEN c := OllGL6.RGB(236, 112, 99) ELSIF kind = 6 THEN c := OllGL6.RGB(90, 60, 140)
    ELSIF kind = 7 THEN c := OllGL6.RGB(40, 110, 160) ELSIF kind = 8 THEN c := OllGL6.RGB(150, 100, 20)
    ELSIF kind = 9 THEN c := OllGL6.RGB(56, 120, 200) ELSIF kind = 10 THEN c := OllGL6.RGB(90, 90, 110)
    ELSIF kind = 11 THEN c := OllGL6.RGB(110, 50, 170) ELSIF kind = 13 THEN c := OllGL6.RGB(20, 90, 80)
    ELSIF kind = 14 THEN c := OllGL6.RGB(60, 60, 72) ELSIF kind = 15 THEN c := OllGL6.RGB(30, 30, 40)
    ELSIF kind = 16 THEN c := OllGL6.RGB(80, 150, 220) ELSIF kind = 17 THEN c := OllGL6.RGB(200, 90, 40)
    ELSIF kind = 18 THEN c := OllGL6.RGB(170, 40, 110) ELSIF kind = 19 THEN c := OllGL6.RGB(190, 60, 60)
    ELSIF kind = 20 THEN c := OllGL6.RGB(40, 40, 60) ELSIF kind = 21 THEN c := OllGL6.RGB(70, 120, 90)
    ELSIF kind = 22 THEN c := OllGL6.RGB(200, 50, 70) ELSIF kind = 23 THEN c := OllGL6.RGB(24, 70, 120)
    ELSE c := OllGL6.RGB(70, 70, 90)
    END;
    OllGL6.Rotund2D(x, y, sz, sz, sz DIV 4, c);
    IF kind = 2 THEN OllGL6.Inel2D(x + sz DIV 2, y + sz DIV 2, sz DIV 2 - 1, 1, edge) END;
    IF kind = 0 THEN   (* keys *)
      FOR k := 0 TO 4 DO OllGL6.Dreptunghi2D(x + u + k * (6 * u DIV 5), y + 2 * u, 6 * u DIV 5 - 2, 4 * u, text) END;
      FOR k := 0 TO 3 DO IF k # 1 THEN OllGL6.Dreptunghi2D(x + u + k * (6 * u DIV 5) + 6 * u DIV 5 - 4, y + 2 * u, 5, 5 * u DIV 2, dark) END END
    ELSIF kind = 1 THEN OllGL6.Triunghi2D(x + 3 * u, y + 2 * u, x + 3 * u, y + 6 * u, x + 6 * u, y + 4 * u, dark)
    ELSIF kind = 2 THEN OllGL6.Text2D(x + 2 * u, y + 3 * u, ">_", sz DIV 24, green)
    ELSIF kind = 3 THEN
      FOR k := 0 TO 8 DO OllGL6.Cerc2D(x + 2 * u + (k MOD 3) * 2 * u, y + 2 * u + (k DIV 3) * 2 * u, u DIV 2 + 1, text) END
    ELSIF kind = 4 THEN
      OllGL6.Rotund2D(x + 3 * u DIV 2, y + 3 * u DIV 2, 5 * u, 5 * u, u DIV 2, text);
      OllGL6.Cerc2D(x + 3 * u, y + 3 * u, u, red); OllGL6.Dreptunghi2D(x + 4 * u, y + 4 * u, 2 * u, 2 * u, gold)
    ELSIF kind = 5 THEN   (* the chrysalis: an egg in a ring *)
      OllGL6.Inel2D(x + 4 * u, y + 4 * u, 3 * u, u DIV 2 + 1, text); OllGL6.Cerc2D(x + 4 * u, y + 4 * u, 3 * u DIV 2, text)
    ELSIF kind = 6 THEN OllGL6.Text2D(x + u + 2, y + 3 * u, "B7", sz DIV 20, gold)
    ELSIF kind = 7 THEN OllGL6.Text2D(x + u + 2, y + 3 * u, "OB", sz DIV 20, text)
    ELSIF kind = 8 THEN OllGL6.Text2D(x + u + 2, y + 3 * u, "Z7", sz DIV 20, text)
    ELSIF kind = 9 THEN   (* a folder *)
      OllGL6.Rotund2D(x + 3 * u DIV 2, y + 2 * u, 2 * u, u + 2, u DIV 3, OllGL6.RGB(250, 210, 90));
      OllGL6.Rotund2D(x + 3 * u DIV 2, y + 3 * u - 2, 5 * u, 7 * u DIV 2, u DIV 2, OllGL6.RGB(250, 210, 90))
    ELSIF kind = 10 THEN   (* a gear *)
      FOR k := 0 TO 7 DO
        OllGL6.Cerc2D(x + 4 * u + FLOOR(2.6 * FLT(u) * Cos8(k)), y + 4 * u + FLOOR(2.6 * FLT(u) * Sin8(k)), u * 2 DIV 3 + 1, text)
      END;
      OllGL6.Cerc2D(x + 4 * u, y + 4 * u, 5 * u DIV 2, text); OllGL6.Cerc2D(x + 4 * u, y + 4 * u, u, c)
    ELSIF kind = 11 THEN   (* a cube seen from a corner *)
      OllGL6.Triunghi2D(x + 4 * u, y + u, x + 7 * u, y + 5 * u DIV 2, x + 4 * u, y + 4 * u, gold);
      OllGL6.Triunghi2D(x + 4 * u, y + u, x + 4 * u, y + 4 * u, x + u, y + 5 * u DIV 2, gold);
      OllGL6.Triunghi2D(x + u, y + 5 * u DIV 2, x + 4 * u, y + 4 * u, x + 4 * u, y + 7 * u, text);
      OllGL6.Triunghi2D(x + u, y + 5 * u DIV 2, x + 4 * u, y + 7 * u, x + u, y + 11 * u DIV 2, text);
      OllGL6.Triunghi2D(x + 4 * u, y + 4 * u, x + 7 * u, y + 5 * u DIV 2, x + 7 * u, y + 11 * u DIV 2, muted);
      OllGL6.Triunghi2D(x + 4 * u, y + 4 * u, x + 7 * u, y + 11 * u DIV 2, x + 4 * u, y + 7 * u, muted)
    ELSIF kind = 13 THEN   (* tasks: the seven turns of the spiral *)
      FOR k := 0 TO 6 DO
        OllGL6.Cerc2D(x + 4 * u + FLOOR(FLT(u) * (0.4 + 0.4 * FLT(k)) * Cos8(k * 3)), y + 4 * u + FLOOR(FLT(u) * (0.4 + 0.4 * FLT(k)) * Sin8(k * 3)),
          u DIV 3 + 2, green)
      END
    ELSIF kind = 14 THEN   (* calc: keys *)
      OllGL6.Rotund2D(x + 3 * u DIV 2, y + 3 * u DIV 2, 5 * u, 3 * u DIV 2, 3, OllGL6.RGB(160, 220, 170));
      FOR k := 0 TO 5 DO OllGL6.Rotund2D(x + 3 * u DIV 2 + (k MOD 3) * 7 * u DIV 4, y + 7 * u DIV 2 + (k DIV 3) * 3 * u DIV 2, 3 * u DIV 2, u + 2, 3, text) END
    ELSIF kind = 15 THEN   (* clock: a dial and two hands *)
      OllGL6.Cerc2D(x + 4 * u, y + 4 * u, 3 * u, text); OllGL6.Cerc2D(x + 4 * u, y + 4 * u, 3 * u - 3, c);
      OllGL6.Linie2D(x + 4 * u, y + 4 * u, x + 4 * u, y + 2 * u, 3, gold); OllGL6.Linie2D(x + 4 * u, y + 4 * u, x + 11 * u DIV 2, y + 4 * u, 3, text)
    ELSIF kind = 16 THEN   (* images: a hill and the sun *)
      OllGL6.Rotund2D(x + 3 * u DIV 2, y + 3 * u DIV 2, 5 * u, 5 * u, u DIV 2, OllGL6.RGB(200, 230, 255));
      OllGL6.Cerc2D(x + 5 * u, y + 3 * u, u, gold);
      OllGL6.Triunghi2D(x + 3 * u DIV 2, y + 13 * u DIV 2, x + 7 * u DIV 2, y + 7 * u DIV 2, x + 6 * u, y + 13 * u DIV 2, OllGL6.RGB(40, 140, 70))
    ELSIF kind = 17 THEN OllGL6.Text2D(x + 5 * u DIV 2, y + 2 * u, "?", sz DIV 13, text)
    ELSIF kind = 18 THEN   (* music: two notes on a beam *)
      OllGL6.Cerc2D(x + 5 * u DIV 2, y + 11 * u DIV 2, u, text); OllGL6.Cerc2D(x + 11 * u DIV 2, y + 5 * u, u, text);
      OllGL6.Dreptunghi2D(x + 7 * u DIV 2 - 3, y + 2 * u, 3, 7 * u DIV 2, text); OllGL6.Dreptunghi2D(x + 13 * u DIV 2 - 3, y + 3 * u DIV 2, 3, 7 * u DIV 2, text);
      OllGL6.Triunghi2D(x + 7 * u DIV 2 - 3, y + 2 * u, x + 13 * u DIV 2, y + 3 * u DIV 2 - 2, x + 13 * u DIV 2, y + 5 * u DIV 2 - 2, gold);
      OllGL6.Triunghi2D(x + 7 * u DIV 2 - 3, y + 2 * u, x + 13 * u DIV 2, y + 5 * u DIV 2 - 2, x + 7 * u DIV 2 - 3, y + 3 * u, gold)
    ELSIF kind = 20 THEN   (* films: a strip with its holes, a play sign in the middle *)
      OllGL6.Rotund2D(x + u, y + 3 * u DIV 2, 6 * u, 5 * u, u DIV 2, text);
      FOR k := 0 TO 4 DO
        OllGL6.Dreptunghi2D(x + 3 * u DIV 2 + k * 5 * u DIV 4, y + 2 * u, u DIV 2 + 1, u DIV 2 + 1, c);
        OllGL6.Dreptunghi2D(x + 3 * u DIV 2 + k * 5 * u DIV 4, y + 11 * u DIV 2, u DIV 2 + 1, u DIV 2 + 1, c)
      END;
      OllGL6.Triunghi2D(x + 7 * u DIV 2, y + 3 * u, x + 7 * u DIV 2, y + 5 * u, x + 5 * u, y + 4 * u, gold)
    ELSIF kind = 21 THEN   (* notes: a page with lines and a pencil *)
      OllGL6.Rotund2D(x + 3 * u DIV 2, y + u, 5 * u, 6 * u, u DIV 2, text);
      FOR k := 0 TO 3 DO OllGL6.Dreptunghi2D(x + 2 * u, y + 2 * u + k * u * 5 DIV 4, 4 * u - 2 * (k MOD 2) * u DIV 2, 2, muted) END;
      OllGL6.Triunghi2D(x + 5 * u, y + 6 * u, x + 7 * u, y + 2 * u, x + 15 * u DIV 2, y + 5 * u DIV 2, gold);
      OllGL6.Triunghi2D(x + 5 * u, y + 6 * u, x + 15 * u DIV 2, y + 5 * u DIV 2, x + 11 * u DIV 2, y + 25 * u DIV 4, gold)
    ELSIF kind = 22 THEN   (* the recorder: a microphone on its stand *)
      OllGL6.Rotund2D(x + 3 * u, y + u, 2 * u, 7 * u DIV 2, u, text);
      OllGL6.Dreptunghi2D(x + 4 * u - 1, y + 9 * u DIV 2, 3, 3 * u DIV 2, text);
      OllGL6.Rotund2D(x + 5 * u DIV 2, y + 6 * u, 3 * u, u DIV 2 + 2, u DIV 4, text);
      OllGL6.Cerc2D(x + 4 * u, y + 2 * u, u DIV 2, OllGL6.RGB(240, 60, 70))
    ELSIF kind = 23 THEN   (* the web: a globe with its meridians *)
      OllGL6.Cerc2D(x + 4 * u, y + 4 * u, 3 * u, cyan); OllGL6.Cerc2D(x + 4 * u, y + 4 * u, 3 * u - 3, c);
      OllGL6.Inel2D(x + 4 * u, y + 4 * u, 3 * u, 2, cyan);
      OllGL6.Dreptunghi2D(x + u, y + 4 * u - 1, 6 * u, 3, cyan);
      OllGL6.Dreptunghi2D(x + 4 * u - 1, y + u, 3, 6 * u, cyan);
      OllGL6.Dreptunghi2D(x + 3 * u DIV 2, y + 5 * u DIV 2, 5 * u, 2, cyan); OllGL6.Dreptunghi2D(x + 3 * u DIV 2, y + 11 * u DIV 2, 5 * u, 2, cyan);
      OllGL6.Inel2D(x + 4 * u, y + 4 * u, 3 * u DIV 2, 2, cyan)
    ELSIF kind = 19 THEN   (* books: an open book *)
      OllGL6.Triunghi2D(x + u, y + 2 * u, x + 4 * u, y + 5 * u DIV 2, x + 4 * u, y + 13 * u DIV 2, text);
      OllGL6.Triunghi2D(x + u, y + 2 * u, x + 4 * u, y + 13 * u DIV 2, x + u, y + 6 * u, text);
      OllGL6.Triunghi2D(x + 4 * u, y + 5 * u DIV 2, x + 7 * u, y + 2 * u, x + 7 * u, y + 6 * u, text);
      OllGL6.Triunghi2D(x + 4 * u, y + 5 * u DIV 2, x + 7 * u, y + 6 * u, x + 4 * u, y + 13 * u DIV 2, text);
      FOR k := 0 TO 2 DO
        OllGL6.Dreptunghi2D(x + 3 * u DIV 2, y + 3 * u + k * u, 2 * u, 2, muted); OllGL6.Dreptunghi2D(x + 9 * u DIV 2, y + 3 * u + k * u, 2 * u, 2, muted)
      END;
      OllGL6.Dreptunghi2D(x + 4 * u - 1, y + 5 * u DIV 2, 2, 4 * u, gold)
    ELSE   (* text: lines on a page *)
      OllGL6.Rotund2D(x + 2 * u, y + 3 * u DIV 2, 4 * u, 5 * u, u DIV 2, text);
      FOR k := 0 TO 3 DO OllGL6.Dreptunghi2D(x + 5 * u DIV 2, y + 5 * u DIV 2 + k * u, 3 * u, 2, muted) END
    END
  END Glyph;

  PROCEDURE KindOf*(VAR nm: ARRAY OF CHAR): INTEGER;   (* the icon of a file by its ending *)
    VAR k: INTEGER;
  BEGIN
    IF Ends(nm, ".mod") THEN k := 7 ELSIF Ends(nm, ".z7") THEN k := 8 ELSIF Ends(nm, ".z7c") THEN k := 11
    ELSIF Ends(nm, ".bmp") OR Ends(nm, ".ppm") OR Ends(nm, ".pgm") THEN k := 16
    ELSIF Ends(nm, ".mp3") OR Ends(nm, ".ogg") OR Ends(nm, ".wav") OR Ends(nm, ".m4a") OR Ends(nm, ".flac") OR Ends(nm, ".aac")
      OR Ends(nm, ".opus") OR Ends(nm, ".mid") OR Ends(nm, ".amr") THEN k := 18
    ELSIF Ends(nm, ".pdf") THEN k := 19
    ELSIF Ends(nm, ".mp4") OR Ends(nm, ".mkv") OR Ends(nm, ".webm") OR Ends(nm, ".3gp") OR Ends(nm, ".avi") OR Ends(nm, ".mov")
      OR Ends(nm, ".m4v") THEN k := 20
    ELSIF Ends(nm, ".txt") THEN k := 21
    ELSE k := 12 END
    RETURN k
  END KindOf;

  (* ---------- home ---------- *)

  PROCEDURE DayName(d: INTEGER; VAR s: ARRAY OF CHAR);
  BEGIN
    IF d = 0 THEN Copy("MONDAY", s) ELSIF d = 1 THEN Copy("TUESDAY", s) ELSIF d = 2 THEN Copy("WEDNESDAY", s) ELSIF d = 3 THEN Copy("THURSDAY", s)
    ELSIF d = 4 THEN Copy("FRIDAY", s) ELSIF d = 5 THEN Copy("SATURDAY", s) ELSE Copy("SUNDAY", s) END
  END DayName;

  PROCEDURE MonthName(m: INTEGER; VAR s: ARRAY OF CHAR);
  BEGIN
    IF m = 1 THEN Copy("JANUARY", s) ELSIF m = 2 THEN Copy("FEBRUARY", s) ELSIF m = 3 THEN Copy("MARCH", s) ELSIF m = 4 THEN Copy("APRIL", s)
    ELSIF m = 5 THEN Copy("MAY", s) ELSIF m = 6 THEN Copy("JUNE", s) ELSIF m = 7 THEN Copy("JULY", s) ELSIF m = 8 THEN Copy("AUGUST", s)
    ELSIF m = 9 THEN Copy("SEPTEMBER", s) ELSIF m = 10 THEN Copy("OCTOBER", s) ELSIF m = 11 THEN Copy("NOVEMBER", s) ELSE Copy("DECEMBER", s) END
  END MonthName;

  PROCEDURE DockX(k: INTEGER): INTEGER;   (* left edge of dock icon k (0..4) *)
  BEGIN RETURN 20 + k * ((W - 40) DIV 5) + ((W - 40) DIV 5 - 72) DIV 2
  END DockX;

  PROCEDURE DockAct(k: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN IF k = 3 THEN r := 6 ELSIF k = 4 THEN r := 4 ELSIF k = 1 THEN r := 21 ELSE r := k + 1 END
    RETURN r
  END DockAct;

  PROCEDURE DockY(): INTEGER;
  BEGIN RETURN H - 150
  END DockY;

  PROCEDURE Home*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* over the cube; the actions as above *)
    VAR s, t: ARRAY 40 OF CHAR; k, r, dy: INTEGER;
  BEGIN
    Gazda4.Poll; INC(frames);
    r := 0; dy := DockY();
    IF isDown & ~down THEN down := TRUE; moved := FALSE; x0 := x; y0 := y
    ELSIF isDown THEN IF (ABS(x - x0) > 14) OR (ABS(y - y0) > 14) THEN moved := TRUE END
    ELSIF down THEN
      down := FALSE;
      IF ~moved & (y0 >= dy - 10) & (y0 < dy + 110) THEN
        FOR k := 0 TO 4 DO IF (x0 >= DockX(k) - 12) & (x0 < DockX(k) + 84) THEN r := DockAct(k) END END
      ELSIF ~moved & (y0 < BAR + 10) THEN r := 7   (* the status bar: the settings *)
      END
    END;
    Status;
    s[0] := 0X; k := 0;   (* the clock *)
    IF Gazda4.HasClock() THEN Two(Gazda4.Clock(3), s, k); s[k] := ":"; INC(k); Two(Gazda4.Clock(4), s, k) ELSE s := "CUBICUM" END;
    Centre(W DIV 2, BAR + 34, s, 9, text);
    IF Gazda4.HasClock() THEN
      DayName(Gazda4.Clock(6), s); Add(s, " "); AddN(s, Gazda4.Clock(2)); Add(s, " "); MonthName(Gazda4.Clock(1), t); Add(s, t);
      Centre(W DIV 2, BAR + 112, s, 2, muted)
    ELSE Centre(W DIV 2, BAR + 112, "NO CLOCK: BARE METAL", 2, muted)
    END;
    (* the dock *)
    OllGL6.Rotund2D(14, dy - 18, W - 28, 136, 28, surface);
    FOR k := 0 TO 4 DO
      IF k = 3 THEN Glyph(9, DockX(k), dy, 72) ELSIF k = 4 THEN Glyph(3, DockX(k), dy, 72) ELSIF k = 1 THEN Glyph(23, DockX(k), dy, 72) ELSE Glyph(k, DockX(k), dy, 72) END;
      IF k = 0 THEN s := "ARIEL" ELSIF k = 1 THEN s := "NORA" ELSIF k = 2 THEN s := "OBERON" ELSIF k = 3 THEN s := "COBWEB" ELSE s := "COURT" END;
      Centre(DockX(k) + 36, dy + 82, s, 2, text);
      IF k = 0 THEN s := "SYNTH" ELSIF k = 1 THEN s := "WEB" ELSIF k = 2 THEN s := "SHELL" ELSIF k = 3 THEN s := "FILES" ELSE s := "APPS" END;
      Centre(DockX(k) + 36, dy + 102, s, 1, muted)
    END;
    IF down & ~moved & (y0 >= dy - 10) & (y0 < dy + 110) THEN   (* the finger on an icon: it lights up *)
      FOR k := 0 TO 4 DO IF (x0 >= DockX(k) - 12) & (x0 < DockX(k) + 84) THEN OllGL6.Inel2D(DockX(k) + 36, dy + 36, 46, 3, gold) END END
    END;
    IF tMsg > 0 THEN DEC(tMsg); OllGL6.Rotund2D(40, BAR + 140, W - 80, 40, 20, surface2); Centre(W DIV 2, BAR + 154, msg, 2, gold) END
    RETURN r
  END Home;

  PROCEDURE Card*(y, h: INTEGER);   (* a glass card across the screen, for the home information *)
  BEGIN OllGL6.Rotund2D(24, y, W - 48, h, 18, surface)
  END Card;

  (* ---------- the drawer ---------- *)

  PROCEDURE Item(k, v: INTEGER);
  BEGIN IF nIt < NI THEN itK[nIt] := k; itV[nIt] := v; INC(nIt) END
  END Item;

  PROCEDURE Build;   (* the items of the tab *)
    VAR i: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    nIt := 0;
    IF tab = 0 THEN
      Item(kHead, 0); FOR i := 0 TO 16 DO Item(kOwn, i) END;
      Item(kHead, 1); Item(kTool, 0); Item(kTool, 1);
      Item(kHead, 2);
      FOR i := 0 TO Fs2.Count() - 1 DO
        Fs2.Name(i, nm); IF Ends(nm, ".mod") OR Ends(nm, ".z7") THEN Item(kProg, i) END
      END
    ELSE
      FOR i := 0 TO Gazda4.Count() - 1 DO
        IF Gazda4.Mine(i) = (tab = 1) THEN Item(kHost, i) END
      END
    END
  END Build;

  PROCEDURE Layout(top: INTEGER);   (* places the items: 4 in a row, headings on their own row *)
    VAR i, col, y, cw: INTEGER;
  BEGIN
    cw := (W - 32) DIV 4; col := 0; y := top;
    FOR i := 0 TO nIt - 1 DO
      IF itK[i] = kHead THEN
        IF col > 0 THEN y := y + 128; col := 0 END;
        itX[i] := 24; itY[i] := y; y := y + 44
      ELSE
        itX[i] := 16 + col * cw; itY[i] := y; INC(col);
        IF col = 4 THEN col := 0; y := y + 128 END
      END
    END;
    IF col > 0 THEN y := y + 128 END;
    sMax := y - top
  END Layout;

  PROCEDURE FairyName*(v: INTEGER; VAR s: ARRAY OF CHAR);   (* the fairy of own program v *)
  BEGIN
    IF v = 0 THEN Copy("ARIEL", s) ELSIF v = 1 THEN Copy("ECHO", s) ELSIF v = 2 THEN Copy("OBERON", s)
    ELSIF v = 3 THEN Copy("MAB", s) ELSIF v = 4 THEN Copy("COBWEB", s) ELSIF v = 5 THEN Copy("TITANIA", s)
    ELSIF v = 6 THEN Copy("PUCK", s) ELSIF v = 7 THEN Copy("MUSTARDSEED", s) ELSIF v = 8 THEN Copy("MOTH", s)
    ELSIF v = 9 THEN Copy("IRIS", s) ELSIF v = 11 THEN Copy("PHILOMEL", s) ELSIF v = 12 THEN Copy("PEASEBLOSSOM", s) ELSIF v = 13 THEN Copy("JUNO", s) ELSIF v = 14 THEN Copy("QUINCE", s) ELSIF v = 15 THEN Copy("CERES", s)
    ELSIF v = 16 THEN Copy("NORA", s) ELSE Copy("ROBIN", s) END
  END FairyName;

  PROCEDURE Job*(v: INTEGER; VAR s: ARRAY OF CHAR);   (* what fairy v does *)
  BEGIN
    IF v = 0 THEN Copy("SYNTH", s) ELSIF v = 1 THEN Copy("PLAYER", s) ELSIF v = 2 THEN Copy("SHELL", s)
    ELSIF v = 3 THEN Copy("CANVAS", s) ELSIF v = 4 THEN Copy("FILES", s) ELSIF v = 5 THEN Copy("SETTINGS", s)
    ELSIF v = 6 THEN Copy("TASKS", s) ELSIF v = 7 THEN Copy("CALC", s) ELSIF v = 8 THEN Copy("CLOCK", s)
    ELSIF v = 9 THEN Copy("IMAGES", s) ELSIF v = 11 THEN Copy("MUSIC", s) ELSIF v = 12 THEN Copy("BOOKS", s) ELSIF v = 13 THEN Copy("VIDEO", s) ELSIF v = 14 THEN Copy("NOTES", s) ELSIF v = 15 THEN Copy("RECORDER", s)
    ELSIF v = 16 THEN Copy("WEB", s) ELSE Copy("HELP", s) END
  END Job;

  PROCEDURE Name(i: INTEGER; VAR s: ARRAY OF CHAR);   (* the label under item i *)
    VAR k, v: INTEGER;
  BEGIN
    k := itK[i]; v := itV[i];
    IF k = kOwn THEN
      FairyName(v, s)
    ELSIF k = kTool THEN IF v = 0 THEN Copy("INSTALL", s) ELSE Copy("BYZ7", s) END
    ELSIF k = kProg THEN Fs2.Name(v, s); k := Len(s); WHILE (k > 0) & (s[k] # ".") DO DEC(k) END; IF k > 0 THEN s[k] := 0X END
    ELSIF k = kHost THEN Gazda4.Label(v, s)
    ELSE s[0] := 0X
    END;
    IF k = kOwn THEN Fit(s, 12) ELSE Fit(s, 9) END
  END Name;

  PROCEDURE OwnGlyph(v: INTEGER): INTEGER;
    VAR g: INTEGER;
  BEGIN IF v = 3 THEN g := 4 ELSIF v = 4 THEN g := 9 ELSIF v = 5 THEN g := 10 ELSIF v >= 6 THEN g := v + 7 ELSE g := v END
    RETURN g
  END OwnGlyph;

  PROCEDURE Tab(k, x, w: INTEGER; s: ARRAY OF CHAR);
  BEGIN
    IF tab = k THEN OllGL6.Rotund2D(x, 116, w, 40, 20, gold); Centre(x + w DIV 2, 130, s, 2, dark)
    ELSE Centre(x + w DIV 2, 130, s, 2, muted)
    END
  END Tab;

  PROCEDURE Tap(tx, ty: INTEGER): INTEGER;   (* what the finger chose in the drawer *)
    VAR i, r, cw, j: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    r := 0; cw := (W - 32) DIV 4;
    IF (ty >= 110) & (ty < 162) THEN   (* the tabs *)
      j := (tx - 16) * 3 DIV (W - 32); IF j < 0 THEN j := 0 ELSIF j > 2 THEN j := 2 END;
      tab := j; IF (tab > 0) & ~Gazda4.Loaded() & ~Gazda4.Waiting() & Gazda4.Hosted() THEN Gazda4.Ask END; Build
    ELSIF ty >= H - 76 THEN   (* the bottom bar *)
      IF tx < W DIV 3 THEN
        IF Gazda4.Hosted() THEN Gazda4.Ask; Say("ASKING THE HOST FOR ITS APPS") ELSE Say("NO HOST: BARE METAL") END
      ELSIF tx < 2 * W DIV 3 THEN r := -1
      END
    ELSIF ty >= 170 THEN
      i := 0;
      WHILE i < nIt DO
        IF (itK[i] # kHead) & (tx >= itX[i]) & (tx < itX[i] + cw) & (ty >= itY[i] + scroll[tab]) & (ty < itY[i] + scroll[tab] + 124) THEN
          IF itK[i] = kOwn THEN
            IF itV[i] = 3 THEN r := 5 ELSIF itV[i] = 4 THEN r := 6 ELSIF itV[i] = 5 THEN r := 7
            ELSIF itV[i] >= 6 THEN r := itV[i] + 5 ELSE r := itV[i] + 1 END
          ELSIF itK[i] = kTool THEN
            IF itV[i] = 0 THEN j := Gazda4.FindAct("ro.jahbalon.crisalida", "Terminal"); IF j < 0 THEN j := Gazda4.FindAct("ro.jahbalon.oberon.crisalida", "Terminal") END
            ELSE j := Gazda4.FindAct("ro.jahbalon.byz7", "Terminal") END;
            IF ~Gazda4.Hosted() THEN Say("NEEDS A HOST UNDER PIXIPOGO")
            ELSIF j < 0 THEN IF itV[i] = 0 THEN Say("CRISALIDA IS NOT ON THE PHONE") ELSE Say("BYZ7 IS NOT ON THE PHONE") END
            ELSIF Gazda4.Launch(j) THEN IF itV[i] = 0 THEN Say("OPENING CRISALIDA") ELSE Say("OPENING BYZ7") END
            END
          ELSIF itK[i] = kProg THEN
            Fs2.Name(itV[i], nm); j := Len(nm); WHILE (j > 0) & (nm[j] # ".") DO DEC(j) END; IF j > 0 THEN nm[j] := 0X END;
            Copy(nm, chosen); r := 10
          ELSIF itK[i] = kHost THEN
            Gazda4.Label(itV[i], nm); Fit(nm, 20);
            IF Gazda4.Launch(itV[i]) THEN msg := "OPENING "; Add(msg, nm); tMsg := 90 END
          END;
          i := nIt
        END;
        INC(i)
      END
    END
    RETURN r
  END Tap;

  PROCEDURE Drawer*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;
    (* the whole APPS screen; the actions as above *)
    VAR r, i, j, cw, yy, lim: INTEGER; s: ARRAY 40 OF CHAR; wasLoaded: BOOLEAN;
  BEGIN
    wasLoaded := Gazda4.Loaded(); Gazda4.Poll; IF Gazda4.Loaded() & ~wasLoaded THEN Build END;
    IF ~asked & Gazda4.Hosted() THEN asked := TRUE; IF ~Gazda4.Loaded() & ~Gazda4.Waiting() THEN Gazda4.Ask END END;
    r := 0; cw := (W - 32) DIV 4;
    Layout(178);
    lim := H - 90 - 178 - sMax; IF lim > 0 THEN lim := 0 END;
    IF isDown & ~down THEN down := TRUE; moved := FALSE; x0 := x; y0 := y; scroll0 := scroll[tab]
    ELSIF isDown THEN
      IF ABS(y - y0) > 14 THEN moved := TRUE END;
      IF moved & (y0 >= 170) & (y0 < H - 76) THEN scroll[tab] := scroll0 + y - y0 END
    ELSIF down THEN down := FALSE; IF ~moved THEN r := Tap(x0, y0) END
    END;
    IF scroll[tab] > 0 THEN scroll[tab] := 0 ELSIF scroll[tab] < lim THEN scroll[tab] := lim END;
    OllGL6.Incepe(bg);
    FOR i := 0 TO nIt - 1 DO   (* the grid, under the header *)
      yy := itY[i] + scroll[tab];
      IF (yy > 120) & (yy < H - 80) THEN
        IF itK[i] = kHead THEN
          IF itV[i] = 0 THEN s := "THE FAIRIES OF OBERON" ELSIF itV[i] = 1 THEN s := "TOOLS ON THE HOST" ELSE s := "PROGRAMS IN THE CUBE" END;
          OllGL6.Text2D(itX[i], yy + 14, s, 2, gold); OllGL6.Dreptunghi2D(itX[i], yy + 34, W - 48, 1, edge)
        ELSE
          IF down & ~moved & (x0 >= itX[i]) & (x0 < itX[i] + cw) & (y0 >= yy) & (y0 < yy + 124) THEN
            OllGL6.Rotund2D(itX[i] + 4, yy, cw - 8, 122, 18, surface2)
          END;
          IF itK[i] = kOwn THEN Glyph(OwnGlyph(itV[i]), itX[i] + (cw - 64) DIV 2, yy + 10, 64)
          ELSIF itK[i] = kTool THEN Glyph(5 + itV[i], itX[i] + (cw - 64) DIV 2, yy + 10, 64)
          ELSIF itK[i] = kProg THEN Fs2.Name(itV[i], s); IF Ends(s, ".z7") THEN Glyph(8, itX[i] + (cw - 64) DIV 2, yy + 10, 64) ELSE Glyph(7, itX[i] + (cw - 64) DIV 2, yy + 10, 64) END
          ELSE HostIcon(itV[i], itX[i] + (cw - 64) DIV 2, yy + 10, 64)
          END;
          Name(i, s); Centre(itX[i] + cw DIV 2, yy + 84, s, 2, text);
          IF itK[i] = kOwn THEN Job(itV[i], s); Centre(itX[i] + cw DIV 2, yy + 106, s, 1, muted) END
        END
      END
    END;
    IF (tab > 0) & (nIt = 0) THEN
      IF Gazda4.Bare() THEN Centre(W DIV 2, 260, "NO HOST UNDER PIXIPOGO", 2, muted); Centre(W DIV 2, 290, "BARE METAL: ONLY ITS OWN APPS", 2, muted)
      ELSIF Gazda4.Waiting() OR ~Gazda4.Hosted() THEN Centre(W DIV 2, 260, "ASKING THE HOST ...", 2, muted)
      ELSIF Gazda4.Loaded() THEN Centre(W DIV 2, 260, "NOTHING HERE", 2, muted)
      ELSE Centre(W DIV 2, 260, "THIS WINDOW CANNOT LIST APPS", 2, muted); Centre(W DIV 2, 290, "NEEDS ECRAN-GL4.DEX", 2, muted)
      END
    END;
    (* the header, over the grid *)
    OllGL6.Dreptunghi2D(0, 0, W, 170, bg);
    Status;
    OllGL6.Text2D(24, BAR + 26, "THE COURT", 4, text);
    j := 0; FOR i := 0 TO nIt - 1 DO IF itK[i] # kHead THEN INC(j) END END;
    s[0] := 0X; AddN(s, j); IF tab = 0 THEN Add(s, " HERE") ELSE Add(s, " ON THE HOST") END;
    Right(W - 24, BAR + 36, s, 2, muted);
    OllGL6.Rotund2D(16, 112, W - 32, 48, 24, surface);
    Tab(0, 20, (W - 40) DIV 3, "PIXIPOGO"); Tab(1, 20 + (W - 40) DIV 3, (W - 40) DIV 3, "JAHBALON");
    Tab(2, 20 + 2 * ((W - 40) DIV 3), (W - 40) DIV 3, "ANDROID");
    (* the bottom bar *)
    OllGL6.Dreptunghi2D(0, H - 80, W, 160, dark);   (* down past H too: the names of the last row do not show under it *)
    Centre(W DIV 6, H - 46, "REFRESH", 2, muted);
    OllGL6.Rotund2D(W DIV 2 - 70, H - 62, 140, 44, 22, surface2); Centre(W DIV 2, H - 46, "HOME", 2, text);
    IF Gazda4.Waiting() THEN Centre(5 * W DIV 6, H - 46, "...", 2, gold) END;
    IF tMsg > 0 THEN DEC(tMsg); OllGL6.Rotund2D(40, H - 136, W - 80, 44, 22, surface2); Centre(W DIV 2, H - 120, msg, 2, gold) END;
    OllGL6.Arata
    RETURN r
  END Drawer;

  (* ---------- settings ---------- *)

  PROCEDURE Switch(y: INTEGER; s: ARRAY OF CHAR; on: BOOLEAN);   (* one row with a switch *)
  BEGIN
    OllGL6.Text2D(36, y + 14, s, 2, text);
    IF on THEN OllGL6.Rotund2D(W - 104, y + 6, 68, 32, 16, gold); OllGL6.Cerc2D(W - 52, y + 22, 12, text)
    ELSE OllGL6.Rotund2D(W - 104, y + 6, 68, 32, 16, edge); OllGL6.Cerc2D(W - 88, y + 22, 12, muted)
    END
  END Switch;

  PROCEDURE Row(y: INTEGER; a, b: ARRAY OF CHAR);   (* ABOUT: a name and its value *)
  BEGIN OllGL6.Text2D(36, y, a, 2, muted); Right(W - 36, y, b, 2, text)
  END Row;

  PROCEDURE Settings*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;
    VAR r, k, yy, n: INTEGER; s: ARRAY 40 OF CHAR;
  BEGIN
    Gazda4.Poll; r := 0; yy := sTop;
    IF ~asked & Gazda4.Hosted() THEN asked := TRUE; IF ~Gazda4.Loaded() & ~Gazda4.Waiting() THEN Gazda4.Ask END END;
    IF isDown & ~down THEN down := TRUE; moved := FALSE; x0 := x; y0 := y
    ELSIF isDown THEN IF (ABS(x - x0) > 14) OR (ABS(y - y0) > 14) THEN moved := TRUE END
    ELSIF down THEN
      down := FALSE;
      IF ~moved THEN
        IF (y0 >= yy + 40) & (y0 < yy + 110) THEN   (* the colours *)
          k := (x0 - 24) * 5 DIV (W - 48); IF (k >= 0) & (k <= 4) THEN accent := k; gold := AccentOf(k); Save END
        ELSIF (y0 >= yy + 150) & (y0 < yy + 200) THEN boot := ~boot; Save
        ELSIF (y0 >= yy + 200) & (y0 < yy + 250) THEN spin := ~spin; Save
        ELSIF (y0 >= yy + 250) & (y0 < yy + 300) THEN fps := ~fps; Save
        ELSIF (y0 >= yy + 310) & (y0 < yy + 370) THEN r := 8   (* see the boot again *)
        ELSIF y0 >= H - 76 THEN r := -1
        END
      END
    END;
    OllGL6.Incepe(bg);
    Status;
    OllGL6.Text2D(24, BAR + 26, "TITANIA", 4, text); Right(W - 24, BAR + 36, "SETTINGS", 2, muted);
    OllGL6.Text2D(24, yy + 10, "ACCENT", 2, gold);
    FOR k := 0 TO 4 DO
      n := 24 + k * (W - 48) DIV 5 + (W - 48) DIV 10;
      IF k = accent THEN OllGL6.Inel2D(n, yy + 74, 30, 3, text) END;
      OllGL6.Cerc2D(n, yy + 74, 22, AccentOf(k))
    END;
    OllGL6.Text2D(24, yy + 124, "SYSTEM", 2, gold); OllGL6.Dreptunghi2D(24, yy + 144, W - 48, 1, edge);
    Switch(yy + 150, "BOOT SCREEN", boot); Switch(yy + 200, "THE CUBE TURNS ALONE", spin); Switch(yy + 250, "SHOW FPS", fps);
    OllGL6.Rotund2D(24, yy + 314, W - 48, 50, 25, surface2); Centre(W DIV 2, yy + 332, "SEE THE BOOT AGAIN", 2, text);
    OllGL6.Text2D(24, yy + 398, "ABOUT", 2, gold); OllGL6.Dreptunghi2D(24, yy + 418, W - 48, 1, edge);
    Row(yy + 434, "SYSTEM", "PIXIPOGO 49");
    Row(yy + 464, "PARTS", "DESK 6T . NORA 18 . FILME 1 . GL 7");
    Gazda4.System(s); Row(yy + 494, "HOST", s);
    Gazda4.Model(s); IF s[0] = 0X THEN Copy("-", s) END; Fit(s, 24); Row(yy + 524, "DEVICE", s);
    s[0] := 0X; AddN(s, Gazda4.Count()); Row(yy + 554, "HOST APPS", s);
    s[0] := 0X; AddN(s, Fs2.Count()); Row(yy + 584, "FILES IN THE CUBE", s);
    Row(yy + 614, "CUBE", "7 X 7 X 7 . 343 CELLS");
    Row(yy + 644, "LANGUAGE", "OBERON . OLL . BYZ7");
    Centre(W DIV 2, yy + 690, "PION AND CLAUDE . JAHBALON . 2026", 2, muted);
    OllGL6.Dreptunghi2D(0, H - 80, W, 160, dark);
    OllGL6.Rotund2D(W DIV 2 - 70, H - 62, 140, 44, 22, surface2); Centre(W DIV 2, H - 46, "HOME", 2, text);
    OllGL6.Arata
    RETURN r
  END Settings;

  (* ---------- for the tools: the same top and bottom on every screen ---------- *)

  PROCEDURE Header*(t, r: ARRAY OF CHAR);   (* status bar, a big title, a note on the right *)
  BEGIN
    OllGL6.Dreptunghi2D(0, 0, W, BAR + 60, bg); Status;
    OllGL6.Text2D(24, BAR + 14, t, 4, text); Right(W - 24, BAR + 24, r, 2, muted)
  END Header;

  PROCEDURE Bottom*;   (* the bar with HOME; a tap there gives -1 (see IsHome) *)
  BEGIN
    OllGL6.Dreptunghi2D(0, H - 80, W, 160, dark);
    OllGL6.Rotund2D(W DIV 2 - 70, H - 62, 140, 44, 22, surface2); Centre(W DIV 2, H - 46, "HOME", 2, text)
  END Bottom;

  PROCEDURE IsHome*(y: INTEGER): BOOLEAN;
  BEGIN RETURN y >= H - 76
  END IsHome;

  PROCEDURE Toast*(y: INTEGER);   (* the last message of Say, for a moment *)
  BEGIN
    IF tMsg > 0 THEN DEC(tMsg); OllGL6.Rotund2D(40, y, W - 80, 44, 22, surface2); Centre(W DIV 2, y + 16, msg, 2, gold) END
  END Toast;

  PROCEDURE Width*(): INTEGER; BEGIN RETURN W END Width;
  PROCEDURE Height*(): INTEGER; BEGIN RETURN H END Height;

  PROCEDURE Chosen*(VAR s: ARRAY OF CHAR);   (* the program the drawer chose (its name without .mod) *)
  BEGIN Copy(chosen, s)
  END Chosen;

  PROCEDURE Enter*;   (* the finger that opened a screen does not press anything in it *)
  BEGIN down := TRUE; moved := TRUE; Build
  END Enter;

  PROCEDURE Start*(w, h: INTEGER);
  BEGIN
    W := w; H := h; sTop := BAR + 90; Load; Gazda4.Poll; Build
  END Start;

BEGIN
  W := 1; H := 1; tab := 0; nIt := 0; scroll[0] := 0; scroll[1] := 0; scroll[2] := 0; down := FALSE; moved := FALSE; asked := FALSE;
  tMsg := 0; msg[0] := 0X; chosen[0] := 0X; frames := 0; sMax := 0; accent := 0; spin := TRUE; boot := TRUE; fps := TRUE; sTop := 130;
  bg := OllGL6.RGB(14, 4, 28); surface := OllGL6.RGB(34, 18, 58); surface2 := OllGL6.RGB(56, 32, 92); edge := OllGL6.RGB(80, 58, 112);
  text := OllGL6.RGB(240, 235, 250); muted := OllGL6.RGB(150, 140, 175); gold := OllGL6.RGB(212, 160, 23);
  cyan := OllGL6.RGB(125, 211, 252); green := OllGL6.RGB(74, 222, 128); red := OllGL6.RGB(239, 68, 68);
  violet := OllGL6.RGB(124, 58, 237); dark := OllGL6.RGB(8, 2, 16)
END Desk6.
