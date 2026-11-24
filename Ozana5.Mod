MODULE Ozana5;  (* OZANA 5 (24 Nov 2026): the free films play (a picture of one plays it; when her player cannot, the
     film's own page opens in the window into the whole web), SHARE, private tabs, saved pages, the sites as on a computer.
     Nora 18, window ecran-cubn49.dex. A separate app.
     Build:
       OLL2.Apk Motor2.Mod OllGL4.Mod OllGL7.Mod OllGL6t.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Gazda4.Mod Desk6.Mod Pic6.Mod Filme1.Mod Nora18.Mod Ozana5.Mod "Ozana 5"
   OZANA 4 (24 Nov 2026): tabs, a menu for a link held (NEW TAB, COPY), and downloads of any size by the
     phone's downloader. Nora 17, window ecran-cubn48.dex. A separate app.
     Build:
       OLL2.Apk Motor2.Mod OllGL4.Mod OllGL7.Mod OllGL6t.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Gazda4.Mod Desk6.Mod Pic6.Mod Filme1.Mod Nora18.Mod Ozana4.Mod "Ozana 4"
   OZANA 3 (24 Nov 2026): NewPipe for YouTube, and the films given freely (PeerTube, the Internet Archive,
     Commons) read in Oberon by Filme1 and played in her own player. Nora 16, window ecran-cubn47.dex. A separate app.
     Build:
       OLL2.Apk Motor2.Mod OllGL4.Mod OllGL7.Mod OllGL6t.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Gazda4.Mod Desk6.Mod Pic6.Mod Filme1.Mod Nora18.Mod Ozana3.Mod "Ozana 3"
   OZANA 2 (24 Nov 2026): YouTube and TikTok. Pion: "a browser without YouTube and TikTok is worth nothing
     today". Nora 15 opens them in the window into the whole web (the window ecran-cubn46.dex). A separate app, so
     Ozana 1 stays as it is on the phone.
     Build:
       OLL2.Apk Motor2.Mod OllGL4.Mod OllGL7.Mod OllGL6t.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Gazda4.Mod Desk6.Mod Pic6.Mod Nora18.Mod Ozana2.Mod "Ozana 2"
   OZANA 1 (24 Nov 2026): the browser as an app of her own. Pion: "make a separate browser app named
     Ozana (that is, she stays a fairy)". She is Nora 14 living alone: her own name, her own icon on the phone, her own
     marks and history (in her own folder), the whole screen for her. The pages, the forms, find, downloads, the
     pictures on the graphics card (sharp and smooth: OllGL7 and Pic6) and the films and sounds (the player of the
     window) are all Nora's.
     Build (the window ecran-cubn44.dex in $EULA_UNELTE, as for Pixipogo 44):
       OLL2.Apk Motor2.Mod OllGL4.Mod OllGL7.Mod OllGL6t.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Gazda4.Mod Desk6.Mod Pic6.Mod Nora18.Mod Ozana.Mod "Ozana"
   Pion & Claude, 24.11.2026 *)

  IMPORT Motor2, Gazda4, Desk6, Nora18;

  VAR W, H, lCore, r: INTEGER; started: BOOLEAN;

  PROCEDURE Core(ev, val: INTEGER);
  BEGIN
    IF ev = Motor2.Scena THEN
      IF ~started THEN
        started := TRUE; W := Motor2.Latime(); H := Motor2.Inaltime();
        Desk6.Start(W, H);
        Nora18.SetName("Ozana"); Nora18.Alone; Nora18.Start(W, H); Nora18.Enter
      END
    ELSIF (ev = Motor2.Tick) & started THEN
      Gazda4.Poll;
      r := Nora18.Frame(Motor2.Jos(), Motor2.X(), Motor2.Y());
      Motor2.Arat
    END
  END Core;

BEGIN
  W := 1; H := 1; r := 0; started := FALSE;
  lCore := Motor2.Litera("CORE", Core, {Motor2.Tick, Motor2.Scena});
  Motor2.Ruleaza
END Ozana5.
