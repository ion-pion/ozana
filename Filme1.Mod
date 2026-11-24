MODULE Filme1;  (* FILME 1 (24 Nov 2026, Nora 16): the films that are given freely, found and read in Oberon.
     Pion: "both, as usual" (NewPipe for YouTube, and a player of her own for the free ones).
     The search engines of the free films answer in JSON; Filme1 reads it (a small JSON reader, here) and writes a little
     HTML page of what it found, with the pictures and the titles, that Nora reads as any page:
       1  PeerTube, through Sepia Search (sepiasearch.org: the videos of hundreds of PeerTube servers)
       2  the Internet Archive (archive.org: old films, cartoons, concerts, ...), mediatype movies
       3  Wikimedia Commons (the films of Wikipedia)
     A title of PeerTube or of the Archive leads to "nora:play?ADDRESS": Nora asks the address (the details of the video)
     and Pick finds in the answer the file a phone can play (MP4 or WebM, about 720 lines; or the HLS list of PeerTube).
     A title of Commons leads straight to its WebM.
   Pion & Claude, 24.11.2026 *)

  IMPORT Fisier;

  CONST
    JB = 2000000;   (* the most bytes of an answer *)
    DM = 12;        (* how deep the paths are kept *)
    MI = 40;        (* the most films on a page *)
    MF = 600;       (* the most files of a film *)
    SL = 400;       (* the longest address kept *)
    hexd = "0123456789ABCDEF";

  VAR
    jb: ARRAY JB OF CHAR; jn, jp, dep, pk: INTEGER; ok: BOOLEAN;
    seg: ARRAY DM, 48 OF CHAR;
    val: ARRAY 2048 OF CHAR;
    kind, ni, cur: INTEGER;
    lastKey: ARRAY 48 OF CHAR;
    iTitle: ARRAY MI, 160 OF CHAR;
    iImg, iLink, iAddr: ARRAY MI, SL OF CHAR;
    iUuid: ARRAY MI, 64 OF CHAR;
    iInfo: ARRAY MI, 80 OF CHAR;
    iRank, iDur: ARRAY MI OF INTEGER;
    fName: ARRAY MF, 200 OF CHAR; fFmt: ARRAY MF, 32 OF CHAR; fRes: ARRAY MF OF INTEGER; nf: INTEGER;
    playlist: ARRAY SL OF CHAR;

  (* ---------- strings ---------- *)

  PROCEDURE Len(VAR s: ARRAY OF CHAR): INTEGER;
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END
    RETURN i
  END Len;

  PROCEDURE Copy(s: ARRAY OF CHAR; VAR d: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) & (i < LEN(d) - 1) DO d[i] := s[i]; INC(i) END; d[i] := 0X
  END Copy;

  PROCEDURE Add(VAR d: ARRAY OF CHAR; s: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN
    j := Len(d); i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) & (j < LEN(d) - 1) DO d[j] := s[i]; INC(i); INC(j) END; d[j] := 0X
  END Add;

  PROCEDURE AddC(VAR d: ARRAY OF CHAR; c: CHAR);
    VAR j: INTEGER;
  BEGIN j := Len(d); IF j < LEN(d) - 1 THEN d[j] := c; d[j + 1] := 0X END
  END AddC;

  PROCEDURE AddNum(VAR d: ARRAY OF CHAR; n: INTEGER);
    VAR t: ARRAY 12 OF CHAR; k: INTEGER;
  BEGIN
    IF n < 0 THEN AddC(d, "-"); n := -n END;
    k := 0; REPEAT t[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    WHILE k > 0 DO DEC(k); AddC(d, t[k]) END
  END AddNum;

  PROCEDURE Same(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
  BEGIN
    i := 0; WHILE (i < LEN(a)) & (i < LEN(b)) & (a[i] # 0X) & (a[i] = b[i]) DO INC(i) END
    RETURN ((i = LEN(a)) OR (a[i] = 0X)) & ((i = LEN(b)) OR (b[i] = 0X))
  END Same;

  PROCEDURE Starts(VAR s: ARRAY OF CHAR; p: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
  BEGIN
    i := 0; WHILE (i < LEN(p)) & (p[i] # 0X) & (i < LEN(s)) & (s[i] = p[i]) DO INC(i) END
    RETURN (i = LEN(p)) OR (p[i] = 0X)
  END Starts;

  PROCEDURE Ends(VAR s: ARRAY OF CHAR; p: ARRAY OF CHAR): BOOLEAN;
    VAR n, m, i: INTEGER; r: BOOLEAN;
  BEGIN
    n := Len(s); m := 0; WHILE (m < LEN(p)) & (p[m] # 0X) DO INC(m) END;
    r := n >= m; i := 0;
    WHILE r & (i < m) DO r := s[n - m + i] = p[i]; INC(i) END
    RETURN r
  END Ends;

  PROCEDURE Has(VAR s: ARRAY OF CHAR; p: ARRAY OF CHAR): BOOLEAN;   (* p is somewhere in s *)
    VAR n, m, i, j: INTEGER; r: BOOLEAN;
  BEGIN
    n := Len(s); m := 0; WHILE (m < LEN(p)) & (p[m] # 0X) DO INC(m) END;
    r := FALSE; i := 0;
    WHILE ~r & (i + m <= n) DO
      j := 0; WHILE (j < m) & (s[i + j] = p[j]) DO INC(j) END;
      r := j = m; INC(i)
    END
    RETURN r
  END Has;

  PROCEDURE Num(VAR s: ARRAY OF CHAR): INTEGER;
    VAR i, n: INTEGER;
  BEGIN
    i := 0; n := 0;
    WHILE (i < LEN(s)) & (s[i] >= "0") & (s[i] <= "9") & (n < 10000000) DO n := n * 10 + ORD(s[i]) - ORD("0"); INC(i) END
    RETURN n
  END Num;

  PROCEDURE Enc2(s: ARRAY OF CHAR; VAR d: ARRAY OF CHAR; slash: BOOLEAN);   (* s added to d, written for an address (%XX) *)
    VAR i, c: INTEGER; h: ARRAY 17 OF CHAR;
  BEGIN
    h := hexd; i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) DO
      c := ORD(s[i]) MOD 256;
      IF (c >= ORD("a")) & (c <= ORD("z")) OR (c >= ORD("A")) & (c <= ORD("Z")) OR (c >= ORD("0")) & (c <= ORD("9"))
          OR (s[i] = "-") OR (s[i] = "_") OR (s[i] = ".") OR (s[i] = "~") OR slash & (s[i] = "/") THEN AddC(d, s[i])
      ELSE AddC(d, "%"); AddC(d, h[c DIV 16]); AddC(d, h[c MOD 16])
      END;
      INC(i)
    END
  END Enc2;

  PROCEDURE Enc(s: ARRAY OF CHAR; VAR d: ARRAY OF CHAR);
  BEGIN Enc2(s, d, FALSE)
  END Enc;

  PROCEDURE Host(VAR u: ARRAY OF CHAR; VAR h: ARRAY OF CHAR);   (* https://HOST/... -> HOST *)
    VAR i, j: INTEGER;
  BEGIN
    i := 0; WHILE (u[i] # 0X) & ~((u[i] = "/") & (u[i + 1] = "/")) DO INC(i) END;
    IF u[i] = 0X THEN i := 0 ELSE i := i + 2 END;
    j := 0; WHILE (u[i] # 0X) & (u[i] # "/") & (j < LEN(h) - 1) DO h[j] := u[i]; INC(i); INC(j) END; h[j] := 0X
  END Host;

  (* ---------- the JSON reader: every value with its path ---------- *)

  PROCEDURE Load(name: ARRAY OF CHAR): BOOLEAN;
    VAR h, b: INTEGER;
  BEGIN
    jn := 0; h := Fisier.Deschide(name);
    IF h >= 0 THEN
      b := Fisier.Citeste(h);
      WHILE (b >= 0) & (jn < JB - 1) DO jb[jn] := CHR(b); INC(jn); b := Fisier.Citeste(h) END;
      Fisier.Gata(h)
    END;
    jb[jn] := 0X; jp := 0; dep := 0; ok := jn > 0
    RETURN ok
  END Load;

  PROCEDURE Ws;
  BEGIN WHILE (jp < jn) & ((jb[jp] = " ") OR (jb[jp] = 9X) OR (jb[jp] = 0AX) OR (jb[jp] = 0DX)) DO INC(jp) END
  END Ws;

  PROCEDURE Hex(c: CHAR): INTEGER;
    VAR v: INTEGER;
  BEGIN
    IF (c >= "0") & (c <= "9") THEN v := ORD(c) - ORD("0")
    ELSIF (c >= "a") & (c <= "f") THEN v := ORD(c) - ORD("a") + 10
    ELSIF (c >= "A") & (c <= "F") THEN v := ORD(c) - ORD("A") + 10
    ELSE v := 0
    END
    RETURN v
  END Hex;

  PROCEDURE Put(VAR s: ARRAY OF CHAR; b: INTEGER);   (* one more byte at pk *)
  BEGIN IF pk < LEN(s) - 1 THEN s[pk] := CHR(b); INC(pk) END
  END Put;

  PROCEDURE Str(VAR s: ARRAY OF CHAR);   (* the string at jp (after its ") -> s, UTF-8 *)
    VAR u: INTEGER; c: CHAR;
  BEGIN
    INC(jp); pk := 0;
    WHILE (jp < jn) & (jb[jp] # 22X) DO
      c := jb[jp];
      IF c = "\" THEN
        INC(jp); c := jb[jp];
        IF c = "n" THEN Put(s, 32) ELSIF c = "t" THEN Put(s, 32) ELSIF (c = "r") OR (c = "b") OR (c = "f") THEN
        ELSIF c = "u" THEN
          u := Hex(jb[jp + 1]) * 4096 + Hex(jb[jp + 2]) * 256 + Hex(jb[jp + 3]) * 16 + Hex(jb[jp + 4]); jp := jp + 4;
          IF u < 128 THEN Put(s, u)
          ELSIF u < 2048 THEN Put(s, 192 + u DIV 64); Put(s, 128 + u MOD 64)
          ELSIF (u >= 0D800H) & (u < 0E000H) THEN   (* half of a character beyond 65535: an emoji; left out *)
          ELSE Put(s, 224 + u DIV 4096); Put(s, 128 + u DIV 64 MOD 64); Put(s, 128 + u MOD 64)
          END
        ELSE Put(s, ORD(c))
        END
      ELSE Put(s, ORD(c))
      END;
      INC(jp)
    END;
    INC(jp); s[pk] := 0X
  END Str;

  PROCEDURE Push(VAR key: ARRAY OF CHAR);
  BEGIN IF dep < DM THEN Copy(key, seg[dep]) END; INC(dep)
  END Push;

  PROCEDURE K(i: INTEGER; s: ARRAY OF CHAR): BOOLEAN;   (* is part i of the path s? *)
  BEGIN RETURN (i < dep) & (i < DM) & Same(seg[i], s)
  END K;

  PROCEDURE N(i: INTEGER): INTEGER;   (* part i of the path as a number (the place in an array) *)
    VAR v: INTEGER;
  BEGIN v := -1; IF (i < dep) & (i < DM) THEN v := Num(seg[i]) END
    RETURN v
  END N;

  (* ---------- what each answer says ---------- *)

  PROCEDURE Item(i: INTEGER);   (* a new film number i (up to MI) *)
  BEGIN
    WHILE (ni <= i) & (ni < MI) DO
      iTitle[ni][0] := 0X; iImg[ni][0] := 0X; iLink[ni][0] := 0X; iAddr[ni][0] := 0X; iUuid[ni][0] := 0X; iInfo[ni][0] := 0X;
      iRank[ni] := 0; iDur[ni] := -1; INC(ni)
    END
  END Item;

  PROCEDURE Rank(VAR u: ARRAY OF CHAR): INTEGER;   (* how good a film file of Commons is for a phone *)
    VAR r: INTEGER;
  BEGIN
    r := 0;
    IF Ends(u, ".webm") OR Ends(u, ".mp4") THEN
      r := 1;
      IF Has(u, "480p") THEN r := 6 ELSIF Has(u, "720p") THEN r := 5 ELSIF Has(u, "360p") THEN r := 4
      ELSIF Has(u, "240p") THEN r := 3 ELSIF Has(u, "1080p") THEN r := 2
      END
    END
    RETURN r
  END Rank;

  PROCEDURE Seen;   (* one value (in val) with its path (seg[0 .. dep-1]) *)
    VAR i, r: INTEGER;
  BEGIN
    IF kind = 1 THEN   (* Sepia: data[i].name, uuid, url, thumbnailUrl, duration, account.displayName *)
      IF K(0, "data") & (dep >= 3) THEN
        i := N(1);
        IF (i >= 0) & (i < MI) THEN
          Item(i);
          IF dep = 3 THEN
            IF K(2, "name") THEN Copy(val, iTitle[i]) ELSIF K(2, "uuid") THEN Copy(val, iUuid[i])
            ELSIF K(2, "url") THEN Copy(val, iAddr[i]) ELSIF K(2, "thumbnailUrl") THEN Copy(val, iImg[i])
            ELSIF K(2, "duration") THEN iDur[i] := Num(val)
            END
          ELSIF (dep = 4) & K(2, "account") & K(3, "displayName") THEN Copy(val, iInfo[i])
          END
        END
      END
    ELSIF kind = 2 THEN   (* the Archive: response.docs[i].identifier, title *)
      IF K(0, "response") & K(1, "docs") & (dep >= 4) THEN
        i := N(2);
        IF (i >= 0) & (i < MI) THEN
          Item(i);
          IF K(3, "identifier") THEN Copy(val, iUuid[i]) ELSIF K(3, "title") & (iTitle[i][0] = 0X) THEN Copy(val, iTitle[i])
          ELSIF K(3, "year") THEN Copy(val, iInfo[i])
          END
        END
      END
    ELSIF kind = 3 THEN   (* Commons: query.pages.ID.title, .videoinfo[0].thumburl, .url, .derivatives[k].src *)
      IF K(0, "query") & K(1, "pages") & (dep >= 4) THEN
        IF (dep > 2) & ~Same(seg[2], lastKey) & (cur < MI - 1) THEN INC(cur); Item(cur); Copy(seg[2], lastKey) END;
        i := cur;
        IF (i >= 0) & (i < MI) THEN
          IF (dep = 4) & K(3, "title") THEN
            IF Starts(val, "File:") THEN Copy(val, iTitle[i]); r := 0; WHILE iTitle[i][r + 5] # 0X DO iTitle[i][r] := iTitle[i][r + 5]; INC(r) END; iTitle[i][r] := 0X
            ELSE Copy(val, iTitle[i])
            END;
            r := Len(iTitle[i]); WHILE (r > 0) & (iTitle[i][r - 1] # ".") DO DEC(r) END;
            IF r > 1 THEN iTitle[i][r - 1] := 0X END   (* without .webm, .ogv *)
          ELSIF K(3, "videoinfo") & (dep = 6) & K(5, "thumburl") THEN Copy(val, iImg[i])
          ELSIF K(3, "videoinfo") & (dep = 6) & K(5, "duration") THEN iDur[i] := Num(val)
          ELSIF K(3, "videoinfo") & ((dep = 6) & K(5, "url") OR (dep = 8) & K(5, "derivatives") & K(7, "src")) THEN
            r := Rank(val);
            IF r > iRank[i] THEN
              iRank[i] := r;
              IF Starts(val, "//") THEN Copy("https:", iLink[i]); Add(iLink[i], val) ELSE Copy(val, iLink[i]) END
            END
          END
        END
      END
    ELSIF kind = 4 THEN   (* PeerTube, one video: files[i].fileUrl, .resolution.id; streamingPlaylists[i].playlistUrl *)
      IF K(0, "files") & (dep >= 3) THEN
        i := N(1);
        IF (i >= 0) & (i < MF) THEN
          WHILE nf <= i DO fName[nf][0] := 0X; fFmt[nf][0] := 0X; fRes[nf] := 0; INC(nf) END;
          IF (dep = 3) & K(2, "fileUrl") THEN Copy(val, fName[i])
          ELSIF (dep = 4) & K(2, "resolution") & K(3, "id") THEN fRes[i] := Num(val)
          END
        END
      ELSIF K(0, "streamingPlaylists") & (dep = 3) & K(2, "playlistUrl") & (playlist[0] = 0X) THEN Copy(val, playlist)
      ELSIF K(0, "streamingPlaylists") & K(2, "files") & (dep >= 5) & (N(1) = 0) THEN   (* the files of the HLS list *)
        i := N(3) + MF DIV 2;
        IF (N(3) >= 0) & (i < MF) THEN
          WHILE nf <= i DO fName[nf][0] := 0X; fFmt[nf][0] := 0X; fRes[nf] := 0; INC(nf) END;
          IF (dep = 5) & K(4, "fileUrl") THEN Copy(val, fName[i])
          ELSIF (dep = 6) & K(4, "resolution") & K(5, "id") THEN fRes[i] := Num(val)
          END
        END
      END
    ELSIF kind = 5 THEN   (* the Archive, one item: files[i].name, .format *)
      IF K(0, "files") & (dep = 3) THEN
        i := N(1);
        IF (i >= 0) & (i < MF) THEN
          WHILE nf <= i DO fName[nf][0] := 0X; fFmt[nf][0] := 0X; fRes[nf] := 0; INC(nf) END;
          IF K(2, "name") THEN Copy(val, fName[i]) ELSIF K(2, "format") THEN Copy(val, fFmt[i]) END
        END
      END
    END
  END Seen;

  PROCEDURE Value;
    VAR key: ARRAY 48 OF CHAR; i, k: INTEGER; more: BOOLEAN;
  BEGIN
    Ws;
    IF ~ok OR (jp >= jn) THEN ok := FALSE
    ELSIF jb[jp] = "{" THEN
      INC(jp); Ws;
      IF jb[jp] = "}" THEN INC(jp)
      ELSE
        more := TRUE;
        WHILE more & ok DO
          Ws;
          IF jb[jp] # 22X THEN ok := FALSE
          ELSE
            Str(key); Ws; IF jb[jp] = ":" THEN INC(jp) ELSE ok := FALSE END;
            Push(key); Value; DEC(dep); Ws;
            IF jb[jp] = "," THEN INC(jp) ELSIF jb[jp] = "}" THEN INC(jp); more := FALSE ELSE ok := FALSE END
          END
        END
      END
    ELSIF jb[jp] = "[" THEN
      INC(jp); Ws;
      IF jb[jp] = "]" THEN INC(jp)
      ELSE
        more := TRUE; i := 0;
        WHILE more & ok DO
          key[0] := 0X; AddNum(key, i);
          Push(key); Value; DEC(dep); Ws; INC(i);
          IF jb[jp] = "," THEN INC(jp) ELSIF jb[jp] = "]" THEN INC(jp); more := FALSE ELSE ok := FALSE END
        END
      END
    ELSIF jb[jp] = 22X THEN Str(val); Seen
    ELSE   (* a number, true, false, null *)
      k := 0;
      WHILE (jp < jn) & (jb[jp] # ",") & (jb[jp] # "}") & (jb[jp] # "]") & (jb[jp] # " ") & (jb[jp] # 0AX) & (jb[jp] # 0DX) DO
        IF k < LEN(val) - 1 THEN val[k] := jb[jp]; INC(k) END; INC(jp)
      END;
      val[k] := 0X; Seen
    END
  END Value;

  PROCEDURE Read(src: ARRAY OF CHAR; k: INTEGER): BOOLEAN;
  BEGIN
    kind := k; ni := 0; cur := -1; lastKey[0] := 0X; nf := 0; playlist[0] := 0X;
    IF Load(src) THEN Value END
    RETURN (ni + nf > 0) OR (playlist[0] # 0X)
  END Read;

  (* ---------- for Nora ---------- *)

  PROCEDURE Kind*(VAR u: ARRAY OF CHAR): INTEGER;   (* which answer an address gives; 0: not one of these *)
    VAR k: INTEGER;
  BEGIN
    IF Starts(u, "https://sepiasearch.org/api/v1/search/videos") THEN k := 1
    ELSIF Starts(u, "https://archive.org/advancedsearch.php") THEN k := 2
    ELSIF Starts(u, "https://commons.wikimedia.org/w/api.php") THEN k := 3
    ELSIF Has(u, "/api/v1/videos/") THEN k := 4
    ELSIF Starts(u, "https://archive.org/metadata/") THEN k := 5
    ELSE k := 0
    END
    RETURN k
  END Kind;

  PROCEDURE Search*(k: INTEGER; term: ARRAY OF CHAR; VAR u: ARRAY OF CHAR);   (* the address that finds term in place k *)
  BEGIN
    IF k = 1 THEN Copy("https://sepiasearch.org/api/v1/search/videos?count=20&nsfw=false&search=", u); Enc(term, u)
    ELSIF k = 2 THEN
      Copy("https://archive.org/advancedsearch.php?q=", u); Enc(term, u);
      Add(u, "+AND+mediatype%3Amovies&fl%5B%5D=identifier&fl%5B%5D=title&fl%5B%5D=year&sort%5B%5D=downloads+desc&rows=20&output=json")
    ELSE
      Copy("https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=20&gsrsearch=", u);
      Enc(term, u); Add(u, "+filetype%3Avideo&prop=videoinfo&viprop=url%7Cderivatives&viurlwidth=320")
    END
  END Search;

  PROCEDURE W(h: INTEGER; s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Fisier.Scrie(h, ORD(s[i]) MOD 256); INC(i) END
  END W;

  PROCEDURE WT(h: INTEGER; VAR s: ARRAY OF CHAR);   (* text, with & < > " written as HTML *)
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) DO
      IF s[i] = "&" THEN W(h, "&amp;") ELSIF s[i] = "<" THEN W(h, "&lt;") ELSIF s[i] = ">" THEN W(h, "&gt;")
      ELSIF s[i] = 22X THEN W(h, "&quot;") ELSE Fisier.Scrie(h, ORD(s[i]) MOD 256)
      END;
      INC(i)
    END
  END WT;

  PROCEDURE ToHtml*(src, to: ARRAY OF CHAR; k: INTEGER): BOOLEAN;   (* the answer of a search -> a page *)
    VAR h, i, n: INTEGER; s, host: ARRAY SL OF CHAR; place: ARRAY 40 OF CHAR;
  BEGIN
    IF Read(src, k) THEN END;
    IF k = 1 THEN place := "PeerTube" ELSIF k = 2 THEN place := "the Internet Archive" ELSE place := "Wikimedia Commons" END;
    h := Fisier.Creeaza(to);
    IF h >= 0 THEN
      W(h, "<html><head><title>Films . "); W(h, place); W(h, "</title></head><body>");
      n := 0;
      FOR i := 0 TO ni - 1 DO
        s[0] := 0X;
        IF k = 1 THEN
          Host(iAddr[i], host);
          IF (host[0] # 0X) & (iUuid[i][0] # 0X) THEN Copy("nora:play?https://", s); Add(s, host); Add(s, "/api/v1/videos/"); Add(s, iUuid[i]) END;
          IF iInfo[i][0] # 0X THEN Add(iInfo[i], " . ") END; Add(iInfo[i], host)
        ELSIF k = 2 THEN
          IF iUuid[i][0] # 0X THEN
            Copy("nora:play?https://archive.org/metadata/", s); Add(s, iUuid[i]);
            Copy("https://archive.org/services/img/", iImg[i]); Add(iImg[i], iUuid[i])
          END
        ELSE Copy(iLink[i], s)
        END;
        IF (s[0] # 0X) & (iTitle[i][0] # 0X) THEN
          INC(n);
          W(h, "<p>");
          IF iImg[i][0] # 0X THEN W(h, "<a href="); Fisier.Scrie(h, 22H); WT(h, s); Fisier.Scrie(h, 22H); W(h, "><img src="); Fisier.Scrie(h, 22H);
            WT(h, iImg[i]); Fisier.Scrie(h, 22H); W(h, " width=320 height=180></a><br>")
          END;
          W(h, "<a href="); Fisier.Scrie(h, 22H); WT(h, s); Fisier.Scrie(h, 22H); W(h, ">"); WT(h, iTitle[i]); W(h, "</a><br>");
          IF iDur[i] >= 0 THEN
            host[0] := 0X; AddNum(host, iDur[i] DIV 60); AddC(host, ":"); IF iDur[i] MOD 60 < 10 THEN AddC(host, "0") END;
            AddNum(host, iDur[i] MOD 60); W(h, host); IF iInfo[i][0] # 0X THEN W(h, " . ") END
          END;
          WT(h, iInfo[i]); W(h, "</p>")
        END
      END;
      IF n = 0 THEN W(h, "<p>Nothing found on "); W(h, place); W(h, ".</p>") END;
      W(h, "<p><a href=") ; Fisier.Scrie(h, 22H); W(h, "nora:films"); Fisier.Scrie(h, 22H); W(h, ">Films that are given freely</a></p>");
      W(h, "</body></html>"); Fisier.Gata(h)
    END
    RETURN h >= 0
  END ToHtml;

  PROCEDURE Pick*(src: ARRAY OF CHAR; VAR req, out: ARRAY OF CHAR): BOOLEAN;   (* the answer about one film -> its file *)
    VAR k, i, best, sc, bs, r: INTEGER; id: ARRAY 200 OF CHAR;
  BEGIN
    out[0] := 0X; k := Kind(req);
    IF ((k = 4) OR (k = 5)) & Read(src, k) THEN
      best := -1; bs := 0;
      IF k = 4 THEN   (* the file closest to 720 lines, not above; else the HLS list *)
        FOR i := 0 TO nf - 1 DO
          IF fName[i][0] # 0X THEN
            r := fRes[i]; IF r = 0 THEN sc := 1 ELSIF r <= 720 THEN sc := 10 + r ELSE sc := 5 END;
            IF sc > bs THEN bs := sc; best := i END
          END
        END;
        IF best >= 0 THEN Copy(fName[best], out) ELSIF playlist[0] # 0X THEN Copy(playlist, out) END
      ELSE   (* the Archive: an MP4 made for the web *)
        FOR i := 0 TO nf - 1 DO
          IF Ends(fName[i], ".mp4") OR Ends(fName[i], ".MP4") THEN
            IF Same(fFmt[i], "h.264") THEN sc := 6 ELSIF Same(fFmt[i], "h.264 IA") THEN sc := 5
            ELSIF Same(fFmt[i], "512Kb MPEG4") THEN sc := 4 ELSIF Same(fFmt[i], "MPEG4") THEN sc := 3 ELSE sc := 2
            END;
            IF sc > bs THEN bs := sc; best := i END
          END
        END;
        IF best >= 0 THEN
          i := 0; WHILE (i < LEN(req) - 29) & (req[i + 29] # 0X) & (req[i + 29] # "/") & (req[i + 29] # "?") & (i < LEN(id) - 1) DO id[i] := req[i + 29]; INC(i) END;
          id[i] := 0X;   (* "https://archive.org/metadata/" is 29 letters *)
          Copy("https://archive.org/download/", out); Add(out, id); AddC(out, "/"); Enc2(fName[best], out, TRUE)
        END
      END
    END
    RETURN out[0] # 0X
  END Pick;

BEGIN
  jn := 0; jp := 0; dep := 0; ok := FALSE; kind := 0; ni := 0; nf := 0; cur := -1; playlist[0] := 0X
END Filme1.
