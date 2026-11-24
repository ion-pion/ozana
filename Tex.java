package ro.jahbalon.eulaoberon;

import android.content.Context;
import android.opengl.GLES20;
import android.opengl.Matrix;
import java.io.File;
import java.io.FileInputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/* Tex (window 44, Pixipogo 44): pictures on the graphics card. Pion: "to the video card" and "they will want
   fast games on mediocre hardware, so we will give them".
   OllGL7 writes a frame of version 4: after the 3D and 2D triangles come the pictures (12 numbers each) and the
   table of the textures (one generation number for each slot). The pixels of slot k are in the file
   gl-tex-k.raw of the app's folder ("GLT1", width, height, generation, flags; then RGBA, premultiplied), written
   by Oberon; the window loads it into the card when the generation in the frame changes.
   A picture: at (how many 2D triangles came before it: it is drawn between them), slot, x, y, w, h (1/16 pixel),
   sx, sy, sw, sh (the part of the texture, in its pixels; sw <= 0: all of it), tint (RGB with alpha), angle
   (thousandths of a degree, about its centre). Frames of version 3 (OllGL4..6) are drawn as before.
   Pion & Claude, 24.11.2026 */
final class Tex {
    static final int Q = 12, NT = 64, TEX1 = 0x54455831;   /* "TEX1" in input 26: this window draws textures */
    static int[] q = new int[0];       /* the pictures of the last frame, published under e.lacat */
    static int nq;
    static final int[] gen = new int[NT];
    static int ngen;
    static int[] tq = new int[0];
    static final int[] tg = new int[NT];

    private Tex() { }

    /* instead of EcranNativ.citeste3d: the same, plus the pictures, all published at once */
    static void citeste3d(EcranNativ e) {
        IntBuffer ib = e.ib;
        int cap = e.fw * e.fh;
        int[] a = e.antet;
        ib.position(0);
        ib.get(a, 0, 64);
        e.pune(26, TEX1);
        int n3 = Math.max(0, a[2]), n2 = Math.max(0, a[3]);
        if (n3 * 10 + 64 > cap) n3 = (cap - 64) / 10;
        if (n3 * 10 + 64 + n2 * 7 > cap) n2 = (cap - 64 - n3 * 10) / 7;
        int n4 = 0, nt = 0;
        if (a[1] >= 4) { n4 = Math.max(0, a[22]); nt = Math.min(NT, Math.max(0, a[23])); }
        int b = 64 + n3 * 10 + n2 * 7;
        if (b + n4 * Q + nt > cap) { n4 = 0; nt = 0; }
        int n = n3 * 10 + n2 * 7;
        if (e.brut == null || e.brut.length < n) e.brut = new int[n / 4 + n + 64];
        ib.position(64);
        ib.get(e.brut, 0, n);
        if (tq.length < n4 * Q) tq = new int[n4 * Q + 1200];
        if (n4 > 0) ib.get(tq, 0, n4 * Q);
        if (nt > 0) ib.get(tg, 0, nt);
        if (e.v3 == null || e.v3.length < n3 * 27) e.v3 = new float[n3 * 27 + 270];
        if (e.v2 == null || e.v2.length < n2 * 27) e.v2 = new float[n2 * 27 + 270];
        int[] r = e.brut;
        float[] f = e.v3;
        for (int i = 0; i < n3; i++) {
            int s = i * 10;
            float x0 = r[s] / 1000f, y0 = r[s + 1] / 1000f, z0 = r[s + 2] / 1000f;
            float x1 = r[s + 3] / 1000f, y1 = r[s + 4] / 1000f, z1 = r[s + 5] / 1000f;
            float x2 = r[s + 6] / 1000f, y2 = r[s + 7] / 1000f, z2 = r[s + 8] / 1000f;
            int c = r[s + 9];
            float ax = x1 - x0, ay = y1 - y0, az = z1 - z0, bx = x2 - x0, by = y2 - y0, bz = z2 - z0;
            float nx = ay * bz - az * by, ny = az * bx - bz * ax, nz = ax * by - ay * bx;
            float l = (float) Math.sqrt(nx * nx + ny * ny + nz * nz);
            if (l > 0f) { nx /= l; ny /= l; nz /= l; }
            float cr = EcranNativ.cul(c, 0), cg = EcranNativ.cul(c, 1), cb = EcranNativ.cul(c, 2);
            int d = i * 27;
            f[d] = x0; f[d + 1] = y0; f[d + 2] = z0;
            f[d + 9] = x1; f[d + 10] = y1; f[d + 11] = z1;
            f[d + 18] = x2; f[d + 19] = y2; f[d + 20] = z2;
            for (int k = 0; k < 3; k++) {
                int v = d + k * 9;
                f[v + 3] = nx; f[v + 4] = ny; f[v + 5] = nz;
                f[v + 6] = cr; f[v + 7] = cg; f[v + 8] = cb;
            }
        }
        float[] g = e.v2;
        for (int i = 0; i < n2; i++) {
            int s = n3 * 10 + i * 7;
            int c = r[s + 6];
            float cr = EcranNativ.cul(c, 0), cg = EcranNativ.cul(c, 1), cb = EcranNativ.cul(c, 2);
            int d = i * 27;
            for (int k = 0; k < 3; k++) {
                int v = d + k * 9;
                g[v] = r[s + k * 2]; g[v + 1] = r[s + k * 2 + 1]; g[v + 2] = 0f;
                g[v + 3] = 0f; g[v + 4] = 0f; g[v + 5] = 1f;
                g[v + 6] = cr; g[v + 7] = cg; g[v + 8] = cb;
            }
        }
        synchronized (e.lacat) {
            if (e.s3 == null || e.s3.length < n3 * 27) e.s3 = new float[e.v3.length];
            if (e.s2 == null || e.s2.length < n2 * 27) e.s2 = new float[e.v2.length];
            System.arraycopy(e.v3, 0, e.s3, 0, n3 * 27);
            System.arraycopy(e.v2, 0, e.s2, 0, n2 * 27);
            System.arraycopy(a, 0, e.santet, 0, 64);
            e.sn3 = n3; e.sn2 = n2;
            if (q.length < n4 * Q) q = new int[tq.length];
            System.arraycopy(tq, 0, q, 0, n4 * Q);
            nq = n4;
            if (nt > 0) { System.arraycopy(tg, 0, gen, 0, nt); ngen = nt; }   /* a frame with no table keeps the last one */
            e.nou = true;
        }
    }
}

