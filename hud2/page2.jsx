// Page 2 — Engine Health
// 4 radial gauges across top, then O2 + fuel trim panels, then DTC list bottom.

// Stable card wrapper — defined at module scope so its identity persists
// across re-renders. (Inline definitions caused React to remount descendants.)
function P2Card({ children, style }) {
  return <div className="card" style={{ padding: 24, ...style }}>{children}</div>;
}

function Page2Engine({ data, dtcs }) {
  const { engineLoad, mapKpa, mafGs, o2b1, o2b2, ftStB1, ftLtB1, ftStB2, ftLtB2, ignAdv, catTemp } = data;
  // null/undefined means PID not supported by this vehicle
  const hasBank2  = o2b2 != null && ftStB2 != null && ftLtB2 != null;
  const hasCatTemp = catTemp != null;
  const Card = P2Card;

  return (
    <div className="page" style={{ padding: "84px 40px 92px" }}>
      <div style={{
        display: "grid",
        gridTemplateRows: "auto auto 1fr",
        gap: 24, height: "100%",
      }}>
        {/* TOP — 4 radial gauges */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 24 }}>
          <Card style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
            <RadialGauge size={300} value={engineLoad} min={0} max={100}
              label="Engine Load" unit="%" showZones zones={[0.65, 0.88]}
              warning={engineLoad > 75} />
          </Card>
          <Card style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
            <RadialGauge size={300} value={mapKpa} min={0} max={250}
              label="MAP" unit="kPa" decimals={0} />
          </Card>
          <Card style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
            <RadialGauge size={300} value={mafGs} min={0} max={50}
              label="MAF" unit="g/s" decimals={1}
              format={v => v.toFixed(1)} />
          </Card>
          <Card style={{ display: "flex", flexDirection: "column", alignItems: "center", position: "relative" }}>
            <RadialGauge size={300} value={hasCatTemp ? catTemp : 200} min={200} max={900}
              label="Catalyst" unit="°C" decimals={0}
              showZones zones={[0.6, 0.85]}
              warning={hasCatTemp && catTemp > 750}
              critical={hasCatTemp && catTemp > 850}
              format={hasCatTemp ? undefined : () => "—"} />
            {!hasCatTemp && <NAOverlay note="PID 0x3C not supported" />}
          </Card>
        </div>

        {/* MIDDLE — O2 sensors + Fuel trims + Ignition timing */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 24 }}>
          {/* O2 sensors */}
          <Card>
            <div className="t-label" style={{ marginBottom: 18 }}>O₂ Sensor Voltage</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
              <O2Trace label="Bank 1" value={o2b1} />
              <O2Trace label="Bank 2" value={hasBank2 ? o2b2 : null} />
            </div>
          </Card>

          {/* Fuel Trims */}
          <Card>
            <div className="t-label" style={{ marginBottom: 18 }}>Fuel Trim · %</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              <BarGauge width={520} height={36} value={ftStB1} min={-25} max={25}
                centerZero label="STFT · Bank 1" unit="%" decimals={1}
                format={v => (v > 0 ? "+" : "") + v.toFixed(1)} />
              <BarGauge width={520} height={36} value={ftLtB1} min={-25} max={25}
                centerZero label="LTFT · Bank 1" unit="%" decimals={1}
                format={v => (v > 0 ? "+" : "") + v.toFixed(1)} />
              {hasBank2 ? (
                <>
                  <BarGauge width={520} height={36} value={ftStB2} min={-25} max={25}
                    centerZero label="STFT · Bank 2" unit="%" decimals={1}
                    format={v => (v > 0 ? "+" : "") + v.toFixed(1)} />
                  <BarGauge width={520} height={36} value={ftLtB2} min={-25} max={25}
                    centerZero label="LTFT · Bank 2" unit="%" decimals={1}
                    format={v => (v > 0 ? "+" : "") + v.toFixed(1)} />
                </>
              ) : (
                <>
                  <BarNARow label="STFT · Bank 2" />
                  <BarNARow label="LTFT · Bank 2" />
                </>
              )}
            </div>
          </Card>

          {/* Ignition timing — visual */}
          <Card style={{ display: "flex", flexDirection: "column" }}>
            <div className="t-label" style={{ marginBottom: 18 }}>Ignition Timing</div>
            <div style={{ flex: 1, display: "grid", placeItems: "center" }}>
              <IgnitionAdvance value={ignAdv} />
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 12,
              fontSize: 14, color: "var(--text-tertiary)", letterSpacing: "0.08em", fontWeight: 500 }}>
              <span>BTDC · Advance</span>
              <span style={{ color: "var(--text)" }}>{ignAdv >= 0 ? "+" : ""}{ignAdv.toFixed(1)}°</span>
            </div>
          </Card>
        </div>

        {/* BOTTOM — DTC fault codes */}
        <Card style={{ display: "flex", flexDirection: "column", overflow: "hidden" }}>
          <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 18 }}>
            <div className="t-label">Diagnostic Trouble Codes</div>
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <Pill color="crit">{dtcs.filter(d => d.sev === "crit").length} Critical</Pill>
              <Pill color="warn">{dtcs.filter(d => d.sev === "warn").length} Pending</Pill>
              <Pill color="ok">{dtcs.filter(d => d.sev === "info").length} Stored</Pill>
            </div>
          </div>
          <div className="scroll" style={{
            flex: 1, overflowY: "auto", display: "flex", flexDirection: "column", gap: 8,
            paddingRight: 8,
          }}>
            {dtcs.map((d, i) => (
              <div key={i} style={{
                display: "grid",
                gridTemplateColumns: "120px 1fr 100px 140px",
                alignItems: "center", gap: 20,
                padding: "16px 20px",
                borderRadius: 12,
                background: "var(--hairline)",
                borderLeft: `4px solid ${d.sev === "crit" ? "var(--crit)" : d.sev === "warn" ? "var(--warn)" : "var(--text-quaternary)"}`,
              }}>
                <span style={{
                  fontFamily: "var(--font-mono)", fontSize: 22, fontWeight: 500,
                  color: d.sev === "crit" ? "var(--crit)" : d.sev === "warn" ? "var(--warn)" : "var(--text-secondary)",
                  letterSpacing: "0.04em",
                }}>{d.code}</span>
                <span style={{ fontSize: 18, color: "var(--text)", fontWeight: 400 }}>{d.desc}</span>
                <span style={{ fontSize: 13, color: "var(--text-tertiary)", letterSpacing: "0.1em", fontWeight: 600, textTransform: "uppercase" }}>{d.module}</span>
                <span style={{
                  fontSize: 12, fontWeight: 600, letterSpacing: "0.14em", textTransform: "uppercase",
                  color: d.sev === "crit" ? "var(--crit)" : d.sev === "warn" ? "var(--warn)" : "var(--text-tertiary)",
                  textAlign: "right",
                }}>{d.status}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

function Pill({ color = "ok", children }) {
  const palette = {
    crit: { bg: "rgba(255,59,48,0.16)", fg: "var(--crit)" },
    warn: { bg: "rgba(255,179,64,0.16)", fg: "var(--warn)" },
    ok:   { bg: "var(--accent-soft)",   fg: "var(--accent)" },
  }[color];
  return (
    <span style={{
      padding: "6px 14px", borderRadius: 999,
      fontSize: 13, fontWeight: 600, letterSpacing: "0.1em",
      background: palette.bg, color: palette.fg,
    }}>{children}</span>
  );
}

// Disabled-state placeholder for any single-row widget
function NAOverlay({ note }) {
  return (
    <div style={{
      position: "absolute", inset: 0, borderRadius: "inherit",
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      gap: 6, background: "rgba(0,0,0,0.45)", backdropFilter: "blur(2px)",
      WebkitBackdropFilter: "blur(2px)",
    }}>
      <span style={{
        fontSize: 13, fontWeight: 700, letterSpacing: "0.22em",
        color: "var(--text-tertiary)",
        padding: "6px 12px", borderRadius: 999,
        background: "var(--hairline)", border: "1px solid var(--card-border)",
      }}>NOT EQUIPPED</span>
      {note && <span style={{ fontSize: 11, color: "var(--text-quaternary)", letterSpacing: "0.14em", fontWeight: 600 }}>{note}</span>}
    </div>
  );
}

// Center-zero bar disabled placeholder
function BarNARow({ label }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 8, width: 520, opacity: 0.55 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
        <span className="t-label-sm">{label}</span>
        <span style={{
          fontSize: 13, fontWeight: 700, letterSpacing: "0.18em",
          color: "var(--text-tertiary)",
        }}>N/A — SINGLE BANK</span>
      </div>
      <svg width={520} height={36} viewBox="0 0 520 36">
        <rect x="0" y="7" width="520" height="22" rx="11" fill="var(--gauge-track)" />
        <line x1="260" y1="4" x2="260" y2="32" stroke="var(--text-quaternary)" strokeWidth="1" />
        <line x1="20" y1="18" x2="500" y2="18" stroke="var(--text-quaternary)" strokeWidth="1" strokeDasharray="4 6" />
      </svg>
    </div>
  );
}

// O2 sensor trace — animates continuously via local rAF, independent of telemetry rate
function O2Trace({ label, value }) {
  // null = PID not supported
  if (value == null) {
    return (
      <div>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6, alignItems: "baseline" }}>
          <span className="t-label-sm">{label}</span>
          <span style={{
            fontSize: 13, fontWeight: 700, letterSpacing: "0.18em",
            color: "var(--text-tertiary)",
          }}>NOT EQUIPPED</span>
        </div>
        <svg width={520} height={60} viewBox="0 0 520 60"
          style={{ background: "var(--hairline)", borderRadius: 8, opacity: 0.6 }}>
          <line x1="0" y1="33" x2="520" y2="33"
            stroke="var(--text-quaternary)" strokeDasharray="3,4" strokeWidth="1" />
          <text x="260" y="36" textAnchor="middle"
            fill="var(--text-quaternary)" fontSize="11" fontWeight="600"
            fontFamily="var(--font-display)" letterSpacing="0.18em">SINGLE-BANK ENGINE</text>
        </svg>
      </div>
    );
  }
  const v = Math.max(0, Math.min(1, value));
  const w = 520, h = 60;
  const polyRef = React.useRef(null);
  const valueRef = React.useRef(v);
  valueRef.current = v;
  React.useEffect(() => {
    let raf;
    const tick = () => {
      if (polyRef.current) {
        const points = [];
        const t = performance.now() * 0.001;
        const cur = valueRef.current;
        for (let x = 0; x <= w; x += 8) {
          const phase = (x / w) * Math.PI * 6 + t * 4;
          const wave = Math.sin(phase) * 0.18 + Math.sin(phase * 1.7) * 0.08;
          const yv = Math.max(0.05, Math.min(0.95, cur + wave));
          points.push(`${x},${h - yv * h}`);
        }
        polyRef.current.setAttribute("points", points.join(" "));
      }
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, []);
  // Build a fake waveform that oscillates around current value
  const points = [];
  for (let x = 0; x <= w; x += 8) {
    const phase = (x / w) * Math.PI * 6;
    const wave = Math.sin(phase) * 0.18 + Math.sin(phase * 1.7) * 0.08;
    const yv = Math.max(0.05, Math.min(0.95, v + wave));
    points.push(`${x},${h - yv * h}`);
  }
  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6, alignItems: "baseline" }}>
        <span className="t-label-sm">{label}</span>
        <span style={{
          fontFamily: "var(--font-display)", fontSize: 24, fontWeight: 350,
          color: "var(--text)", fontVariantNumeric: "tabular-nums", letterSpacing: "-0.01em",
        }}>{v.toFixed(2)}<span style={{ fontSize: 13, color: "var(--text-tertiary)", marginLeft: 4 }}>V</span></span>
      </div>
      <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`}
        style={{ background: "var(--hairline)", borderRadius: 8 }}>
        {/* center line at 0.45V (stoich) */}
        <line x1="0" y1={h * 0.55} x2={w} y2={h * 0.55}
          stroke="var(--text-quaternary)" strokeDasharray="3,4" strokeWidth="1" />
        <polyline ref={polyRef} points={points.join(" ")} fill="none"
          stroke="var(--accent)" strokeWidth="2"
          style={{ filter: "drop-shadow(0 0 6px var(--accent-glow))" }} />
      </svg>
    </div>
  );
}

// Ignition advance — 240° arc gauge so the active 0–35° BTDC range
// occupies a generous central sweep, with a small retard zone at the start.
function IgnitionAdvance({ value }) {
  return (
    <RadialGauge size={300} value={value} min={-10} max={50}
      label="BTDC" unit="°" decimals={1}
      format={v => (v >= 0 ? "+" : "") + v.toFixed(1)} />
  );
}

Object.assign(window, { Page2Engine });
