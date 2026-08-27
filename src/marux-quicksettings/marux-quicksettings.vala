/* =============================================================================
 * MaruxOS 퀵설정 (marux-quicksettings) — 배치 W MVP, 2026-08-14
 * -----------------------------------------------------------------------------
 * 우상단 인디케이터 바 → 클릭 → 드롭다운 퀵설정 패널 (Win11/macOS 컨트롤센터 풍).
 *   - WiFi: 토글 / 스캔 목록 / 연결 (백엔드 = wpa_cli, IP는 dhcpcd)
 *   - 볼륨: 슬라이더 (백엔드 = amixer)
 * GTK3 + vala (자체 스택 — MaruxOS 자체 valac로 컴파일). 100% 자체 제작, 기성 애플릿 없음.
 * 디자인: Marux 유리 톤 (rgba 어두운 패널 + 라운드 12 — picom 컴포지터 전제,
 *         비컴포지트에선 불투명 폴백 = plank과 동일 거동).
 * 주의: 패스워드 입력은 별도 일반 다이얼로그 (DOCK/UTILITY 창은 WM 포커스 못 받는 함정 회피).
 * ============================================================================= */
using Gtk;

const string IFACE = "wlan0";
const int MARGIN  = 16;   /* 화면 가장자리 여백 (v2: 8→16, '구석에 딱 붙음' 해소) */
const int BAR_H   = 34;
const int PANEL_W = 344;

/* ---------- 외부 명령 헬퍼 (shell 미경유 — 따옴표 지옥 회피) ---------- */
string run_cmd(string[] argv) {
    try {
        string so; string se; int st;
        Process.spawn_sync(null, argv, null, SpawnFlags.SEARCH_PATH, null, out so, out se, out st);
        return so ?? "";
    } catch (Error e) { return ""; }
}
string wpa(string[] sub) {
    string[] argv = { "wpa_cli", "-i", IFACE };
    foreach (var s in sub) argv += s;
    return run_cmd(argv);
}
bool has_wlan() { return FileUtils.test("/sys/class/net/" + IFACE, FileTest.EXISTS); }

/* wpa_cli status에서 키 추출 — 직접 파싱.
 * ⚠️ v21까지 HashTable<string,string>을 썼는데 실기기에서 `wpa_state`는 읽히고 바로 아랫줄
 *    `ip_address`는 유실되는 현상 발생(사용자 신고: IP 받았는데 "IP 없음"). vala 제네릭
 *    컨테이너의 문자열 소유권 문제로 판단 → 컨테이너 자체를 제거해 원천 차단. */
