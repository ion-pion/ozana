MODULE Gazda4;  (* GAZDA 4 (20 Nov 2026, Cubicum N 18): files between the phone and Cubicum N (window ecran-cubn18.dex).
     Import: imp-go -> the phone's file picker; the file comes into HOME (a photo also as NAME.ppm for IMAGES); imp-ok.txt.
     Export: exp.txt + exp-go -> Download/CubicumN on the phone; exp-ok.txt. With no host both say NO HOST.
   GAZDA 3 (19 Nov 2026, Cubicum N 17): asks the host for its apps by itself as soon as it finds the host
     (during the boot screen), and reads the icons a little in every frame, so nothing stops: the names come at once,
     the icons fill in. Pion: "it takes time to load JAHBALON, there are many".
   GAZDA 2 (19 Nov 2026, Cubicum N 16): icons of 32 x 32 (the window ecran-cubn16.dex sends them so;
     Pion: "the icons look like the 80s") and FindAct: an app of a package by its activity (Byz7 has two).
   GAZDA 1 (19 Nov 2026): the HOST under Cubicum N. Pion: "Cubicum N should see its own apps and
     the apps of the system it sits on: it can run bare metal and hosted."
   Hosted (Android): the window ecran-gl4.dex answers through little files in HOME, like the clipboard and the clock:
     stare.txt  battery, Android version, phone model (every 3 s)
     apps-req   -> apps.ico (32 x 32 RGBA for every app) and apps.txt (package|activity|label)
     run.txt + run-go -> the phone starts that app
   Bare metal: nobody writes stare.txt, so after a few seconds Hosted() is FALSE and Cubicum N shows only its own apps.
   Nothing here knows Android: another host (a PC, an emulator) only has to answer the same files.
   Pion & Claude, 19.11.2026 *)

  IMPORT Fisier, Ceas;

  CONST NA* = 240; IC* = 32;   (* apps; icon side *)

  VAR
    pkg: ARRAY NA OF ARRAY 64 OF CHAR;
    act: ARRAY NA OF ARRAY 100 OF CHAR;
    lab: ARRAY NA OF ARRAY 42 OF CHAR;
    ico: ARRAY NA * IC * IC OF INTEGER;   (* RGB(..) or 0 = see-through (RGB never gives 0; white is -1) *)
    na, bat, sdk, t0, tStare, tCeas, tCere, tTry: INTEGER;
    charging, hosted, waiting, loaded, autoAsked: BOOLEAN;
    hIco, icoPos: INTEGER;
    impSt, expSt, tImp, tExp: INTEGER;   (* 0 nothing, 1 waiting, 2 done, 3 failed *)
    impName, impPpm, expPath, dummy: ARRAY 64 OF CHAR;   (* the icons file while it is being read; how many pixels are in *)
    android, model: ARRAY 40 OF CHAR;
    ceas: ARRAY 8 OF INTEGER;   (* year month day hour minute second weekday (0 = Monday) *)
    line: ARRAY 200 OF CHAR;

  PROCEDURE RGB(r, g, b: INTEGER): INTEGER;
  BEGIN RETURN r MOD 256 + 256 * (g MOD 256) + 65536 * (b MOD 256) - 16777216
  END RGB;

  PROCEDURE ReadLine(h: INTEGER): BOOLEAN;   (* the next line of the file into line; FALSE at the end *)
    VAR c, n: INTEGER;
  BEGIN
    n := 0; c := Fisier.Citeste(h);
    WHILE (c >= 0) & (c # 10) DO
      IF (c >= 32) & (c < 127) & (n < LEN(line) - 1) THEN line[n] := CHR(c); INC(n) END;
      c := Fisier.Citeste(h)
    END;
    line[n] := 0X
    RETURN (c >= 0) OR (n > 0)
  END ReadLine;

  PROCEDURE Word(k: INTEGER; VAR s: ARRAY OF CHAR);   (* word k of line (words split by spaces) *)
    VAR i, j, w: INTEGER;
  BEGIN
    i := 0; w := 0; j := 0;
    WHILE line[i] = " " DO INC(i) END;
    WHILE (line[i] # 0X) & (w < k) DO
      WHILE (line[i] # 0X) & (line[i] # " ") DO INC(i) END;
      WHILE line[i] = " " DO INC(i) END;
      INC(w)
    END;
    WHILE (line[i] # 0X) & (line[i] # " ") & (j < LEN(s) - 1) DO s[j] := line[i]; INC(i); INC(j) END;
    s[j] := 0X
  END Word;

  PROCEDURE Num(k: INTEGER): INTEGER;
    VAR s: ARRAY 16 OF CHAR; i, v: INTEGER; neg: BOOLEAN;
  BEGIN
    Word(k, s); i := 0; v := 0; neg := FALSE;
    IF s[0] = "-" THEN neg := TRUE; i := 1 END;
    WHILE (s[i] >= "0") & (s[i] <= "9") DO v := v * 10 + ORD(s[i]) - ORD("0"); INC(i) END;
    IF neg THEN v := -v END
    RETURN v
  END Num;

  PROCEDURE Starts(p: ARRAY OF CHAR): BOOLEAN;   (* line starts with p *)
    VAR i: INTEGER;
  BEGIN
    i := 0; WHILE (p[i] # 0X) & (line[i] = p[i]) DO INC(i) END
    RETURN p[i] = 0X
  END Starts;

  PROCEDURE Rest(k: INTEGER; VAR s: ARRAY OF CHAR);   (* from word k to the end of line *)
    VAR i, j, w: INTEGER;
  BEGIN
    i := 0; w := 0;
    WHILE (line[i] # 0X) & (w < k) DO
      WHILE (line[i] # 0X) & (line[i] # " ") DO INC(i) END;
      WHILE line[i] = " " DO INC(i) END;
      INC(w)
    END;
    j := 0; WHILE (line[i] # 0X) & (j < LEN(s) - 1) DO IF line[i] = "-" THEN s[j] := " " ELSE s[j] := line[i] END; INC(i); INC(j) END;
    s[j] := 0X
  END Rest;

  PROCEDURE ReadStare;
    VAR h: INTEGER;
  BEGIN
    h := Fisier.Deschide("stare.txt");
    IF h >= 0 THEN
      hosted := TRUE;
      WHILE ReadLine(h) DO
        IF Starts("BAT ") THEN bat := Num(1); charging := Num(2) = 1
        ELSIF Starts("ANDROID ") THEN Word(1, android); sdk := Num(2)
        ELSIF Starts("MODEL ") THEN Rest(1, model)
        END
      END;
      Fisier.Gata(h)
    END
  END ReadStare;

  PROCEDURE ReadCeas;
    VAR h, k: INTEGER;
  BEGIN
    h := Fisier.Deschide("clock.txt");
    IF h >= 0 THEN
      IF ReadLine(h) THEN FOR k := 0 TO 6 DO ceas[k] := Num(k) END END;
      Fisier.Gata(h)
    END
  END ReadCeas;

  PROCEDURE Part(VAR s: ARRAY OF CHAR; VAR i: INTEGER; VAR d: ARRAY OF CHAR);   (* up to the next | *)
    VAR j: INTEGER;
  BEGIN
    j := 0;
    WHILE (s[i] # 0X) & (s[i] # "|") DO IF j < LEN(d) - 1 THEN d[j] := s[i]; INC(j) END; INC(i) END;
    d[j] := 0X; IF s[i] = "|" THEN INC(i) END
  END Part;

  PROCEDURE ReadApps(): BOOLEAN;   (* the names now; the icons are read by Poll, a little at a time *)
    VAR h, n, k, i: INTEGER;
  BEGIN
    h := Fisier.Deschide("apps.txt");
    IF h >= 0 THEN
      n := 0; IF ReadLine(h) THEN n := Num(0) END; IF n > NA THEN n := NA END;
      k := 0;
      WHILE (k < n) & ReadLine(h) DO
        i := 0; Part(line, i, pkg[k]); Part(line, i, act[k]); Part(line, i, lab[k]); INC(k)
      END;
      Fisier.Gata(h); na := k;
      FOR i := 0 TO na * IC * IC - 1 DO ico[i] := 0 END;
      IF hIco >= 0 THEN Fisier.Gata(hIco) END;
      hIco := Fisier.Deschide("apps.ico"); icoPos := 0
    END
    RETURN h >= 0
  END ReadApps;

  PROCEDURE ReadIcons(max: INTEGER);   (* up to max pixels of the icons *)
    VAR r, g, b, a, k: INTEGER;
  BEGIN
    k := 0;
    WHILE (hIco >= 0) & (k < max) DO
      r := Fisier.Citeste(hIco);
      IF (r < 0) OR (icoPos >= na * IC * IC) THEN Fisier.Gata(hIco); hIco := -1
      ELSE
        g := Fisier.Citeste(hIco); b := Fisier.Citeste(hIco); a := Fisier.Citeste(hIco);
        IF a > 110 THEN ico[icoPos] := RGB(r DIV 16 * 17, g DIV 16 * 17, b DIV 16 * 17) END;   (* 16 shades *)
        INC(icoPos); INC(k)
      END
    END
  END ReadIcons;

  PROCEDURE Ask*;   (* ask the host for its apps again *)
    VAR h: INTEGER;
  BEGIN
    Fisier.Sterge("apps.txt");
    h := Fisier.Creeaza("apps-req"); IF h >= 0 THEN Fisier.Scrie(h, 49); Fisier.Gata(h) END;
    waiting := TRUE; tCere := Ceas.Ms(); tTry := tCere
  END Ask;

  PROCEDURE Signal(nm: ARRAY OF CHAR);
    VAR h: INTEGER;
  BEGIN h := Fisier.Creeaza(nm); IF h >= 0 THEN Fisier.Scrie(h, 49); Fisier.Gata(h) END
  END Signal;

  PROCEDURE Import*;   (* the phone's file picker *)
  BEGIN
    IF hosted THEN Fisier.Sterge("imp-ok.txt"); Signal("imp-go"); impSt := 1; tImp := Ceas.Ms() ELSE impSt := 3 END;
    impName[0] := 0X; impPpm[0] := 0X
  END Import;

  PROCEDURE Export*(nm: ARRAY OF CHAR);   (* file nm of HOME to Download/CubicumN *)
    VAR h, i: INTEGER;
  BEGIN
    expPath[0] := 0X;
    IF hosted THEN
      Fisier.Sterge("exp-ok.txt"); h := Fisier.Creeaza("exp.txt");
      IF h >= 0 THEN
        i := 0; WHILE (i < LEN(nm)) & (nm[i] # 0X) DO Fisier.Scrie(h, ORD(nm[i])); INC(i) END; Fisier.Scrie(h, 10); Fisier.Gata(h);
        Signal("exp-go"); expSt := 1; tExp := Ceas.Ms()
      ELSE expSt := 3
      END
    ELSE expSt := 3
    END
  END Export;

  PROCEDURE Result(nm: ARRAY OF CHAR; VAR st: INTEGER; VAR a, b: ARRAY OF CHAR);   (* "1 a [b]" or "0 why" *)
    VAR h: INTEGER;
  BEGIN
    h := Fisier.Deschide(nm);
    IF h >= 0 THEN
      IF ReadLine(h) THEN
        IF line[0] = "1" THEN st := 2; Word(1, a); Word(2, b) ELSE st := 3; Word(1, a) END
      ELSE st := 3
      END;
      Fisier.Gata(h); Fisier.Sterge(nm)
    END
  END Result;

  PROCEDURE ImportState*(): INTEGER; BEGIN RETURN impSt END ImportState;
  PROCEDURE ExportState*(): INTEGER; BEGIN RETURN expSt END ExportState;
  PROCEDURE ImportDone*; BEGIN impSt := 0 END ImportDone;
  PROCEDURE ExportDone*; BEGIN expSt := 0 END ExportDone;

  PROCEDURE ImportName*(VAR s: ARRAY OF CHAR);   (* the file that came in *)
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (impName[i] # 0X) & (i < LEN(s) - 1) DO s[i] := impName[i]; INC(i) END; s[i] := 0X
  END ImportName;

  PROCEDURE ImportPpm*(VAR s: ARRAY OF CHAR);   (* its picture for IMAGES, or "" *)
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (impPpm[i] # 0X) & (i < LEN(s) - 1) DO s[i] := impPpm[i]; INC(i) END; s[i] := 0X
  END ImportPpm;

  PROCEDURE ExportPath*(VAR s: ARRAY OF CHAR);   (* where it went on the phone *)
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (expPath[i] # 0X) & (i < LEN(s) - 1) DO s[i] := expPath[i]; INC(i) END; s[i] := 0X
  END ExportPath;

  PROCEDURE Poll*;   (* every frame; it reads the files only now and then *)
    VAR now: INTEGER;
  BEGIN
    now := Ceas.Ms();
    IF now - tCeas >= 500 THEN ReadCeas; tCeas := now END;
    IF now - tStare >= 3000 THEN ReadStare; tStare := now END;
    IF hosted & ~autoAsked THEN autoAsked := TRUE; IF ~loaded & ~waiting THEN Ask END END;   (* at once: during the boot *)
    IF hIco >= 0 THEN ReadIcons(3072) END;
    IF (impSt = 1) & (now - tImp > 400) THEN tImp := now; Result("imp-ok.txt", impSt, impName, impPpm) END;
    IF (expSt = 1) & (now - tExp > 300) THEN tExp := now; Result("exp-ok.txt", expSt, expPath, dummy) END;
    IF waiting & (now - tTry >= 300) THEN
      tTry := now;
      IF ReadApps() THEN waiting := FALSE; loaded := TRUE
      ELSIF now - tCere > 8000 THEN waiting := FALSE   (* nobody answers: bare metal *)
      END
    END
  END Poll;

  PROCEDURE IconReady*(i: INTEGER): BOOLEAN;   (* is the icon of app i read already? *)
  BEGIN RETURN (i + 1) * IC * IC <= icoPos
  END IconReady;

  PROCEDURE Hosted*(): BOOLEAN;   (* is there a system under Cubicum N? *)
  BEGIN RETURN hosted
  END Hosted;

  PROCEDURE Bare*(): BOOLEAN;   (* sure there is none: a few seconds passed and nobody answered *)
  BEGIN RETURN ~hosted & (Ceas.Ms() - t0 > 4000)
  END Bare;

  PROCEDURE Waiting*(): BOOLEAN;
  BEGIN RETURN waiting
  END Waiting;

  PROCEDURE Loaded*(): BOOLEAN;
  BEGIN RETURN loaded
  END Loaded;

  PROCEDURE Count*(): INTEGER;
  BEGIN RETURN na
  END Count;

  PROCEDURE Label*(i: INTEGER; VAR s: ARRAY OF CHAR);
    VAR j: INTEGER;
  BEGIN
    j := 0;
    IF (i >= 0) & (i < na) THEN WHILE (lab[i][j] # 0X) & (j < LEN(s) - 1) DO s[j] := lab[i][j]; INC(j) END END;
    s[j] := 0X
  END Label;

  PROCEDURE Package*(i: INTEGER; VAR s: ARRAY OF CHAR);
    VAR j: INTEGER;
  BEGIN
    j := 0;
    IF (i >= 0) & (i < na) THEN WHILE (pkg[i][j] # 0X) & (j < LEN(s) - 1) DO s[j] := pkg[i][j]; INC(j) END END;
    s[j] := 0X
  END Package;

  PROCEDURE Mine*(i: INTEGER): BOOLEAN;   (* one of Pion's apps: the package starts with ro.jahbalon *)
    VAR p: ARRAY 13 OF CHAR; k: INTEGER; ok: BOOLEAN;
  BEGIN
    p := "ro.jahbalon."; ok := (i >= 0) & (i < na); k := 0;
    WHILE ok & (p[k] # 0X) DO IF pkg[i][k] # p[k] THEN ok := FALSE END; INC(k) END
    RETURN ok
  END Mine;

  PROCEDURE Find*(p: ARRAY OF CHAR): INTEGER;   (* the first app of package p; -1 = not on this host *)
    VAR i, k, r: INTEGER; same: BOOLEAN;
  BEGIN
    r := -1; i := 0;
    WHILE (r < 0) & (i < na) DO
      k := 0; same := TRUE;
      WHILE same & (p[k] # 0X) DO IF pkg[i][k] # p[k] THEN same := FALSE END; INC(k) END;
      IF same & (pkg[i][k] = 0X) THEN r := i END;
      INC(i)
    END
    RETURN r
  END Find;

  PROCEDURE FindAct*(p, a: ARRAY OF CHAR): INTEGER;   (* the app of package p whose activity holds a; else Find(p) *)
    VAR i, k, j, r: INTEGER; same, has: BOOLEAN;
  BEGIN
    r := -1; i := 0;
    WHILE (r < 0) & (i < na) DO
      k := 0; same := TRUE;
      WHILE same & (p[k] # 0X) DO IF pkg[i][k] # p[k] THEN same := FALSE END; INC(k) END;
      IF same & (pkg[i][k] = 0X) THEN
        has := FALSE; j := 0;
        WHILE ~has & (act[i][j] # 0X) DO
          k := 0; WHILE (a[k] # 0X) & (act[i][j + k] = a[k]) DO INC(k) END;
          IF a[k] = 0X THEN has := TRUE END; INC(j)
        END;
        IF has THEN r := i END
      END;
      INC(i)
    END;
    IF r < 0 THEN r := Find(p) END
    RETURN r
  END FindAct;

  PROCEDURE Pixel*(i, x, y: INTEGER): INTEGER;   (* icon of app i; 0 = see-through *)
    VAR r: INTEGER;
  BEGIN
    r := 0; IF (i >= 0) & (i < na) & (x >= 0) & (x < IC) & (y >= 0) & (y < IC) THEN r := ico[(i * IC + y) * IC + x] END
    RETURN r
  END Pixel;

  PROCEDURE Put(h: INTEGER; s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Fisier.Scrie(h, ORD(s[i])); INC(i) END
  END Put;

  PROCEDURE Launch*(i: INTEGER): BOOLEAN;   (* the host starts app i *)
    VAR h: INTEGER; ok: BOOLEAN;
  BEGIN
    ok := hosted & (i >= 0) & (i < na);
    IF ok THEN
      h := Fisier.Creeaza("run.txt");
      IF h >= 0 THEN
        Put(h, pkg[i]); Fisier.Scrie(h, ORD("|")); Put(h, act[i]); Fisier.Scrie(h, 10); Fisier.Gata(h);
        h := Fisier.Creeaza("run-go"); IF h >= 0 THEN Fisier.Scrie(h, 49); Fisier.Gata(h) END
      ELSE ok := FALSE
      END
    END
    RETURN ok
  END Launch;

  PROCEDURE Battery*(): INTEGER;   (* percent; -1 = no battery known *)
  BEGIN RETURN bat
  END Battery;

  PROCEDURE Charging*(): BOOLEAN;
  BEGIN RETURN charging
  END Charging;

  PROCEDURE System*(VAR s: ARRAY OF CHAR);   (* "ANDROID 14" or "BARE METAL" *)
    VAR i, j: INTEGER; p: ARRAY 12 OF CHAR;
  BEGIN
    IF hosted THEN p := "ANDROID " ELSE p := "BARE METAL" END;
    i := 0; WHILE (p[i] # 0X) & (i < LEN(s) - 1) DO s[i] := p[i]; INC(i) END;
    j := 0; IF hosted THEN WHILE (android[j] # 0X) & (i < LEN(s) - 1) DO s[i] := android[j]; INC(i); INC(j) END END;
    s[i] := 0X
  END System;

  PROCEDURE Model*(VAR s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    i := 0; WHILE (model[i] # 0X) & (i < LEN(s) - 1) DO s[i] := model[i]; INC(i) END; s[i] := 0X
  END Model;

  PROCEDURE Clock*(k: INTEGER): INTEGER;   (* 0 year, 1 month, 2 day, 3 hour, 4 minute, 5 second, 6 weekday (0 = Monday) *)
    VAR r: INTEGER;
  BEGIN r := 0; IF (k >= 0) & (k < 7) THEN r := ceas[k] END
    RETURN r
  END Clock;

  PROCEDURE HasClock*(): BOOLEAN;
  BEGIN RETURN ceas[0] > 2000
  END HasClock;

BEGIN
  na := 0; bat := -1; sdk := 0; charging := FALSE; hosted := FALSE; waiting := FALSE; loaded := FALSE; autoAsked := FALSE;
  hIco := -1; icoPos := 0; impSt := 0; expSt := 0; tImp := 0; tExp := 0; impName[0] := 0X; impPpm[0] := 0X; expPath[0] := 0X;
  android[0] := 0X; model[0] := 0X; t0 := Ceas.Ms(); tStare := t0 - 5000; tCeas := t0 - 1000; tCere := t0; tTry := t0;
  ceas[0] := 0; ceas[1] := 0; ceas[2] := 0; ceas[3] := 0; ceas[4] := 0; ceas[5] := 0; ceas[6] := 0
END Gazda4.
