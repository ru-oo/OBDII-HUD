// Chrome: status bar (top), page indicator dots (bottom), theme FAB + bottom sheet.

const { useState, useEffect } = React;

/* ───────────────────────────────────────────────────────────────
   StatusBar — GPS lock, OBD, time, battery
─────────────────────────────────────────────────────────────── */
function StatusBar({ gpsLock = true, obdConnected = true, batteryV = 14.2, time }) {
  const t = time || new Date();
  const hh = String(t.getHours()).padStart(2, "0");
  const mm = String(t.getMinutes()).padStart(2, "0");

  const Item = ({ icon, children, ok = true, warn = false }) => (
    <div style={{
      display: "flex", alignItems: "center", gap: 10, height: 40,
      padding: "0 16px",
      color: warn ? "var(--warn)" : ok ? "var(--text-secondary)" : "var(--text-tertiary)",
      fontSize: 18, fontWeight: 500, letterSpacing: "0.04em",
      fontFamily: "var(--font-display)",
      fontVariantNumeric: "tabular-nums",
    }}>
      {icon}
      <span>{children}</span>
    </div>
  );

  // small inline icons
  const icoGPS = (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
      <circle cx="12" cy="12" r="3.5" /><circle cx="12" cy="12" r="8" opacity="0.6" />
      <line x1="12" y1="2" x2="12" y2="5" /><line x1="12" y1="19" x2="12" y2="22" />
      <line x1="2" y1="12" x2="5" y2="12" /><line x1="19" y1="12" x2="22" y2="12" />
    </svg>
  );
  const icoOBD = (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
      <rect x="3" y="6" width="18" height="12" rx="2" />
      <circle cx="8" cy="12" r="1.2" fill="currentColor" />
      <circle cx="12" cy="12" r="1.2" fill="currentColor" />
      <circle cx="16" cy="12" r="1.2" fill="currentColor" />
    </svg>
  );
  const icoBat = (
    <svg width="22" height="14" viewBox="0 0 32 16" fill="none" stroke="currentColor" strokeWidth="1.6">
      <rect x="0.8" y="0.8" width="27" height="14.4" rx="2.4" />
      <rect x="3.5" y="3.5" width="20" height="9" fill="currentColor" opacity="0.85" />
      <rect x="29" y="5" width="2.5" height="6" fill="currentColor" />
    </svg>
  );

  return (
    <div style={{
      position: "absolute", top: 0, left: 0, right: 0,
      height: 56, padding: "0 28px",
      display: "flex", alignItems: "center", justifyContent: "space-between",
      zIndex: 50,
      borderBottom: "1px solid var(--hairline)",
      background: "linear-gradient(to bottom, var(--bg) 0%, transparent 100%)",
    }}>
      <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
        <Item icon={icoGPS} ok={gpsLock} warn={!gpsLock}>{gpsLock ? "GPS · 9 SAT" : "NO GPS"}</Item>
        <span style={{ width: 1, height: 20, background: "var(--hairline)" }} />
        <Item icon={icoOBD} ok={obdConnected} warn={!obdConnected}>{obdConnected ? "OBD-II" : "OBD OFFLINE"}</Item>
      </div>
      <div style={{
        fontFamily: "var(--font-display)", fontSize: 22, fontWeight: 400,
        color: "var(--text)", letterSpacing: "0.04em",
        fontVariantNumeric: "tabular-nums",
      }}>{hh}:{mm}</div>
      <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
        <Item ok>
          <span style={{ color: "var(--text-tertiary)", marginRight: 6 }}>BAT</span>
          {batteryV.toFixed(1)}<span style={{ color: "var(--text-tertiary)", marginLeft: 4 }}>V</span>
        </Item>
        <span style={{ width: 1, height: 20, background: "var(--hairline)" }} />
        <Item icon={icoBat} ok>87%</Item>
      </div>
    </div>
  );
}

/* ───────────────────────────────────────────────────────────────
   PageDots — bottom-center page indicators
─────────────────────────────────────────────────────────────── */
function PageDots({ count, current, onSelect }) {
  return (
    <div style={{
      position: "absolute", bottom: 28, left: "50%", transform: "translateX(-50%)",
      display: "flex", gap: 12, zIndex: 50,
    }}>
      {Array.from({ length: count }).map((_, i) => {
        const active = i === current;
        return (
          <button key={i}
            onClick={() => onSelect(i)}
            aria-label={`Page ${i + 1}`}
            style={{
              width: active ? 36 : 12, height: 12,
              borderRadius: 999,
              background: active ? "var(--accent)" : "var(--text-quaternary)",
              border: "none",
              padding: 0,
              boxShadow: active ? "0 0 16px var(--accent-glow)" : "none",
              transition: "all 320ms var(--ease-spring)",
              cursor: "pointer",
            }} />
        );
      })}
    </div>
  );
}

