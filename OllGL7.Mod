MODULE OllGL7;  (* GL 7 (24 nov 2026, Pixipogo 44): OllGL6 plus pictures on the graphics card (textures).
     Pion: "la placa video" and "they will want fast games on mediocre hardware; so we will give them".
     The pixels are given here from Oberon (Pic5 reads the pictures, a game makes its own), they go to the card once,
     and then a picture costs as little as two triangles, every frame, at the real resolution of the screen (the
     2D coordinates are the half pixels of the window, the card draws on all the pixels).
       OllGL7.Texturi()                        does the window draw them? (window ecran-cubn44.dex or newer)
       OllGL7.Textura(k, l, h, px)             slot k (0 .. 63) gets l x h pixels, px[y * l + x], colours as RGB / RGBA
       OllGL7.IncepeTextura(k, l, h); OllGL7.PixelTextura(c) l * h times, row after row; OllGL7.GataTextura
       OllGL7.Pixelat(TRUE)                    the next textures are drawn with sharp pixels (pixel art), not smoothed
       OllGL7.StergeTextura(k)                 the card forgets slot k
       Poza2D(x, y, l, h, k)                   the whole picture k in the rectangle
       Bucata2D(x, y, l, h, k, sx, sy, sl, sh) a part of it (a sprite of a sheet), in the pixels of the texture
       Sprite2D(x, y, l, h, unghi, k, c)       REAL: centred on (x, y), turned by unghi degrees, tinted by c
                                               (RGB(255, 255, 255) as it is; RGBA(255, 255, 255, 128) half seen)
     The pictures are drawn in the order of the calls, among the 2D triangles: what is drawn after covers them.
     Everything of OllGL6 is here the same (and OllGL6t is OllGL6 made of OllGL7, so the old modules share the frame).
     The window gets the pixels in the file gl-tex-k.raw of the app's folder; the frame says which generation
     of each slot to show (frame of version 4: 3D, 2D, then the pictures, 12 numbers each, then the 64 generations).

   GL 6 (19 nov 2026, Cubicum N 17): ca OllGL5, cu 40000 de triunghiuri 2D (121 de iconite pe telefonul lui Pion
     mancau tot cadrul si nu mai incapea titlul).
   GL 5 (19 nov 2026): ca OllGL4, cu 20000 de triunghiuri 2D intr-un cadru si Rotund2D.
   GL 4 (10 nov 2026): Rezerva(randuri). GL 3 (5 nov 2026): LuminaPunct. GL 2: Text2D, Numar2D, Cerc2D, Inel2D,
     Linie2D, Disc. La fiecare cadru:
       Incepe(fond);  Camera(ochi x y z, tinta x y z, unghi);  [Ceata(de, pana)]  [Lumina(f)]
       Triunghi / Patrat / Cub / Disc                       (* in lume: y in sus *)
       Triunghi2D / Dreptunghi2D / ... / Poza2D / Sprite2D  (* peste, in pixeli *)
       Arata
   Pion & Claude, 24.11.2026 *)

  IMPORT Ecran, Math, Fisier;

  CONST SEMN = 3361863;   (* 00334C47H: "GL3", cu alfa 0 (o culoare din RGB are alfa 255) *)
    M2 = 40000;           (* cate triunghiuri 2D intr-un cadru *)
    M4 = 4000;            (* cate poze intr-un cadru *)
    NT* = 64;             (* cate texturi (sloturi) *)
    TEX1 = 1413830705;    (* "TEX1": fereastra le stie *)
    MAXT* = 4096;         (* cel mai lung lat al unei texturi *)

  VAR w, h, cap, n3, n2, fond, rez: INTEGER;
    ox, oy, oz, tx, ty, tz, fov, cde, cpana, amb: REAL;
    lx, ly, lz, lraza, lputere: REAL; lcul: INTEGER;   (* lumina-punct *)
    rx, ry, rz, ux, uy, uz: REAL;   (* dreapta si susul camerei, pentru Disc *)
    t2: ARRAY 280000 OF INTEGER;
    sus, jos: ARRAY 128 OF INTEGER;
    n4, gseq, tk, tn, tf, pixelat: INTEGER;   (* pozele; ultima generatie; textura care se scrie: slot, pixeli ramasi, fisier *)
    t4: ARRAY M4 * 12 OF INTEGER;
    tgen, tlat, tina: ARRAY NT OF INTEGER;

  PROCEDURE RGB*(r, g, b: INTEGER): INTEGER;
  BEGIN RETURN r MOD 256 + 256 * (g MOD 256) + 65536 * (b MOD 256) - 16777216
  END RGB;

  PROCEDURE Pune(i, v: INTEGER);   (* al i-lea INTEGER al cadrului *)
  BEGIN Ecran.Pune(i MOD w, i DIV w, v)
  END Pune;

  PROCEDURE Mii(x: REAL): INTEGER;
  BEGIN RETURN FLOOR(x * 1000.0 + 0.5)
  END Mii;

  PROCEDURE Incepe*(culoareFond: INTEGER);
  BEGIN
    w := Ecran.Latime(); h := Ecran.Inaltime(); IF w < 1 THEN w := 1 END; IF h < 1 THEN h := 1 END; cap := w * (h - rez); IF cap < 64 THEN cap := 64 END;
    n3 := 0; n2 := 0; n4 := 0; fond := culoareFond; lraza := 0.0
  END Incepe;

  PROCEDURE Rezerva*(randuri: INTEGER);   (* cate randuri de la capatul ecranului nu se ating (sunetul) *)
  BEGIN IF randuri < 0 THEN randuri := 0 END; rez := randuri
  END Rezerva;

  PROCEDURE Camera*(x, y, z, x1, y1, z1, unghi: REAL);   (* ochiul, unde se uita, unghiul de vedere (grade, pe inaltime) *)
    VAR dx, dy, dz, l: REAL;
  BEGIN
    ox := x; oy := y; oz := z; tx := x1; ty := y1; tz := z1; fov := unghi;
    dx := x1 - x; dy := y1 - y; dz := z1 - z; l := Math.sqrt(dx * dx + dy * dy + dz * dz);
    IF l < 0.0001 THEN dx := 0.0; dy := 0.0; dz := -1.0 ELSE dx := dx / l; dy := dy / l; dz := dz / l END;
    (* dreapta = directia x (0, 1, 0); daca te uiti drept in sus sau in jos, ia (0, 0, -1) ca sus *)
    IF ABS(dy) > 0.98 THEN rx := -dy; ry := 0.0; rz := 0.0 ELSE rx := -dz; ry := 0.0; rz := dx END;
    l := Math.sqrt(rx * rx + ry * ry + rz * rz); rx := rx / l; ry := ry / l; rz := rz / l;
    ux := ry * dz - rz * dy; uy := rz * dx - rx * dz; uz := rx * dy - ry * dx
  END Camera;

  PROCEDURE Ceata*(de, pana: REAL);   (* 0, 0 = fara *)
  BEGIN cde := de; cpana := pana
  END Ceata;

  PROCEDURE Lumina*(f: REAL);   (* cat se vede o fata din umbra: 0.1 .. 1; 1 = culorile exact cum le dai *)
  BEGIN amb := f
  END Lumina;

  PROCEDURE LuminaPunct*(x, y, z, raza, putere: REAL; c: INTEGER);   (* un bec in (x, y, z): la raza lui, lumina scade la jumatate *)
  BEGIN lx := x; ly := y; lz := z; lraza := raza; lputere := putere; lcul := c
  END LuminaPunct;

  PROCEDURE Triunghi*(x0, y0, z0, x1, y1, z1, x2, y2, z2: REAL; c: INTEGER);
    VAR b: INTEGER;
  BEGIN
    b := 64 + n3 * 10;
    IF b + 10 + n2 * 7 <= cap THEN
      Pune(b, Mii(x0)); Pune(b + 1, Mii(y0)); Pune(b + 2, Mii(z0));
      Pune(b + 3, Mii(x1)); Pune(b + 4, Mii(y1)); Pune(b + 5, Mii(z1));
      Pune(b + 6, Mii(x2)); Pune(b + 7, Mii(y2)); Pune(b + 8, Mii(z2));
      Pune(b + 9, c); INC(n3)
    END
  END Triunghi;

  PROCEDURE Patrat*(x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3: REAL; c: INTEGER);
  BEGIN
    Triunghi(x0, y0, z0, x1, y1, z1, x2, y2, z2, c);
    Triunghi(x0, y0, z0, x2, y2, z2, x3, y3, z3, c)
  END Patrat;

  PROCEDURE Cub*(x, y, z, lat: REAL; c: INTEGER);
    VAR a, b, d, e, f, g: REAL;
  BEGIN
    a := x - lat / 2.0; b := x + lat / 2.0; d := y - lat / 2.0; e := y + lat / 2.0; f := z - lat / 2.0; g := z + lat / 2.0;
    Patrat(a, d, g, b, d, g, b, e, g, a, e, g, c);
    Patrat(b, d, f, a, d, f, a, e, f, b, e, f, c);
    Patrat(a, d, f, a, d, g, a, e, g, a, e, f, c);
    Patrat(b, d, g, b, d, f, b, e, f, b, e, g, c);
    Patrat(a, e, g, b, e, g, b, e, f, a, e, f, c);
    Patrat(a, d, f, b, d, f, b, d, g, a, d, g, c)
  END Cub;

  PROCEDURE Disc*(x, y, z, r: REAL; n, c: INTEGER);   (* cerc plin cu n laturi (6..32), cu fata spre camera *)
    VAR k: INTEGER; u0, u1, c0, s0, c1, s1: REAL;
  BEGIN
    IF n < 6 THEN n := 6 ELSIF n > 32 THEN n := 32 END;
    FOR k := 0 TO n - 1 DO
      u0 := 6.28318530717959 * FLT(k) / FLT(n); u1 := 6.28318530717959 * FLT(k + 1) / FLT(n);
      c0 := Math.cos(u0) * r; s0 := Math.sin(u0) * r; c1 := Math.cos(u1) * r; s1 := Math.sin(u1) * r;
      Triunghi(x, y, z,
        x + c0 * rx + s0 * ux, y + c0 * ry + s0 * uy, z + c0 * rz + s0 * uz,
        x + c1 * rx + s1 * ux, y + c1 * ry + s1 * uy, z + c1 * rz + s1 * uz, c)
    END
  END Disc;

  (* ---------- deasupra, in pixeli ---------- *)

  PROCEDURE Triunghi2D*(x0, y0, x1, y1, x2, y2, c: INTEGER);
    VAR b: INTEGER;
  BEGIN
    IF n2 < M2 THEN
      b := n2 * 7;
      t2[b] := x0; t2[b + 1] := y0; t2[b + 2] := x1; t2[b + 3] := y1; t2[b + 4] := x2; t2[b + 5] := y2; t2[b + 6] := c;
      INC(n2)
    END
  END Triunghi2D;

  PROCEDURE Dreptunghi2D*(x, y, lat, inalt, c: INTEGER);
  BEGIN
    IF (lat > 0) & (inalt > 0) THEN
      Triunghi2D(x, y, x + lat, y, x + lat, y + inalt, c);
      Triunghi2D(x, y, x + lat, y + inalt, x, y + inalt, c)
    END
  END Dreptunghi2D;

  PROCEDURE Cerc2D*(x, y, r, c: INTEGER);   (* plin *)
    VAR k, n, x0, y0, x1, y1: INTEGER; u: REAL;
  BEGIN
    IF r < 1 THEN r := 1 END;
    n := 8 + r DIV 3; IF n > 28 THEN n := 28 END;
    x0 := x + r; y0 := y;
    FOR k := 1 TO n DO
      u := 6.28318530717959 * FLT(k) / FLT(n);
      x1 := x + FLOOR(Math.cos(u) * FLT(r) + 0.5); y1 := y + FLOOR(Math.sin(u) * FLT(r) + 0.5);
      Triunghi2D(x, y, x0, y0, x1, y1, c); x0 := x1; y0 := y1
    END
  END Cerc2D;

  PROCEDURE Inel2D*(x, y, r, gros, c: INTEGER);   (* doar marginea *)
    VAR k, n, a0, b0, a1, b1, p0, q0, p1, q1: INTEGER; u, r2: REAL;
  BEGIN
    IF r < 1 THEN r := 1 END; r2 := FLT(r - gros); IF r2 < 0.0 THEN r2 := 0.0 END;
    n := 10 + r DIV 3; IF n > 32 THEN n := 32 END;
    a0 := x + r; b0 := y; p0 := x + FLOOR(r2); q0 := y;
    FOR k := 1 TO n DO
      u := 6.28318530717959 * FLT(k) / FLT(n);
      a1 := x + FLOOR(Math.cos(u) * FLT(r) + 0.5); b1 := y + FLOOR(Math.sin(u) * FLT(r) + 0.5);
      p1 := x + FLOOR(Math.cos(u) * r2 + 0.5); q1 := y + FLOOR(Math.sin(u) * r2 + 0.5);
      Triunghi2D(a0, b0, a1, b1, p1, q1, c); Triunghi2D(a0, b0, p1, q1, p0, q0, c);
      a0 := a1; b0 := b1; p0 := p1; q0 := q1
    END
  END Inel2D;

  PROCEDURE Linie2D*(x0, y0, x1, y1, gros, c: INTEGER);
    VAR dx, dy, l, nx, ny: REAL; a, b: INTEGER;
  BEGIN
    dx := FLT(x1 - x0); dy := FLT(y1 - y0); l := Math.sqrt(dx * dx + dy * dy);
    IF l < 0.5 THEN Dreptunghi2D(x0, y0, gros, gros, c)
    ELSE
      nx := -dy / l * FLT(gros) / 2.0; ny := dx / l * FLT(gros) / 2.0;
      a := FLOOR(nx + 0.5); b := FLOOR(ny + 0.5); IF (a = 0) & (b = 0) THEN a := 1 END;
      Triunghi2D(x0 + a, y0 + b, x1 + a, y1 + b, x1 - a, y1 - b, c);
      Triunghi2D(x0 + a, y0 + b, x1 - a, y1 - b, x0 - a, y0 - b, c)
    END
  END Linie2D;

  PROCEDURE Litera2D*(x, y: INTEGER; ch: CHAR; m, c: INTEGER);   (* 5 x 7, punctele de pe un rand lipite *)
    VAR k, r, b, v, i0: INTEGER;
  BEGIN
    k := ORD(ch); IF (k >= ORD("a")) & (k <= ORD("z")) THEN k := k - 32 END;
    IF (k >= 0) & (k < 128) THEN
      FOR r := 0 TO 6 DO
        IF r < 6 THEN v := sus[k]; FOR b := r TO 4 DO v := v DIV 32 END; v := v MOD 32 ELSE v := jos[k] END;
        b := 0;
        WHILE b < 5 DO
          IF ODD(v DIV LSL(1, 4 - b)) THEN
            i0 := b; WHILE (b < 5) & ODD(v DIV LSL(1, 4 - b)) DO INC(b) END;
            Dreptunghi2D(x + i0 * m, y + r * m, (b - i0) * m, m, c)
          ELSE INC(b)
          END
        END
      END
    END
  END Litera2D;

  PROCEDURE Text2D*(x, y: INTEGER; s: ARRAY OF CHAR; m, c: INTEGER);   (* ca Grafica.Text *)
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Litera2D(x + i * 6 * m, y, s[i], m, c); INC(i) END
  END Text2D;

  PROCEDURE Numar2D*(x, y, n, m, c: INTEGER);
    VAR d: ARRAY 12 OF CHAR; s: ARRAY 13 OF CHAR; k, i: INTEGER; minus: BOOLEAN;
  BEGIN
    minus := n < 0; IF minus THEN n := -n END;
    k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    i := 0; IF minus THEN s[0] := "-"; i := 1 END;
    WHILE k > 0 DO DEC(k); s[i] := d[k]; INC(i) END; s[i] := 0X;
    Text2D(x, y, s, m, c)
  END Numar2D;

  PROCEDURE Sfert(x, y, r, u0, c: INTEGER);   (* un sfert de cerc plin, din unghiul u0 (in sferturi) *)
    VAR k, x0, y0, x1, y1: INTEGER; u: REAL;
  BEGIN
    u := 1.5707963267949 * FLT(u0);
    x0 := x + FLOOR(Math.cos(u) * FLT(r) + 0.5); y0 := y + FLOOR(Math.sin(u) * FLT(r) + 0.5);
    FOR k := 1 TO 5 DO
      u := 1.5707963267949 * (FLT(u0) + FLT(k) / 5.0);
      x1 := x + FLOOR(Math.cos(u) * FLT(r) + 0.5); y1 := y + FLOOR(Math.sin(u) * FLT(r) + 0.5);
      Triunghi2D(x, y, x0, y0, x1, y1, c); x0 := x1; y0 := y1
    END
  END Sfert;

  PROCEDURE Rotund2D*(x, y, lat, inalt, r, c: INTEGER);   (* dreptunghi plin cu colturi rotunde de raza r *)
  BEGIN
    IF r > lat DIV 2 THEN r := lat DIV 2 END; IF r > inalt DIV 2 THEN r := inalt DIV 2 END;
    IF r < 1 THEN Dreptunghi2D(x, y, lat, inalt, c)
    ELSE
      Dreptunghi2D(x + r, y, lat - 2 * r, inalt, c);
      Dreptunghi2D(x, y + r, r, inalt - 2 * r, c); Dreptunghi2D(x + lat - r, y + r, r, inalt - 2 * r, c);
      Sfert(x + r, y + r, r, 2, c); Sfert(x + lat - r, y + r, r, 3, c);
      Sfert(x + lat - r, y + inalt - r, r, 0, c); Sfert(x + r, y + inalt - r, r, 1, c)
    END
  END Rotund2D;

  PROCEDURE Liber2D*(): INTEGER;   (* cate triunghiuri 2D mai incap in cadrul acesta *)
  BEGIN RETURN M2 - n2
  END Liber2D;


  (* ---------- pozele: texturi pe placa grafica ---------- *)

  PROCEDURE RGBA*(r, g, b, a: INTEGER): INTEGER;   (* a: 0 nevazut .. 255 plin *)
    VAR v: INTEGER;
  BEGIN
    v := r MOD 256 + 256 * (g MOD 256) + 65536 * (b MOD 256); a := a MOD 256;
    IF a >= 128 THEN v := v + (a - 256) * 16777216 ELSE v := v + a * 16777216 END
    RETURN v
  END RGBA;

  PROCEDURE Texturi*(): BOOLEAN;   (* fereastra stie sa le deseneze? *)
  BEGIN RETURN Ecran.Citeste(26) = TEX1
  END Texturi;

  PROCEDURE Pixelat*(da: BOOLEAN);   (* texturile urmatoare: pixeli ascutiti (pixel art) *)
  BEGIN IF da THEN pixelat := 1 ELSE pixelat := 0 END
  END Pixelat;

  PROCEDURE Int(f, v: INTEGER);   (* 4 octeti, cel mic primul *)
  BEGIN
    IF v < 0 THEN
      v := v + 2147483647 + 1;
      Fisier.Scrie(f, v MOD 256); Fisier.Scrie(f, v DIV 256 MOD 256); Fisier.Scrie(f, v DIV 65536 MOD 256); Fisier.Scrie(f, v DIV 16777216 + 128)
    ELSE
      Fisier.Scrie(f, v MOD 256); Fisier.Scrie(f, v DIV 256 MOD 256); Fisier.Scrie(f, v DIV 65536 MOD 256); Fisier.Scrie(f, v DIV 16777216)
    END
  END Int;

  PROCEDURE Nume(k: INTEGER; VAR s: ARRAY OF CHAR);   (* gl-tex-k.raw *)
    VAR i: INTEGER;
  BEGIN
    s[0] := "g"; s[1] := "l"; s[2] := "-"; s[3] := "t"; s[4] := "e"; s[5] := "x"; s[6] := "-"; i := 7;
    IF k >= 10 THEN s[i] := CHR(ORD("0") + k DIV 10); INC(i) END;
    s[i] := CHR(ORD("0") + k MOD 10); INC(i);
    s[i] := "."; s[i + 1] := "r"; s[i + 2] := "a"; s[i + 3] := "w"; s[i + 4] := 0X
  END Nume;

  PROCEDURE GataTextura*;   (* dupa ultimul pixel: placa o ia la cadrul urmator *)
  BEGIN
    IF tf >= 0 THEN
      WHILE tn > 0 DO Int(tf, 0); DEC(tn) END;   (* ce lipseste: nevazut *)
      Fisier.Gata(tf); tf := -1; tgen[tk] := gseq
    END
  END GataTextura;

  PROCEDURE IncepeTextura*(k, l, h: INTEGER);   (* apoi PixelTextura de l * h ori, rand dupa rand, de sus *)
    VAR s: ARRAY 24 OF CHAR;
  BEGIN
    IF tf >= 0 THEN GataTextura END;
    IF (k >= 0) & (k < NT) & (l > 0) & (h > 0) & (l <= MAXT) & (h <= MAXT) THEN
      Nume(k, s); tf := Fisier.Creeaza(s);
      IF tf >= 0 THEN
        INC(gseq); tk := k; tn := l * h; tlat[k] := l; tina[k] := h;
        Fisier.Scrie(tf, ORD("G")); Fisier.Scrie(tf, ORD("L")); Fisier.Scrie(tf, ORD("T")); Fisier.Scrie(tf, ORD("1"));
        Int(tf, l); Int(tf, h); Int(tf, gseq); Int(tf, pixelat)
      END
    END
  END IncepeTextura;

  PROCEDURE PixelTextura*(c: INTEGER);   (* culoarea ca RGB / RGBA; placa vrea culorile inmultite cu alfa *)
    VAR r, g, b, a: INTEGER;
  BEGIN
    IF (tf >= 0) & (tn > 0) THEN
      IF c < 0 THEN c := c + 2147483647 + 1; a := 128 ELSE a := 0 END;
      a := a + c DIV 16777216; c := c MOD 16777216;
      r := c MOD 256; g := c DIV 256 MOD 256; b := c DIV 65536;
      IF a < 255 THEN r := (r * a + 127) DIV 255; g := (g * a + 127) DIV 255; b := (b * a + 127) DIV 255 END;
      Fisier.Scrie(tf, r); Fisier.Scrie(tf, g); Fisier.Scrie(tf, b); Fisier.Scrie(tf, a);
      DEC(tn)
    END
  END PixelTextura;

  PROCEDURE Textura*(k, l, h: INTEGER; VAR px: ARRAY OF INTEGER);   (* px[y * l + x] *)
    VAR i, n: INTEGER;
  BEGIN
    n := l * h; IF n > LEN(px) THEN n := LEN(px) END;
    IncepeTextura(k, l, h);
    IF tf >= 0 THEN FOR i := 0 TO n - 1 DO PixelTextura(px[i]) END END;
    GataTextura
  END Textura;

  PROCEDURE StergeTextura*(k: INTEGER);
    VAR s: ARRAY 24 OF CHAR;
  BEGIN
    IF (k >= 0) & (k < NT) THEN tgen[k] := 0; tlat[k] := 0; tina[k] := 0; Nume(k, s); Fisier.Sterge(s) END
  END StergeTextura;

  PROCEDURE LatTextura*(k: INTEGER): INTEGER;
    VAR v: INTEGER;
  BEGIN v := 0; IF (k >= 0) & (k < NT) THEN v := tlat[k] END
    RETURN v
  END LatTextura;

  PROCEDURE InaltTextura*(k: INTEGER): INTEGER;
    VAR v: INTEGER;
  BEGIN v := 0; IF (k >= 0) & (k < NT) THEN v := tina[k] END
    RETURN v
  END InaltTextura;

  PROCEDURE Poza(x16, y16, l16, h16, k, sx, sy, sl, sh, c, mgrade: INTEGER);   (* in saisprezecimi de pixel *)
    VAR b: INTEGER;
  BEGIN
    IF (n4 < M4) & (k >= 0) & (k < NT) & (tgen[k] # 0) & (l16 > 0) & (h16 > 0) THEN
      b := n4 * 12;
      t4[b] := n2; t4[b + 1] := k; t4[b + 2] := x16; t4[b + 3] := y16; t4[b + 4] := l16; t4[b + 5] := h16;
      t4[b + 6] := sx; t4[b + 7] := sy; t4[b + 8] := sl; t4[b + 9] := sh; t4[b + 10] := c; t4[b + 11] := mgrade;
      INC(n4)
    END
  END Poza;

  PROCEDURE Poza2D*(x, y, l, h, k: INTEGER);   (* toata textura k in dreptunghi *)
  BEGIN Poza(x * 16, y * 16, l * 16, h * 16, k, 0, 0, 0, 0, -1, 0)
  END Poza2D;

  PROCEDURE Bucata2D*(x, y, l, h, k, sx, sy, sl, sh: INTEGER);   (* bucata (sx, sy, sl, sh) a texturii, in pixelii ei *)
  BEGIN Poza(x * 16, y * 16, l * 16, h * 16, k, sx, sy, sl, sh, -1, 0)
  END Bucata2D;

  PROCEDURE Sprite2D*(x, y, l, h, unghi: REAL; k, c: INTEGER);   (* centrul in (x, y), intoarsa cu unghi grade, colorata cu c *)
  BEGIN
    Poza(FLOOR((x - l / 2.0) * 16.0 + 0.5), FLOOR((y - h / 2.0) * 16.0 + 0.5), FLOOR(l * 16.0 + 0.5), FLOOR(h * 16.0 + 0.5),
      k, 0, 0, 0, 0, c, FLOOR(unghi * 1000.0 + 0.5))
  END Sprite2D;

  PROCEDURE BucataSprite2D*(x, y, l, h, unghi: REAL; k, sx, sy, sl, sh, c: INTEGER);   (* un sprite dintr-o foaie *)
  BEGIN
    Poza(FLOOR((x - l / 2.0) * 16.0 + 0.5), FLOOR((y - h / 2.0) * 16.0 + 0.5), FLOOR(l * 16.0 + 0.5), FLOOR(h * 16.0 + 0.5),
      k, sx, sy, sl, sh, c, FLOOR(unghi * 1000.0 + 0.5))
  END BucataSprite2D;

  PROCEDURE LiberePoze*(): INTEGER;   (* cate poze mai incap in cadrul acesta *)
  BEGIN RETURN M4 - n4
  END LiberePoze;

  PROCEDURE Arata*;
    VAR b, k, n, m, rest: INTEGER;
  BEGIN
    b := 64 + n3 * 10; rest := cap - b - NT; IF rest < 0 THEN rest := 0 END;
    n := n2; IF n * 7 > rest THEN n := rest DIV 7 END;
    rest := rest - n * 7; m := n4; IF m * 12 > rest THEN m := rest DIV 12 END;
    FOR k := 0 TO n * 7 - 1 DO Pune(b + k, t2[k]) END;
    b := b + n * 7;
    IF b + m * 12 + NT <= cap THEN
      FOR k := 0 TO m * 12 - 1 DO Pune(b + k, t4[k]) END;
      b := b + m * 12;
      FOR k := 0 TO NT - 1 DO Pune(b + k, tgen[k]) END
    ELSE m := 0
    END;
    Pune(0, SEMN); Pune(1, 4); Pune(2, n3); Pune(3, n);
    Pune(4, fond); Pune(5, Mii(fov));
    Pune(6, Mii(ox)); Pune(7, Mii(oy)); Pune(8, Mii(oz));
    Pune(9, Mii(tx)); Pune(10, Mii(ty)); Pune(11, Mii(tz));
    Pune(12, Mii(cde)); Pune(13, Mii(cpana)); Pune(14, Mii(amb)); Pune(15, 0);
    Pune(16, Mii(lx)); Pune(17, Mii(ly)); Pune(18, Mii(lz)); Pune(19, Mii(lraza)); Pune(20, Mii(lputere)); Pune(21, lcul);
    IF b + NT <= cap THEN Pune(22, m); Pune(23, NT) ELSE Pune(22, 0); Pune(23, 0) END;
    Ecran.Arata
  END Arata;

  PROCEDURE G(k, a, b: INTEGER);
  BEGIN sus[k] := a; jos[k] := b
  END G;

  PROCEDURE Litere;   (* aceleasi litere ca in Grafica *)
  BEGIN
    G(32, 0, 0); G(48, 488232753, 14); G(49, 146935940, 14); G(50, 487622792, 31); G(51, 1042417713, 14);
    G(52, 73747426, 2); G(53, 1057948721, 14); G(54, 210270769, 14); G(55, 1041305864, 8); G(56, 488159793, 14);
    G(57, 488160290, 12); G(65, 488177201, 17); G(66, 1025047089, 30); G(67, 488129041, 14); G(68, 958973490, 28);
    G(69, 1057520144, 31); G(70, 1057520144, 16); G(71, 488136241, 15); G(72, 588840497, 17); G(73, 474091652, 14);
    G(74, 237045842, 12); G(75, 589980306, 17); G(76, 554189328, 31); G(77, 599447089, 17); G(78, 589092465, 17);
    G(79, 488162865, 14); G(80, 1025047056, 16); G(81, 488162994, 13); G(82, 1025047186, 17); G(83, 520632353, 30);
    G(84, 1044516996, 4); G(85, 588826161, 14); G(86, 588826154, 4); G(87, 588830389, 10); G(88, 588583249, 17);
    G(89, 588583044, 4); G(90, 1041305872, 31); G(46, 12, 12); G(44, 388, 8); G(58, 12976524, 0); G(45, 31744, 0);
    G(43, 4357252, 0); G(61, 1016800, 0); G(33, 138547328, 4); G(63, 487622784, 4); G(47, 1118480, 0);
    G(40, 71573764, 2); G(41, 272697412, 8); G(37, 831590675, 3); G(42, 4897444, 0); G(60, 71581956, 2); G(62, 272696388, 8)
  END Litere;

BEGIN
  w := 1; h := 1; cap := 1; n3 := 0; n2 := 0; fond := 0; rez := 0;
  ox := 0.0; oy := 0.0; oz := 10.0; tx := 0.0; ty := 0.0; tz := 0.0; fov := 60.0; cde := 0.0; cpana := 0.0; amb := 0.35;
  rx := 1.0; ry := 0.0; rz := 0.0; ux := 0.0; uy := 1.0; uz := 0.0;
  lx := 0.0; ly := 0.0; lz := 0.0; lraza := 0.0; lputere := 0.0; lcul := 0;
  n4 := 0; gseq := 0; tk := 0; tn := 0; tf := -1; pixelat := 0;
  WHILE tk < NT DO tgen[tk] := 0; tlat[tk] := 0; tina[tk] := 0; INC(tk) END; tk := 0;
  Litere
END OllGL7.
