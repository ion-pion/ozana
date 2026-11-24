MODULE OllGL6;  (* GL 6t (24 nov 2026, Pixipogo 44): OllGL6 made of OllGL7. Desk6, Shell, Nora and the others still call
     OllGL6, and now they all draw into the one frame of OllGL7, so Nora can put pictures (textures) among them.
     Every procedure here only calls the one of OllGL7 with the same name. Pion & Claude, 24.11.2026 *)

  IMPORT OllGL7;

  PROCEDURE RGB*(r, g, b: INTEGER): INTEGER;
  BEGIN RETURN OllGL7.RGB(r, g, b)
  END RGB;

  PROCEDURE Incepe*(culoareFond: INTEGER);
  BEGIN OllGL7.Incepe(culoareFond)
  END Incepe;

  PROCEDURE Rezerva*(randuri: INTEGER);
  BEGIN OllGL7.Rezerva(randuri)
  END Rezerva;

  PROCEDURE Camera*(x, y, z, x1, y1, z1, unghi: REAL);
  BEGIN OllGL7.Camera(x, y, z, x1, y1, z1, unghi)
  END Camera;

  PROCEDURE Ceata*(de, pana: REAL);
  BEGIN OllGL7.Ceata(de, pana)
  END Ceata;

  PROCEDURE Lumina*(f: REAL);
  BEGIN OllGL7.Lumina(f)
  END Lumina;

  PROCEDURE LuminaPunct*(x, y, z, raza, putere: REAL; c: INTEGER);
  BEGIN OllGL7.LuminaPunct(x, y, z, raza, putere, c)
  END LuminaPunct;

  PROCEDURE Triunghi*(x0, y0, z0, x1, y1, z1, x2, y2, z2: REAL; c: INTEGER);
  BEGIN OllGL7.Triunghi(x0, y0, z0, x1, y1, z1, x2, y2, z2, c)
  END Triunghi;

  PROCEDURE Patrat*(x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3: REAL; c: INTEGER);
  BEGIN OllGL7.Patrat(x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3, c)
  END Patrat;

  PROCEDURE Cub*(x, y, z, lat: REAL; c: INTEGER);
  BEGIN OllGL7.Cub(x, y, z, lat, c)
  END Cub;

  PROCEDURE Disc*(x, y, z, r: REAL; n, c: INTEGER);
  BEGIN OllGL7.Disc(x, y, z, r, n, c)
  END Disc;

  PROCEDURE Triunghi2D*(x0, y0, x1, y1, x2, y2, c: INTEGER);
  BEGIN OllGL7.Triunghi2D(x0, y0, x1, y1, x2, y2, c)
  END Triunghi2D;

  PROCEDURE Dreptunghi2D*(x, y, lat, inalt, c: INTEGER);
  BEGIN OllGL7.Dreptunghi2D(x, y, lat, inalt, c)
  END Dreptunghi2D;

  PROCEDURE Cerc2D*(x, y, r, c: INTEGER);
  BEGIN OllGL7.Cerc2D(x, y, r, c)
  END Cerc2D;

  PROCEDURE Inel2D*(x, y, r, gros, c: INTEGER);
  BEGIN OllGL7.Inel2D(x, y, r, gros, c)
  END Inel2D;

  PROCEDURE Linie2D*(x0, y0, x1, y1, gros, c: INTEGER);
  BEGIN OllGL7.Linie2D(x0, y0, x1, y1, gros, c)
  END Linie2D;

  PROCEDURE Litera2D*(x, y: INTEGER; ch: CHAR; m, c: INTEGER);
  BEGIN OllGL7.Litera2D(x, y, ch, m, c)
  END Litera2D;

  PROCEDURE Text2D*(x, y: INTEGER; s: ARRAY OF CHAR; m, c: INTEGER);
  BEGIN OllGL7.Text2D(x, y, s, m, c)
  END Text2D;

  PROCEDURE Numar2D*(x, y, n, m, c: INTEGER);
  BEGIN OllGL7.Numar2D(x, y, n, m, c)
  END Numar2D;

  PROCEDURE Rotund2D*(x, y, lat, inalt, r, c: INTEGER);
  BEGIN OllGL7.Rotund2D(x, y, lat, inalt, r, c)
  END Rotund2D;

  PROCEDURE Liber2D*(): INTEGER;
  BEGIN RETURN OllGL7.Liber2D()
  END Liber2D;

  PROCEDURE Arata*;
  BEGIN OllGL7.Arata
  END Arata;

END OllGL6.
