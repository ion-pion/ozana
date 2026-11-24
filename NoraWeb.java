package ro.jahbalon.eulaoberon;

import android.app.Activity;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

/* NoraWeb (window 46, Pixipogo 46 / Ozana 2): a window into the whole web, for the sites that are only JavaScript.
   Pion: "a browser without YouTube and TikTok is worth nothing today". Nora (Oberon) reads the pages herself; for
   YouTube, TikTok and the like she opens this box over her page, and the phone's own web engine runs the site and its
   own player (as the site gives it). Driven by files, like the film player:
     webv.txt + webv-go:  "show X Y W H FW URL" (the box in the frame's pixels; FW the width of the frame), "place X Y W H FW",
                          "back", "reload", "hide", and (window 47) "app PACKAGE URL": the address given to an app of the phone
                          (NewPipe: org.schabi.newpipe; "-": whichever app the phone chooses), and (window 48) "get NAME URL":
                          a file of any size to Download, by the phone's downloader (the files of the box go there too);
                          (window 49) "share TEXT" (the phone's Share), "desk 1|0" (the box as a computer or as a phone)
     webv-st.txt:         "SHOWN PROGRESS CANBACK" then the address, then the title
   The phone's BACK key goes back in the box (then closes it) while the box is shown. Pion & Claude, 24.11.2026 */
public final class NoraWeb implements Runnable {
    static NoraWeb eu;
    final Activity a;
    final File dir;
    FrameLayout box;
    WebView wv;
    View full;
    WebChromeClient.CustomViewCallback fullCb;
    FrameLayout.LayoutParams lp;
    volatile boolean shown, canBack;
    volatile int prog;
    volatile String curUrl = "", title = "";
    String last = "";

    NoraWeb(Activity a) {
        this.a = a;
        this.dir = a.getFilesDir();
    }

    public static void porneste(Activity a) {
        try {
            eu = new NoraWeb(a);
            Thread t = new Thread(eu, "nora-web");
            t.setDaemon(true);
            t.start();
        } catch (Throwable t) { }
    }

    /* the BACK key of the phone, while the box is shown: back in the box, or close it */
    public static boolean inapoi() {
        NoraWeb n = eu;
        if (n == null || !n.shown) return false;
        try {
            if (n.full != null) { n.fara(); return true; }
            if (n.wv != null && n.wv.canGoBack()) { n.wv.goBack(); return true; }
            n.ascunde();
        } catch (Throwable t) { }
        return true;
    }

    static String citeste(File f) throws Exception {
        FileInputStream in = new FileInputStream(f);
        try {
            byte[] b = new byte[(int) Math.min(f.length(), 65536)];
            int n = 0;
            while (n < b.length) { int r = in.read(b, n, b.length - n); if (r < 0) break; n += r; }
            return new String(b, 0, n, "UTF-8");
        } finally { in.close(); }
    }

    public void run() {
        File go = new File(dir, "webv-go"), cmd = new File(dir, "webv.txt");
        int k = 0;
        while (!a.isFinishing()) {
            try { Thread.sleep(50); } catch (InterruptedException e) { return; }
            try {
                if (go.exists()) {
                    final String c = citeste(cmd).trim();
                    go.delete();
                    a.runOnUiThread(new Runnable() { public void run() { try { fa(c); } catch (Throwable t) { } } });
                }
                if (++k % 5 == 0) {
                    stare();
                    if (shown) a.runOnUiThread(new Runnable() { public void run() { try { lipeste(); } catch (Throwable t) { } } });
                }
            } catch (Throwable t) { }
        }
    }

    void stare() throws Exception {
        String s = (shown ? "1" : "0") + " " + prog + " " + (canBack ? "1" : "0") + "\n" + curUrl + "\n" + title + "\n";
        if (s.equals(last)) return;
        last = s;
        FileOutputStream o = new FileOutputStream(new File(dir, "webv-st.txt"));
        try { o.write(s.getBytes("UTF-8")); } finally { o.close(); }
    }

    /* setContentView (2D <-> graphics card) takes the box off the screen: put it back */
    void lipeste() {
        if (box != null && box.getParent() == null && lp != null) a.addContentView(box, lp);
        if (full != null && full.getParent() == null) a.addContentView(full, new FrameLayout.LayoutParams(-1, -1));
    }

    void loc(String[] p, int i) {
        int x = Integer.parseInt(p[i]), y = Integer.parseInt(p[i + 1]), w = Integer.parseInt(p[i + 2]);
        int h = Integer.parseInt(p[i + 3]), fw = Integer.parseInt(p[i + 4]);
        int sw = a.getWindow().getDecorView().getWidth();
        if (sw <= 0 || fw <= 0) { sw = 1; fw = 1; }
        FrameLayout.LayoutParams l = new FrameLayout.LayoutParams(w * sw / fw, h * sw / fw);
        l.leftMargin = x * sw / fw;
        l.topMargin = y * sw / fw;
        lp = l;
        if (box != null) box.setLayoutParams(l);
    }

    static volatile boolean desk;   /* the box asks for the sites as a computer would */
    static final String DESK_UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36";