/* the graphics card of the window, with textures */
class Plasa2 extends EcranNativ.Plasa {
    final EcranNativ e;
    FloatBuffer f3, f2, fq;
    int m3, m2, mq;
    int[] lq = new int[0];
    final int[] lgen = new int[Tex.NT];
    int nlg;
    final int[] tid = new int[Tex.NT], tw = new int[Tex.NT], th = new int[Tex.NT], loaded = new int[Tex.NT];
    int tprog, taP, taT, taK, tuM, tuS, maxTex = 2048;
    ByteBuffer pix;
    final float[] orto = new float[16];
    final float[] vv48 = new float[48], qx = new float[4], qy = new float[4], qdx = new float[4], qdy = new float[4], qu = new float[4], qv = new float[4];
    static final int[] ord = { 0, 1, 2, 0, 2, 3 };

    Plasa2(EcranNativ e, Context c) {
        e.super(c);
        this.e = e;
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig cfg) {
        super.onSurfaceCreated(gl, cfg);
        tprog = GLES20.glCreateProgram();
        GLES20.glAttachShader(tprog, umbra(35633,
            "uniform mat4 uM; attribute vec2 aP; attribute vec2 aT; attribute vec4 aK;\n"
            + "varying vec2 vT; varying vec4 vK;\n"
            + "void main() { gl_Position = uM * vec4(aP, 0.0, 1.0); vT = aT; vK = aK; }\n"));
        GLES20.glAttachShader(tprog, umbra(35632,
            "precision mediump float; uniform sampler2D uS; varying vec2 vT; varying vec4 vK;\n"
            + "void main() { gl_FragColor = texture2D(uS, vT) * vK; }\n"));
        GLES20.glLinkProgram(tprog);
        taP = GLES20.glGetAttribLocation(tprog, "aP");
        taT = GLES20.glGetAttribLocation(tprog, "aT");
        taK = GLES20.glGetAttribLocation(tprog, "aK");
        tuM = GLES20.glGetUniformLocation(tprog, "uM");
        tuS = GLES20.glGetUniformLocation(tprog, "uS");
        int[] mx = new int[1];
        GLES20.glGetIntegerv(3379, mx, 0);   /* GL_MAX_TEXTURE_SIZE */
        if (mx[0] >= 64) maxTex = mx[0];
        for (int k = 0; k < Tex.NT; k++) { tid[k] = 0; loaded[k] = 0; }   /* a new context has none of them */
    }

