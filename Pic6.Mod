MODULE Pic6;  (* PIC 6 (24 Nov 2026, Pixipogo 45): smoother pictures. Pion: "and smooth the pictures, as you say".
     Most JPEG and every WEBP keep their colour at half the size of the picture (one colour for 2 x 2 pixels); Pic 5
     took that colour as it was, so the edges of the colours had little steps. Now the whole picture is kept first
     (its planes: the light at every pixel, the colours at their own size, a byte each, up to 24 MB), and each pixel
     takes its colour from the 4 nearest, 9 3 3 1 sixteenths (the "fancy upsampling" of libjpeg and libwebp).
     And WEBP gets its loop filter (RFC 6386, 15; simple and normal, as libwebp does it): the edges of its 4 x 4 and
     16 x 16 blocks are smoothed as the one who made the picture meant them to be.
     A picture too big for the planes is read as in Pic 5.
   PIC 5 (24 Nov 2026, Pixipogo 44): the pictures whole, for the graphics card. Pion: "a better quality
     will always be appreciated" and then "to the video card". The cells were at most 128 on a side (the squares of
     Nora); now they can be as many as the pixels, up to MC = 1600 on a side, and each keeps its transparency:
       IF Pic5.Load("web.dat", 640) THEN  (* Pic5.cw x Pic5.ch pixels in Pic5.pix, colours as OllGL7.RGBA *)
     A picture smaller than the size asked for keeps its own pixels (no squares at all); a bigger one is made
     smaller with the mean of the pixels that fall in each one. So OllGL7.Textura can give it to the card.
     Transparency: as before, a transparent pixel is laid on white (a dark page would hide black letters drawn on
     nothing); Pic5.KeepAlpha(TRUE) keeps it, for the sprites of a game.
     The cell array of Pic 1 .. 4 is gone: pix has the alpha in it (r + 256 g + 65536 b + 16777216 a).
   PIC 4 (24 Nov 2026, Pixipogo 43): PIC 4 (24 Nov 2026, Pixipogo 43): the whole progressive JPEG. Pion's Guardian pages: their photos are
     progressive, and Pic 2 and 3 read only the mean of each 8 x 8 block of them (a 140 pixel picture came out as 17
     squares). Now all the scans are read: the first ones of the means, those of the detail (spectral selection),
     and the bits added later (successive approximation), as libjpeg writes them; then the inverse DCT as for
     the baseline ones. Up to 2 million coefficients (a picture of about 2000 x 1300); bigger ones as before.
   PIC 3b (24 Nov 2026): PQ took 17 parameters and OLL2 takes 16 at most ("a box outside the table, number 16"); now 8 values at a time.
   PIC 3 (23 Nov 2026, Pixipogo 42): WEBP. Pion: "if I am tired, what stops you? Go on".
     The lossy WEBP pictures (a VP8 key frame, RFC 6386), the way libwebp reads them: the boolean decoder, the
     probabilities of the coefficients, the modes of the 16 x 16, 4 x 4 and chroma blocks, the Y2 block (WHT), the
     inverse DCT, YUV -> RGB with libwebp's numbers. Not the loop filter: it smooths the edges of the 4 x 4 blocks,
     which the squares do anyway. Lossless WEBP (VP8L) and the alpha of a WEBP are not here yet.
     The tables are libwebp's (BSD licence, Google), written out here as Oberon.
   PIC 2 (23 Nov 2026, Pixipogo 38): Pion: "do what you said". Now also
       GIF          the first picture of it (LZW), interlaced too, transparency on white;
       progressive JPEG   from the means of its 8 x 8 blocks (the first scans): enough for 128 squares on a side;
     and the size is asked for: Load(name, 64) for the page, Load(name, 120) for a picture seen big.
   PIC 1 (23 Nov 2026, Pixipogo 37): pictures for NoraChick, read here in Oberon, with no Android under them.
     Pion chose "pictures" for the browser; Pixipogo should do as much as it can in Oberon (and one day on bare metal),
     so the window only brings the bytes (web.dat) and Pic1 reads them:
       JPEG  baseline (the usual photos; Wikipedia's thumbnails). Progressive JPEG is not here yet.
       PNG   all colour kinds and depths, interlaced too, with transparency laid on white.
       SVG: Pic1 says what it is and that it cannot read it yet.
     The picture comes out small, at most MC x MC cells (each the mean colour of its part of the picture): the
     cube draws every cell as a little square, the way the letters are drawn.
       IF Pic1.Load("web.dat") THEN  (* Pic1.W, Pic1.H: the real size; Pic1.cw x Pic1.ch cells in Pic1.cell *)
       ELSE  (* Pic1.why says why *)
       END
   Pion & Claude, 23.11.2026 *)

  IMPORT Fisier, Math;

  CONST
    MC* = 1600;      (* the most cells on a side *)
    NC = 2560000;    (* MC * MC *)
    ND = 400000;     (* the 8 x 8 blocks of a progressive JPEG it keeps (their means) *)
    NPC = 2000000;   (* the coefficients of a progressive JPEG it keeps whole *)
    WBN = 4194304;   (* the most bytes of a VP8 chunk (what the window brings at most) *)
    BPS = 32; YOFF = BPS + 8; UOFF = YOFF + BPS * 16 + BPS; VOFF = UOFF + 16; YUVN = BPS * 17 + BPS * 9;   (* libwebp's work buffer *)
    MW = 8192;       (* the widest picture it reads *)
    JPN = 24000000;  (* the bytes of the planes of a JPEG or WEBP read whole *)
    WIN = 32768;     (* the window of deflate, and the longest row of a PNG *)
    IHDR = 49484452H; PLTE = 504C5445H; TRNS = 74524E53H; IDAT = 49444154H; IEND = 49454E44H;

  VAR
    W*, H*, cw*, ch*, kind*: INTEGER;   (* kind: 0 none, 1 JPEG, 2 PNG, 3 GIF, 4 WEBP *)
    pix*: ARRAY NC OF INTEGER;          (* the colours as OllGL7.RGBA (r + 256 g + 65536 b + 16777216 a), row after row *)
    why*: ARRAY 48 OF CHAR;
    good, eof: BOOLEAN;
    fh: INTEGER;
    accR, accG, accB, accA, accN: ARRAY NC OF INTEGER;   (* the colours multiplied by alpha (0 .. 255 each) *)
    keepA: BOOLEAN;
    jp: ARRAY JPN OF CHAR;                 (* the planes: component c at jOff[c], jW[c] bytes a row *)
    jOff, jW, jVw, jVh, jFx, jFy: ARRAY 4 OF INTEGER;   (* where, how wide, how much is real, how many pixels a sample *)
    planes: BOOLEAN;
    lfSimple, lfLevel, lfSharp, lfRef0, lfMode0: INTEGER; lfUse: BOOLEAN; wSegF: ARRAY 4 OF INTEGER;
    fLim, fIl, fHev: ARRAY 512 OF INTEGER; fIn: ARRAY 512 OF BOOLEAN;   (* the loop filter of each macroblock of a row *)
    colMap: ARRAY MW OF INTEGER;
    rowBase: INTEGER;
    pow2: ARRAY 17 OF INTEGER;
    (* JPEG *)
    zz: ARRAY 64 OF INTEGER;
    qt: ARRAY 4, 64 OF INTEGER;
    hBits: ARRAY 8, 17 OF INTEGER;
    hVal: ARRAY 8, 256 OF INTEGER;
    hMin, hMax, hPtr: ARRAY 8, 18 OF INTEGER;
    nComp, hMaxF, vMaxF, ri, bitBuf, bitCnt, mcuW, mcuH: INTEGER;
    cId, cHf, cVf, cQ, cTd, cTa, cPred: ARRAY 4 OF INTEGER;
    coef, blk: ARRAY 64 OF INTEGER;
    cosT, tmpR: ARRAY 64 OF REAL;
    plane: ARRAY 4, 1024 OF INTEGER;
    markerHit, progressive: BOOLEAN;
    hitMarker, lim: INTEGER;   (* the marker met inside a scan; the most cells asked for *)
    aw, ah, dOff: ARRAY 4 OF INTEGER;   (* progressive: the blocks of each component (with the padding of the MCUs) *)
    dcv: ARRAY ND OF INTEGER;
    pc: ARRAY NPC OF INTEGER; fullProg: BOOLEAN; eobrun: INTEGER;   (* the whole progressive JPEG *)
    (* GIF *)
    gPre, gSuf: ARRAY 4096 OF INTEGER; gStack: ARRAY 4097 OF INTEGER;
    gPal: ARRAY 256 OF INTEGER; gLeft, gBuf, gCnt: INTEGER; gEnd: BOOLEAN;
    rowMap: ARRAY MW OF INTEGER;
    (* WEBP *)
    wb: ARRAY WBN OF CHAR; wbN: INTEGER;
    wP0, wUp, wPr: ARRAY 1056 OF INTEGER; wBm: ARRAY 900 OF INTEGER; wQ: ARRAY 256 OF INTEGER;
    rVal, rRange, rCnt, rPos, rEnd: ARRAY 9 OF INTEGER;   (* the boolean decoders: 0 the modes, 1 .. 8 the coefficients *)
    wCat: ARRAY 48 OF INTEGER; wZig, wDc: ARRAY 16 OF INTEGER; wBand: ARRAY 17 OF INTEGER; wTree: ARRAY 18 OF INTEGER;
    wSegP: ARRAY 3 OF INTEGER; wSegQ, wY1dc, wY1ac, wY2dc, wY2ac, wUvdc, wUvac: ARRAY 4 OF INTEGER;
    wUseSeg, wUpdMap, wAbs, wUseSkip, mbI4: BOOLEAN;
    wSkipP, wMbW, wMbH, wOs, wCs, mbSeg, mbSkip, mbYm, mbUv, wNzDcL: INTEGER;
    wIntT, wNzYT: ARRAY 2048 OF INTEGER; wNzUT, wNzVT: ARRAY 1024 OF INTEGER; wNzDcT: ARRAY 512 OF INTEGER;
    wIntL, wNzYL: ARRAY 4 OF INTEGER; wNzUL, wNzVL: ARRAY 2 OF INTEGER; mbIm: ARRAY 16 OF INTEGER;
    wCo: ARRAY 384 OF INTEGER; wYuv: ARRAY YUVN OF INTEGER;
    wOutY: ARRAY 16 * MW OF INTEGER; wOutU, wOutV: ARRAY 8 * (MW DIV 2) OF INTEGER;
    wTopY: ARRAY MW OF INTEGER; wTopU, wTopV: ARRAY MW DIV 2 OF INTEGER;
    (* PNG *)
    win, cur, prev: ARRAY WIN OF INTEGER;
    wpos: INTEGER;
    pal, palA: ARRAY 256 OF INTEGER;
    depth, ctype, chans, bpp, rowBytes, rowPos, filt, pngY, chunkLeft, dBuf, dCnt: INTEGER;
    idatEnd, allDone: BOOLEAN;
    pno, il, pw, ph, psx, psy, pdx, pdy: INTEGER;   (* the pno of an interlaced PNG (Adam7); one pno when not *)
    aSx, aSy, aDx, aDy: ARRAY 7 OF INTEGER;
    hcnt: ARRAY 3, 16 OF INTEGER;
    hsym: ARRAY 3, 320 OF INTEGER;
    lens, tmpL: ARRAY 320 OF INTEGER;
    lBase, lExtra, dBase, dExtra: ARRAY 30 OF INTEGER;
    clOrder: ARRAY 19 OF INTEGER;

  (* ---------- common ---------- *)

  PROCEDURE Fail(m: ARRAY OF CHAR);   (* the first reason stays *)
    VAR i: INTEGER;
  BEGIN
    IF good THEN
      i := 0; WHILE (i < LEN(m)) & (m[i] # 0X) & (i < LEN(why) - 1) DO why[i] := m[i]; INC(i) END; why[i] := 0X
    END;
    good := FALSE
  END Fail;

  PROCEDURE Byte(): INTEGER;
    VAR b: INTEGER;
  BEGIN
    b := Fisier.Citeste(fh);
    IF b < 0 THEN b := 0; IF ~eof THEN eof := TRUE; Fail("the file ends too soon") END END
    RETURN b
  END Byte;

  PROCEDURE Word(): INTEGER;   (* two bytes, the high one first *)
    VAR a, b: INTEGER;
  BEGIN a := Byte(); b := Byte()
    RETURN a * 256 + b
  END Word;

  PROCEDURE Clamp(v: INTEGER): INTEGER;
  BEGIN IF v < 0 THEN v := 0 ELSIF v > 255 THEN v := 255 END
    RETURN v
  END Clamp;

  PROCEDURE Grid(w, h: INTEGER);   (* the size of the picture -> how many cells *)
    VAR i: INTEGER;
  BEGIN
    W := w; H := h;
    IF (w <= 0) OR (h <= 0) THEN Fail("a picture of no size")
    ELSIF (w > MW) OR (h > MW) THEN Fail("too big")
    ELSE
      IF w >= h THEN cw := w; IF cw > lim THEN cw := lim END; ch := h * cw DIV w
      ELSE ch := h; IF ch > lim THEN ch := lim END; cw := w * ch DIV h
      END;
      IF cw < 1 THEN cw := 1 END;
      IF ch < 1 THEN ch := 1 END;
      FOR i := 0 TO cw * ch - 1 DO accR[i] := 0; accG[i] := 0; accB[i] := 0; accA[i] := 0; accN[i] := 0 END;
      FOR i := 0 TO w - 1 DO colMap[i] := i * cw DIV w END
    END
  END Grid;

  PROCEDURE Row(y: INTEGER);   (* the pixels that come now are on row y *)
  BEGIN rowBase := (y * ch DIV H) * cw
  END Row;

  PROCEDURE PixA(x, r, g, b, a: INTEGER);   (* a pixel with its alpha: 0 nothing .. 255 all *)
    VAR k: INTEGER;
  BEGIN
    k := rowBase + colMap[x];
    IF a >= 255 THEN accR[k] := accR[k] + r; accG[k] := accG[k] + g; accB[k] := accB[k] + b; accA[k] := accA[k] + 255
    ELSIF a > 0 THEN
      accR[k] := accR[k] + (r * a + 127) DIV 255; accG[k] := accG[k] + (g * a + 127) DIV 255;
      accB[k] := accB[k] + (b * a + 127) DIV 255; accA[k] := accA[k] + a
    END;
    accN[k] := accN[k] + 1
  END PixA;

  PROCEDURE Pix(x, r, g, b: INTEGER);
  BEGIN PixA(x, r, g, b, 255)
  END Pix;

  PROCEDURE Trans(x, r, g, b, a: INTEGER);   (* a pixel that may be transparent: kept so, or laid on white *)
  BEGIN
    IF keepA THEN PixA(x, r, g, b, a)
    ELSE
      IF a < 255 THEN
        r := (r * a + 255 * (255 - a)) DIV 255; g := (g * a + 255 * (255 - a)) DIV 255; b := (b * a + 255 * (255 - a)) DIV 255
      END;
      PixA(x, r, g, b, 255)
    END
  END Trans;

  PROCEDURE KeepAlpha*(yes: BOOLEAN);   (* TRUE: the transparent pixels stay so; FALSE (at first): on white *)
  BEGIN keepA := yes
  END KeepAlpha;

  PROCEDURE Finish;   (* each cell: the mean of its pixels *)
    VAR i, n, a, r, g, b: INTEGER;
  BEGIN
    FOR i := 0 TO cw * ch - 1 DO
      n := accN[i];
      IF n > 0 THEN
        a := (accA[i] + n DIV 2) DIV n;
        IF accA[i] > 0 THEN   (* back from "times alpha": the mean colour of what is seen *)
          r := FLOOR(FLT(accR[i]) * 255.0 / FLT(accA[i]) + 0.5); g := FLOOR(FLT(accG[i]) * 255.0 / FLT(accA[i]) + 0.5);
          b := FLOOR(FLT(accB[i]) * 255.0 / FLT(accA[i]) + 0.5);
          IF r > 255 THEN r := 255 END; IF g > 255 THEN g := 255 END; IF b > 255 THEN b := 255 END
        ELSE r := 0; g := 0; b := 0
        END
      ELSE a := 0; r := 0; g := 0; b := 0
      END;
      IF a >= 128 THEN pix[i] := r + 256 * g + 65536 * b + (a - 256) * 16777216
      ELSE pix[i] := r + 256 * g + 65536 * b + a * 16777216
      END
    END
  END Finish;

  (* ---------- the planes and their colours ---------- *)

  PROCEDURE PlanesFor(n: INTEGER);   (* components 0 .. n-1 with jW, jFx, jFy, jVw, jVh set and jOff[k] = its height *)
    VAR c, t, h: INTEGER;
  BEGIN
    t := 0; planes := TRUE;
    FOR c := 0 TO n - 1 DO
      h := jOff[c];
      IF (jW[c] > 0) & (h > 0) & (t <= JPN - jW[c] * h) & (jW[c] <= JPN DIV h) THEN jOff[c] := t; t := t + jW[c] * h
      ELSE planes := FALSE
      END
    END
  END PlanesFor;

  PROCEDURE At(c, x, y: INTEGER): INTEGER;
  BEGIN RETURN ORD(jp[jOff[c] + y * jW[c] + x])
  END At;

  PROCEDURE Up(c, X, Y: INTEGER): INTEGER;   (* component c at pixel (X, Y): from its 4 nearest samples, 9 3 3 1 *)
    VAR i, i2, j, j2, f, v: INTEGER;
  BEGIN
    f := jFx[c];
    IF f = 1 THEN i := X; i2 := X
    ELSIF f = 2 THEN i := X DIV 2; IF ODD(X) THEN i2 := i + 1 ELSE i2 := i - 1 END
    ELSE i := X DIV f; i2 := i
    END;
    f := jFy[c];
    IF f = 1 THEN j := Y; j2 := Y
    ELSIF f = 2 THEN j := Y DIV 2; IF ODD(Y) THEN j2 := j + 1 ELSE j2 := j - 1 END
    ELSE j := Y DIV f; j2 := j
    END;
    IF i >= jVw[c] THEN i := jVw[c] - 1 END; IF i2 >= jVw[c] THEN i2 := jVw[c] - 1 END; IF i2 < 0 THEN i2 := 0 END;
    IF j >= jVh[c] THEN j := jVh[c] - 1 END; IF j2 >= jVh[c] THEN j2 := jVh[c] - 1 END; IF j2 < 0 THEN j2 := 0 END;
    IF (i = i2) & (j = j2) THEN v := At(c, i, j)
    ELSE v := (9 * At(c, i, j) + 3 * At(c, i2, j) + 3 * At(c, i, j2) + At(c, i2, j2) + 8) DIV 16
    END
    RETURN v
  END Up;

  (* ---------- JPEG (baseline) ---------- *)

  PROCEDURE BuildHuff(t: INTEGER);
    VAR l, code, k: INTEGER;
  BEGIN
    code := 0; k := 0;
    FOR l := 1 TO 16 DO
      hPtr[t][l] := k; hMin[t][l] := code;
      code := code + hBits[t][l]; k := k + hBits[t][l];
      IF hBits[t][l] > 0 THEN hMax[t][l] := code - 1 ELSE hMax[t][l] := -1 END;
      code := code * 2
    END
  END BuildHuff;

  PROCEDURE Bit(): INTEGER;   (* the next bit of the scan; a marker inside it gives zeros *)
    VAR b, b2, r: INTEGER;
  BEGIN
    IF bitCnt = 0 THEN
      b := 0;
      IF ~markerHit THEN
        b := Byte();
        IF b = 0FFH THEN
          b2 := Byte();
          IF b2 # 0 THEN markerHit := TRUE; hitMarker := b2; b := 0 END
        END
      END;
      bitBuf := b; bitCnt := 8
    END;
    DEC(bitCnt); r := bitBuf DIV pow2[bitCnt] MOD 2
    RETURN r
  END Bit;

  PROCEDURE Bits(n: INTEGER): INTEGER;
    VAR i, v: INTEGER;
  BEGIN v := 0; FOR i := 1 TO n DO v := v * 2 + Bit() END
    RETURN v
  END Bits;

  PROCEDURE Extend(v, s: INTEGER): INTEGER;   (* s bits -> a number with its sign *)
  BEGIN IF (s > 0) & (v < pow2[s - 1]) THEN v := v - pow2[s] + 1 END
    RETURN v
  END Extend;

  PROCEDURE Huff(t: INTEGER): INTEGER;   (* one value of Huffman table t *)
    VAR code, l, r, i: INTEGER;
  BEGIN
    code := Bit(); l := 1; r := 0;
    WHILE (l <= 16) & (code > hMax[t][l]) DO code := code * 2 + Bit(); INC(l) END;
    IF l > 16 THEN Fail("bad JPEG data")
    ELSE
      i := hPtr[t][l] + code - hMin[t][l];
      IF (i >= 0) & (i < 256) THEN r := hVal[t][i] ELSE Fail("bad JPEG table") END
    END
    RETURN r
  END Huff;

  PROCEDURE Idct(ac: BOOLEAN);   (* coef -> blk *)
    VAR k, u, v, x, y, dc: INTEGER; sum: REAL;
  BEGIN
    IF ~ac THEN   (* only the mean: the block is one colour *)
      dc := Clamp((coef[0] + 4) DIV 8 + 128);
      FOR k := 0 TO 63 DO blk[k] := dc END
    ELSE
      FOR v := 0 TO 7 DO
        FOR x := 0 TO 7 DO
          sum := 0.0;
          FOR u := 0 TO 7 DO sum := sum + cosT[x * 8 + u] * FLT(coef[v * 8 + u]) END;
          tmpR[v * 8 + x] := sum
        END
      END;
      FOR y := 0 TO 7 DO
        FOR x := 0 TO 7 DO
          sum := 0.0;
          FOR v := 0 TO 7 DO sum := sum + cosT[y * 8 + v] * tmpR[v * 8 + x] END;
          blk[y * 8 + x] := Clamp(FLOOR(sum + 128.5))
        END
      END
    END
  END Idct;

  PROCEDURE Block(c: INTEGER);   (* one 8 x 8 block of component c -> blk *)
    VAR k, rs, r, s, t, q: INTEGER; ac: BOOLEAN;
  BEGIN
    FOR k := 0 TO 63 DO coef[k] := 0 END;
    q := cQ[c];
    s := Huff(cTd[c]); t := Bits(s);
    cPred[c] := cPred[c] + Extend(t, s);
    coef[0] := cPred[c] * qt[q][0];
    k := 1; ac := FALSE;
    WHILE (k < 64) & good DO
      rs := Huff(4 + cTa[c]); r := rs DIV 16; s := rs MOD 16;
      IF s = 0 THEN
        IF r = 15 THEN k := k + 16 ELSE k := 64 END
      ELSE
        k := k + r;
        IF k < 64 THEN t := Bits(s); coef[zz[k]] := Extend(t, s) * qt[q][k]; ac := TRUE END;
        INC(k)
      END
    END;
    Idct(ac)
  END Block;



  PROCEDURE Sample(c, px, py: INTEGER): INTEGER;   (* component c at pixel (px, py) of the MCU *)
    VAR sx, sy: INTEGER;
  BEGIN
    sx := px * cHf[c] DIV hMaxF; sy := py * cVf[c] DIV vMaxF
    RETURN plane[c][sy * cHf[c] * 8 + sx]
  END Sample;

  PROCEDURE Kept(c, bx, by: INTEGER);   (* a block of the whole progressive JPEG -> blk *)
    VAR k, b, q: INTEGER; ac: BOOLEAN;
  BEGIN
    b := (dOff[c] + by * aw[c] + bx) * 64; q := cQ[c]; ac := FALSE;
    FOR k := 0 TO 63 DO coef[k] := 0 END;
    FOR k := 0 TO 63 DO
      IF pc[b + k] # 0 THEN coef[zz[k]] := pc[b + k] * qt[q][k]; IF k > 0 THEN ac := TRUE END END
    END;
    Idct(ac)
  END Kept;

  PROCEDURE Mcu(mx, my: INTEGER);
    VAR c, h, v, x, y, pw, px, py, yy, cb, cr, r, g, b, X, Y: INTEGER;
  BEGIN
    c := 0;
    WHILE (c < nComp) & good DO
      pw := cHf[c] * 8;
      FOR v := 0 TO cVf[c] - 1 DO
        FOR h := 0 TO cHf[c] - 1 DO
          IF progressive THEN Kept(c, mx * cHf[c] + h, my * cVf[c] + v) ELSE Block(c) END;
          IF planes THEN   (* the whole picture is kept: the colours come later *)
            X := jOff[c] + ((my * cVf[c] + v) * 8) * jW[c] + (mx * cHf[c] + h) * 8;
            FOR y := 0 TO 7 DO
              FOR x := 0 TO 7 DO jp[X + y * jW[c] + x] := CHR(blk[y * 8 + x]) END
            END
          ELSE
            FOR y := 0 TO 7 DO
              FOR x := 0 TO 7 DO plane[c][(v * 8 + y) * pw + h * 8 + x] := blk[y * 8 + x] END
            END
          END
        END
      END;
      INC(c)
    END;
    IF planes THEN py := mcuH ELSE py := 0 END;
    WHILE py < mcuH DO
      Y := my * mcuH + py;
      IF Y < H THEN
        Row(Y);
        FOR px := 0 TO mcuW - 1 DO
          X := mx * mcuW + px;
          IF X < W THEN
            yy := Sample(0, px, py);
            IF nComp = 3 THEN
              cb := Sample(1, px, py) - 128; cr := Sample(2, px, py) - 128;
              r := Clamp(yy + 359 * cr DIV 256); g := Clamp(yy - (88 * cb + 183 * cr) DIV 256); b := Clamp(yy + 454 * cb DIV 256)
            ELSE r := yy; g := yy; b := yy
            END;
            Pix(X, r, g, b)
          END
        END
      END;
      INC(py)
    END
  END Mcu;

  PROCEDURE JConvert;   (* the planes of the whole JPEG -> the pixels, each colour from its 4 nearest samples *)
    VAR X, Y, yy, cb, cr, r, g, b: INTEGER;
  BEGIN
    FOR Y := 0 TO H - 1 DO
      Row(Y);
      FOR X := 0 TO W - 1 DO
        yy := Up(0, X, Y);
        IF nComp = 3 THEN
          cb := Up(1, X, Y) - 128; cr := Up(2, X, Y) - 128;
          r := Clamp(yy + 359 * cr DIV 256); g := Clamp(yy - (88 * cb + 183 * cr) DIV 256); b := Clamp(yy + 454 * cb DIV 256)
        ELSE r := yy; g := yy; b := yy
        END;
        Pix(X, r, g, b)
      END
    END
  END JConvert;

  PROCEDURE Restart(n, total: INTEGER);   (* after n MCUs of a scan with restarts: the RSTn marker *)
    VAR i, b: INTEGER;
  BEGIN
    IF (ri > 0) & (n MOD ri = 0) & (n < total) THEN
      bitCnt := 0;
      IF markerHit THEN markerHit := FALSE; hitMarker := 0
      ELSE
        b := Byte(); WHILE good & (b # 0FFH) DO b := Byte() END;
        b := Byte(); WHILE good & (b = 0FFH) DO b := Byte() END
      END;
      FOR i := 0 TO 3 DO cPred[i] := 0 END;
      eobrun := 0
    END
  END Restart;

  PROCEDURE Scan;
    VAR mx, my, n, i, b, mcusX, mcusY: INTEGER;
  BEGIN
    mcusX := (W + mcuW - 1) DIV mcuW; mcusY := (H + mcuH - 1) DIV mcuH;
    bitCnt := 0; markerHit := FALSE; n := 0;
    FOR i := 0 TO 3 DO cPred[i] := 0 END;
    my := 0;
    WHILE (my < mcusY) & good DO
      mx := 0;
      WHILE (mx < mcusX) & good DO
        Mcu(mx, my); INC(n); Restart(n, mcusX * mcusY);
        INC(mx)
      END;
      INC(my)
    END
  END Scan;

  PROCEDURE Factors;   (* after the frame: the biggest sampling, the MCU, the blocks of each component *)
    VAR j, mcusX, mcusY, n: INTEGER;
  BEGIN
    IF nComp = 1 THEN cHf[0] := 1; cVf[0] := 1 END;
    hMaxF := 1; vMaxF := 1;
    FOR j := 0 TO nComp - 1 DO
      IF cHf[j] > hMaxF THEN hMaxF := cHf[j] END;
      IF cVf[j] > vMaxF THEN vMaxF := cVf[j] END
    END;
    mcuW := 8 * hMaxF; mcuH := 8 * vMaxF;
    mcusX := (W + mcuW - 1) DIV mcuW; mcusY := (H + mcuH - 1) DIV mcuH;
    n := 0;
    FOR j := 0 TO nComp - 1 DO
      aw[j] := mcusX * cHf[j]; ah[j] := mcusY * cVf[j]; dOff[j] := n; n := n + aw[j] * ah[j]
    END;
    FOR j := 0 TO nComp - 1 DO
      jW[j] := mcusX * cHf[j] * 8; jOff[j] := mcusY * cVf[j] * 8;
      jFx[j] := hMaxF DIV cHf[j]; jFy[j] := vMaxF DIV cVf[j];
      jVw[j] := (W * cHf[j] + hMaxF - 1) DIV hMaxF; jVh[j] := (H * cVf[j] + vMaxF - 1) DIV vMaxF
    END;
    PlanesFor(nComp);
    IF nComp > 3 THEN planes := FALSE END;
    IF progressive THEN
      fullProg := n * 64 <= NPC;
      IF fullProg THEN FOR j := 0 TO n * 64 - 1 DO pc[j] := 0 END
      ELSIF n > ND THEN Fail("progressive JPEG too big")
      ELSE FOR j := 0 TO n - 1 DO dcv[j] := 0 END
      END
    END
  END Factors;

  PROCEDURE DcBlock(c, bx, by, ahi, al: INTEGER);   (* progressive: the mean of one block (first time, or one more bit) *)
    VAR s, t, k: INTEGER;
  BEGIN
    k := dOff[c] + by * aw[c] + bx;
    IF ahi = 0 THEN
      s := Huff(cTd[c]); t := Bits(s); cPred[c] := cPred[c] + Extend(t, s);
      IF fullProg THEN pc[k * 64] := cPred[c] * pow2[al] ELSE dcv[k] := cPred[c] * pow2[al] END
    ELSIF Bit() = 1 THEN
      IF fullProg THEN pc[k * 64] := pc[k * 64] + pow2[al] ELSE dcv[k] := dcv[k] + pow2[al] END
    END
  END DcBlock;

  PROCEDURE DcScan(ns, ahi, al: INTEGER; VAR sc: ARRAY OF INTEGER);   (* a progressive scan of the means *)
    VAR mx, my, n, i, c, h, v, bw, bh, total: INTEGER;
  BEGIN
    bitCnt := 0; markerHit := FALSE; hitMarker := 0; n := 0;
    FOR i := 0 TO 3 DO cPred[i] := 0 END;
    IF ns = 1 THEN   (* one component: each block is an MCU, only the blocks with picture in them *)
      c := sc[0];
      bw := ((W * cHf[c] + hMaxF - 1) DIV hMaxF + 7) DIV 8; bh := ((H * cVf[c] + vMaxF - 1) DIV vMaxF + 7) DIV 8;
      total := bw * bh; my := 0;
      WHILE (my < bh) & good DO
        mx := 0;
        WHILE (mx < bw) & good DO DcBlock(c, mx, my, ahi, al); INC(n); Restart(n, total); INC(mx) END;
        INC(my)
      END
    ELSE
      bw := (W + mcuW - 1) DIV mcuW; bh := (H + mcuH - 1) DIV mcuH; total := bw * bh; my := 0;
      WHILE (my < bh) & good DO
        mx := 0;
        WHILE (mx < bw) & good DO
          FOR i := 0 TO ns - 1 DO
            c := sc[i];
            FOR v := 0 TO cVf[c] - 1 DO FOR h := 0 TO cHf[c] - 1 DO DcBlock(c, mx * cHf[c] + h, my * cVf[c] + v, ahi, al) END END
          END;
          INC(n); Restart(n, total); INC(mx)
        END;
        INC(my)
      END
    END
  END DcScan;

  PROCEDURE Refine(i, bit: INTEGER);   (* one more bit of a coefficient that is not 0 *)
  BEGIN
    IF (Bit() = 1) & ~ODD(pc[i] DIV bit) THEN
      IF pc[i] > 0 THEN pc[i] := pc[i] + bit ELSE pc[i] := pc[i] - bit END
    END
  END Refine;

  PROCEDURE AcFirst(b, c, ss, se, al: INTEGER);   (* the first bits of the detail ss .. se of the block at pc[b] *)
    VAR k, rs, r, s, t: INTEGER;
  BEGIN
    IF eobrun > 0 THEN DEC(eobrun)
    ELSE
      k := ss;
      WHILE good & (k <= se) DO
        rs := Huff(4 + cTa[c]); r := rs DIV 16; s := rs MOD 16;
        IF s = 0 THEN
          IF r < 15 THEN
            eobrun := pow2[r] - 1; IF r > 0 THEN eobrun := eobrun + Bits(r) END;
            k := 64
          ELSE k := k + 16
          END
        ELSE
          k := k + r;
          IF k <= 63 THEN t := Bits(s); pc[b + k] := Extend(t, s) * pow2[al] END;
          INC(k)
        END
      END
    END
  END AcFirst;

  PROCEDURE AcRefine(b, c, ss, se, al: INTEGER);   (* one more bit of the detail ss .. se of the block at pc[b] *)
    VAR k, rs, r, s, bit: INTEGER; placed: BOOLEAN;
  BEGIN
    bit := pow2[al];
    IF eobrun > 0 THEN
      DEC(eobrun);
      FOR k := ss TO se DO IF pc[b + k] # 0 THEN Refine(b + k, bit) END END
    ELSE
      k := ss;
      REPEAT
        rs := Huff(4 + cTa[c]); s := rs MOD 16; r := rs DIV 16;
        IF s = 0 THEN
          IF r < 15 THEN
            eobrun := pow2[r] - 1; IF r > 0 THEN eobrun := eobrun + Bits(r) END;
            r := 64
          END
        ELSIF Bit() = 1 THEN s := bit
        ELSE s := -bit
        END;
        placed := FALSE;
        WHILE good & ~placed & (k <= se) DO
          IF pc[b + k] # 0 THEN Refine(b + k, bit)
          ELSIF r = 0 THEN pc[b + k] := s; placed := TRUE
          ELSE DEC(r)
          END;
          INC(k)
        END
      UNTIL ~good OR (k > se)
    END
  END AcRefine;

  PROCEDURE AcScan(c, ss, se, ahi, al: INTEGER);   (* a progressive scan of the detail, one component *)
    VAR bx, by, bw, bh, n, b, total: INTEGER;
  BEGIN
    bitCnt := 0; markerHit := FALSE; hitMarker := 0; n := 0; eobrun := 0;
    bw := ((W * cHf[c] + hMaxF - 1) DIV hMaxF + 7) DIV 8; bh := ((H * cVf[c] + vMaxF - 1) DIV vMaxF + 7) DIV 8;
    total := bw * bh; by := 0;
    WHILE (by < bh) & good DO
      bx := 0;
      WHILE (bx < bw) & good DO
        b := (dOff[c] + by * aw[c] + bx) * 64;
        IF ahi = 0 THEN AcFirst(b, c, ss, se, al) ELSE AcRefine(b, c, ss, se, al) END;
        INC(n); Restart(n, total); INC(bx)
      END;
      INC(by)
    END
  END AcScan;

  PROCEDURE SkipScan;   (* a scan of the fine detail: not needed for the squares; to the next marker *)
    VAR b: INTEGER; done: BOOLEAN;
  BEGIN
    done := FALSE;
    WHILE good & ~done DO
      b := Byte();
      WHILE good & (b = 0FFH) & ~done DO
        b := Byte();
        IF (b # 0) & (b # 0FFH) & ~((b >= 0D0H) & (b <= 0D7H)) THEN hitMarker := b; done := TRUE END
      END
    END
  END SkipScan;

  PROCEDURE ProgOut;   (* the pixels from the means of the blocks *)
    VAR x, y, c, k, r, g, b, cb, cr, yy: INTEGER; val: ARRAY 4 OF INTEGER;
  BEGIN
    FOR y := 0 TO H - 1 DO
      Row(y);
      FOR x := 0 TO W - 1 DO
        FOR c := 0 TO nComp - 1 DO
          k := dOff[c] + (y * cVf[c] DIV vMaxF DIV 8) * aw[c] + x * cHf[c] DIV hMaxF DIV 8;
          val[c] := Clamp((dcv[k] * qt[cQ[c]][0] + 4) DIV 8 + 128)
        END;
        yy := val[0];
        IF nComp = 3 THEN
          cb := val[1] - 128; cr := val[2] - 128;
          r := Clamp(yy + 359 * cr DIV 256); g := Clamp(yy - (88 * cb + 183 * cr) DIV 256); b := Clamp(yy + 454 * cb DIV 256)
        ELSE r := yy; g := yy; b := yy
        END;
        Pix(x, r, g, b)
      END
    END
  END ProgOut;

  PROCEDURE Jpeg;
    VAR m, sl, i, j, n, t, b, ns, cs, w, h, ss, se, ahi, al: INTEGER; done: BOOLEAN; sc: ARRAY 4 OF INTEGER;
  BEGIN
    kind := 1; done := FALSE; nComp := 0; ri := 0; progressive := FALSE; hitMarker := 0;
    WHILE good & ~done DO
      IF hitMarker # 0 THEN m := hitMarker; hitMarker := 0   (* the scan before already met it *)
      ELSE
        b := Byte(); WHILE good & (b # 0FFH) DO b := Byte() END;   (* to the next marker *)
        m := Byte(); WHILE good & (m = 0FFH) DO m := Byte() END
      END;
      IF (m = 0D8H) OR ((m >= 0D0H) & (m <= 0D7H)) OR (m = 1) THEN   (* a marker with nothing after it *)
      ELSIF m = 0D9H THEN done := TRUE
      ELSE
        sl := Word() - 2;
        IF (m = 0C0H) OR (m = 0C1H) OR (m = 0C2H) THEN
          progressive := m = 0C2H;
          b := Byte(); h := Word(); w := Word(); nComp := Byte();
          IF b # 8 THEN Fail("JPEG of 12 bits")
          ELSIF (nComp # 1) & (nComp # 3) THEN Fail("JPEG in CMYK")
          ELSE
            FOR j := 0 TO nComp - 1 DO
              cId[j] := Byte(); b := Byte(); cHf[j] := b DIV 16; cVf[j] := b MOD 16; cQ[j] := Byte() MOD 4;
              IF (cHf[j] < 1) OR (cHf[j] > 4) OR (cVf[j] < 1) OR (cVf[j] > 4) THEN Fail("bad JPEG frame") END
            END;
            Grid(w, h); IF good THEN Factors END
          END
        ELSIF (m >= 0C3H) & (m <= 0CFH) & (m # 0C4H) & (m # 0C8H) & (m # 0CCH) THEN Fail("unusual JPEG")
        ELSIF m = 0C4H THEN
          WHILE good & (sl > 0) DO
            b := Byte(); t := (b DIV 16) MOD 2 * 4 + b MOD 4; n := 0;
            FOR i := 1 TO 16 DO hBits[t][i] := Byte(); n := n + hBits[t][i] END;
            IF n > 256 THEN Fail("bad JPEG table")
            ELSE FOR i := 0 TO n - 1 DO hVal[t][i] := Byte() END; BuildHuff(t)
            END;
            sl := sl - 17 - n
          END
        ELSIF m = 0DBH THEN
          WHILE good & (sl > 0) DO
            b := Byte(); t := b MOD 4;
            IF b DIV 16 = 0 THEN FOR i := 0 TO 63 DO qt[t][i] := Byte() END; sl := sl - 65
            ELSE FOR i := 0 TO 63 DO qt[t][i] := Word() END; sl := sl - 129
            END
          END
        ELSIF m = 0DDH THEN ri := Word()
        ELSIF m = 0DAH THEN
          ns := Byte();
          IF (ns < 1) OR (ns > 4) THEN Fail("bad JPEG scan") END;
          i := 0;
          WHILE good & (i < ns) DO
            cs := Byte(); b := Byte(); sc[i] := 0;
            FOR j := 0 TO nComp - 1 DO IF cId[j] = cs THEN cTd[j] := b DIV 16 MOD 4; cTa[j] := b MOD 4; sc[i] := j END END;
            INC(i)
          END;
          ss := Byte(); se := Byte(); b := Byte(); ahi := b DIV 16; al := b MOD 16;
          IF nComp = 0 THEN Fail("a JPEG scan with no frame")
          ELSIF ~good THEN
          ELSIF progressive THEN
            IF ss = 0 THEN DcScan(ns, ahi, al, sc)
            ELSIF fullProg & (ns = 1) & (se <= 63) & (ss <= se) THEN AcScan(sc[0], ss, se, ahi, al)
            ELSE SkipScan
            END
          ELSIF ns # nComp THEN Fail("JPEG in several scans")
          ELSE Scan; done := TRUE; IF good & planes THEN JConvert END
          END
        ELSE
          FOR i := 1 TO sl DO b := Byte() END   (* APPn, comments, ...: not needed *)
        END
      END
    END;
    IF good & progressive THEN
      IF fullProg THEN   (* the whole picture: MCU by MCU, as the baseline ones *)
        j := 0;
        WHILE good & (j < (H + mcuH - 1) DIV mcuH) DO
          i := 0; WHILE good & (i < (W + mcuW - 1) DIV mcuW) DO Mcu(i, j); INC(i) END;
          INC(j)
        END;
        IF good & planes THEN JConvert END
      ELSE ProgOut
      END
    END
  END Jpeg;

  (* ---------- PNG: inflate and the rows ---------- *)

  PROCEDURE Be32(): INTEGER;
    VAR a, b: INTEGER;
  BEGIN a := Word(); b := Word()
    RETURN a * 65536 + b
  END Be32;

  PROCEDURE IByte(): INTEGER;   (* the next byte of the IDAT chunks, one after the other *)
    VAR b, n, t: INTEGER;
  BEGIN
    WHILE good & ~idatEnd & (chunkLeft = 0) DO
      b := Be32();   (* the CRC of the chunk before *)
      n := Be32(); t := Be32();
      IF t = IDAT THEN chunkLeft := n ELSE idatEnd := TRUE END
    END;
    IF idatEnd OR ~good THEN b := 0; Fail("the PNG data ends too soon")
    ELSE b := Byte(); DEC(chunkLeft)
    END
    RETURN b
  END IByte;

  PROCEDURE DBit(): INTEGER;   (* deflate: the low bit first *)
    VAR r: INTEGER;
  BEGIN
    IF dCnt = 0 THEN dBuf := IByte(); dCnt := 8 END;
    r := dBuf MOD 2; dBuf := dBuf DIV 2; DEC(dCnt)
    RETURN r
  END DBit;

  PROCEDURE DBits(n: INTEGER): INTEGER;
    VAR i, v: INTEGER;
  BEGIN v := 0; FOR i := 0 TO n - 1 DO v := v + DBit() * pow2[i] END
    RETURN v
  END DBits;

  PROCEDURE Build(t, n: INTEGER);   (* Huffman table t from the code lengths lens[0 .. n-1] *)
    VAR off: ARRAY 16 OF INTEGER; i, l: INTEGER;
  BEGIN
    FOR l := 0 TO 15 DO hcnt[t][l] := 0 END;
    FOR i := 0 TO n - 1 DO hcnt[t][lens[i]] := hcnt[t][lens[i]] + 1 END;
    off[1] := 0; FOR l := 1 TO 14 DO off[l + 1] := off[l] + hcnt[t][l] END;
    FOR i := 0 TO n - 1 DO IF lens[i] # 0 THEN hsym[t][off[lens[i]]] := i; off[lens[i]] := off[lens[i]] + 1 END END
  END Build;

  PROCEDURE Decode(t: INTEGER): INTEGER;
    VAR code, first, count, index, l, r: INTEGER;
  BEGIN
    code := 0; first := 0; index := 0; l := 1; r := -1;
    WHILE (r < 0) & (l <= 15) & good DO
      code := code + DBit(); count := hcnt[t][l];
      IF code - count < first THEN r := hsym[t][index + (code - first)]
      ELSE index := index + count; first := (first + count) * 2; code := code * 2; INC(l)
      END
    END;
    IF r < 0 THEN Fail("bad PNG data"); r := 0 END
    RETURN r
  END Decode;

  PROCEDURE PSample(x, c: INTEGER): INTEGER;   (* sample c of pixel x of the row *)
    VAR v, bit: INTEGER;
  BEGIN
    IF depth = 8 THEN v := cur[x * chans + c]
    ELSIF depth = 16 THEN v := cur[(x * chans + c) * 2]
    ELSE bit := x * depth; v := cur[bit DIV 8] DIV pow2[8 - depth - bit MOD 8] MOD pow2[depth]
    END
    RETURN v
  END PSample;

  PROCEDURE EmitRow;
    VAR x, r, g, b, a, k: INTEGER;
  BEGIN
    Row(psy + pngY * pdy);
    FOR x := 0 TO pw - 1 DO
      a := 255;
      IF ctype = 3 THEN k := PSample(x, 0); r := pal[k] DIV 65536; g := pal[k] DIV 256 MOD 256; b := pal[k] MOD 256; a := palA[k]
      ELSIF (ctype = 0) OR (ctype = 4) THEN
        g := PSample(x, 0); IF depth < 8 THEN g := g * 255 DIV (pow2[depth] - 1) END;
        r := g; b := g; IF ctype = 4 THEN a := PSample(x, 1) END
      ELSE
        r := PSample(x, 0); g := PSample(x, 1); b := PSample(x, 2); IF ctype = 6 THEN a := PSample(x, 3) END
      END;
      Trans(psx + x * pdx, r, g, b, a)
    END
  END EmitRow;

  PROCEDURE Unfilter;
    VAR i, a, b, c, p, pa, pb, pc, x: INTEGER;
  BEGIN
    FOR i := 0 TO rowBytes - 1 DO
      IF i >= bpp THEN a := cur[i - bpp]; c := prev[i - bpp] ELSE a := 0; c := 0 END;
      b := prev[i];
      IF filt = 1 THEN x := cur[i] + a
      ELSIF filt = 2 THEN x := cur[i] + b
      ELSIF filt = 3 THEN x := cur[i] + (a + b) DIV 2
      ELSIF filt = 4 THEN
        p := a + b - c; pa := ABS(p - a); pb := ABS(p - b); pc := ABS(p - c);
        IF (pa <= pb) & (pa <= pc) THEN x := cur[i] + a ELSIF pb <= pc THEN x := cur[i] + b ELSE x := cur[i] + c END
      ELSE x := cur[i]
      END;
      cur[i] := x MOD 256
    END
  END Unfilter;

  PROCEDURE NextPass;   (* the next pno that has pixels; for a PNG that is not interlaced, the whole picture once *)
    VAR i: INTEGER; found: BOOLEAN;
  BEGIN
    found := FALSE;
    WHILE ~found & ~allDone DO
      INC(pno);
      IF il = 0 THEN
        IF pno = 0 THEN psx := 0; psy := 0; pdx := 1; pdy := 1; pw := W; ph := H; found := TRUE ELSE allDone := TRUE END
      ELSIF pno >= 7 THEN allDone := TRUE
      ELSE
        psx := aSx[pno]; psy := aSy[pno]; pdx := aDx[pno]; pdy := aDy[pno];
        pw := (W - psx + pdx - 1) DIV pdx; ph := (H - psy + pdy - 1) DIV pdy;
        found := (pw > 0) & (ph > 0)
      END
    END;
    IF found THEN
      rowBytes := (pw * depth * chans + 7) DIV 8; pngY := 0; rowPos := 0;
      FOR i := 0 TO rowBytes - 1 DO prev[i] := 0 END
    END
  END NextPass;

  PROCEDURE Feed(b: INTEGER);   (* a byte that came out of inflate: the rows *)
    VAR i: INTEGER;
  BEGIN
    IF ~allDone THEN
      IF rowPos = 0 THEN filt := b; rowPos := 1
      ELSE
        cur[rowPos - 1] := b; INC(rowPos);
        IF rowPos > rowBytes THEN
          Unfilter; EmitRow;
          FOR i := 0 TO rowBytes - 1 DO prev[i] := cur[i] END;
          INC(pngY); rowPos := 0;
          IF pngY >= ph THEN NextPass END
        END
      END
    END
  END Feed;

  PROCEDURE Out(b: INTEGER);
  BEGIN win[wpos] := b; wpos := (wpos + 1) MOD WIN; Feed(b)
  END Out;

  PROCEDURE Inflate;
    VAR a, b, fin, typ, i, n, sym, ln, dist, hlit, hdist, hclen, rep, pl: INTEGER;
  BEGIN
    a := IByte(); b := IByte();
    IF a MOD 16 # 8 THEN Fail("PNG not in deflate") ELSIF b DIV 32 MOD 2 = 1 THEN Fail("PNG with a dictionary") END;
    dCnt := 0; wpos := 0; fin := 0; pno := -1; allDone := FALSE; NextPass;
    WHILE good & (fin = 0) & ~allDone DO
      fin := DBit(); typ := DBits(2);
      IF typ = 0 THEN   (* stored *)
        dCnt := 0; a := IByte(); b := IByte(); n := a + b * 256; a := IByte(); a := IByte();
        i := 0; WHILE good & (i < n) DO Out(IByte()); INC(i) END
      ELSIF (typ = 1) OR (typ = 2) THEN
        IF typ = 1 THEN   (* the fixed codes *)
          FOR i := 0 TO 143 DO lens[i] := 8 END; FOR i := 144 TO 255 DO lens[i] := 9 END;
          FOR i := 256 TO 279 DO lens[i] := 7 END; FOR i := 280 TO 287 DO lens[i] := 8 END;
          Build(0, 288);
          FOR i := 0 TO 29 DO lens[i] := 5 END; Build(1, 30)
        ELSE   (* the codes come first *)
          hlit := DBits(5) + 257; hdist := DBits(5) + 1; hclen := DBits(4) + 4;
          FOR i := 0 TO 18 DO lens[i] := 0 END;
          FOR i := 0 TO hclen - 1 DO lens[clOrder[i]] := DBits(3) END;
          Build(2, 19);
          i := 0;
          WHILE good & (i < hlit + hdist) DO
            sym := Decode(2);
            IF sym < 16 THEN tmpL[i] := sym; INC(i)
            ELSE
              pl := 0;
              IF sym = 16 THEN
                IF i = 0 THEN Fail("bad PNG codes") ELSE pl := tmpL[i - 1] END; rep := 3 + DBits(2)
              ELSIF sym = 17 THEN rep := 3 + DBits(3)
              ELSE rep := 11 + DBits(7)
              END;
              WHILE (rep > 0) & (i < hlit + hdist) DO tmpL[i] := pl; INC(i); DEC(rep) END
            END
          END;
          FOR i := 0 TO hlit - 1 DO lens[i] := tmpL[i] END; Build(0, hlit);
          FOR i := 0 TO hdist - 1 DO lens[i] := tmpL[hlit + i] END; Build(1, hdist)
        END;
        sym := 0;
        WHILE good & (sym # 256) & ~allDone DO
          sym := Decode(0);
          IF sym < 256 THEN Out(sym)
          ELSIF sym > 256 THEN
            sym := sym - 257;
            IF sym >= 29 THEN Fail("bad PNG length")
            ELSE
              ln := lBase[sym] + DBits(lExtra[sym]);
              n := Decode(1);
              IF n >= 30 THEN Fail("bad PNG distance")
              ELSE
                dist := dBase[n] + DBits(dExtra[n]);
                FOR i := 1 TO ln DO Out(win[(wpos - dist + WIN) MOD WIN]) END
              END
            END;
            sym := 0
          END
        END
      ELSE Fail("bad PNG block")
      END
    END
  END Inflate;

  PROCEDURE Png;
    VAR n, t, i, w, h, b: INTEGER; done: BOOLEAN;
  BEGIN
    kind := 2; done := FALSE;
    FOR i := 1 TO 4 DO b := Byte() END;   (* the rest of the signature *)
    FOR i := 0 TO 255 DO pal[i] := 0; palA[i] := 255 END;
    W := 0;
    WHILE good & ~done DO
      n := Be32(); t := Be32();
      IF t = IHDR THEN
        w := Be32(); h := Be32(); depth := Byte(); ctype := Byte(); b := Byte(); b := Byte(); il := Byte();
        FOR i := 1 TO 4 + n - 13 DO b := Byte() END;
        IF ctype = 0 THEN chans := 1 ELSIF ctype = 2 THEN chans := 3 ELSIF ctype = 3 THEN chans := 1
        ELSIF ctype = 4 THEN chans := 2 ELSIF ctype = 6 THEN chans := 4 ELSE chans := 0; Fail("bad PNG colours")
        END;
        IF (il # 0) & (il # 1) THEN Fail("bad PNG interlace")
        ELSIF (depth # 1) & (depth # 2) & (depth # 4) & (depth # 8) & (depth # 16) THEN Fail("bad PNG depth")
        ELSIF good THEN
          bpp := (depth * chans + 7) DIV 8; rowBytes := (w * depth * chans + 7) DIV 8;
          IF rowBytes >= WIN THEN Fail("too wide") ELSE Grid(w, h) END
        END
      ELSIF t = PLTE THEN
        FOR i := 0 TO n DIV 3 - 1 DO
          w := Byte(); h := Byte(); b := Byte();
          IF i < 256 THEN pal[i] := w * 65536 + h * 256 + b END
        END;
        FOR i := 1 TO n MOD 3 + 4 DO b := Byte() END
      ELSIF t = TRNS THEN
        FOR i := 0 TO n - 1 DO b := Byte(); IF (ctype = 3) & (i < 256) THEN palA[i] := b END END;
        FOR i := 1 TO 4 DO b := Byte() END
      ELSIF t = IDAT THEN
        IF W = 0 THEN Fail("PNG with no header") ELSE chunkLeft := n; idatEnd := FALSE; Inflate END;
        done := TRUE
      ELSIF t = IEND THEN Fail("PNG with no picture")
      ELSE
        FOR i := 1 TO n + 4 DO b := Byte() END
      END
    END
  END Png;

  (* ---------- GIF: the first picture ---------- *)

  PROCEDURE Le16(): INTEGER;   (* two bytes, the low one first *)
    VAR a, b: INTEGER;
  BEGIN a := Byte(); b := Byte()
    RETURN b * 256 + a
  END Le16;

  PROCEDURE Skip;   (* sub-blocks up to the empty one *)
    VAR n, i, b: INTEGER;
  BEGIN
    n := Byte();
    WHILE good & (n > 0) DO FOR i := 1 TO n DO b := Byte() END; n := Byte() END
  END Skip;

  PROCEDURE GBit(): INTEGER;   (* the bits of the picture's sub-blocks, the low bit first *)
    VAR r: INTEGER;
  BEGIN
    IF gCnt = 0 THEN
      IF ~gEnd & (gLeft = 0) THEN gLeft := Byte(); IF gLeft = 0 THEN gEnd := TRUE END END;
      IF gEnd THEN gBuf := 0 ELSE gBuf := Byte(); DEC(gLeft) END;
      gCnt := 8
    END;
    r := gBuf MOD 2; gBuf := gBuf DIV 2; DEC(gCnt)
    RETURN r
  END GBit;

  PROCEDURE GCode(n: INTEGER): INTEGER;
    VAR i, v: INTEGER;
  BEGIN v := 0; FOR i := 0 TO n - 1 DO v := v + GBit() * pow2[i] END
    RETURN v
  END GCode;

  PROCEDURE GifRows(h: INTEGER; interlaced: BOOLEAN);   (* the order of the rows: interlaced GIFs give every 8th first *)
    VAR i, k: INTEGER;
  BEGIN
    IF interlaced THEN
      k := 0;
      i := 0; WHILE i < h DO rowMap[k] := i; INC(k); i := i + 8 END;
      i := 4; WHILE i < h DO rowMap[k] := i; INC(k); i := i + 8 END;
      i := 2; WHILE i < h DO rowMap[k] := i; INC(k); i := i + 4 END;
      i := 1; WHILE i < h DO rowMap[k] := i; INC(k); i := i + 2 END
    ELSE FOR i := 0 TO h - 1 DO rowMap[i] := i END
    END
  END GifRows;

  PROCEDURE GifPixels(w, h, trans: INTEGER);   (* LZW -> the colours of the picture *)
    VAR i, minSize, size, clear, eoi, next, code, old, inCode, first, sp, count, total, x, p: INTEGER;
  BEGIN
    minSize := Byte();
    IF (minSize < 2) OR (minSize > 11) THEN Fail("bad GIF data") END;
    clear := pow2[minSize]; eoi := clear + 1;
    FOR i := 0 TO clear - 1 DO gPre[i] := -1; gSuf[i] := i END;
    size := minSize + 1; next := eoi + 1; old := -1; first := 0;
    gLeft := 0; gCnt := 0; gEnd := FALSE;
    count := 0; total := w * h;
    WHILE good & (count < total) & ~gEnd DO
      code := GCode(size);
      IF code = clear THEN size := minSize + 1; next := eoi + 1; old := -1
      ELSIF code = eoi THEN gEnd := TRUE
      ELSE
        inCode := code; sp := 0;
        IF old = -1 THEN
          IF code >= clear THEN Fail("bad GIF data") ELSE gStack[0] := code; sp := 1; first := code; old := code END
        ELSE
          IF code >= next THEN
            IF code > next THEN Fail("bad GIF data") ELSE gStack[0] := first; sp := 1; code := old END
          END;
          WHILE good & (code >= clear) & (sp < 4096) DO gStack[sp] := gSuf[code]; INC(sp); code := gPre[code] END;
          first := code; gStack[sp] := first; INC(sp);
          IF next < 4096 THEN
            gPre[next] := old; gSuf[next] := first; INC(next);
            IF (next = pow2[size]) & (size < 12) THEN INC(size) END
          END;
          old := inCode
        END;
        WHILE (sp > 0) & (count < total) DO   (* the colours come out of the stack backwards *)
          DEC(sp); p := gStack[sp];
          x := count MOD w; IF x = 0 THEN Row(rowMap[count DIV w]) END;
          IF p = trans THEN Trans(x, 255, 255, 255, 0)
          ELSE Pix(x, gPal[p] DIV 65536, gPal[p] DIV 256 MOD 256, gPal[p] MOD 256)
          END;
          INC(count)
        END
      END
    END;
    WHILE good & (count < total) DO   (* a GIF cut short: the rest is white *)
      x := count MOD w; IF x = 0 THEN Row(rowMap[count DIV w]) END; Pix(x, 255, 255, 255); INC(count)
    END
  END GifPixels;

  PROCEDURE Gif;
    VAR b, i, n, k, flags, gct, lct, trans, w, h: INTEGER; done: BOOLEAN;
  BEGIN
    kind := 3; trans := -1; done := FALSE;
    FOR i := 1 TO 4 DO b := Byte() END;   (* "F8 9a" or "F8 7a" *)
    w := Le16(); h := Le16(); flags := Byte(); b := Byte(); b := Byte();
    gct := 0;
    IF flags DIV 128 = 1 THEN
      gct := pow2[flags MOD 8 + 1];
      FOR i := 0 TO gct - 1 DO n := Byte(); k := Byte(); b := Byte(); gPal[i] := n * 65536 + k * 256 + b END
    END;
    WHILE good & ~done DO
      b := Byte();
      IF b = 21H THEN   (* an extension; F9 tells which colour is see-through *)
        b := Byte();
        IF b = 0F9H THEN
          n := Byte(); flags := Byte(); b := Byte(); b := Byte(); k := Byte();
          FOR i := 5 TO n DO b := Byte() END;
          IF ODD(flags) THEN trans := k END
        END;
        Skip
      ELSIF b = 2CH THEN   (* the picture *)
        b := Le16(); b := Le16(); w := Le16(); h := Le16(); flags := Byte();
        IF flags DIV 128 = 1 THEN
          lct := pow2[flags MOD 8 + 1];
          FOR i := 0 TO lct - 1 DO n := Byte(); k := Byte(); b := Byte(); gPal[i] := n * 65536 + k * 256 + b END
        ELSIF gct = 0 THEN FOR i := 0 TO 255 DO gPal[i] := i * 65793 END   (* no colours given: greys *)
        END;
        Grid(w, h);
        IF good THEN GifRows(h, flags DIV 64 MOD 2 = 1); GifPixels(w, h, trans) END;
        done := TRUE
      ELSIF b = 3BH THEN Fail("GIF with no picture")
      ELSE Fail("bad GIF")
      END
    END
  END Gif;

  (* ---------- WEBP: the lossy pictures (VP8 key frame, RFC 6386), in the way of libwebp ---------- *)

  PROCEDURE PA(r, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10: INTEGER);
    VAR k: INTEGER;
  BEGIN
    k := r * 11; wP0[k] := a0; wP0[k + 1] := a1; wP0[k + 2] := a2; wP0[k + 3] := a3; wP0[k + 4] := a4; wP0[k + 5] := a5;
    wP0[k + 6] := a6; wP0[k + 7] := a7; wP0[k + 8] := a8; wP0[k + 9] := a9; wP0[k + 10] := a10
  END PA;

  PROCEDURE PU(r, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10: INTEGER);
    VAR k: INTEGER;
  BEGIN
    k := r * 11; wUp[k] := a0; wUp[k + 1] := a1; wUp[k + 2] := a2; wUp[k + 3] := a3; wUp[k + 4] := a4; wUp[k + 5] := a5;
    wUp[k + 6] := a6; wUp[k + 7] := a7; wUp[k + 8] := a8; wUp[k + 9] := a9; wUp[k + 10] := a10
  END PU;

  PROCEDURE PB(r, a0, a1, a2, a3, a4, a5, a6, a7, a8: INTEGER);
    VAR k: INTEGER;
  BEGIN
    k := r * 9; wBm[k] := a0; wBm[k + 1] := a1; wBm[k + 2] := a2; wBm[k + 3] := a3; wBm[k + 4] := a4; wBm[k + 5] := a5;
    wBm[k + 6] := a6; wBm[k + 7] := a7; wBm[k + 8] := a8
  END PB;

  PROCEDURE PQ(r, a0, a1, a2, a3, a4, a5, a6, a7: INTEGER);   (* 8 at a time: OLL2 takes at most 16 parameters *)
    VAR k: INTEGER;
  BEGIN
    k := r * 8; wQ[k] := a0; wQ[k + 1] := a1; wQ[k + 2] := a2; wQ[k + 3] := a3; wQ[k + 4] := a4; wQ[k + 5] := a5;
    wQ[k + 6] := a6; wQ[k + 7] := a7
  END PQ;

  PROCEDURE TabA;   (* the probabilities a VP8 picture starts with (RFC 6386, 13.5), from libwebp *)
  BEGIN
    PA(0, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(1, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(2, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(3, 253, 136, 254, 255, 228, 219, 128, 128, 128, 128, 128);
    PA(4, 189, 129, 242, 255, 227, 213, 255, 219, 128, 128, 128);
    PA(5, 106, 126, 227, 252, 214, 209, 255, 255, 128, 128, 128);
    PA(6, 1, 98, 248, 255, 236, 226, 255, 255, 128, 128, 128);
    PA(7, 181, 133, 238, 254, 221, 234, 255, 154, 128, 128, 128);
    PA(8, 78, 134, 202, 247, 198, 180, 255, 219, 128, 128, 128);
    PA(9, 1, 185, 249, 255, 243, 255, 128, 128, 128, 128, 128);
    PA(10, 184, 150, 247, 255, 236, 224, 128, 128, 128, 128, 128);
    PA(11, 77, 110, 216, 255, 236, 230, 128, 128, 128, 128, 128);
    PA(12, 1, 101, 251, 255, 241, 255, 128, 128, 128, 128, 128);
    PA(13, 170, 139, 241, 252, 236, 209, 255, 255, 128, 128, 128);
    PA(14, 37, 116, 196, 243, 228, 255, 255, 255, 128, 128, 128);
    PA(15, 1, 204, 254, 255, 245, 255, 128, 128, 128, 128, 128);
    PA(16, 207, 160, 250, 255, 238, 128, 128, 128, 128, 128, 128);
    PA(17, 102, 103, 231, 255, 211, 171, 128, 128, 128, 128, 128);
    PA(18, 1, 152, 252, 255, 240, 255, 128, 128, 128, 128, 128);
    PA(19, 177, 135, 243, 255, 234, 225, 128, 128, 128, 128, 128);
    PA(20, 80, 129, 211, 255, 194, 224, 128, 128, 128, 128, 128);
    PA(21, 1, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(22, 246, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(23, 255, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(24, 198, 35, 237, 223, 193, 187, 162, 160, 145, 155, 62);
    PA(25, 131, 45, 198, 221, 172, 176, 220, 157, 252, 221, 1);
    PA(26, 68, 47, 146, 208, 149, 167, 221, 162, 255, 223, 128);
    PA(27, 1, 149, 241, 255, 221, 224, 255, 255, 128, 128, 128);
    PA(28, 184, 141, 234, 253, 222, 220, 255, 199, 128, 128, 128);
    PA(29, 81, 99, 181, 242, 176, 190, 249, 202, 255, 255, 128);
    PA(30, 1, 129, 232, 253, 214, 197, 242, 196, 255, 255, 128);
    PA(31, 99, 121, 210, 250, 201, 198, 255, 202, 128, 128, 128);
    PA(32, 23, 91, 163, 242, 170, 187, 247, 210, 255, 255, 128);
    PA(33, 1, 200, 246, 255, 234, 255, 128, 128, 128, 128, 128);
    PA(34, 109, 178, 241, 255, 231, 245, 255, 255, 128, 128, 128);
    PA(35, 44, 130, 201, 253, 205, 192, 255, 255, 128, 128, 128);
    PA(36, 1, 132, 239, 251, 219, 209, 255, 165, 128, 128, 128);
    PA(37, 94, 136, 225, 251, 218, 190, 255, 255, 128, 128, 128);
    PA(38, 22, 100, 174, 245, 186, 161, 255, 199, 128, 128, 128);
    PA(39, 1, 182, 249, 255, 232, 235, 128, 128, 128, 128, 128);
    PA(40, 124, 143, 241, 255, 227, 234, 128, 128, 128, 128, 128);
    PA(41, 35, 77, 181, 251, 193, 211, 255, 205, 128, 128, 128);
    PA(42, 1, 157, 247, 255, 236, 231, 255, 255, 128, 128, 128);
    PA(43, 121, 141, 235, 255, 225, 227, 255, 255, 128, 128, 128);
    PA(44, 45, 99, 188, 251, 195, 217, 255, 224, 128, 128, 128);
    PA(45, 1, 1, 251, 255, 213, 255, 128, 128, 128, 128, 128);
    PA(46, 203, 1, 248, 255, 255, 128, 128, 128, 128, 128, 128);
    PA(47, 137, 1, 177, 255, 224, 255, 128, 128, 128, 128, 128);
    PA(48, 253, 9, 248, 251, 207, 208, 255, 192, 128, 128, 128);
    PA(49, 175, 13, 224, 243, 193, 185, 249, 198, 255, 255, 128);
    PA(50, 73, 17, 171, 221, 161, 179, 236, 167, 255, 234, 128);
    PA(51, 1, 95, 247, 253, 212, 183, 255, 255, 128, 128, 128);
    PA(52, 239, 90, 244, 250, 211, 209, 255, 255, 128, 128, 128);
    PA(53, 155, 77, 195, 248, 188, 195, 255, 255, 128, 128, 128);
    PA(54, 1, 24, 239, 251, 218, 219, 255, 205, 128, 128, 128);
    PA(55, 201, 51, 219, 255, 196, 186, 128, 128, 128, 128, 128);
    PA(56, 69, 46, 190, 239, 201, 218, 255, 228, 128, 128, 128);
    PA(57, 1, 191, 251, 255, 255, 128, 128, 128, 128, 128, 128);
    PA(58, 223, 165, 249, 255, 213, 255, 128, 128, 128, 128, 128);
    PA(59, 141, 124, 248, 255, 255, 128, 128, 128, 128, 128, 128);
    PA(60, 1, 16, 248, 255, 255, 128, 128, 128, 128, 128, 128);
    PA(61, 190, 36, 230, 255, 236, 255, 128, 128, 128, 128, 128);
    PA(62, 149, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(63, 1, 226, 255, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(64, 247, 192, 255, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(65, 240, 128, 255, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(66, 1, 134, 252, 255, 255, 128, 128, 128, 128, 128, 128);
    PA(67, 213, 62, 250, 255, 255, 128, 128, 128, 128, 128, 128);
    PA(68, 55, 93, 255, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(69, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(70, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(71, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(72, 202, 24, 213, 235, 186, 191, 220, 160, 240, 175, 255);
    PA(73, 126, 38, 182, 232, 169, 184, 228, 174, 255, 187, 128);
    PA(74, 61, 46, 138, 219, 151, 178, 240, 170, 255, 216, 128);
    PA(75, 1, 112, 230, 250, 199, 191, 247, 159, 255, 255, 128);
    PA(76, 166, 109, 228, 252, 211, 215, 255, 174, 128, 128, 128);
    PA(77, 39, 77, 162, 232, 172, 180, 245, 178, 255, 255, 128);
    PA(78, 1, 52, 220, 246, 198, 199, 249, 220, 255, 255, 128);
    PA(79, 124, 74, 191, 243, 183, 193, 250, 221, 255, 255, 128);
    PA(80, 24, 71, 130, 219, 154, 170, 243, 182, 255, 255, 128);
    PA(81, 1, 182, 225, 249, 219, 240, 255, 224, 128, 128, 128);
    PA(82, 149, 150, 226, 252, 216, 205, 255, 171, 128, 128, 128);
    PA(83, 28, 108, 170, 242, 183, 194, 254, 223, 255, 255, 128);
    PA(84, 1, 81, 230, 252, 204, 203, 255, 192, 128, 128, 128);
    PA(85, 123, 102, 209, 247, 188, 196, 255, 233, 128, 128, 128);
    PA(86, 20, 95, 153, 243, 164, 173, 255, 203, 128, 128, 128);
    PA(87, 1, 222, 248, 255, 216, 213, 128, 128, 128, 128, 128);
    PA(88, 168, 175, 246, 252, 235, 205, 255, 255, 128, 128, 128);
    PA(89, 47, 116, 215, 255, 211, 212, 255, 255, 128, 128, 128);
    PA(90, 1, 121, 236, 253, 212, 214, 255, 255, 128, 128, 128);
    PA(91, 141, 84, 213, 252, 201, 202, 255, 219, 128, 128, 128);
    PA(92, 42, 80, 160, 240, 162, 185, 255, 205, 128, 128, 128);
    PA(93, 1, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(94, 244, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128);
    PA(95, 238, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128)
  END TabA;

  PROCEDURE TabU;   (* how likely each of them is to be changed (RFC 6386, 13.4) *)
  BEGIN
    PU(0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(1, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(2, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(3, 176, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(4, 223, 241, 252, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(5, 249, 253, 253, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(6, 255, 244, 252, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(7, 234, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(8, 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(9, 255, 246, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(10, 239, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(11, 254, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(12, 255, 248, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(13, 251, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(14, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(15, 255, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(16, 251, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(17, 254, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(18, 255, 254, 253, 255, 254, 255, 255, 255, 255, 255, 255);
    PU(19, 250, 255, 254, 255, 254, 255, 255, 255, 255, 255, 255);
    PU(20, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(21, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(22, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(23, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(24, 217, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(25, 225, 252, 241, 253, 255, 255, 254, 255, 255, 255, 255);
    PU(26, 234, 250, 241, 250, 253, 255, 253, 254, 255, 255, 255);
    PU(27, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(28, 223, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(29, 238, 253, 254, 254, 255, 255, 255, 255, 255, 255, 255);
    PU(30, 255, 248, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(31, 249, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(32, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(33, 255, 253, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(34, 247, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(35, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(36, 255, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(37, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(38, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(39, 255, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(40, 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(41, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(42, 255, 254, 253, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(43, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(44, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(45, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(46, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(47, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(48, 186, 251, 250, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(49, 234, 251, 244, 254, 255, 255, 255, 255, 255, 255, 255);
    PU(50, 251, 251, 243, 253, 254, 255, 254, 255, 255, 255, 255);
    PU(51, 255, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(52, 236, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(53, 251, 253, 253, 254, 254, 255, 255, 255, 255, 255, 255);
    PU(54, 255, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(55, 254, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(56, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(57, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(58, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(59, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(60, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(61, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(62, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(63, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(64, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(65, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(66, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(67, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(68, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(69, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(70, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(71, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(72, 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(73, 250, 254, 252, 254, 255, 255, 255, 255, 255, 255, 255);
    PU(74, 248, 254, 249, 253, 255, 255, 255, 255, 255, 255, 255);
    PU(75, 255, 253, 253, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(76, 246, 253, 253, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(77, 252, 254, 251, 254, 254, 255, 255, 255, 255, 255, 255);
    PU(78, 255, 254, 252, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(79, 248, 254, 253, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(80, 253, 255, 254, 254, 255, 255, 255, 255, 255, 255, 255);
    PU(81, 255, 251, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(82, 245, 251, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(83, 253, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(84, 255, 251, 253, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(85, 252, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(86, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(87, 255, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(88, 249, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(89, 255, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(90, 255, 255, 253, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(91, 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(92, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(93, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(94, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
    PU(95, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255)
  END TabU;

  PROCEDURE TabB;   (* the modes of the 4 x 4 blocks, by the modes above and to the left (RFC 6386, 11.5) *)
  BEGIN
    PB(0, 231, 120, 48, 89, 115, 113, 120, 152, 112);
    PB(1, 152, 179, 64, 126, 170, 118, 46, 70, 95);
    PB(2, 175, 69, 143, 80, 85, 82, 72, 155, 103);
    PB(3, 56, 58, 10, 171, 218, 189, 17, 13, 152);
    PB(4, 114, 26, 17, 163, 44, 195, 21, 10, 173);
    PB(5, 121, 24, 80, 195, 26, 62, 44, 64, 85);
    PB(6, 144, 71, 10, 38, 171, 213, 144, 34, 26);
    PB(7, 170, 46, 55, 19, 136, 160, 33, 206, 71);
    PB(8, 63, 20, 8, 114, 114, 208, 12, 9, 226);
    PB(9, 81, 40, 11, 96, 182, 84, 29, 16, 36);
    PB(10, 134, 183, 89, 137, 98, 101, 106, 165, 148);
    PB(11, 72, 187, 100, 130, 157, 111, 32, 75, 80);
    PB(12, 66, 102, 167, 99, 74, 62, 40, 234, 128);
    PB(13, 41, 53, 9, 178, 241, 141, 26, 8, 107);
    PB(14, 74, 43, 26, 146, 73, 166, 49, 23, 157);
    PB(15, 65, 38, 105, 160, 51, 52, 31, 115, 128);
    PB(16, 104, 79, 12, 27, 217, 255, 87, 17, 7);
    PB(17, 87, 68, 71, 44, 114, 51, 15, 186, 23);
    PB(18, 47, 41, 14, 110, 182, 183, 21, 17, 194);
    PB(19, 66, 45, 25, 102, 197, 189, 23, 18, 22);
    PB(20, 88, 88, 147, 150, 42, 46, 45, 196, 205);
    PB(21, 43, 97, 183, 117, 85, 38, 35, 179, 61);
    PB(22, 39, 53, 200, 87, 26, 21, 43, 232, 171);
    PB(23, 56, 34, 51, 104, 114, 102, 29, 93, 77);
    PB(24, 39, 28, 85, 171, 58, 165, 90, 98, 64);
    PB(25, 34, 22, 116, 206, 23, 34, 43, 166, 73);
    PB(26, 107, 54, 32, 26, 51, 1, 81, 43, 31);
    PB(27, 68, 25, 106, 22, 64, 171, 36, 225, 114);
    PB(28, 34, 19, 21, 102, 132, 188, 16, 76, 124);
    PB(29, 62, 18, 78, 95, 85, 57, 50, 48, 51);
    PB(30, 193, 101, 35, 159, 215, 111, 89, 46, 111);
    PB(31, 60, 148, 31, 172, 219, 228, 21, 18, 111);
    PB(32, 112, 113, 77, 85, 179, 255, 38, 120, 114);
    PB(33, 40, 42, 1, 196, 245, 209, 10, 25, 109);
    PB(34, 88, 43, 29, 140, 166, 213, 37, 43, 154);
    PB(35, 61, 63, 30, 155, 67, 45, 68, 1, 209);
    PB(36, 100, 80, 8, 43, 154, 1, 51, 26, 71);
    PB(37, 142, 78, 78, 16, 255, 128, 34, 197, 171);
    PB(38, 41, 40, 5, 102, 211, 183, 4, 1, 221);
    PB(39, 51, 50, 17, 168, 209, 192, 23, 25, 82);
    PB(40, 138, 31, 36, 171, 27, 166, 38, 44, 229);
    PB(41, 67, 87, 58, 169, 82, 115, 26, 59, 179);
    PB(42, 63, 59, 90, 180, 59, 166, 93, 73, 154);
    PB(43, 40, 40, 21, 116, 143, 209, 34, 39, 175);
    PB(44, 47, 15, 16, 183, 34, 223, 49, 45, 183);
    PB(45, 46, 17, 33, 183, 6, 98, 15, 32, 183);
    PB(46, 57, 46, 22, 24, 128, 1, 54, 17, 37);
    PB(47, 65, 32, 73, 115, 28, 128, 23, 128, 205);
    PB(48, 40, 3, 9, 115, 51, 192, 18, 6, 223);
    PB(49, 87, 37, 9, 115, 59, 77, 64, 21, 47);
    PB(50, 104, 55, 44, 218, 9, 54, 53, 130, 226);
    PB(51, 64, 90, 70, 205, 40, 41, 23, 26, 57);
    PB(52, 54, 57, 112, 184, 5, 41, 38, 166, 213);
    PB(53, 30, 34, 26, 133, 152, 116, 10, 32, 134);
    PB(54, 39, 19, 53, 221, 26, 114, 32, 73, 255);
    PB(55, 31, 9, 65, 234, 2, 15, 1, 118, 73);
    PB(56, 75, 32, 12, 51, 192, 255, 160, 43, 51);
    PB(57, 88, 31, 35, 67, 102, 85, 55, 186, 85);
    PB(58, 56, 21, 23, 111, 59, 205, 45, 37, 192);
    PB(59, 55, 38, 70, 124, 73, 102, 1, 34, 98);
    PB(60, 125, 98, 42, 88, 104, 85, 117, 175, 82);
    PB(61, 95, 84, 53, 89, 128, 100, 113, 101, 45);
    PB(62, 75, 79, 123, 47, 51, 128, 81, 171, 1);
    PB(63, 57, 17, 5, 71, 102, 57, 53, 41, 49);
    PB(64, 38, 33, 13, 121, 57, 73, 26, 1, 85);
    PB(65, 41, 10, 67, 138, 77, 110, 90, 47, 114);
    PB(66, 115, 21, 2, 10, 102, 255, 166, 23, 6);
    PB(67, 101, 29, 16, 10, 85, 128, 101, 196, 26);
    PB(68, 57, 18, 10, 102, 102, 213, 34, 20, 43);
    PB(69, 117, 20, 15, 36, 163, 128, 68, 1, 26);
    PB(70, 102, 61, 71, 37, 34, 53, 31, 243, 192);
    PB(71, 69, 60, 71, 38, 73, 119, 28, 222, 37);
    PB(72, 68, 45, 128, 34, 1, 47, 11, 245, 171);
    PB(73, 62, 17, 19, 70, 146, 85, 55, 62, 70);
    PB(74, 37, 43, 37, 154, 100, 163, 85, 160, 1);
    PB(75, 63, 9, 92, 136, 28, 64, 32, 201, 85);
    PB(76, 75, 15, 9, 9, 64, 255, 184, 119, 16);
    PB(77, 86, 6, 28, 5, 64, 255, 25, 248, 1);
    PB(78, 56, 8, 17, 132, 137, 255, 55, 116, 128);
    PB(79, 58, 15, 20, 82, 135, 57, 26, 121, 40);
    PB(80, 164, 50, 31, 137, 154, 133, 25, 35, 218);
    PB(81, 51, 103, 44, 131, 131, 123, 31, 6, 158);
    PB(82, 86, 40, 64, 135, 148, 224, 45, 183, 128);
    PB(83, 22, 26, 17, 131, 240, 154, 14, 1, 209);
    PB(84, 45, 16, 21, 91, 64, 222, 7, 1, 197);
    PB(85, 56, 21, 39, 155, 60, 138, 23, 102, 213);
    PB(86, 83, 12, 13, 54, 192, 255, 68, 47, 28);
    PB(87, 85, 26, 85, 85, 128, 128, 32, 146, 171);
    PB(88, 18, 11, 7, 63, 144, 171, 4, 4, 246);
    PB(89, 35, 27, 10, 146, 174, 171, 12, 26, 128);
    PB(90, 190, 80, 35, 99, 180, 80, 126, 54, 45);
    PB(91, 85, 126, 47, 87, 176, 51, 41, 20, 32);
    PB(92, 101, 75, 128, 139, 118, 146, 116, 128, 85);
    PB(93, 56, 41, 15, 176, 236, 85, 37, 9, 62);
    PB(94, 71, 30, 17, 119, 118, 255, 17, 18, 138);
    PB(95, 101, 38, 60, 138, 55, 70, 43, 26, 142);
    PB(96, 146, 36, 19, 30, 171, 255, 97, 27, 20);
    PB(97, 138, 45, 61, 62, 219, 1, 81, 188, 64);
    PB(98, 32, 41, 20, 117, 151, 142, 20, 21, 163);
    PB(99, 112, 19, 12, 61, 195, 128, 48, 4, 24)
  END TabB;

  PROCEDURE TabQ;   (* the steps of the quantizers (RFC 6386, 14.1): DC 0 .. 127, then AC *)
  BEGIN
    PQ(0, 4, 5, 6, 7, 8, 9, 10, 10);
    PQ(1, 11, 12, 13, 14, 15, 16, 17, 17);
    PQ(2, 18, 19, 20, 20, 21, 21, 22, 22);
    PQ(3, 23, 23, 24, 25, 25, 26, 27, 28);
    PQ(4, 29, 30, 31, 32, 33, 34, 35, 36);
    PQ(5, 37, 37, 38, 39, 40, 41, 42, 43);
    PQ(6, 44, 45, 46, 46, 47, 48, 49, 50);
    PQ(7, 51, 52, 53, 54, 55, 56, 57, 58);
    PQ(8, 59, 60, 61, 62, 63, 64, 65, 66);
    PQ(9, 67, 68, 69, 70, 71, 72, 73, 74);
    PQ(10, 75, 76, 76, 77, 78, 79, 80, 81);
    PQ(11, 82, 83, 84, 85, 86, 87, 88, 89);
    PQ(12, 91, 93, 95, 96, 98, 100, 101, 102);
    PQ(13, 104, 106, 108, 110, 112, 114, 116, 118);
    PQ(14, 122, 124, 126, 128, 130, 132, 134, 136);
    PQ(15, 138, 140, 143, 145, 148, 151, 154, 157);
    PQ(16, 4, 5, 6, 7, 8, 9, 10, 11);
    PQ(17, 12, 13, 14, 15, 16, 17, 18, 19);
    PQ(18, 20, 21, 22, 23, 24, 25, 26, 27);
    PQ(19, 28, 29, 30, 31, 32, 33, 34, 35);
    PQ(20, 36, 37, 38, 39, 40, 41, 42, 43);
    PQ(21, 44, 45, 46, 47, 48, 49, 50, 51);
    PQ(22, 52, 53, 54, 55, 56, 57, 58, 60);
    PQ(23, 62, 64, 66, 68, 70, 72, 74, 76);
    PQ(24, 78, 80, 82, 84, 86, 88, 90, 92);
    PQ(25, 94, 96, 98, 100, 102, 104, 106, 108);
    PQ(26, 110, 112, 114, 116, 119, 122, 125, 128);
    PQ(27, 131, 134, 137, 140, 143, 146, 149, 152);
    PQ(28, 155, 158, 161, 164, 167, 170, 173, 177);
    PQ(29, 181, 185, 189, 193, 197, 201, 205, 209);
    PQ(30, 213, 217, 221, 225, 229, 234, 239, 245);
    PQ(31, 249, 254, 259, 264, 269, 274, 279, 284)
  END TabQ;


  PROCEDURE WbAt(i: INTEGER): INTEGER;   (* a byte of the VP8 data; 0 past its end *)
    VAR v: INTEGER;
  BEGIN IF (i >= 0) & (i < wbN) THEN v := ORD(wb[i]) ELSE v := 0 END
    RETURN v
  END WbAt;

  PROCEDURE RInit(r, start, size: INTEGER);   (* the boolean decoder r reads bytes start .. start + size - 1 *)
  BEGIN
    rEnd[r] := start + size; IF rEnd[r] > wbN THEN rEnd[r] := wbN END;
    rPos[r] := start + 2; rRange[r] := 255; rCnt[r] := 0;
    rVal[r] := 0; IF start < rEnd[r] THEN rVal[r] := WbAt(start) * 256 END;
    IF start + 1 < rEnd[r] THEN rVal[r] := rVal[r] + WbAt(start + 1) END
  END RInit;

  PROCEDURE RBit(r, prob: INTEGER): INTEGER;   (* one bit that is 0 with probability prob / 256 *)
    VAR split, big, bit: INTEGER;
  BEGIN
    split := 1 + (rRange[r] - 1) * prob DIV 256; big := split * 256;
    IF rVal[r] >= big THEN bit := 1; rRange[r] := rRange[r] - split; rVal[r] := rVal[r] - big
    ELSE bit := 0; rRange[r] := split
    END;
    WHILE rRange[r] < 128 DO
      rVal[r] := rVal[r] * 2; rRange[r] := rRange[r] * 2; INC(rCnt[r]);
      IF rCnt[r] = 8 THEN
        rCnt[r] := 0;
        IF rPos[r] < rEnd[r] THEN rVal[r] := rVal[r] + WbAt(rPos[r]) END;
        INC(rPos[r])
      END
    END
    RETURN bit
  END RBit;

  PROCEDURE RVal(r, n: INTEGER): INTEGER;   (* n bits, the high one first *)
    VAR v, i: INTEGER;
  BEGIN v := 0; FOR i := 1 TO n DO v := v * 2 + RBit(r, 128) END
    RETURN v
  END RVal;

  PROCEDURE RSigned(r, n: INTEGER): INTEGER;   (* n bits, then the sign *)
    VAR v: INTEGER;
  BEGIN v := RVal(r, n); IF RBit(r, 128) = 1 THEN v := -v END
    RETURN v
  END RSigned;

  PROCEDURE RFlagged(r, n: INTEGER): INTEGER;   (* a flag, then (if set) a signed value; else 0 *)
    VAR v: INTEGER;
  BEGIN v := 0; IF RBit(r, 128) = 1 THEN v := RSigned(r, n) END
    RETURN v
  END RFlagged;

  PROCEDURE Large(r, p: INTEGER): INTEGER;   (* a coefficient bigger than 1 (RFC 6386, 13.2) *)
    VAR v, b1, b0, cat, i: INTEGER;
  BEGIN
    IF RBit(r, wPr[p + 3]) = 0 THEN
      IF RBit(r, wPr[p + 4]) = 0 THEN v := 2 ELSE v := 3 + RBit(r, wPr[p + 5]) END
    ELSIF RBit(r, wPr[p + 6]) = 0 THEN
      IF RBit(r, wPr[p + 7]) = 0 THEN v := 5 + RBit(r, 159)
      ELSE v := 7 + 2 * RBit(r, 165); v := v + RBit(r, 145)
      END
    ELSE
      b1 := RBit(r, wPr[p + 8]); b0 := RBit(r, wPr[p + 9 + b1]); cat := 2 * b1 + b0; v := 0; i := 0;
      WHILE wCat[cat * 12 + i] # 0 DO v := v + v + RBit(r, wCat[cat * 12 + i]); INC(i) END;
      v := v + 3 + 8 * pow2[cat]
    END
    RETURN v
  END Large;

  PROCEDURE PIdx(t, n, ctx: INTEGER): INTEGER;   (* where the 11 probabilities of type t, place n, context ctx are *)
  BEGIN RETURN ((t * 8 + wBand[n]) * 3 + ctx) * 11
  END PIdx;

  PROCEDURE Coeffs(r, t, ctx, dq0, dq1, n, base: INTEGER; VAR out: ARRAY OF INTEGER): INTEGER;
    (* the coefficients of one 4 x 4 block into out[base ..]; the place after the last that is not 0 *)
    VAR p, v, res: INTEGER; done: BOOLEAN;
  BEGIN
    p := PIdx(t, n, ctx); done := FALSE; res := 16;
    WHILE ~done & (n < 16) DO
      IF RBit(r, wPr[p]) = 0 THEN res := n; done := TRUE   (* the one before was the last *)
      ELSE
        WHILE ~done & (RBit(r, wPr[p + 1]) = 0) DO   (* zeros *)
          INC(n); IF n = 16 THEN res := 16; done := TRUE ELSE p := PIdx(t, n, 0) END
        END;
        IF ~done THEN
          IF RBit(r, wPr[p + 2]) = 0 THEN v := 1; p := PIdx(t, n + 1, 1)
          ELSE v := Large(r, p); p := PIdx(t, n + 1, 2)
          END;
          IF RBit(r, 128) = 1 THEN v := -v END;
          IF n > 0 THEN out[base + wZig[n]] := v * dq1 ELSE out[base + wZig[n]] := v * dq0 END;
          INC(n)
        END
      END
    END
    RETURN res
  END Coeffs;

  PROCEDURE Wht;   (* the 16 means of the luma blocks out of the Y2 block *)
    VAR tmp: ARRAY 16 OF INTEGER; i, a0, a1, a2, a3, dc, o: INTEGER;
  BEGIN
    FOR i := 0 TO 3 DO
      a0 := wDc[i] + wDc[12 + i]; a1 := wDc[4 + i] + wDc[8 + i]; a2 := wDc[4 + i] - wDc[8 + i]; a3 := wDc[i] - wDc[12 + i];
      tmp[i] := a0 + a1; tmp[8 + i] := a0 - a1; tmp[4 + i] := a3 + a2; tmp[12 + i] := a3 - a2
    END;
    o := 0;
    FOR i := 0 TO 3 DO
      dc := tmp[i * 4] + 3;
      a0 := dc + tmp[3 + i * 4]; a1 := tmp[1 + i * 4] + tmp[2 + i * 4]; a2 := tmp[1 + i * 4] - tmp[2 + i * 4]; a3 := dc - tmp[3 + i * 4];
      wCo[o] := (a0 + a1) DIV 8; wCo[o + 16] := (a3 + a2) DIV 8; wCo[o + 32] := (a0 - a1) DIV 8; wCo[o + 48] := (a3 - a2) DIV 8;
      o := o + 64
    END
  END Wht;

  PROCEDURE Mul1(a: INTEGER): INTEGER; BEGIN RETURN a * 20091 DIV 65536 + a END Mul1;
  PROCEDURE Mul2(a: INTEGER): INTEGER; BEGIN RETURN a * 35468 DIV 65536 END Mul2;

  PROCEDURE Put(d, v: INTEGER);   (* a residual added to the prediction *)
  BEGIN wYuv[d] := Clamp(wYuv[d] + v DIV 8)
  END Put;

  PROCEDURE Transform(base, d: INTEGER);   (* the inverse DCT of block base, added at d *)
    VAR tmp: ARRAY 16 OF INTEGER; i, a, b, c, e, dc: INTEGER;
  BEGIN
    FOR i := 0 TO 3 DO
      a := wCo[base + i] + wCo[base + 8 + i]; b := wCo[base + i] - wCo[base + 8 + i];
      c := Mul2(wCo[base + 4 + i]) - Mul1(wCo[base + 12 + i]); e := Mul1(wCo[base + 4 + i]) + Mul2(wCo[base + 12 + i]);
      tmp[i * 4] := a + e; tmp[i * 4 + 1] := b + c; tmp[i * 4 + 2] := b - c; tmp[i * 4 + 3] := a - e
    END;
    FOR i := 0 TO 3 DO
      dc := tmp[i] + 4;
      a := dc + tmp[8 + i]; b := dc - tmp[8 + i];
      c := Mul2(tmp[4 + i]) - Mul1(tmp[12 + i]); e := Mul1(tmp[4 + i]) + Mul2(tmp[12 + i]);
      Put(d + i * BPS, a + e); Put(d + i * BPS + 1, b + c); Put(d + i * BPS + 2, b - c); Put(d + i * BPS + 3, a - e)
    END
  END Transform;

  PROCEDURE Fill(d, n, v: INTEGER);   (* an n x n square of v *)
    VAR x, y: INTEGER;
  BEGIN FOR y := 0 TO n - 1 DO FOR x := 0 TO n - 1 DO wYuv[d + y * BPS + x] := v END END
  END Fill;

  PROCEDURE PredBig(d, n, mode: INTEGER);   (* 16 x 16 luma or 8 x 8 chroma: 0 DC, 1 TM, 2 VE, 3 HE, 4 DC no top,
                                                5 DC no left, 6 DC with neither *)
    VAR x, y, s, sh: INTEGER;
  BEGIN
    IF n = 16 THEN sh := 32 ELSE sh := 16 END;
    IF mode = 0 THEN
      s := n; FOR y := 0 TO n - 1 DO s := s + wYuv[d - 1 + y * BPS] + wYuv[d + y - BPS] END; Fill(d, n, s DIV sh)
    ELSIF mode = 1 THEN
      FOR y := 0 TO n - 1 DO
        FOR x := 0 TO n - 1 DO wYuv[d + y * BPS + x] := Clamp(wYuv[d + y * BPS - 1] + wYuv[d - BPS + x] - wYuv[d - BPS - 1]) END
      END
    ELSIF mode = 2 THEN FOR y := 0 TO n - 1 DO FOR x := 0 TO n - 1 DO wYuv[d + y * BPS + x] := wYuv[d - BPS + x] END END
    ELSIF mode = 3 THEN FOR y := 0 TO n - 1 DO FOR x := 0 TO n - 1 DO wYuv[d + y * BPS + x] := wYuv[d + y * BPS - 1] END END
    ELSIF mode = 4 THEN s := n DIV 2; FOR y := 0 TO n - 1 DO s := s + wYuv[d - 1 + y * BPS] END; Fill(d, n, s DIV (sh DIV 2))
    ELSIF mode = 5 THEN s := n DIV 2; FOR x := 0 TO n - 1 DO s := s + wYuv[d + x - BPS] END; Fill(d, n, s DIV (sh DIV 2))
    ELSE Fill(d, n, 128)
    END
  END PredBig;

  PROCEDURE Avg3(a, b, c: INTEGER): INTEGER; BEGIN RETURN (a + 2 * b + c + 2) DIV 4 END Avg3;
  PROCEDURE Avg2(a, b: INTEGER): INTEGER; BEGIN RETURN (a + b + 1) DIV 2 END Avg2;

  PROCEDURE S(d, x, y, v: INTEGER); BEGIN wYuv[d + x + y * BPS] := v END S;

  PROCEDURE Pred4(d, mode: INTEGER);   (* a 4 x 4 block (RFC 6386, 12.3) *)
    VAR A, B, C, D, E, F, G, H, I, J, K, L, X, x, y, s: INTEGER;
  BEGIN
    I := wYuv[d - 1]; J := wYuv[d - 1 + BPS]; K := wYuv[d - 1 + 2 * BPS]; L := wYuv[d - 1 + 3 * BPS]; X := wYuv[d - 1 - BPS];
    A := wYuv[d - BPS]; B := wYuv[d + 1 - BPS]; C := wYuv[d + 2 - BPS]; D := wYuv[d + 3 - BPS];
    E := wYuv[d + 4 - BPS]; F := wYuv[d + 5 - BPS]; G := wYuv[d + 6 - BPS]; H := wYuv[d + 7 - BPS];
    IF mode = 0 THEN s := (A + B + C + D + I + J + K + L + 4) DIV 8; Fill(d, 4, s)   (* DC *)
    ELSIF mode = 1 THEN   (* TM *)
      FOR y := 0 TO 3 DO FOR x := 0 TO 3 DO S(d, x, y, Clamp(wYuv[d + y * BPS - 1] + wYuv[d - BPS + x] - X)) END END
    ELSIF mode = 2 THEN   (* VE *)
      FOR y := 0 TO 3 DO S(d, 0, y, Avg3(X, A, B)); S(d, 1, y, Avg3(A, B, C)); S(d, 2, y, Avg3(B, C, D)); S(d, 3, y, Avg3(C, D, E)) END
    ELSIF mode = 3 THEN   (* HE *)
      FOR x := 0 TO 3 DO S(d, x, 0, Avg3(X, I, J)); S(d, x, 1, Avg3(I, J, K)); S(d, x, 2, Avg3(J, K, L)); S(d, x, 3, Avg3(K, L, L)) END
    ELSIF mode = 4 THEN   (* RD *)
      S(d, 0, 3, Avg3(J, K, L));
      S(d, 1, 3, Avg3(I, J, K)); S(d, 0, 2, Avg3(I, J, K));
      S(d, 2, 3, Avg3(X, I, J)); S(d, 1, 2, Avg3(X, I, J)); S(d, 0, 1, Avg3(X, I, J));
      S(d, 3, 3, Avg3(A, X, I)); S(d, 2, 2, Avg3(A, X, I)); S(d, 1, 1, Avg3(A, X, I)); S(d, 0, 0, Avg3(A, X, I));
      S(d, 3, 2, Avg3(B, A, X)); S(d, 2, 1, Avg3(B, A, X)); S(d, 1, 0, Avg3(B, A, X));
      S(d, 3, 1, Avg3(C, B, A)); S(d, 2, 0, Avg3(C, B, A));
      S(d, 3, 0, Avg3(D, C, B))
    ELSIF mode = 5 THEN   (* VR *)
      S(d, 0, 0, Avg2(X, A)); S(d, 1, 2, Avg2(X, A));
      S(d, 1, 0, Avg2(A, B)); S(d, 2, 2, Avg2(A, B));
      S(d, 2, 0, Avg2(B, C)); S(d, 3, 2, Avg2(B, C));
      S(d, 3, 0, Avg2(C, D));
      S(d, 0, 3, Avg3(K, J, I));
      S(d, 0, 2, Avg3(J, I, X));
      S(d, 0, 1, Avg3(I, X, A)); S(d, 1, 3, Avg3(I, X, A));
      S(d, 1, 1, Avg3(X, A, B)); S(d, 2, 3, Avg3(X, A, B));
      S(d, 2, 1, Avg3(A, B, C)); S(d, 3, 3, Avg3(A, B, C));
      S(d, 3, 1, Avg3(B, C, D))
    ELSIF mode = 6 THEN   (* LD *)
      S(d, 0, 0, Avg3(A, B, C));
      S(d, 1, 0, Avg3(B, C, D)); S(d, 0, 1, Avg3(B, C, D));
      S(d, 2, 0, Avg3(C, D, E)); S(d, 1, 1, Avg3(C, D, E)); S(d, 0, 2, Avg3(C, D, E));
      S(d, 3, 0, Avg3(D, E, F)); S(d, 2, 1, Avg3(D, E, F)); S(d, 1, 2, Avg3(D, E, F)); S(d, 0, 3, Avg3(D, E, F));
      S(d, 3, 1, Avg3(E, F, G)); S(d, 2, 2, Avg3(E, F, G)); S(d, 1, 3, Avg3(E, F, G));
      S(d, 3, 2, Avg3(F, G, H)); S(d, 2, 3, Avg3(F, G, H));
      S(d, 3, 3, Avg3(G, H, H))
    ELSIF mode = 7 THEN   (* VL *)
      S(d, 0, 0, Avg2(A, B));
      S(d, 1, 0, Avg2(B, C)); S(d, 0, 2, Avg2(B, C));
      S(d, 2, 0, Avg2(C, D)); S(d, 1, 2, Avg2(C, D));
      S(d, 3, 0, Avg2(D, E)); S(d, 2, 2, Avg2(D, E));
      S(d, 0, 1, Avg3(A, B, C));
      S(d, 1, 1, Avg3(B, C, D)); S(d, 0, 3, Avg3(B, C, D));
      S(d, 2, 1, Avg3(C, D, E)); S(d, 1, 3, Avg3(C, D, E));
      S(d, 3, 1, Avg3(D, E, F)); S(d, 2, 3, Avg3(D, E, F));
      S(d, 3, 2, Avg3(E, F, G));
      S(d, 3, 3, Avg3(F, G, H))
    ELSIF mode = 8 THEN   (* HD *)
      S(d, 0, 0, Avg2(I, X)); S(d, 2, 1, Avg2(I, X));
      S(d, 0, 1, Avg2(J, I)); S(d, 2, 2, Avg2(J, I));
      S(d, 0, 2, Avg2(K, J)); S(d, 2, 3, Avg2(K, J));
      S(d, 0, 3, Avg2(L, K));
      S(d, 3, 0, Avg3(A, B, C));
      S(d, 2, 0, Avg3(X, A, B));
      S(d, 1, 0, Avg3(I, X, A)); S(d, 3, 1, Avg3(I, X, A));
      S(d, 1, 1, Avg3(J, I, X)); S(d, 3, 2, Avg3(J, I, X));
      S(d, 1, 2, Avg3(K, J, I)); S(d, 3, 3, Avg3(K, J, I));
      S(d, 1, 3, Avg3(L, K, J))
    ELSE   (* HU *)
      S(d, 0, 0, Avg2(I, J));
      S(d, 2, 0, Avg2(J, K)); S(d, 0, 1, Avg2(J, K));
      S(d, 2, 1, Avg2(K, L)); S(d, 0, 2, Avg2(K, L));
      S(d, 1, 0, Avg3(I, J, K));
      S(d, 3, 0, Avg3(J, K, L)); S(d, 1, 1, Avg3(J, K, L));
      S(d, 3, 1, Avg3(K, L, L)); S(d, 1, 2, Avg3(K, L, L));
      S(d, 3, 2, L); S(d, 2, 2, L); S(d, 0, 3, L); S(d, 1, 3, L); S(d, 2, 3, L); S(d, 3, 3, L)
    END
  END Pred4;

  PROCEDURE CheckMode(mx, my, mode: INTEGER): INTEGER;   (* DC at the edges of the picture *)
  BEGIN
    IF mode = 0 THEN
      IF mx = 0 THEN IF my = 0 THEN mode := 6 ELSE mode := 5 END
      ELSIF my = 0 THEN mode := 4
      END
    END
    RETURN mode
  END CheckMode;

  PROCEDURE IntraMode(mx: INTEGER);   (* the modes of one macroblock, from the first partition *)
    VAR x, y, ym, i, p: INTEGER;
  BEGIN
    mbSeg := 0;
    IF wUpdMap THEN
      IF RBit(0, wSegP[0]) = 0 THEN mbSeg := RBit(0, wSegP[1]) ELSE mbSeg := RBit(0, wSegP[2]) + 2 END
    END;
    mbSkip := 0; IF wUseSkip THEN mbSkip := RBit(0, wSkipP) END;
    mbI4 := RBit(0, 145) = 0;
    IF ~mbI4 THEN
      IF RBit(0, 156) = 1 THEN IF RBit(0, 128) = 1 THEN ym := 1 ELSE ym := 3 END
      ELSIF RBit(0, 163) = 1 THEN ym := 2 ELSE ym := 0
      END;
      mbYm := ym;
      FOR i := 0 TO 3 DO wIntT[mx * 4 + i] := ym; wIntL[i] := ym END
    ELSE
      FOR y := 0 TO 3 DO
        ym := wIntL[y];
        FOR x := 0 TO 3 DO
          p := (wIntT[mx * 4 + x] * 10 + ym) * 9;   (* kBModesProba[top][left] *)
          i := wTree[RBit(0, wBm[p])];
          WHILE i > 0 DO i := wTree[2 * i + RBit(0, wBm[p + i])] END;
          ym := -i; wIntT[mx * 4 + x] := ym; mbIm[y * 4 + x] := ym
        END;
        wIntL[y] := ym
      END
    END;
    IF RBit(0, 142) = 0 THEN mbUv := 0
    ELSIF RBit(0, 114) = 0 THEN mbUv := 2
    ELSIF RBit(0, 183) = 1 THEN mbUv := 1
    ELSE mbUv := 3
    END
  END IntraMode;

  PROCEDURE Residuals(r, mx: INTEGER);   (* the coefficients of one macroblock, from token partition r *)
    VAR i, x, y, l, nz, ctx, first, t, sg: INTEGER;
  BEGIN
    FOR i := 0 TO 383 DO wCo[i] := 0 END;
    sg := mbSeg;
    IF ~mbI4 THEN
      FOR i := 0 TO 15 DO wDc[i] := 0 END;
      ctx := wNzDcT[mx] + wNzDcL;
      nz := Coeffs(r, 1, ctx, wY2dc[sg], wY2ac[sg], 0, 0, wDc);
      IF nz > 0 THEN wNzDcT[mx] := 1; wNzDcL := 1 ELSE wNzDcT[mx] := 0; wNzDcL := 0 END;
      IF nz > 1 THEN Wht ELSE FOR i := 0 TO 15 DO wCo[i * 16] := (wDc[0] + 3) DIV 8 END END;
      first := 1; t := 0
    ELSE first := 0; t := 3
    END;
    FOR y := 0 TO 3 DO
      l := wNzYL[y];
      FOR x := 0 TO 3 DO
        ctx := l + wNzYT[mx * 4 + x];
        nz := Coeffs(r, t, ctx, wY1dc[sg], wY1ac[sg], first, (y * 4 + x) * 16, wCo);
        IF nz > first THEN l := 1 ELSE l := 0 END;
        wNzYT[mx * 4 + x] := l
      END;
      wNzYL[y] := l
    END;
    FOR y := 0 TO 1 DO
      l := wNzUL[y];
      FOR x := 0 TO 1 DO
        ctx := l + wNzUT[mx * 2 + x];
        nz := Coeffs(r, 2, ctx, wUvdc[sg], wUvac[sg], 0, (16 + y * 2 + x) * 16, wCo);
        IF nz > 0 THEN l := 1 ELSE l := 0 END;
        wNzUT[mx * 2 + x] := l
      END;
      wNzUL[y] := l
    END;
    FOR y := 0 TO 1 DO
      l := wNzVL[y];
      FOR x := 0 TO 1 DO
        ctx := l + wNzVT[mx * 2 + x];
        nz := Coeffs(r, 2, ctx, wUvdc[sg], wUvac[sg], 0, (20 + y * 2 + x) * 16, wCo);
        IF nz > 0 THEN l := 1 ELSE l := 0 END;
        wNzVT[mx * 2 + x] := l
      END;
      wNzVL[y] := l
    END
  END Residuals;

  PROCEDURE NoResiduals(mx: INTEGER);   (* a macroblock with nothing to add *)
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO 383 DO wCo[i] := 0 END;
    FOR i := 0 TO 3 DO wNzYT[mx * 4 + i] := 0; wNzYL[i] := 0 END;
    FOR i := 0 TO 1 DO wNzUT[mx * 2 + i] := 0; wNzUL[i] := 0; wNzVT[mx * 2 + i] := 0; wNzVL[i] := 0 END;
    IF ~mbI4 THEN wNzDcT[mx] := 0; wNzDcL := 0 END
  END NoResiduals;

  PROCEDURE Reconstruct(mx, my: INTEGER);   (* predict and add, in the work buffer, then into the row *)
    VAR j, i, n, d, m, tr: INTEGER;
  BEGIN
    IF mx > 0 THEN   (* the left samples, from the macroblock before *)
      FOR j := -1 TO 15 DO FOR i := 0 TO 3 DO wYuv[YOFF + j * BPS - 4 + i] := wYuv[YOFF + j * BPS + 12 + i] END END;
      FOR j := -1 TO 7 DO
        FOR i := 0 TO 3 DO
          wYuv[UOFF + j * BPS - 4 + i] := wYuv[UOFF + j * BPS + 4 + i]; wYuv[VOFF + j * BPS - 4 + i] := wYuv[VOFF + j * BPS + 4 + i]
        END
      END
    END;
    IF my > 0 THEN   (* the top samples, from the row above *)
      FOR i := 0 TO 15 DO wYuv[YOFF - BPS + i] := wTopY[mx * 16 + i] END;
      FOR i := 0 TO 7 DO wYuv[UOFF - BPS + i] := wTopU[mx * 8 + i]; wYuv[VOFF - BPS + i] := wTopV[mx * 8 + i] END
    END;
    IF mbI4 THEN
      tr := YOFF - BPS + 16;
      IF my > 0 THEN
        IF mx >= wMbW - 1 THEN FOR i := 0 TO 3 DO wYuv[tr + i] := wTopY[mx * 16 + 15] END
        ELSE FOR i := 0 TO 3 DO wYuv[tr + i] := wTopY[mx * 16 + 16 + i] END
        END
      END;
      FOR i := 0 TO 3 DO   (* the same top-right for the blocks below *)
        wYuv[tr + 4 * BPS + i] := wYuv[tr + i]; wYuv[tr + 8 * BPS + i] := wYuv[tr + i]; wYuv[tr + 12 * BPS + i] := wYuv[tr + i]
      END;
      FOR n := 0 TO 15 DO
        d := YOFF + (n MOD 4) * 4 + (n DIV 4) * 4 * BPS;
        Pred4(d, mbIm[n]); Transform(n * 16, d)
      END
    ELSE
      m := CheckMode(mx, my, mbYm); PredBig(YOFF, 16, m);
      FOR n := 0 TO 15 DO Transform(n * 16, YOFF + (n MOD 4) * 4 + (n DIV 4) * 4 * BPS) END
    END;
    m := CheckMode(mx, my, mbUv); PredBig(UOFF, 8, m); PredBig(VOFF, 8, m);
    FOR n := 0 TO 3 DO
      Transform((16 + n) * 16, UOFF + (n MOD 2) * 4 + (n DIV 2) * 4 * BPS);
      Transform((20 + n) * 16, VOFF + (n MOD 2) * 4 + (n DIV 2) * 4 * BPS)
    END;
    FOR j := 0 TO 15 DO FOR i := 0 TO 15 DO wOutY[j * wOs + mx * 16 + i] := wYuv[YOFF + j * BPS + i] END END;
    FOR j := 0 TO 7 DO
      FOR i := 0 TO 7 DO
        wOutU[j * wCs + mx * 8 + i] := wYuv[UOFF + j * BPS + i]; wOutV[j * wCs + mx * 8 + i] := wYuv[VOFF + j * BPS + i]
      END
    END
  END Reconstruct;

  PROCEDURE C8(v: INTEGER): INTEGER;   (* libwebp's VP8Clip8 *)
  BEGIN IF v < 0 THEN v := 0 ELSIF v >= 16384 THEN v := 255 ELSE v := v DIV 64 END
    RETURN v
  END C8;

  (* ---------- the loop filter of VP8 (RFC 6386, 15), in the planes, as libwebp does it ---------- *)

  PROCEDURE PS(i, v: INTEGER);
  BEGIN IF v < 0 THEN v := 0 ELSIF v > 255 THEN v := 255 END; jp[i] := CHR(v)
  END PS;

  PROCEDURE S1(v: INTEGER): INTEGER;   (* -128 .. 127 *)
  BEGIN IF v < -128 THEN v := -128 ELSIF v > 127 THEN v := 127 END
    RETURN v
  END S1;

  PROCEDURE S2(v: INTEGER): INTEGER;   (* -16 .. 15 *)
  BEGIN IF v < -16 THEN v := -16 ELSIF v > 15 THEN v := 15 END
    RETURN v
  END S2;

  PROCEDURE F2(p, s: INTEGER);   (* 4 pixels in, 2 out *)
    VAR p1, p0, q0, q1, a, a1, a2: INTEGER;
  BEGIN
    p1 := ORD(jp[p - 2 * s]); p0 := ORD(jp[p - s]); q0 := ORD(jp[p]); q1 := ORD(jp[p + s]);
    a := 3 * (q0 - p0) + S1(p1 - q1); a1 := S2((a + 4) DIV 8); a2 := S2((a + 3) DIV 8);
    PS(p - s, p0 + a2); PS(p, q0 - a1)
  END F2;

  PROCEDURE F4(p, s: INTEGER);   (* 4 in, 4 out *)
    VAR p1, p0, q0, q1, a, a1, a2, a3: INTEGER;
  BEGIN
    p1 := ORD(jp[p - 2 * s]); p0 := ORD(jp[p - s]); q0 := ORD(jp[p]); q1 := ORD(jp[p + s]);
    a := 3 * (q0 - p0); a1 := S2((a + 4) DIV 8); a2 := S2((a + 3) DIV 8); a3 := (a1 + 1) DIV 2;
    PS(p - 2 * s, p1 + a3); PS(p - s, p0 + a2); PS(p, q0 - a1); PS(p + s, q1 - a3)
  END F4;

  PROCEDURE F6(p, s: INTEGER);   (* 6 in, 6 out *)
    VAR p2, p1, p0, q0, q1, q2, a, a1, a2, a3: INTEGER;
  BEGIN
    p2 := ORD(jp[p - 3 * s]); p1 := ORD(jp[p - 2 * s]); p0 := ORD(jp[p - s]);
    q0 := ORD(jp[p]); q1 := ORD(jp[p + s]); q2 := ORD(jp[p + 2 * s]);
    a := S1(3 * (q0 - p0) + S1(p1 - q1));
    a1 := (27 * a + 63) DIV 128; a2 := (18 * a + 63) DIV 128; a3 := (9 * a + 63) DIV 128;
    PS(p - 3 * s, p2 + a3); PS(p - 2 * s, p1 + a2); PS(p - s, p0 + a1);
    PS(p, q0 - a1); PS(p + s, q1 - a2); PS(p + 2 * s, q2 - a3)
  END F6;

  PROCEDURE Hev(p, s, t: INTEGER): BOOLEAN;
  BEGIN RETURN (ABS(ORD(jp[p - 2 * s]) - ORD(jp[p - s])) > t) OR (ABS(ORD(jp[p + s]) - ORD(jp[p])) > t)
  END Hev;

  PROCEDURE Needs(p, s, t: INTEGER): BOOLEAN;
  BEGIN RETURN 4 * ABS(ORD(jp[p - s]) - ORD(jp[p])) + ABS(ORD(jp[p - 2 * s]) - ORD(jp[p + s])) <= t
  END Needs;

  PROCEDURE Needs2(p, s, t, it: INTEGER): BOOLEAN;
    VAR p3, p2, p1, p0, q0, q1, q2, q3: INTEGER; ok: BOOLEAN;
  BEGIN
    p3 := ORD(jp[p - 4 * s]); p2 := ORD(jp[p - 3 * s]); p1 := ORD(jp[p - 2 * s]); p0 := ORD(jp[p - s]);
    q0 := ORD(jp[p]); q1 := ORD(jp[p + s]); q2 := ORD(jp[p + 2 * s]); q3 := ORD(jp[p + 3 * s]);
    IF 4 * ABS(p0 - q0) + ABS(p1 - q1) > t THEN ok := FALSE
    ELSE ok := (ABS(p3 - p2) <= it) & (ABS(p2 - p1) <= it) & (ABS(p1 - p0) <= it) & (ABS(q3 - q2) <= it) & (ABS(q2 - q1) <= it) & (ABS(q1 - q0) <= it)
    END
    RETURN ok
  END Needs2;

  PROCEDURE Simple(p, hs, vs, thresh: INTEGER);   (* 16 places along an edge *)
    VAR i, t: INTEGER;
  BEGIN
    t := 2 * thresh + 1;
    FOR i := 0 TO 15 DO IF Needs(p, hs, t) THEN F2(p, hs) END; p := p + vs END
  END Simple;

  PROCEDURE Loop(p, hs, vs, size, thresh, it, hev: INTEGER; six: BOOLEAN);   (* FilterLoop26 (six) or 24 *)
    VAR i, t: INTEGER;
  BEGIN
    t := 2 * thresh + 1;
    FOR i := 1 TO size DO
      IF Needs2(p, hs, t, it) THEN
        IF Hev(p, hs, hev) THEN F2(p, hs) ELSIF six THEN F6(p, hs) ELSE F4(p, hs) END
      END;
      p := p + vs
    END
  END Loop;

  PROCEDURE FilterInfo(mx: INTEGER; nz: BOOLEAN);   (* the strength for this macroblock (libwebp's PrecomputeFilterStrengths) *)
    VAR level, il: INTEGER;
  BEGIN
    level := lfLevel;
    IF wUseSeg THEN level := wSegF[mbSeg]; IF ~wAbs THEN level := level + lfLevel END END;
    IF lfUse THEN level := level + lfRef0; IF mbI4 THEN level := level + lfMode0 END END;
    IF level < 0 THEN level := 0 ELSIF level > 63 THEN level := 63 END;
    IF (lfLevel = 0) OR (level = 0) THEN fLim[mx] := 0
    ELSE
      il := level;
      IF lfSharp > 0 THEN
        IF lfSharp > 4 THEN il := il DIV 4 ELSE il := il DIV 2 END;
        IF il > 9 - lfSharp THEN il := 9 - lfSharp END
      END;
      IF il < 1 THEN il := 1 END;
      fIl[mx] := il; fLim[mx] := 2 * level + il;
      IF level >= 40 THEN fHev[mx] := 2 ELSIF level >= 15 THEN fHev[mx] := 1 ELSE fHev[mx] := 0 END
    END;
    fIn[mx] := mbI4 OR nz
  END FilterInfo;

  PROCEDURE FilterRow(my: INTEGER);
    VAR mx, k, yb, ub, vb, sy, su, lim, il, hv: INTEGER;
  BEGIN
    sy := jW[0]; su := jW[1];
    FOR mx := 0 TO wMbW - 1 DO
      lim := fLim[mx]; il := fIl[mx]; hv := fHev[mx];
      IF lim > 0 THEN
        yb := jOff[0] + my * 16 * sy + mx * 16; ub := jOff[1] + my * 8 * su + mx * 8; vb := jOff[2] + my * 8 * su + mx * 8;
        IF lfSimple = 1 THEN
          IF mx > 0 THEN Simple(yb, 1, sy, lim + 4) END;
          IF fIn[mx] THEN FOR k := 1 TO 3 DO Simple(yb + 4 * k, 1, sy, lim) END END;
          IF my > 0 THEN Simple(yb, sy, 1, lim + 4) END;
          IF fIn[mx] THEN FOR k := 1 TO 3 DO Simple(yb + 4 * k * sy, sy, 1, lim) END END
        ELSE
          IF mx > 0 THEN
            Loop(yb, 1, sy, 16, lim + 4, il, hv, TRUE); Loop(ub, 1, su, 8, lim + 4, il, hv, TRUE); Loop(vb, 1, su, 8, lim + 4, il, hv, TRUE)
          END;
          IF fIn[mx] THEN
            FOR k := 1 TO 3 DO Loop(yb + 4 * k, 1, sy, 16, lim, il, hv, FALSE) END;
            Loop(ub + 4, 1, su, 8, lim, il, hv, FALSE); Loop(vb + 4, 1, su, 8, lim, il, hv, FALSE)
          END;
          IF my > 0 THEN
            Loop(yb, sy, 1, 16, lim + 4, il, hv, TRUE); Loop(ub, su, 1, 8, lim + 4, il, hv, TRUE); Loop(vb, su, 1, 8, lim + 4, il, hv, TRUE)
          END;
          IF fIn[mx] THEN
            FOR k := 1 TO 3 DO Loop(yb + 4 * k * sy, sy, 1, 16, lim, il, hv, FALSE) END;
            Loop(ub + 4 * su, su, 1, 8, lim, il, hv, FALSE); Loop(vb + 4 * su, su, 1, 8, lim, il, hv, FALSE)
          END
        END
      END
    END
  END FilterRow;

  PROCEDURE WConvert;   (* the filtered planes -> the pixels, each colour from its 4 nearest samples *)
    VAR x, y, yy, u, v, r, g, b: INTEGER;
  BEGIN
    FOR y := 0 TO H - 1 DO
      Row(y);
      FOR x := 0 TO W - 1 DO
        yy := At(0, x, y) * 19077 DIV 256; u := Up(1, x, y); v := Up(2, x, y);
        r := C8(yy + v * 26149 DIV 256 - 14234);
        g := C8(yy - u * 6419 DIV 256 - v * 13320 DIV 256 + 8708);
        b := C8(yy + u * 33050 DIV 256 - 17685);
        Pix(x, r, g, b)
      END
    END
  END WConvert;

  PROCEDURE EmitMbRow(my: INTEGER);   (* the 16 rows of pixels of this macroblock row, YUV -> RGB *)
    VAR j, x, y, yy, u, v, r, g, b, k: INTEGER;
  BEGIN
    IF planes THEN   (* into the planes, then the loop filter; the pixels come at the end *)
      FOR j := 0 TO 15 DO
        k := jOff[0] + (my * 16 + j) * jW[0];
        FOR x := 0 TO wOs - 1 DO jp[k + x] := CHR(wOutY[j * wOs + x]) END
      END;
      FOR j := 0 TO 7 DO
        k := (my * 8 + j) * jW[1];
        FOR x := 0 TO wCs - 1 DO jp[jOff[1] + k + x] := CHR(wOutU[j * wCs + x]); jp[jOff[2] + k + x] := CHR(wOutV[j * wCs + x]) END
      END;
      IF lfLevel > 0 THEN FilterRow(my) END;
      j := 16
    ELSE j := 0
    END;
    WHILE j <= 15 DO
      y := my * 16 + j;
      IF y < H THEN
        Row(y);
        FOR x := 0 TO W - 1 DO
          yy := wOutY[j * wOs + x] * 19077 DIV 256; k := (j DIV 2) * wCs + x DIV 2;
          u := wOutU[k]; v := wOutV[k];
          r := C8(yy + v * 26149 DIV 256 - 14234);
          g := C8(yy - u * 6419 DIV 256 - v * 13320 DIV 256 + 8708);
          b := C8(yy + u * 33050 DIV 256 - 17685);
          Pix(x, r, g, b)
        END
      END;
      INC(j)
    END;
    FOR x := 0 TO wOs - 1 DO wTopY[x] := wOutY[15 * wOs + x] END;
    FOR x := 0 TO wCs - 1 DO wTopU[x] := wOutU[7 * wCs + x]; wTopV[x] := wOutV[7 * wCs + x] END
  END EmitMbRow;

  PROCEDURE QClip(v, m: INTEGER): INTEGER;
  BEGIN IF v < 0 THEN v := 0 ELSIF v > m THEN v := m END
    RETURN v
  END QClip;

  PROCEDURE Quant(base: INTEGER);   (* the quantizers of the 4 segments (RFC 6386, 9.6) *)
    VAR s, q, dy1, dy2, dy2a, duv, duva: INTEGER;
  BEGIN
    dy1 := RFlagged(0, 4); dy2 := RFlagged(0, 4); dy2a := RFlagged(0, 4); duv := RFlagged(0, 4); duva := RFlagged(0, 4);
    FOR s := 0 TO 3 DO
      IF wUseSeg THEN q := wSegQ[s]; IF ~wAbs THEN q := q + base END ELSE q := base END;
      wY1dc[s] := wQ[QClip(q + dy1, 127)]; wY1ac[s] := wQ[128 + QClip(q, 127)];
      wY2dc[s] := wQ[QClip(q + dy2, 127)] * 2;
      wY2ac[s] := wQ[128 + QClip(q + dy2a, 127)] * 101581 DIV 65536; IF wY2ac[s] < 8 THEN wY2ac[s] := 8 END;
      wUvdc[s] := wQ[QClip(q + duv, 117)]; wUvac[s] := wQ[128 + QClip(q + duva, 127)]
    END
  END Quant;

  PROCEDURE Vp8;   (* the VP8 data in wb[0 .. wbN-1] *)
    VAR bits, partLen, w, h, i, s, t, b, c, p, k, start, np, last, psize, left, mx, my, r: INTEGER;
  BEGIN
    bits := WbAt(0) + WbAt(1) * 256 + WbAt(2) * 65536; partLen := bits DIV 32;
    IF ODD(bits) THEN Fail("WEBP that is not a still picture")
    ELSIF (WbAt(3) # 9DH) OR (WbAt(4) # 1) OR (WbAt(5) # 2AH) THEN Fail("bad WEBP")
    ELSE
      w := (WbAt(6) + WbAt(7) * 256) MOD 16384; h := (WbAt(8) + WbAt(9) * 256) MOD 16384;
      Grid(w, h)
    END;
    IF good THEN
      wMbW := (w + 15) DIV 16; wMbH := (h + 15) DIV 16; wOs := wMbW * 16; wCs := wMbW * 8;
      jW[0] := wOs; jOff[0] := wMbH * 16; jFx[0] := 1; jFy[0] := 1; jVw[0] := w; jVh[0] := h;
      FOR i := 1 TO 2 DO jW[i] := wCs; jOff[i] := wMbH * 8; jFx[i] := 2; jFy[i] := 2; jVw[i] := (w + 1) DIV 2; jVh[i] := (h + 1) DIV 2 END;
      PlanesFor(3); FOR i := 0 TO 3 DO wSegF[i] := 0 END;
      RInit(0, 10, partLen);
      b := RBit(0, 128); b := RBit(0, 128);   (* colour space, clamping *)
      (* segments *)
      wUseSeg := RBit(0, 128) = 1; wUpdMap := FALSE; wAbs := TRUE;
      FOR s := 0 TO 3 DO wSegQ[s] := 0 END;
      FOR s := 0 TO 2 DO wSegP[s] := 255 END;
      IF wUseSeg THEN
        wUpdMap := RBit(0, 128) = 1;
        IF RBit(0, 128) = 1 THEN
          wAbs := RBit(0, 128) = 1;
          FOR s := 0 TO 3 DO wSegQ[s] := RFlagged(0, 7) END;
          FOR s := 0 TO 3 DO wSegF[s] := RFlagged(0, 6) END
        END;
        IF wUpdMap THEN FOR s := 0 TO 2 DO IF RBit(0, 128) = 1 THEN wSegP[s] := RVal(0, 8) END END END
      END;
      (* the loop filter (RFC 6386, 9.6) *)
      lfSimple := RBit(0, 128); lfLevel := RVal(0, 6); lfSharp := RVal(0, 3); lfUse := RBit(0, 128) = 1;
      lfRef0 := 0; lfMode0 := 0;
      IF lfUse THEN
        IF RBit(0, 128) = 1 THEN
          FOR i := 0 TO 3 DO IF RBit(0, 128) = 1 THEN b := RSigned(0, 6); IF i = 0 THEN lfRef0 := b END END END;
          FOR i := 0 TO 3 DO IF RBit(0, 128) = 1 THEN b := RSigned(0, 6); IF i = 0 THEN lfMode0 := b END END END
        END
      END;
      (* the partitions of the coefficients *)
      np := pow2[RVal(0, 2)]; last := np - 1;
      start := 10 + partLen; p := start + last * 3; left := wbN - p;
      FOR i := 0 TO last - 1 DO
        psize := WbAt(start + i * 3) + WbAt(start + i * 3 + 1) * 256 + WbAt(start + i * 3 + 2) * 65536;
        IF psize > left THEN psize := left END;
        RInit(1 + i, p, psize); p := p + psize; left := left - psize
      END;
      RInit(1 + last, p, left);
      Quant(RVal(0, 7));
      b := RBit(0, 128);   (* refresh the probabilities: ignored *)
      FOR t := 0 TO 3 DO
        FOR b := 0 TO 7 DO
          FOR c := 0 TO 2 DO
            FOR i := 0 TO 10 DO
              k := ((t * 8 + b) * 3 + c) * 11 + i;
              IF RBit(0, wUp[k]) = 1 THEN wPr[k] := RVal(0, 8) ELSE wPr[k] := wP0[k] END
            END
          END
        END
      END;
      wUseSkip := RBit(0, 128) = 1; IF wUseSkip THEN wSkipP := RVal(0, 8) END;
      (* the macroblocks *)
      FOR i := 0 TO wMbW * 4 - 1 DO wIntT[i] := 0; wNzYT[i] := 0 END;
      FOR i := 0 TO wMbW * 2 - 1 DO wNzUT[i] := 0; wNzVT[i] := 0 END;
      FOR i := 0 TO wMbW - 1 DO wNzDcT[i] := 0 END;
      my := 0;
      WHILE good & (my < wMbH) DO
        r := 1 + my MOD np;
        FOR i := 0 TO 3 DO wIntL[i] := 0; wNzYL[i] := 0 END;
        FOR i := 0 TO 1 DO wNzUL[i] := 0; wNzVL[i] := 0 END;
        wNzDcL := 0;
        FOR i := 0 TO 15 DO wYuv[YOFF + i * BPS - 1] := 129 END;
        FOR i := 0 TO 7 DO wYuv[UOFF + i * BPS - 1] := 129; wYuv[VOFF + i * BPS - 1] := 129 END;
        IF my > 0 THEN wYuv[YOFF - 1 - BPS] := 129; wYuv[UOFF - 1 - BPS] := 129; wYuv[VOFF - 1 - BPS] := 129
        ELSE
          FOR i := -1 TO 19 DO wYuv[YOFF - BPS + i] := 127 END;
          FOR i := -1 TO 7 DO wYuv[UOFF - BPS + i] := 127; wYuv[VOFF - BPS + i] := 127 END
        END;
        FOR mx := 0 TO wMbW - 1 DO
          IntraMode(mx);
          IF wUseSkip & (mbSkip = 1) THEN NoResiduals(mx) ELSE Residuals(r, mx) END;
          IF planes THEN i := 0; WHILE (i < 384) & (wCo[i] = 0) DO INC(i) END; FilterInfo(mx, i < 384) END;
          Reconstruct(mx, my)
        END;
        EmitMbRow(my);
        IF rPos[0] > rEnd[0] + 8 THEN Fail("the WEBP ends too soon") END;
        INC(my)
      END;
      IF good & planes THEN WConvert END
    END
  END Vp8;

  PROCEDURE Webp;   (* RIFF ... WEBP: the chunks, up to "VP8 " *)
    VAR b, i, n, t, sz: INTEGER; done: BOOLEAN;
  BEGIN
    kind := 4; done := FALSE;
    b := Byte(); b := Byte();   (* "FF" *)
    sz := Byte(); sz := Byte(); sz := Byte(); sz := Byte();
    t := Be32();   (* "WEBP" *)
    IF t # 57454250H THEN Fail("not a picture") END;
    WHILE good & ~done DO
      t := Be32();
      n := Byte(); n := n + Byte() * 256; n := n + Byte() * 65536; n := n + Byte() * 16777216;
      IF eof THEN done := TRUE
      ELSIF t = 56503820H THEN   (* "VP8 " *)
        IF n > WBN THEN Fail("WEBP too big")
        ELSE
          FOR i := 0 TO n - 1 DO wb[i] := CHR(Byte()) END;
          wbN := n; IF good THEN Vp8 END
        END;
        done := TRUE
      ELSIF t = 5650384CH THEN Fail("lossless WEBP")
      ELSE FOR i := 1 TO n + n MOD 2 DO b := Byte() END   (* VP8X, ALPH, ICCP, EXIF ...: not needed *)
      END
    END
  END Webp;

  PROCEDURE WebpInit;
    VAR i: INTEGER;
  BEGIN
    TabA; TabU; TabB; TabQ;
    wZig[0] := 0; wZig[1] := 1; wZig[2] := 4; wZig[3] := 8; wZig[4] := 5; wZig[5] := 2; wZig[6] := 3; wZig[7] := 6;
    wZig[8] := 9; wZig[9] := 12; wZig[10] := 13; wZig[11] := 10; wZig[12] := 7; wZig[13] := 11; wZig[14] := 14; wZig[15] := 15;
    wBand[0] := 0; wBand[1] := 1; wBand[2] := 2; wBand[3] := 3; wBand[4] := 6; wBand[5] := 4; wBand[6] := 5;
    FOR i := 7 TO 14 DO wBand[i] := 6 END; wBand[15] := 7; wBand[16] := 0;
    FOR i := 0 TO 47 DO wCat[i] := 0 END;
    wCat[0] := 173; wCat[1] := 148; wCat[2] := 140;
    wCat[12] := 176; wCat[13] := 155; wCat[14] := 140; wCat[15] := 135;
    wCat[24] := 180; wCat[25] := 157; wCat[26] := 141; wCat[27] := 134; wCat[28] := 130;
    wCat[36] := 254; wCat[37] := 254; wCat[38] := 243; wCat[39] := 230; wCat[40] := 196; wCat[41] := 177;
    wCat[42] := 153; wCat[43] := 140; wCat[44] := 133; wCat[45] := 130; wCat[46] := 129;
    (* the tree of the 4 x 4 modes: 0 DC 1 TM 2 VE 3 HE 4 RD 5 VR 6 LD 7 VL 8 HD 9 HU (kYModesIntra4) *)
    wTree[0] := 0; wTree[1] := 1; wTree[2] := -1; wTree[3] := 2; wTree[4] := -2; wTree[5] := 3;
    wTree[6] := 4; wTree[7] := 6; wTree[8] := -3; wTree[9] := 5; wTree[10] := -4; wTree[11] := -5;
    wTree[12] := -6; wTree[13] := 7; wTree[14] := -7; wTree[15] := 8; wTree[16] := -8; wTree[17] := -9;
    FOR i := 0 TO YUVN - 1 DO wYuv[i] := 0 END
  END WebpInit;

  (* ---------- the door ---------- *)

  PROCEDURE Load*(name: ARRAY OF CHAR; most: INTEGER): BOOLEAN;   (* the picture in file name -> at most most x most
                                                                       cells; FALSE: why says why *)
    VAR a, b: INTEGER;
  BEGIN
    lim := most; IF lim > MC THEN lim := MC END; IF lim < 1 THEN lim := 1 END;
    good := TRUE; eof := FALSE; why[0] := 0X; kind := 0; W := 0; H := 0; cw := 0; ch := 0; planes := FALSE;
    fh := Fisier.Deschide(name);
    IF fh < 0 THEN Fail("no file")
    ELSE
      a := Byte(); b := Byte();
      IF (a = 0FFH) & (b = 0D8H) THEN Jpeg
      ELSIF (a = 89H) & (b = 50H) THEN b := Byte(); b := Byte(); Png
      ELSIF (a = 47H) & (b = 49H) THEN Gif
      ELSIF (a = 52H) & (b = 49H) THEN Webp
      ELSIF a = 3CH THEN Fail("SVG")
      ELSE Fail("not a picture")
      END;
      Fisier.Gata(fh);
      IF good THEN Finish END
    END
    RETURN good
  END Load;

  PROCEDURE Tables;
    VAR i, s, y, lo, hi, x, u: INTEGER; c: REAL;
  BEGIN
    pow2[0] := 1; FOR i := 1 TO 16 DO pow2[i] := pow2[i - 1] * 2 END;
    i := 0;   (* zigzag: the k-th coefficient sits at zz[k] (row * 8 + column) *)
    FOR s := 0 TO 14 DO
      lo := 0; IF s > 7 THEN lo := s - 7 END;
      hi := s; IF hi > 7 THEN hi := 7 END;
      IF ODD(s) THEN FOR y := lo TO hi DO zz[i] := y * 8 + s - y; INC(i) END
      ELSE FOR y := hi TO lo BY -1 DO zz[i] := y * 8 + s - y; INC(i) END
      END
    END;
    FOR x := 0 TO 7 DO
      FOR u := 0 TO 7 DO
        IF u = 0 THEN c := 0.35355339059327373 ELSE c := 0.5 END;
        cosT[x * 8 + u] := c * Math.cos(FLT((2 * x + 1) * u) * 3.141592653589793 / 16.0)
      END
    END;
    FOR i := 0 TO 28 DO IF i < 8 THEN lExtra[i] := 0 ELSE lExtra[i] := (i - 4) DIV 4 END END;
    lExtra[28] := 0;
    lBase[0] := 3; FOR i := 1 TO 28 DO lBase[i] := lBase[i - 1] + pow2[lExtra[i - 1]] END; lBase[28] := 258;
    FOR i := 0 TO 29 DO IF i < 4 THEN dExtra[i] := 0 ELSE dExtra[i] := (i - 2) DIV 2 END END;
    dBase[0] := 1; FOR i := 1 TO 29 DO dBase[i] := dBase[i - 1] + pow2[dExtra[i - 1]] END;
    clOrder[0] := 16; clOrder[1] := 17; clOrder[2] := 18; clOrder[3] := 0; clOrder[4] := 8; clOrder[5] := 7;
    clOrder[6] := 9; clOrder[7] := 6; clOrder[8] := 10; clOrder[9] := 5; clOrder[10] := 11; clOrder[11] := 4;
    clOrder[12] := 12; clOrder[13] := 3; clOrder[14] := 13; clOrder[15] := 2; clOrder[16] := 14; clOrder[17] := 1;
    clOrder[18] := 15;
    aSx[0] := 0; aSy[0] := 0; aDx[0] := 8; aDy[0] := 8;   aSx[1] := 4; aSy[1] := 0; aDx[1] := 8; aDy[1] := 8;
    aSx[2] := 0; aSy[2] := 4; aDx[2] := 4; aDy[2] := 8;   aSx[3] := 2; aSy[3] := 0; aDx[3] := 4; aDy[3] := 4;
    aSx[4] := 0; aSy[4] := 2; aDx[4] := 2; aDy[4] := 4;   aSx[5] := 1; aSy[5] := 0; aDx[5] := 2; aDy[5] := 2;
    aSx[6] := 0; aSy[6] := 1; aDx[6] := 1; aDy[6] := 2
  END Tables;

BEGIN
  W := 0; H := 0; cw := 0; ch := 0; kind := 0; why[0] := 0X; good := TRUE; eof := FALSE; lim := 64; keepA := FALSE; planes := FALSE; lfLevel := 0; Tables; WebpInit
END Pic6.
