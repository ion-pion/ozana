MODULE Motor2;  (* MOTOR 2 (9 nov 2026), Pion: "fa motorul sa fie universal". Pentru OLL v9.1 (Byz7 4).
     Tot ce stie Motor1 (litere, evenimente, ritmuri, bucla de cadre), plus ce le trebuie tuturor jocurilor de pana acum
     (Tubul, Tir, Cristal, Labirint), ca sa nu le mai scrie fiecare joc de la capat:
       SCENE      fiecare litera traieste in anumite scene (titlu, joc, final, ...); Motor2.SchimbaScena(s).
       DEGETUL    Atinge, Ridica, Trage, Apasa (atingere scurta, pe loc), Lung (tinut pe loc 0,6 s); DX/DY = cat s-a tras.
       ZONE       dreptunghiuri (butoane) care, atinse, pun evenimentul lor: Motor2.Zona(x, y, l, h, ev, val, scene).
       INCLINAREA Calibreaza = pozitia de acum e zero; Ix/Iy fata de ea; Ridicat = cat e telefonul ridicat fata de orizontala.
       PAUZA      Motor2.Pauza(TRUE): timpul jocului, ritmurile si alarmele stau; AutoPauza: singur, cand treci in spate.
       ALARME     Motor2.Dupa(ms, ev, val): o singura data, peste ms (timp de joc); Anuleaza.
       FPS        cadre pe secunda, ca sa vezi cat de greu e cadrul.
     Ce scrie un joc: literele lui (cate o procedura (ev, val)), le inscrie, apoi Motor2.Ruleaza.
     Primul cadru trimite Scena (val = scena de pornire): atunci are jocul fereastra si poate afla Latime/Inaltime.

   Evenimentele 0..7 sunt ale motorului, 8..31 ale jocului (Primul = 8), ca la Motor1. *)

  IMPORT Out, Ceas, Math, Ecran;

  CONST
    ML = 32; MQ = 512; MR = 16; MZ = 32; MA = 32;
    MaxLivrari = 4000;
    Tick* = 0;     (* in fiecare cadru; val = numarul cadrului *)
    Atinge* = 1;   (* degetul a atins ecranul: X(), Y() *)
    Ridica* = 2;   (* degetul s-a ridicat; val = cat a stat jos (ms) *)
    Trage* = 3;    (* degetul s-a miscat; DX(), DY() = cu cat, de la cadrul trecut *)
    Apasa* = 4;    (* atingere scurta, aproape pe loc; val = zona atinsa sau -1 *)
    Lung* = 5;     (* tinut pe loc 0,6 s (o data pe atingere) *)
    Fundal* = 6;   (* val 1: aplicatia a trecut in spate; 0: a revenit *)
    Scena* = 7;    (* val = scena noua *)
    Primul* = 8;
    Toate* = {0 .. 31};   (* toate scenele *)

  TYPE Handler* = PROCEDURE (ev, val: INTEGER);

  VAR
    (* literele *)
    nl: INTEGER; nume: ARRAY ML, 16 OF CHAR; asc, sce: ARRAY ML OF SET; hp: ARRAY ML OF Handler; trez: ARRAY ML OF INTEGER;
    (* cutia *)
    qe, qv, qd: ARRAY MQ OF INTEGER; qa, qn, pierdute: INTEGER;
    (* ritmuri si alarme, in timp de joc *)
    rev, rper, rurm: ARRAY MR OF INTEGER; nr: INTEGER;
    aev, aval, acand: ARRAY MA OF INTEGER; aviu: ARRAY MA OF BOOLEAN;
    (* zone *)
    zx, zy, zw, zh, zev, zval: ARRAY MZ OF INTEGER; zsc: ARRAY MZ OF SET; zviu: ARRAY MZ OF BOOLEAN; nz, zonaAtinsa: INTEGER;
    (* degetul *)
    x, y, xj, yj, dx, dy, tJos, atingeri, prag: INTEGER; jos, josInainte, mutat, lungDat: BOOLEAN;
    (* inclinarea *)
    gx, gy, gz, gx0, gy0, gz0: INTEGER;
    (* timpul *)
    w, h, tStart, tUltim, tReal, tJoc, cadru, scena, fundal, fps, nf, tFps: INTEGER; pas: REAL;
    pauza, autoPauza, stop, arat, jurnal, pornitM: BOOLEAN;

  (* ---------- literele ---------- *)

  PROCEDURE Litera*(n: ARRAY OF CHAR; p: Handler; ev: SET): INTEGER;   (* traieste in toate scenele; -1 = prea multe *)
    VAR i, l: INTEGER;
  BEGIN
    l := -1;
    IF nl < ML THEN
      l := nl; INC(nl);
      i := 0; WHILE (i < 15) & (n[i] # 0X) DO nume[l, i] := n[i]; INC(i) END; nume[l, i] := 0X;
      hp[l] := p; asc[l] := ev; sce[l] := Toate; trez[l] := 0
    END;
    RETURN l
  END Litera;

  PROCEDURE InScene*(l: INTEGER; s: SET);   (* litera l primeste evenimente doar in scenele s (Scena o primeste mereu) *)
  BEGIN IF (l >= 0) & (l < nl) THEN sce[l] := s END
  END InScene;

  PROCEDURE Asculta*(l, ev: INTEGER);
  BEGIN IF (l >= 0) & (l < nl) THEN INCL(asc[l], ev) END
  END Asculta;

  PROCEDURE Ignora*(l, ev: INTEGER);
  BEGIN IF (l >= 0) & (l < nl) THEN EXCL(asc[l], ev) END
  END Ignora;

  PROCEDURE Litere*(): INTEGER;
  BEGIN RETURN nl
  END Litere;

  PROCEDURE Treziri*(l: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN r := 0; IF (l >= 0) & (l < nl) THEN r := trez[l] END; RETURN r
  END Treziri;

  PROCEDURE Nume*(l: INTEGER; VAR s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    IF (l >= 0) & (l < nl) THEN WHILE (i < LEN(s) - 1) & (nume[l, i] # 0X) DO s[i] := nume[l, i]; INC(i) END END;
    s[i] := 0X
  END Nume;

  (* ---------- cutia ---------- *)

  PROCEDURE Pune0(ev, val, d: INTEGER);
    VAR k: INTEGER;
  BEGIN
    IF (ev < 0) OR (ev > 31) OR (qn = MQ) THEN INC(pierdute)
    ELSE k := (qa + qn) MOD MQ; qe[k] := ev; qv[k] := val; qd[k] := d; INC(qn)
    END
  END Pune0;

  PROCEDURE Pune*(ev, val: INTEGER);   (* literelor care asculta ev si traiesc in scena de acum *)
  BEGIN Pune0(ev, val, -1)
  END Pune;

  PROCEDURE Spre*(l, ev, val: INTEGER);   (* doar literei l, oricare ar fi scena *)
  BEGIN IF (l >= 0) & (l < nl) THEN Pune0(ev, val, l) ELSE INC(pierdute) END
  END Spre;

  PROCEDURE Pierdute*(): INTEGER;
  BEGIN RETURN pierdute
  END Pierdute;

  PROCEDURE Jurnal*(da: BOOLEAN);
  BEGIN jurnal := da
  END Jurnal;

  PROCEDURE Scrie(ev, val, l: INTEGER);
  BEGIN
    Out.Int(cadru, 6); Out.String("  ev "); Out.Int(ev, 2); Out.String(" val "); Out.Int(val, 1);
    Out.String(" -> "); Out.String(nume[l]); Out.Ln
  END Scrie;

  PROCEDURE Da(l, e, v: INTEGER);
  BEGIN INC(trez[l]); IF jurnal & (e # Tick) THEN Scrie(e, v, l) END; hp[l](e, v)
  END Da;

  PROCEDURE Livreaza;
    VAR n, e, v, d, l: INTEGER;
  BEGIN
    n := 0;
    WHILE (qn > 0) & (n < MaxLivrari) DO
      e := qe[qa]; v := qv[qa]; d := qd[qa]; qa := (qa + 1) MOD MQ; DEC(qn); INC(n);
      IF d >= 0 THEN Da(d, e, v)
      ELSE
        FOR l := 0 TO nl - 1 DO
          IF (e IN asc[l]) & ((e = Scena) OR (scena IN sce[l])) THEN Da(l, e, v) END
        END
      END
    END;
    IF qn > 0 THEN
      pierdute := pierdute + qn; qn := 0;
      Out.String("Motor2: prea multe evenimente intr-un cadru (bucla intre litere?)"); Out.Ln
    END
  END Livreaza;

  (* ---------- scene, pauza ---------- *)

  PROCEDURE SchimbaScena*(s: INTEGER);
  BEGIN IF (s >= 0) & (s <= 31) THEN scena := s; Pune(Scena, s) END
  END SchimbaScena;

  PROCEDURE ScenaAcum*(): INTEGER;
  BEGIN RETURN scena
  END ScenaAcum;

  PROCEDURE Pauza*(da: BOOLEAN);   (* timpul jocului, ritmurile si alarmele stau; Tick vine mai departe (ca sa desenezi pauza) *)
  BEGIN pauza := da
  END Pauza;

  PROCEDURE InPauza*(): BOOLEAN;
  BEGIN RETURN pauza
  END InPauza;

  PROCEDURE AutoPauza*(da: BOOLEAN);   (* pauza singura cand aplicatia trece in spate *)
  BEGIN autoPauza := da
  END AutoPauza;

  (* ---------- ritmuri si alarme (timp de joc) ---------- *)

  PROCEDURE Ritm*(ev, perioada: INTEGER);   (* ev la fiecare perioada ms; val = a cata oara *)
  BEGIN
    IF (nr < MR) & (perioada > 0) THEN rev[nr] := ev; rper[nr] := perioada; rurm[nr] := tJoc + perioada; INC(nr) END
  END Ritm;

  PROCEDURE Dupa*(ms, ev, val: INTEGER): INTEGER;   (* ev o singura data, peste ms; intoarce alarma (-1 = prea multe) *)
    VAR i, r: INTEGER;
  BEGIN
    r := -1; i := 0;
    WHILE (r < 0) & (i < MA) DO
      IF ~aviu[i] THEN r := i; aviu[i] := TRUE; aev[i] := ev; aval[i] := val; acand[i] := tJoc + ms END;
      INC(i)
    END;
    RETURN r
  END Dupa;

  PROCEDURE Anuleaza*(a: INTEGER);
  BEGIN IF (a >= 0) & (a < MA) THEN aviu[a] := FALSE END
  END Anuleaza;

  PROCEDURE Ceasuri;
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO nr - 1 DO
      IF tJoc >= rurm[i] THEN
        Pune(rev[i], rurm[i] DIV rper[i]); rurm[i] := rurm[i] + rper[i];
        IF rurm[i] <= tJoc THEN rurm[i] := tJoc + rper[i] END
      END
    END;
    FOR i := 0 TO MA - 1 DO
      IF aviu[i] & (tJoc >= acand[i]) THEN aviu[i] := FALSE; Pune(aev[i], aval[i]) END
    END
  END Ceasuri;

  (* ---------- zone (butoane) ---------- *)

  PROCEDURE Zona*(zx0, zy0, zl, zi, ev, val: INTEGER; scene: SET): INTEGER;   (* -1 = prea multe *)
    VAR z: INTEGER;
  BEGIN
    z := -1;
    IF nz < MZ THEN
      z := nz; INC(nz);
      zx[z] := zx0; zy[z] := zy0; zw[z] := zl; zh[z] := zi; zev[z] := ev; zval[z] := val; zsc[z] := scene; zviu[z] := TRUE
    END;
    RETURN z
  END Zona;

  PROCEDURE MutaZona*(z, zx0, zy0, zl, zi: INTEGER);
  BEGIN IF (z >= 0) & (z < nz) THEN zx[z] := zx0; zy[z] := zy0; zw[z] := zl; zh[z] := zi END
  END MutaZona;

  PROCEDURE ZonaVie*(z: INTEGER; da: BOOLEAN);   (* o zona oprita nu raspunde *)
  BEGIN IF (z >= 0) & (z < nz) THEN zviu[z] := da END
  END ZonaVie;

  PROCEDURE ZonaLa*(px, py: INTEGER): INTEGER;   (* zona vie, din scena de acum, de sub punctul (px, py); -1 = niciuna *)
    VAR z, r: INTEGER;
  BEGIN
    r := -1; z := nz - 1;
    WHILE (r < 0) & (z >= 0) DO
      IF zviu[z] & (scena IN zsc[z]) & (px >= zx[z]) & (px < zx[z] + zw[z]) & (py >= zy[z]) & (py < zy[z] + zh[z]) THEN r := z END;
      DEC(z)
    END;
    RETURN r
  END ZonaLa;

  PROCEDURE ZonaAtinsa*(): INTEGER;   (* zona apasata in cadrul acesta; -1 = niciuna *)
  BEGIN RETURN zonaAtinsa
  END ZonaAtinsa;

  (* ---------- intrarea ---------- *)

  PROCEDURE Calibreaza*;   (* inclinarea de acum devine zero *)
  BEGIN gx0 := Ecran.Citeste(7); gy0 := Ecran.Citeste(8); gz0 := Ecran.Citeste(9)
  END Calibreaza;

  PROCEDURE Intrare;
    VAR c, f, xa, ya, z: INTEGER; nou: BOOLEAN;
  BEGIN
    gx := Ecran.Citeste(7); gy := Ecran.Citeste(8); gz := Ecran.Citeste(9);
    jos := Ecran.Citeste(0) # 0; dx := 0; dy := 0; zonaAtinsa := -1;
    c := Ecran.Citeste(3); nou := c # atingeri; atingeri := c;
    xa := x; ya := y;
    IF jos OR nou THEN x := Ecran.Citeste(1); y := Ecran.Citeste(2) END;
    IF nou THEN
      Pune(Atinge, 0); xj := x; yj := y; tJos := tReal; mutat := FALSE; lungDat := FALSE
    ELSIF jos & josInainte THEN
      dx := x - xa; dy := y - ya;
      IF (dx # 0) OR (dy # 0) THEN Pune(Trage, 0) END;
      IF ABS(x - xj) + ABS(y - yj) > prag THEN mutat := TRUE END;
      IF ~mutat & ~lungDat & (tReal - tJos >= 600) THEN lungDat := TRUE; Pune(Lung, 0) END
    END;
    IF ~jos & (josInainte OR nou) THEN
      Pune(Ridica, tReal - tJos);
      IF ~mutat & ~lungDat & (tReal - tJos < 450) THEN
        z := ZonaLa(x, y); zonaAtinsa := z;
        Pune(Apasa, z);
        IF z >= 0 THEN Pune(zev[z], zval[z]) END
      END
    END;
    josInainte := jos;
    f := Ecran.Citeste(17); IF f # 0 THEN f := 1 END;
    IF f # fundal THEN
      fundal := f; Pune(Fundal, f);
      IF (f = 1) & autoPauza THEN pauza := TRUE END
    END
  END Intrare;

  (* ---------- ce afla literele ---------- *)

  PROCEDURE X*(): INTEGER;  BEGIN RETURN x END X;
  PROCEDURE Y*(): INTEGER;  BEGIN RETURN y END Y;
  PROCEDURE DX*(): INTEGER;  BEGIN RETURN dx END DX;
  PROCEDURE DY*(): INTEGER;  BEGIN RETURN dy END DY;
  PROCEDURE XJos*(): INTEGER;  BEGIN RETURN xj END XJos;   (* unde a atins degetul la inceput *)
  PROCEDURE YJos*(): INTEGER;  BEGIN RETURN yj END YJos;
  PROCEDURE Jos*(): BOOLEAN;  BEGIN RETURN jos END Jos;
  PROCEDURE Gx*(): INTEGER;  BEGIN RETURN gx END Gx;   (* gravitatia, in miimi de m/s2 *)
  PROCEDURE Gy*(): INTEGER;  BEGIN RETURN gy END Gy;
  PROCEDURE Gz*(): INTEGER;  BEGIN RETURN gz END Gz;
  PROCEDURE Ix*(): INTEGER;  BEGIN RETURN gx - gx0 END Ix;   (* fata de Calibreaza *)
  PROCEDURE Iy*(): INTEGER;  BEGIN RETURN gy - gy0 END Iy;
  PROCEDURE Iz*(): INTEGER;  BEGIN RETURN gz - gz0 END Iz;

  PROCEDURE Ridicat*(): REAL;   (* sinusul unghiului telefonului fata de orizontala: 0 culcat, 1 in picioare *)
    VAR n, r: REAL;
  BEGIN
    n := Math.sqrt(FLT(gy) * FLT(gy) + FLT(gz) * FLT(gz));
    IF n > 1.0 THEN r := FLT(gy) / n ELSE r := 0.5 END;
    RETURN r
  END Ridicat;

  PROCEDURE Latime*(): INTEGER;  BEGIN RETURN w END Latime;
  PROCEDURE Inaltime*(): INTEGER;  BEGIN RETURN h END Inaltime;
  PROCEDURE Pas*(): REAL;  BEGIN RETURN pas END Pas;   (* 1.0 = un cadru de 16 ms (si in pauza) *)
  PROCEDURE Timp*(): INTEGER;  BEGIN RETURN tJoc END Timp;   (* ms de joc: fara pauze *)
  PROCEDURE TimpReal*(): INTEGER;  BEGIN RETURN tReal END TimpReal;   (* ms de la pornire, cu tot cu pauze *)
  PROCEDURE Cadru*(): INTEGER;  BEGIN RETURN cadru END Cadru;
  PROCEDURE Fps*(): INTEGER;  BEGIN RETURN fps END Fps;

  PROCEDURE Arat*;   (* cadrul a fost deja trimis (placa grafica): motorul nu mai cheama Ecran.Arata *)
  BEGIN arat := TRUE
  END Arat;

  PROCEDURE Opreste*;
  BEGIN stop := TRUE
  END Opreste;

  (* ---------- bucla ---------- *)

  PROCEDURE Ruleaza*;
    VAR f0, k, dt: INTEGER;
  BEGIN
    IF ~Ecran.Deschide() THEN Out.String("Motor2: fereastra nu s-a deschis (merge in Byz7 2 sau mai nou)"); Out.Ln
    ELSE
      w := Ecran.Latime(); h := Ecran.Inaltime(); prag := w DIV 40; IF prag < 8 THEN prag := 8 END;
      atingeri := Ecran.Citeste(3); josInainte := FALSE; fundal := 0; Calibreaza;
      tStart := Ceas.Ms(); tUltim := tStart; tReal := 0; tJoc := 0; cadru := 0; stop := FALSE; tFps := 0; nf := 0; fps := 0;
      Out.String("Motor2: "); Out.Int(nl, 0); Out.String(" litere, fereastra "); Out.Int(w, 0); Out.String(" x ");
      Out.Int(h, 0); Out.Ln; Out.Flush;
      Pune(Scena, scena);   (* pornirea: acum e fereastra *)
      WHILE ~stop & Ecran.Deschis() DO
        f0 := Ceas.Ms(); dt := f0 - tUltim; tUltim := f0; tReal := f0 - tStart;
        IF dt > 100 THEN dt := 100 END;   (* dupa o oprire lunga, jocul nu sare *)
        IF ~pauza THEN tJoc := tJoc + dt END;
        pas := FLT(dt) / 16.0; IF pas > 3.0 THEN pas := 3.0 END; IF pas < 0.2 THEN pas := 0.2 END;
        arat := FALSE;
        Intrare;
        IF ~pauza THEN Ceasuri END;
        Pune(Tick, cadru); Livreaza;
        IF ~arat THEN Ecran.Arata END;
        INC(cadru); INC(nf);
        IF tReal - tFps >= 1000 THEN fps := nf; nf := 0; tFps := tReal END;
        k := 16 - (Ceas.Ms() - f0); IF k > 0 THEN Ceas.Asteapta(k) END
      END;
      Out.String("Motor2: oprit dupa "); Out.Int(cadru, 0); Out.String(" cadre; mesaje pierdute: "); Out.Int(pierdute, 0); Out.Ln;
      FOR k := 0 TO nl - 1 DO
        Out.String("  "); Out.String(nume[k]); Out.String(" trezita de "); Out.Int(trez[k], 0); Out.String(" ori"); Out.Ln
      END
    END
  END Ruleaza;

  PROCEDURE Init;
    VAR i: INTEGER;
  BEGIN
    nl := 0; qa := 0; qn := 0; pierdute := 0; nr := 0; nz := 0; scena := 0; zonaAtinsa := -1;
    FOR i := 0 TO MA - 1 DO aviu[i] := FALSE END;
    jurnal := FALSE; arat := FALSE; stop := FALSE; pauza := FALSE; autoPauza := TRUE; pornitM := TRUE;
    pas := 1.0; jos := FALSE; josInainte := FALSE; mutat := FALSE; lungDat := FALSE;
    x := 0; y := 0; xj := 0; yj := 0; dx := 0; dy := 0; tJos := 0; prag := 12;
    gx0 := 0; gy0 := 0; gz0 := 0; cadru := 0; tJoc := 0; tReal := 0; fps := 0
  END Init;

BEGIN
  Init
END Motor2.