    static FloatBuffer loc(FloatBuffer b, int n) {
        if (b == null || b.capacity() < n)
            return ByteBuffer.allocateDirect(Math.max(n, 1024) * 5 / 4 * 4).order(ByteOrder.nativeOrder()).asFloatBuffer();
        return b;
    }

    static int le(byte[] h, int o) {
        return (h[o] & 255) | (h[o + 1] & 255) << 8 | (h[o + 2] & 255) << 16 | (h[o + 3] & 255) << 24;
    }

    /* slot k from gl-tex-k.raw, if the file is of generation g */
    void incarca(int k, int g) {
        File fl = new File(e.getFilesDir(), "gl-tex-" + k + ".raw");
        FileInputStream in = null;
        try {
            in = new FileInputStream(fl);
            byte[] h = new byte[20];
            int got = 0;
            while (got < 20) { int r = in.read(h, got, 20 - got); if (r < 0) return; got += r; }
            if (le(h, 0) != 0x31544C47 || le(h, 12) != g) return;   /* "GLT1"; another generation: later */
            int w = le(h, 4), hh = le(h, 8), fl8 = le(h, 16);
            if (w < 1 || hh < 1 || w > maxTex || hh > maxTex) { loaded[k] = g; return; }
            int n = w * hh * 4;
            if (pix == null || pix.capacity() < n) pix = ByteBuffer.allocateDirect(n).order(ByteOrder.nativeOrder());
            pix.clear();
            pix.limit(n);
            java.nio.channels.FileChannel ch = in.getChannel();
            while (pix.hasRemaining()) { if (ch.read(pix) < 0) return; }
            pix.position(0);
            if (tid[k] == 0) { int[] t = new int[1]; GLES20.glGenTextures(1, t, 0); tid[k] = t[0]; }
            GLES20.glBindTexture(3553, tid[k]);
            int filt = (fl8 & 1) != 0 ? 9728 : 9729;   /* NEAREST for pixel art, else LINEAR */
            GLES20.glTexParameteri(3553, 10241, filt);
            GLES20.glTexParameteri(3553, 10240, filt);
            GLES20.glTexParameteri(3553, 10242, 33071);   /* CLAMP_TO_EDGE */
            GLES20.glTexParameteri(3553, 10243, 33071);
            GLES20.glPixelStorei(3317, 1);
            GLES20.glTexImage2D(3553, 0, 6408, w, hh, 0, 6408, 5121, pix);
            tw[k] = w; th[k] = hh; loaded[k] = g;
        } catch (Throwable t) {
            /* not there yet: try again with a later frame */
        } finally {
            if (in != null) try { in.close(); } catch (Throwable t) { }
        }
    }

    void texturi() {
        for (int k = 0; k < nlg; k++) {
            int g = lgen[k];
            if (g == loaded[k]) continue;
            if (g == 0) {
                if (tid[k] != 0) { int[] t = { tid[k] }; GLES20.glDeleteTextures(1, t, 0); tid[k] = 0; }
                loaded[k] = 0;
            } else incarca(k, g);
        }
    }

    void tri(int first, int n) {
        if (n <= 0) return;
        GLES20.glUseProgram(prog);
        f2.position(0); GLES20.glVertexAttribPointer(aP, 3, 5126, false, 36, f2);
        f2.position(3); GLES20.glVertexAttribPointer(aN, 3, 5126, false, 36, f2);
        f2.position(6); GLES20.glVertexAttribPointer(aC, 3, 5126, false, 36, f2);
        GLES20.glEnableVertexAttribArray(aP); GLES20.glEnableVertexAttribArray(aN); GLES20.glEnableVertexAttribArray(aC);
        GLES20.glDrawArrays(4, first * 3, n * 3);
    }

    void lista3(FloatBuffer b, int n) {
        if (n <= 0) return;
        b.position(0); GLES20.glVertexAttribPointer(aP, 3, 5126, false, 36, b);
        b.position(3); GLES20.glVertexAttribPointer(aN, 3, 5126, false, 36, b);
        b.position(6); GLES20.glVertexAttribPointer(aC, 3, 5126, false, 36, b);
        GLES20.glEnableVertexAttribArray(aP); GLES20.glEnableVertexAttribArray(aN); GLES20.glEnableVertexAttribArray(aC);
        GLES20.glDrawArrays(4, 0, n * 3);
    }