string? status_get(string blob, string key) {
    foreach (var line in blob.split("
")) {
        var l = line.strip();
        if (l.has_prefix(key + "=")) {
            var v = l.substring(key.length + 1).strip();
            return (v.length > 0) ? v : null;
        }
    }
    return null;
}

/* IP 폴백 — wpa_cli status에 ip_address가 없어도 커널에서 직접 읽는다(이중 안전망) */
string? get_ip() {
    var o = run_cmd({"ip", "-4", "addr", "show", IFACE});
    var i = o.index_of("inet ");
    if (i < 0) return null;
    var rest = o.substring(i + 5);
    var j = rest.index_of_char('/');
    if (j <= 0) return null;
    var ip = rest[0:j].strip();
    return (ip.length > 6) ? ip : null;
}

/* 신호(dBm) → 유니코드 바 (DejaVu 보유 글리프만 사용 — 이모지 폰트 없음) */
string sig_bars(int dbm) {
    if (dbm >= -55) return "▂▄▆█";
    if (dbm >= -67) return "▂▄▆";
    if (dbm >= -75) return "▂▄";
    return "▂";
}

/* 믹서 컨트롤 동적 감지 — v18 실기기 교훈: "Master" 하드코딩 금지 (vc4-hdmi엔 HW 볼륨 無,
 * softvol Master는 첫 재생 후 등장). amixer 부재/카드 부재도 그레이스풀 처리. */
string? MIXER = null;
string? detect_mixer() {
    var o = run_cmd({"amixer", "scontrols"});   /* "Simple mixer control 'Master',0" */
    var i = o.index_of("'");
    if (i < 0) return null;
    var j = o.index_of("'", i + 1);
    if (j < 0) return null;
    return o[i+1:j];
}
int get_volume() {
    if (MIXER == null) return -1;
    var o = run_cmd({"amixer", "sget", MIXER});
    var i = o.index_of("[");
    if (i < 0) return -1;
    var j = o.index_of("%]", i);
    if (j < 0) return -1;
    return int.parse(o[i+1:j]);
}

/* 라운드 유리 배경 cairo 직접 페인트 — CSS 배경은 v18 실기기에서 미발현(투명 패널 버그).
 * 톤 = 플로팅 시계와 통일 (#c8c8c8, ~92% — 사용자 확정 룩). */
bool draw_glass_hl(Gtk.Widget w, Cairo.Context cr, double r, bool hot) {
    double wd = w.get_allocated_width();
    double h  = w.get_allocated_height();
    cr.save();
    cr.set_operator(Cairo.Operator.SOURCE);
    cr.set_source_rgba(0, 0, 0, 0);
    cr.paint();
    cr.restore();
    cr.new_sub_path();
    cr.arc(wd - r, r,     r, -Math.PI/2, 0);
    cr.arc(wd - r, h - r, r, 0, Math.PI/2);
    cr.arc(r,      h - r, r, Math.PI/2, Math.PI);
    cr.arc(r,      r,     r, Math.PI, 3*Math.PI/2);
    cr.close_path();
    /* hot = 마우스 오버 → 한 톤 밝게 (CSS는 창 배경에서 신뢰도가 낮아 cairo로 직접) */
    if (hot) cr.set_source_rgba(0.906, 0.906, 0.906, 0.96);
    else     cr.set_source_rgba(0.784, 0.784, 0.784, 0.92);
    cr.fill();
    return false;   /* 자식 위젯 계속 그림 */
}

/* 연결 신호 세기 → 0~3 단계 (wpa_cli signal_poll의 RSSI) */
int wifi_signal_level() {
    var o = run_cmd({"wpa_cli", "-i", IFACE, "signal_poll"});
    var i = o.index_of("RSSI=");
    if (i < 0) return 0;
    var rest = o.substring(i + 5);
    var j = rest.index_of_char('
');
    var v = (j > 0) ? rest[0:j] : rest;
    int rssi = int.parse(v.strip());
    if (rssi == 0)    return 0;
    if (rssi >= -55)  return 3;
    if (rssi >= -70)  return 2;
    return 1;
}

/* 한영 입력 상태 — ibus-hangul이 내보내는 상태 파일을 읽는다.
 * ibus-hangul은 Shift+Space로 *엔진 내부 모드*만 바꿔 `ibus engine`으로는 한/영 구분이
 * 불가능했다(v22까지 항상 "한" 고정). ibus 패널 D-Bus를 구현하는 대신, 모든 전환이 통과하는
 * 단일 지점(ibus_hangul_engine_set_input_mode)에서 상태를 파일로 내보내도록 엔진을 패치.
 * 파일 부재 = 아직 전환 이력 없음 = 기본값 latin("A"). */
const string IME_MODE_FILE = "/tmp/marux-ime-mode";
string ime_label() {
    string body;
    try {
        if (!FileUtils.test(IME_MODE_FILE, FileTest.EXISTS)) return "A";
        FileUtils.get_contents(IME_MODE_FILE, out body);
    } catch (Error e) { return "A"; }
    return (body.strip() == "han") ? "한" : "A";
}

/* 2줄 시계 — 사진 레퍼런스 포맷(오후 2:57 / 2026-08-23).
 * %p/%-I는 로케일·플랫폼 편차가 있어 직접 조립한다. */
void clock_now(out string t1, out string t2) {
    var n = new DateTime.now_local();
    int h = n.get_hour();
    int h12 = h % 12; if (h12 == 0) h12 = 12;
    t1 = "%s %d:%02d".printf((h < 12) ? "오전" : "오후", h12, n.get_minute());
    t2 = n.format("%Y-%m-%d");
}

public class QuickSettings {
    Gtk.Window bar;
    Gtk.Label  ime_lbl;    /* 한/A */
    Gtk.DrawingArea wifi_icon;   /* cairo WiFi 아이콘 */
    int wifi_level = 0;          /* 0=끊김, 1~3=신호 세기 */
    bool bar_hot = false;        /* 바 마우스 오버 */
    Gtk.Label  vol_ind;    /* ♪% */
    Gtk.Label  clk_time;   /* 오후 2:57 */
    Gtk.Label  clk_date;   /* 2026-08-23 */
    Gtk.Window panel;
    bool panel_shown = false;

    Gtk.Switch  wifi_sw;
    Gtk.Label   wifi_lbl;
    Gtk.Button  scan_btn;
    Gtk.ListBox net_list;
    Gtk.Scale   vol_scale;
    Gtk.Label   vol_lbl;
    bool syncing = false;   /* 프로그램적 위젯 갱신 중 시그널 무시 */

    static void enable_rgba(Gtk.Window w) {
        var v = w.get_screen().get_rgba_visual();
        if (v != null) w.set_visual(v);
        w.app_paintable = true;
    }

    void load_css() {
        /* 배경(유리)은 cairo가 담당(draw_glass). CSS는 계층·타이포·컨트롤 톤만.
         * ⚠️ PRIORITY_USER: Adwaita 기본 스타일(border-image/box-shadow)이 라운드를
         *    덮어써서 버튼이 각져 보이던 문제 해소 — 사용자 피드백 v2. */
        var css = """
            #qs-bar, #qs-root-win { background-color: transparent; }
            #qs-bar label { color: #16181d; font-family: "NanumGothic"; }
            #bar-ime  { font-weight: bold; font-size: 13px; }
            #bar-wifi { font-size: 13px; }
            #bar-vol  { font-size: 12px; }
            #bar-sep  { background-color: rgba(60,63,70,0.30); min-width: 1px; margin: 2px 0; }
            #bar-hot        { background-color: transparent; border-radius: 10px; }
            #bar-hot.hot    { background-color: rgba(255,255,255,0.38); }
            #clk-time { font-weight: bold; font-size: 14px; }
            #clk-date { font-size: 10px; color: #3a3d44; }
            #qs-root { padding: 4px; }

            /* 섹션 카드 — 유리 위 밝은 레이어로 계층감 */
            .qs-card {
                background-color: rgba(255,255,255,0.42);
                border-radius: 14px;
                padding: 14px;
            }
            .qs-title {
                color: #2a2d34; font-weight: bold; font-size: 13px;
            }
            .qs-sub {
                color: #4a4e57; font-size: 11px;
            }
            #qs-root label { color: #16181d; }

            /* 버튼 — 확실한 라운드 (Adwaita 덮어쓰기) */
            #qs-root button {
                background-image: none;
                background-color: rgba(58,61,68,0.92);
                color: #ffffff;
                border: none;
                border-image: none;
                box-shadow: none;
                border-radius: 12px;
                padding: 9px 16px;
                font-weight: bold;
                text-shadow: none;
                min-height: 0;
            }
            #qs-root button:hover  { background-color: rgba(34,37,43,0.96); }
            #qs-root button:active { background-color: rgba(20,22,26,0.98); }
            #qs-root button:disabled {
                background-color: rgba(120,124,132,0.55); color: rgba(255,255,255,0.7);
            }

            /* 네트워크 목록 */
            #qs-root list { background-color: transparent; }
            #qs-root list row {
                background-color: rgba(255,255,255,0.34);
                border-radius: 10px;
                padding: 9px 12px;
                margin-bottom: 5px;
            }
            #qs-root list row:hover    { background-color: rgba(255,255,255,0.72); }
            #qs-root list row:selected { background-color: rgba(58,61,68,0.90); }
            #qs-root list row:selected label { color: #ffffff; }

            /* 볼륨 슬라이더 */
            #qs-root scale { min-height: 26px; padding: 0; }
            #qs-root scale trough {
                background-color: rgba(90,94,102,0.32);
                border-radius: 9px; min-height: 7px; border: none;
            }
            #qs-root scale highlight {
                background-color: rgba(48,51,58,0.92);
                border-radius: 9px; min-height: 7px;
            }
            #qs-root scale slider {
                background-color: #ffffff;
                border: none; box-shadow: none;
                border-radius: 50%;
                min-width: 17px; min-height: 17px;
                margin: -6px;
            }
            #qs-root scale:disabled trough    { background-color: rgba(120,124,132,0.25); }
            #qs-root scale:disabled highlight { background-color: rgba(120,124,132,0.4); }

            /* 스위치 */
            #qs-root switch { min-width: 46px; min-height: 25px; }
        """;
        var p = new Gtk.CssProvider();
        try { p.load_from_data(css, css.length); } catch (Error e) {}
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), p,
            Gtk.STYLE_PROVIDER_PRIORITY_USER);
    }

    /* ---------- 우상단 통합 상태 바 (v22) ----------
     * 레이아웃:  한 │ ▂▄▆█ │ ♪72% ‖ 오후 2:57 / 2026-08-23
     * 시계를 tint2에서 흡수 — 같은 창에 그리므로 "연결된 느낌"이 구조적으로 보장된다. */
    void build_bar() {
        /* POPUP = override-redirect: WM이 관리하지 않아 bamf/plank가 창으로 인식하지 못한다.
         * (v23 POPUP_MENU, v22 DOCK 모두 독에 유령 항목이 남았음 — 창 "타입 힌트"로는 부족) */
        bar = new Gtk.Window(Gtk.WindowType.POPUP);
        bar.set_skip_taskbar_hint(true);
        bar.set_skip_pager_hint(true);
        bar.set_keep_above(true);
        bar.set_type_hint(Gdk.WindowTypeHint.DOCK);
        enable_rgba(bar);
        bar.set_name("qs-bar");
        bar.draw.connect((cr) => draw_glass_hl(bar, cr, 10, bar_hot));

        var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        row.margin_start = 12; row.margin_end = 12;
        row.margin_top = 5;    row.margin_bottom = 5;

        ime_lbl  = new Gtk.Label("—");   ime_lbl.set_name("bar-ime");
        vol_ind  = new Gtk.Label("♪ --"); vol_ind.set_name("bar-vol");

        /* WiFi는 폰트 글리프가 없어(이모지 금지 함정) cairo로 직접 그린다 */
        wifi_icon = new Gtk.DrawingArea();
        wifi_icon.set_size_request(20, 16);
        wifi_icon.valign = Gtk.Align.CENTER;
        wifi_icon.draw.connect((cr) => {
            double cx = 10.0, cy = 13.5;
            cr.set_line_cap(Cairo.LineCap.ROUND);
            for (int i = 0; i < 3; i++) {
                bool on = (wifi_level > i);
                cr.set_source_rgba(0.09, 0.09, 0.11, on ? 0.92 : 0.20);
                cr.set_line_width(1.9);
                cr.new_path();
                cr.arc(cx, cy, 4.0 + i * 3.6, -2.356, -0.785);   /* -135° ~ -45° */
                cr.stroke();
            }
            cr.set_source_rgba(0.09, 0.09, 0.11, (wifi_level > 0) ? 0.92 : 0.20);
            cr.arc(cx, cy, 1.5, 0, 2 * Math.PI);
            cr.fill();
            return true;
        });

        row.pack_start(ime_lbl,   false, false, 0);
        row.pack_start(wifi_icon, false, false, 0);
        row.pack_start(vol_ind,   false, false, 0);

        var sep = new Gtk.Separator(Gtk.Orientation.VERTICAL);
        sep.set_name("bar-sep");
        row.pack_start(sep, false, false, 4);

        var clk = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        clk_time = new Gtk.Label("--:--"); clk_time.set_name("clk-time"); clk_time.xalign = 1;
        clk_date = new Gtk.Label("----");  clk_date.set_name("clk-date"); clk_date.xalign = 1;
        clk.pack_start(clk_time, false, false, 0);
        clk.pack_start(clk_date, false, false, 0);
        row.pack_start(clk, false, false, 0);

        var eb = new Gtk.EventBox();
        eb.visible_window = false;   /* 유리 배경은 창의 cairo가 그린다 */
        eb.add(row);
        eb.button_press_event.connect(() => { toggle_panel(); return true; });
        /* 호버는 창 레벨에서 받아 cairo 배경을 다시 그린다 (CSS 미적용 문제 회피) */
        bar.add_events(Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        bar.enter_notify_event.connect(() => { bar_hot = true;  bar.queue_draw(); return false; });
        bar.leave_notify_event.connect(() => { bar_hot = false; bar.queue_draw(); return false; });
        bar.add(eb);
        bar.show_all();
        place_bar();
    }

    void place_bar() {
        int w, h;
        bar.get_size(out w, out h);
        var scr = Gdk.Screen.get_default();
        bar.move(scr.get_width() - w - MARGIN, MARGIN);
    }
    void refresh_bar() {
        /* 시계 */
        string t1, t2;
        clock_now(out t1, out t2);
        clk_time.set_text(t1);
        clk_date.set_text(t2);

        /* 한영 */
        ime_lbl.set_text(ime_label());

        /* WiFi — 아이콘 단계 (0=끊김) */
        if (!has_wlan()) {
            wifi_level = 0;
        } else {
            var state = status_get(wpa({"status"}), "wpa_state") ?? "";
            wifi_level = (state == "COMPLETED") ? wifi_signal_level() : 0;
        }
        wifi_icon.queue_draw();

        /* 볼륨 */
        if (MIXER == null) MIXER = detect_mixer();
        var v = get_volume();
        vol_ind.set_text((v < 0) ? "♪ --" : "♪ %d%%".printf(v));

        place_bar();
    }

    /* ---------- 드롭다운 패널 ---------- */
    static Gtk.Box make_card() {
        var c = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
        c.get_style_context().add_class("qs-card");
        return c;
    }
    static Gtk.Label make_title(string t) {
        var l = new Gtk.Label(t);
        l.xalign = 0;
        l.get_style_context().add_class("qs-title");
        return l;
    }

    void build_panel() {
        /* 패널도 override-redirect. 키 입력이 필요한 비밀번호 창만 일반 TOPLEVEL로 띄운다. */
        panel = new Gtk.Window(Gtk.WindowType.POPUP);
        panel.set_skip_taskbar_hint(true);
        panel.set_skip_pager_hint(true);
        panel.set_keep_above(true);
        panel.set_type_hint(Gdk.WindowTypeHint.POPUP_MENU);
        panel.set_default_size(PANEL_W, -1);
        enable_rgba(panel);
        panel.set_name("qs-root-win");
        panel.draw.connect((cr) => draw_glass_hl(panel, cr, 16, false));

        /* 바깥 여백 — 유리 테두리와 내용 사이 숨 쉴 공간 (v2 피드백) */
        var root = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
        root.set_name("qs-root");
        root.margin = 16;

        /* ===== WiFi 카드 ===== */
        var wcard = make_card();
        var wrow = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        wrow.pack_start(make_title("WiFi"), true, true, 0);
        wifi_sw = new Gtk.Switch();
        wifi_sw.valign = Gtk.Align.CENTER;
        wifi_sw.state_set.connect((s2) => {
            if (syncing) return false;
            if (s2) { run_cmd({"ip", "link", "set", IFACE, "up"}); wpa({"reconnect"}); }
            else     wpa({"disconnect"});
            GLib.Timeout.add(800, () => { refresh_panel(); return false; });
            return false;
        });
        wrow.pack_end(wifi_sw, false, false, 0);
        wcard.pack_start(wrow, false, false, 0);

        wifi_lbl = new Gtk.Label("—");
        wifi_lbl.xalign = 0; wifi_lbl.wrap = true;
        wifi_lbl.get_style_context().add_class("qs-sub");
        wcard.pack_start(wifi_lbl, false, false, 0);

        scan_btn = new Gtk.Button.with_label("네트워크 검색");
        scan_btn.clicked.connect(do_scan);
        wcard.pack_start(scan_btn, false, false, 2);

        var sc = new Gtk.ScrolledWindow(null, null);
        sc.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        sc.set_min_content_height(168);
        net_list = new Gtk.ListBox();
        net_list.set_selection_mode(Gtk.SelectionMode.NONE);
        net_list.row_activated.connect(on_net_row);
        sc.add(net_list);
        wcard.pack_start(sc, true, true, 0);
        root.pack_start(wcard, true, true, 0);

        /* ===== 볼륨 카드 ===== */
        var vcard = make_card();
        var vrow = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        vrow.pack_start(make_title("볼륨"), true, true, 0);
        vol_lbl = new Gtk.Label("--");
        vol_lbl.get_style_context().add_class("qs-sub");
        vrow.pack_end(vol_lbl, false, false, 0);
        vcard.pack_start(vrow, false, false, 0);

        vol_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 5);
        vol_scale.set_draw_value(false);
        vol_scale.value_changed.connect(() => {
            if (syncing || MIXER == null) return;
            var v = (int) vol_scale.get_value();
            run_cmd({"amixer", "-q", "sset", MIXER, "%d%%".printf(v)});
            vol_lbl.set_text("%d%%".printf(v));
            refresh_bar();
        });
        vcard.pack_start(vol_scale, false, false, 0);
        root.pack_start(vcard, false, false, 0);

        panel.add(root);
    }
    void place_panel() {
        var scr = Gdk.Screen.get_default();
        panel.move(scr.get_width() - PANEL_W - MARGIN, MARGIN + BAR_H + 6);
    }
    void toggle_panel() {
        if (panel_shown) { panel.hide(); panel_shown = false; return; }
        refresh_panel();
        panel.show_all();
        place_panel();
        panel_shown = true;
    }
    void refresh_panel() {
        syncing = true;
        if (!has_wlan()) {
            wifi_sw.sensitive = false; scan_btn.sensitive = false;
            wifi_lbl.set_text("WiFi 하드웨어/커널 미지원 (구커널?)");
        } else {
            var blob = wpa({"status"});
            var state = status_get(blob, "wpa_state") ?? "";
            wifi_sw.sensitive = true;
            wifi_sw.set_active(state != "INTERFACE_DISABLED" && state != "");
            if (state == "COMPLETED") {
                var ssid = status_get(blob, "ssid") ?? "?";
                var ip = status_get(blob, "ip_address") ?? get_ip();   /* 폴백 */
                if (ip != null) {
                    wifi_lbl.set_text("연결됨: %s (%s)".printf(ssid, ip));
                } else {
                    wifi_lbl.set_text("연결됨: %s (IP 받는 중…)".printf(ssid));
                    run_cmd({"dhcpcd", "-b", "-q", IFACE});
                    schedule_ip_recheck();   /* DHCP가 늦어도 자동 반영 */
                }
            } else if (state == "") {
                wifi_lbl.set_text("wpa_supplicant 미기동");
            } else {
                wifi_lbl.set_text("상태: " + state);
            }
        }
        if (MIXER == null) MIXER = detect_mixer();   /* softvol Master는 첫 재생 후 등장 → 재감지 */
        var v = get_volume();
        vol_scale.sensitive = (v >= 0);
        if (v >= 0) { vol_scale.set_value(v); vol_lbl.set_text("%d%%".printf(v)); }
        else vol_lbl.set_text("--");
        syncing = false;
        refresh_bar();
    }

    /* ---------- 스캔/연결 ---------- */
    void do_scan() {
        if (!has_wlan()) return;
        wpa({"scan"});
        scan_btn.sensitive = false;
        scan_btn.label = "검색 중…";
        GLib.Timeout.add_seconds(3, () => { fill_results(); return false; });
    }
    void fill_results() {
        foreach (var c in net_list.get_children()) net_list.remove(c);
        /* HashTable 제네릭 회피(IP 유실 버그와 동일 패턴) — 병렬 배열로 중복제거+최강신호 유지 */
        string[] ssids = {}; int[] sigs = {}; bool[] secs = {};
        var lines = wpa({"scan_results"}).split("
");
        for (int i = 1; i < lines.length; i++) {
            var f = lines[i].split("	");
            if (f.length < 5) continue;
            var ssid = f[4].strip();
            if (ssid.length == 0) continue;
            int sig = int.parse(f[2]);
            bool sec = ("WPA" in f[3]);
            int found = -1;
            for (int k = 0; k < ssids.length; k++) { if (ssids[k] == ssid) { found = k; break; } }
            if (found < 0) { ssids += ssid; sigs += sig; secs += sec; }
            else if (sig > sigs[found]) { sigs[found] = sig; secs[found] = sec; }
        }
        /* 신호순 정렬 — 3배열 동시 스왑 (List.sort 클로저 불가 함정 회피) */
        for (int i = 1; i < ssids.length; i++) {
            for (int j = i; j > 0 && sigs[j] > sigs[j-1]; j--) {
                var ts = ssids[j]; ssids[j] = ssids[j-1]; ssids[j-1] = ts;
                var tg = sigs[j];  sigs[j]  = sigs[j-1];  sigs[j-1]  = tg;
                var tc = secs[j];  secs[j]  = secs[j-1];  secs[j-1]  = tc;
            }
        }
        for (int k = 0; k < ssids.length; k++) {
            var row = new Gtk.ListBoxRow();
            /* 목록에서도 신호를 아이콘으로 (v23 피드백: 창 안은 여전히 텍스트였음) */
            var hb = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            int lv = (sigs[k] >= -55) ? 3 : ((sigs[k] >= -70) ? 2 : 1);
            var ic = new Gtk.DrawingArea();
            ic.set_size_request(18, 14);
            ic.valign = Gtk.Align.CENTER;
            ic.draw.connect((cr) => {
                double cx = 9.0, cy = 12.0;
                cr.set_line_cap(Cairo.LineCap.ROUND);
                for (int a = 0; a < 3; a++) {
                    cr.set_source_rgba(0.09, 0.09, 0.11, (lv > a) ? 0.90 : 0.18);
                    cr.set_line_width(1.7);
                    cr.new_path();
                    cr.arc(cx, cy, 3.4 + a * 3.1, -2.356, -0.785);
                    cr.stroke();
                }
                cr.set_source_rgba(0.09, 0.09, 0.11, 0.90);
                cr.arc(cx, cy, 1.3, 0, 2 * Math.PI);
                cr.fill();
                return true;
            });
            /* 이모지 금지(폰트 부재) — 한글 표기 */
            var lbl = new Gtk.Label("%s %s".printf(ssids[k], secs[k] ? "(잠금)" : ""));
            lbl.xalign = 0;
            hb.pack_start(ic,  false, false, 0);
            hb.pack_start(lbl, true,  true,  0);
            row.add(hb);
            row.set_data<string>("ssid", ssids[k]);
            row.set_data<bool>("secured", secs[k]);
            net_list.add(row);
        }
        net_list.show_all();
        scan_btn.sensitive = true;
        scan_btn.label = "네트워크 검색";
    }
    void on_net_row(Gtk.ListBoxRow row) {
        string ssid = row.get_data<string>("ssid");
        bool secured = row.get_data<bool>("secured");
        /* 이미 등록된 네트워크면 select만 */
        foreach (var line in wpa({"list_networks"}).split("\n")) {
            var f = line.split("\t");
            if (f.length >= 2 && f[1] == ssid) {
                wpa({"enable_network", f[0]});   /* TEMP-DISABLED 해제 */
                wpa({"select_network", f[0]});
                after_connect();
                return;
            }
        }
        if (secured) ask_password(ssid);
        else connect_new(ssid, null);
    }
    void ask_password(string ssid) {
        /* 부모를 panel(override-redirect)로 두면 배치가 깨지므로 최상위 독립 창으로 띄운다 */
        var d = new Gtk.Dialog.with_buttons("WiFi 연결", null,
            Gtk.DialogFlags.MODAL, "취소", Gtk.ResponseType.CANCEL, "연결", Gtk.ResponseType.OK);
        d.set_position(Gtk.WindowPosition.CENTER_ALWAYS);
        d.set_keep_above(true);
        var box = d.get_content_area();
        box.spacing = 8; box.margin = 12;
        box.add(new Gtk.Label("『%s』 비밀번호:".printf(ssid)));
        var entry = new Gtk.Entry();
        entry.visibility = false;
        entry.activates_default = true;
        box.add(entry);
        d.set_default_response(Gtk.ResponseType.OK);
        d.show_all();
        d.present();
        d.response.connect((r) => {
            if (r == Gtk.ResponseType.OK && entry.text.length >= 8)
                connect_new(ssid, entry.text);
            d.destroy();
        });
    }
    void connect_new(string ssid, string? psk) {
        var id = wpa({"add_network"}).strip();
        wpa({"set_network", id, "ssid", "\"%s\"".printf(ssid)});
        if (psk != null) wpa({"set_network", id, "psk", "\"%s\"".printf(psk)});
        else wpa({"set_network", id, "key_mgmt", "NONE"});
        wpa({"enable_network", id});
        wpa({"select_network", id});
        wpa({"save_config"});
        after_connect();
    }
    /* DHCP 완료가 늦을 때 IP를 자동으로 다시 확인 (3·6·10초). v21 "IP 안 뜸" 후속 */
    int ip_tries = 0;
    void schedule_ip_recheck() {
        ip_tries = 0;
        GLib.Timeout.add_seconds(3, () => {
            ip_tries++;
            if (!panel_shown || ip_tries > 3) return false;
            var ip = get_ip();
            if (ip != null) {
                var ssid = status_get(wpa({"status"}), "ssid") ?? "?";
                wifi_lbl.set_text("연결됨: %s (%s)".printf(ssid, ip));
                refresh_bar();
                return false;
            }
            return true;   /* 계속 재시도 */
        });
    }

    void after_connect() {
        wifi_lbl.set_text("연결 중…");
        GLib.Timeout.add_seconds(4, () => {
            run_cmd({"dhcpcd", "-b", "-q", IFACE});
            GLib.Timeout.add_seconds(4, () => {
                var blob = wpa({"status"});
                var st = status_get(blob, "wpa_state") ?? "";
                if (st == "COMPLETED") {
                    refresh_panel();
                } else {
                    /* 실패를 삼키지 않고 사용자에게 알린다 (v22 피드백: "왜 또 연결이 안 되냐")
                     * wpa는 실패한 네트워크를 TEMP-DISABLED로 자동 차단하므로 그 사실도 알린다. */
                    var nets = wpa({"list_networks"});
                    var blocked = ("TEMP-DISABLED" in nets);
                    var msg = blocked
                        ? "연결에 실패했습니다.
비밀번호를 확인해 주세요."
                        : "연결에 실패했습니다. (상태: " + st + ")";
                    wifi_lbl.set_text("연결 실패");
                    /* 패널은 포커스를 잃으면 닫히므로 별도 창으로 알린다 (v23 피드백) */
                    /* 부모가 없으면 화면 뒤/밖에 뜰 수 있어 명시 배치 (v24 피드백: 경고창 안 보임) */
                    var dlg = new Gtk.MessageDialog(null, 0,
                        Gtk.MessageType.WARNING, Gtk.ButtonsType.OK, "%s", msg);
                    dlg.set_title("WiFi 연결 실패");
                    dlg.set_position(Gtk.WindowPosition.CENTER_ALWAYS);
                    dlg.set_keep_above(true);
                    dlg.stick();
                    dlg.response.connect(() => { dlg.destroy(); });
                    dlg.show_all();
                    dlg.present();
                    refresh_bar();
                }
                return false;
            });
            return false;
        });
    }

    public void start() {
        MIXER = detect_mixer();
        load_css();
        build_bar();
        build_panel();
        refresh_bar();
        GLib.Timeout.add_seconds(1, () => { refresh_bar(); return true; });   /* 시계 때문에 1초 */
    }
}

int main(string[] args) {
    Gtk.init(ref args);
    var qs = new QuickSettings();
    qs.start();
    Gtk.main();
    return 0;
}