/* ───────────────────────────────────────────────────────────────
   ThemeFAB + ThemeSheet — bottom-right FAB opens slide-up sheet
─────────────────────────────────────────────────────────────── */
function ThemeFAB({ onClick }) {
  return (
    <button onClick={onClick}
      aria-label="Theme settings"
      style={{
        position: "absolute", bottom: 24, right: 24, zIndex: 60,
        width: 72, height: 72, borderRadius: "50%",
        border: "1.5px solid var(--card-border-strong)",
        background: "var(--card)",
        backdropFilter: "blur(20px)",
        WebkitBackdropFilter: "blur(20px)",
        color: "var(--text)",
        display: "grid", placeItems: "center",
        boxShadow: "0 0 32px var(--accent-glow), 0 12px 24px rgba(0,0,0,0.3)",
        cursor: "pointer",
        transition: "transform 200ms var(--ease-spring)",
      }}
      onMouseDown={e => e.currentTarget.style.transform = "scale(0.94)"}
      onMouseUp={e => e.currentTarget.style.transform = "scale(1)"}
      onMouseLeave={e => e.currentTarget.style.transform = "scale(1)"}>
      <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
        <circle cx="12" cy="12" r="3.5" />
        <path d="M12 2v3 M12 19v3 M2 12h3 M19 12h3 M4.9 4.9l2.1 2.1 M17 17l2.1 2.1 M4.9 19.1l2.1-2.1 M17 7l2.1-2.1" />
      </svg>
    </button>
  );
}

function ThemeSheet({ open, onClose, theme, onTheme, accent, onAccent, simSpeed, onSimSpeed }) {
  return (
    <>
      {/* Scrim */}
      <div onClick={onClose}
        style={{
          position: "absolute", inset: 0, zIndex: 70,
          background: open ? "rgba(0,0,0,0.5)" : "rgba(0,0,0,0)",
          backdropFilter: open ? "blur(4px)" : "blur(0)",
          WebkitBackdropFilter: open ? "blur(4px)" : "blur(0)",
          opacity: open ? 1 : 0,
          pointerEvents: open ? "auto" : "none",
          transition: "all 320ms var(--ease-out)",
        }} />
      {/* Sheet */}
      <div style={{
        position: "absolute", left: 0, right: 0, bottom: 0, zIndex: 80,
        transform: open ? "translateY(0)" : "translateY(100%)",
        transition: "transform 420ms var(--ease-out)",
        background: "var(--bg-elevated)",
        borderTop: "1px solid var(--card-border-strong)",
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: "28px 48px 48px",
        boxShadow: "0 -24px 64px rgba(0,0,0,0.6)",
      }}>
        <div style={{ maxWidth: 900, margin: "0 auto" }}>
        <div style={{ width: 52, height: 5, background: "var(--text-quaternary)", borderRadius: 999, margin: "0 auto 24px" }} />

        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 28 }}>
          <h2 style={{ margin: 0, fontSize: 32, fontWeight: 400, letterSpacing: "-0.02em" }}>Display</h2>
          <button onClick={onClose}
            style={{
              background: "var(--card)", border: "1px solid var(--card-border)",
              color: "var(--text)", borderRadius: 999, padding: "10px 22px",
              fontSize: 16, fontWeight: 500,
            }}>Done</button>
        </div>

        <div className="t-label" style={{ marginBottom: 16 }}>Theme</div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 16, marginBottom: 36 }}>
          {[
            { id: "dark",  label: "Dark",      sub: "Default", swatch: "linear-gradient(135deg, #000 0%, #0b0d10 100%)", accent: "#22e6ff" },
            { id: "light", label: "Light",     sub: "Day",     swatch: "linear-gradient(135deg, #f6f8fa 0%, #eef1f4 100%)", accent: "#0a84ff" },
            { id: "night", label: "Night Red", sub: "Driving", swatch: "linear-gradient(135deg, #000 0%, #0a0000 100%)", accent: "#ff2a2a" },
          ].map(t => {
            const active = theme === t.id;
            return (
              <button key={t.id} onClick={() => onTheme(t.id)}
                style={{
                  background: t.swatch,
                  border: `2px solid ${active ? t.accent : "var(--card-border)"}`,
                  borderRadius: 20, padding: 24,
                  display: "flex", flexDirection: "column", alignItems: "flex-start",
                  gap: 12, minHeight: 140,
                  color: t.id === "light" ? "#0b0f14" : t.accent,
                  cursor: "pointer",
                  boxShadow: active ? `0 0 32px ${t.accent}55` : "none",
                  transition: "all 240ms var(--ease-out)",
                }}>
                <div style={{
                  width: 16, height: 16, borderRadius: "50%",
                  background: t.accent, boxShadow: `0 0 16px ${t.accent}`,
                }} />
                <div style={{ marginTop: "auto" }}>
                  <div style={{ fontSize: 22, fontWeight: 500 }}>{t.label}</div>
                  <div style={{ fontSize: 13, opacity: 0.6, fontWeight: 500, letterSpacing: "0.08em", textTransform: "uppercase" }}>{t.sub}</div>
                </div>
              </button>
            );
          })}
        </div>

        <div className="t-label" style={{ marginBottom: 16 }}>Simulation Speed · {simSpeed.toFixed(1)}×</div>
        <input type="range" min="0" max="3" step="0.1" value={simSpeed}
          onChange={e => onSimSpeed(parseFloat(e.target.value))}
          style={{ width: "100%", accentColor: "var(--accent)" }} />
        </div>
      </div>
    </>
  );
}

Object.assign(window, { StatusBar, PageDots, ThemeFAB, ThemeSheet });