    /* the vertices of the pictures: 6 each, x y u v r g b a */
    void varfuri() {
        fq = loc(fq, mq * 48);
        float[] v = vv48, px = qx, py = qy, dx = qdx, dy = qdy, uu = qu, vv = qv;
        fq.position(0);
        for (int i = 0; i < mq; i++) {
            int o = i * Tex.Q, k = lq[o + 1];
            float x = lq[o + 2] / 16f, y = lq[o + 3] / 16f, w = lq[o + 4] / 16f, h = lq[o + 5] / 16f;
            float u0 = 0f, v0 = 0f, u1 = 1f, v1 = 1f;
            if (k >= 0 && k < Tex.NT && tw[k] > 0 && lq[o + 8] > 0 && lq[o + 9] > 0) {
                u0 = lq[o + 6] / (float) tw[k]; v0 = lq[o + 7] / (float) th[k];
                u1 = (lq[o + 6] + lq[o + 8]) / (float) tw[k]; v1 = (lq[o + 7] + lq[o + 9]) / (float) th[k];
            }
            int c = lq[o + 10];
            float a = ((c >>> 24) & 255) / 255f;
            float r = (c & 255) / 255f * a, g = ((c >> 8) & 255) / 255f * a, b = ((c >> 16) & 255) / 255f * a;
            float cx = x + w / 2f, cy = y + h / 2f, hx = w / 2f, hy = h / 2f;
            double ang = lq[o + 11] / 1000.0 * Math.PI / 180.0;
            float cs = (float) Math.cos(ang), sn = (float) Math.sin(ang);
            /* corners: 0 top left, 1 top right, 2 bottom right, 3 bottom left */
            dx[0] = -hx; dx[1] = hx; dx[2] = hx; dx[3] = -hx; dy[0] = -hy; dy[1] = -hy; dy[2] = hy; dy[3] = hy;
            for (int j = 0; j < 4; j++) { px[j] = cx + dx[j] * cs - dy[j] * sn; py[j] = cy + dx[j] * sn + dy[j] * cs; }
            uu[0] = u0; uu[1] = u1; uu[2] = u1; uu[3] = u0; vv[0] = v0; vv[1] = v0; vv[2] = v1; vv[3] = v1;
            for (int j = 0; j < 6; j++) {
                int p = ord[j], d = j * 8;
                v[d] = px[p]; v[d + 1] = py[p]; v[d + 2] = uu[p]; v[d + 3] = vv[p];
                v[d + 4] = r; v[d + 5] = g; v[d + 6] = b; v[d + 7] = a;
            }
            fq.put(v, 0, 48);
        }
    }