    void fa(String c) {
        if (c.startsWith("share ")) {   /* "share TEXT": to another app (WhatsApp, mail ...), as the phone offers */
            android.content.Intent i = new android.content.Intent("android.intent.action.SEND");
            i.setType("text/plain");
            i.putExtra("android.intent.extra.TEXT", c.substring(6));
            a.startActivity(android.content.Intent.createChooser(i, "Share"));
            return;
        }
        String[] p = c.split(" ", 7);
        String k = p[0];
        if (k.equals("show") && p.length >= 7) {
            ascunde();
            facut();
            loc(p, 1);
            lipeste();
            box.setVisibility(0);
            shown = true; prog = 0; canBack = false; curUrl = p[6]; title = "";
            wv.loadUrl(p[6]);
        } else if (k.equals("place") && p.length >= 6) {
            loc(p, 1);
        } else if (k.equals("back")) {
            if (wv != null && wv.canGoBack()) wv.goBack();
        } else if (k.equals("reload")) {
            if (wv != null) wv.reload();
        } else if (k.equals("hide")) {
            ascunde();
        } else if (k.equals("desk") && p.length >= 2) {   /* "desk 1": as a computer; "desk 0": as a phone */
            desk = p[1].equals("1");
            if (wv != null) { try { wv.getSettings().setUserAgentString(desk ? DESK_UA : null); wv.reload(); } catch (Throwable t) { } }
        } else if (k.equals("get") && p.length >= 3) {   /* "get NAME URL": a file of any size, by the phone's downloader */
            iaFisier(p[2], p[1], null, null);
        } else if (k.equals("app") && p.length >= 3) {   /* "app PACKAGE URL": the address to an app of the phone (- = any) */
            try {
                android.content.Intent i = new android.content.Intent("android.intent.action.VIEW", android.net.Uri.parse(p[2]));
                if (!p[1].equals("-")) i.setPackage(p[1]);
                a.startActivity(i);
            } catch (Throwable t) {
                android.widget.Toast.makeText(a, p[1].equals("org.schabi.newpipe")
                    ? "NewPipe is not on this phone (it comes from F-Droid or newpipe.net)" : "No app of the phone opens this", 1).show();
            }
        }
    }

    /* a file to the Download folder of the phone, with the phone's own downloader (its notification shows how far it is) */
    void iaFisier(String url, String name, String ua, String mime) {
        try {
            android.app.DownloadManager.Request r = new android.app.DownloadManager.Request(android.net.Uri.parse(url));
            if (ua != null) r.addRequestHeader("User-Agent", ua);
            try {
                String c = android.webkit.CookieManager.getInstance().getCookie(url);
                if (c != null) r.addRequestHeader("Cookie", c);
            } catch (Throwable t) { }
            if (mime != null) r.setMimeType(mime);
            r.setTitle(name);
            r.setNotificationVisibility(1);   /* VISIBILITY_VISIBLE_NOTIFY_COMPLETED */
            r.setDestinationInExternalPublicDir("Download", name);
            ((android.app.DownloadManager) a.getSystemService("download")).enqueue(r);
            android.widget.Toast.makeText(a, "Downloading " + name + " to Download", 0).show();
        } catch (Throwable t) {
            android.widget.Toast.makeText(a, "The phone would not download it: " + t.getMessage(), 1).show();
        }
    }

    void facut() {
        box = new FrameLayout(a);
        box.setBackgroundColor(0xFF000000);
        wv = new WebView(a);
        WebSettings s = wv.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setLoadWithOverviewMode(true);
        s.setUseWideViewPort(true);
        try { s.setMediaPlaybackRequiresUserGesture(false); } catch (Throwable t) { }
        if (desk) s.setUserAgentString(DESK_UA);
        wv.setWebViewClient(new WebViewClient() {
            public boolean shouldOverrideUrlLoading(WebView v, String u) {
                return !(u.startsWith("http://") || u.startsWith("https://"));   /* intent:, market: ...: stay here */
            }
            public void onPageFinished(WebView v, String u) { curUrl = u; canBack = v.canGoBack(); String t = v.getTitle(); if (t != null) title = t; }
            public void doUpdateVisitedHistory(WebView v, String u, boolean r) { curUrl = u; canBack = v.canGoBack(); }
        });
        wv.setWebChromeClient(new WebChromeClient() {
            public void onProgressChanged(WebView v, int q) { prog = q; canBack = v.canGoBack(); }
            public void onReceivedTitle(WebView v, String t) { if (t != null) title = t; }
            public void onShowCustomView(View v, WebChromeClient.CustomViewCallback cb) {   /* a film over the whole screen */
                fara();
                full = v; fullCb = cb;
                a.addContentView(v, new FrameLayout.LayoutParams(-1, -1));
            }
            public void onHideCustomView() { fara(); }
        });
        wv.setDownloadListener(new android.webkit.DownloadListener() {   /* a file asked for in the box */
            public void onDownloadStart(String url, String ua, String cd, String mime, long len) {
                String n = android.webkit.URLUtil.guessFileName(url, cd, mime);
                iaFisier(url, n == null ? "file" : n, ua, mime);
            }
        });
        box.addView(wv, new FrameLayout.LayoutParams(-1, -1));
    }

    void fara() {   /* out of the whole screen */
        View f = full;
        WebChromeClient.CustomViewCallback cb = fullCb;
        full = null; fullCb = null;
        if (f != null && f.getParent() != null) ((ViewGroup) f.getParent()).removeView(f);
        if (cb != null) try { cb.onCustomViewHidden(); } catch (Throwable t) { }
    }

    void ascunde() {
        fara();
        if (wv != null) {
            try { wv.stopLoading(); wv.loadUrl("about:blank"); } catch (Throwable t) { }
            if (box != null) box.removeView(wv);
            try { wv.destroy(); } catch (Throwable t) { }
            wv = null;
        }
        if (box != null && box.getParent() != null) ((ViewGroup) box.getParent()).removeView(box);
        box = null;
        shown = false; prog = 0; canBack = false;
    }
}