    void poze(int first, int n, int k) {
        if (n <= 0 || k < 0 || k >= Tex.NT || tid[k] == 0) return;
        GLES20.glDisableVertexAttribArray(aN); GLES20.glDisableVertexAttribArray(aC); GLES20.glDisableVertexAttribArray(aP);
        GLES20.glUseProgram(tprog);
        GLES20.glUniformMatrix4fv(tuM, 1, false, orto, 0);
        GLES20.glActiveTexture(33984);
        GLES20.glBindTexture(3553, tid[k]);
        GLES20.glUniform1i(tuS, 0);
        fq.position(0); GLES20.glVertexAttribPointer(taP, 2, 5126, false, 32, fq);
        fq.position(2); GLES20.glVertexAttribPointer(taT, 2, 5126, false, 32, fq);
        fq.position(4); GLES20.glVertexAttribPointer(taK, 4, 5126, false, 32, fq);
        GLES20.glEnableVertexAttribArray(taP); GLES20.glEnableVertexAttribArray(taT); GLES20.glEnableVertexAttribArray(taK);
        GLES20.glEnable(3042);
        GLES20.glBlendFunc(1, 771);   /* ONE, ONE_MINUS_SRC_ALPHA: the pixels are premultiplied */
        GLES20.glDrawArrays(4, first * 6, n * 6);
        GLES20.glDisable(3042);
        GLES20.glDisableVertexAttribArray(taP); GLES20.glDisableVertexAttribArray(taT); GLES20.glDisableVertexAttribArray(taK);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        synchronized (e.lacat) {
            m3 = e.sn3; m2 = e.sn2;
            f3 = loc(f3, m3 * 27); f2 = loc(f2, m2 * 27);
            f3.position(0); f3.put(e.s3, 0, m3 * 27);
            f2.position(0); f2.put(e.s2, 0, m2 * 27);
            System.arraycopy(e.santet, 0, an, 0, 64);
            mq = Tex.nq;
            if (lq.length < mq * Tex.Q) lq = new int[Tex.q.length];
            System.arraycopy(Tex.q, 0, lq, 0, mq * Tex.Q);
            nlg = Tex.ngen;
            System.arraycopy(Tex.gen, 0, lgen, 0, nlg);
        }
        texturi();
        int fond = an[4];
        float fr = EcranNativ.cul(fond, 0), fg = EcranNativ.cul(fond, 1), fb = EcranNativ.cul(fond, 2);
        GLES20.glClearColor(fr, fg, fb, 1f);
        GLES20.glClear(16640);
        GLES20.glUseProgram(prog);
        GLES20.glUniform3f(uF, fr, fg, fb);
        float fov = an[5] / 1000f;
        if (fov < 5f || fov > 170f) fov = 60f;
        float ox = an[6] / 1000f, oy = an[7] / 1000f, oz = an[8] / 1000f;
        float tx = an[9] / 1000f, ty = an[10] / 1000f, tz = an[11] / 1000f;
        float dx = ox - tx, dy = oy - ty, dz = oz - tz;
        float l = (float) Math.sqrt(dx * dx + dy * dy + dz * dz);
        if (l < 1.0E-4f) { l = 1f; dz = 1f; oz = 1f + tz; }
        float ux = 0f, uy = 1f, uz = 0f;
        if (Math.abs(dy / l) > 0.98f) { uy = 0f; uz = -1f; }
        Matrix.perspectiveM(proj, 0, fov, sw / (float) sh, 0.05f, 400f);
        Matrix.setLookAtM(view, 0, ox, oy, oz, tx, ty, tz, ux, uy, uz);
        Matrix.multiplyMM(mvp, 0, proj, 0, view, 0);
        float lx = dx / l, ly = dy / l + 0.6f, lz = dz / l;
        float ll = (float) Math.sqrt(lx * lx + ly * ly + lz * lz);
        GLES20.glUniformMatrix4fv(uMVP, 1, false, mvp, 0);
        GLES20.glUniformMatrix4fv(uMV, 1, false, view, 0);
        GLES20.glUniform3f(uL, lx / ll, ly / ll, lz / ll);
        float amb = an[14] / 1000f;
        if (amb <= 0f || amb > 1f) amb = 0.35f;
        GLES20.glUniform1f(uAmb, amb);
        GLES20.glUniform2f(uCeata, an[12] / 1000f, an[13] / 1000f);
        float pr = an[19] / 1000f, pp = an[20] / 1000f;
        if (pr > 0f && pp > 0f) {
            int pc = an[21];
            GLES20.glUniform3f(uPL, an[16] / 1000f, an[17] / 1000f, an[18] / 1000f);
            GLES20.glUniform3f(uPC, EcranNativ.cul(pc, 0) * pp, EcranNativ.cul(pc, 1) * pp, EcranNativ.cul(pc, 2) * pp);
            GLES20.glUniform1f(uPR, pr);
        } else {
            GLES20.glUniform3f(uPC, 0f, 0f, 0f);
            GLES20.glUniform1f(uPR, 1f);
        }
        GLES20.glEnable(2929);
        GLES20.glDepthFunc(515);
        lista3(f3, m3);
        GLES20.glDisable(2929);
        Matrix.orthoM(orto, 0, 0f, e.fw, e.fh, 0f, -1f, 1f);
        GLES20.glUniformMatrix4fv(uMVP, 1, false, orto, 0);
        GLES20.glUniformMatrix4fv(uMV, 1, false, unu, 0);
        GLES20.glUniform3f(uL, 0f, 0f, 1f);
        GLES20.glUniform1f(uAmb, 1f);
        GLES20.glUniform2f(uCeata, 0f, 0f);
        GLES20.glUniform3f(uPC, 0f, 0f, 0f);
        if (mq == 0) { tri(0, m2); return; }
        varfuri();
        int t = 0, i = 0;
        while (i < mq) {
            int at = Math.min(Math.max(lq[i * Tex.Q], 0), m2);
            if (at > t) { tri(t, at - t); t = at; }
            int k = lq[i * Tex.Q + 1], j = i + 1;
            while (j < mq && Math.min(Math.max(lq[j * Tex.Q], 0), m2) == at && lq[j * Tex.Q + 1] == k) j++;
            poze(i, j - i, k);
            i = j;
        }
        tri(t, m2 - t);
    }
}
