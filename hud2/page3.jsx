// Page 3 — Navigation + Trip
// Map area (stylized SVG) + overlay HUD + right column (compass, TPMS, trip)

function Page3Nav({ data, tpms, gpsLock = true, tpmsAvailable = true }) {
  const { gpsLat, gpsLon, gpsAlt, heading, speed, avgSpeed, tripKm, totalKm } = data;

  return (
    <div className="page" style={{ padding: "84px 40px 92px" }}>
      <div style={{
        display: "grid", gridTemplateColumns: "1fr 480px", gap: 24, height: "100%",
      }}>
        {/* MAP */}
        <div className="card" style={{ position: "relative", overflow: "hidden", padding: 0 }}>
          <StylizedMap heading={heading} gpsLat={gpsLat} gpsLon={gpsLon} />

          {/* Top-left overlay — coordinates */}
          <div style={{
            position: "absolute", top: 24, left: 24,
            display: "flex", flexDirection: "column", gap: 6,
            padding: "14px 18px", borderRadius: 14,
            background: "rgba(0,0,0,0.45)", backdropFilter: "blur(16px)",
            WebkitBackdropFilter: "blur(16px)",
            border: "1px solid var(--card-border)",
          }}>
            <span className="t-label-sm" style={{ color: "rgba(255,255,255,0.55)" }}>GPS Coordinates</span>
            <span style={{
              fontFamily: "var(--font-mono)", fontSize: 18, color: "#fff", fontWeight: 500,
              letterSpacing: "0.02em",
            }}>{gpsLat.toFixed(5)}° N · {gpsLon.toFixed(5)}° E</span>
          </div>

          {/* Top-right — current speed BIG */}
          <div style={{
            position: "absolute", top: 24, right: 24,
            display: "flex", flexDirection: "column", alignItems: "flex-end",
            padding: "14px 22px", borderRadius: 16,
            background: "rgba(0,0,0,0.45)", backdropFilter: "blur(16px)",
            WebkitBackdropFilter: "blur(16px)",
            border: "1px solid var(--card-border)",
          }}>
            <span className="t-label-sm" style={{ color: "rgba(255,255,255,0.55)" }}>Current</span>
            <span style={{
              fontFamily: "var(--font-display)", fontSize: 64, fontWeight: 250,
              color: "#fff", letterSpacing: "-0.03em", lineHeight: 1,
              fontVariantNumeric: "tabular-nums",
            }}>{Math.round(speed)}<span style={{ fontSize: 20, color: "rgba(255,255,255,0.6)", marginLeft: 6 }}>km/h</span></span>
          </div>

          {/* Bottom — current location panel (no routing/turn-by-turn) */}
          <div style={{
            position: "absolute", bottom: 24, left: 24, right: 24,
            display: "flex", alignItems: "center", gap: 24,
            padding: "20px 28px", borderRadius: 18,
            background: "rgba(0,0,0,0.55)", backdropFilter: "blur(20px)",
            WebkitBackdropFilter: "blur(20px)",
            border: "1px solid var(--card-border-strong)",
          }}>
            <div style={{
              width: 64, height: 64, borderRadius: 14,
              background: "var(--accent-soft)", color: "var(--accent)",
              display: "grid", placeItems: "center",
              boxShadow: gpsLock ? "0 0 24px var(--accent-glow)" : "none",
              opacity: gpsLock ? 1 : 0.5,
            }}>
              <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
                <path d="M12 2 C 7.6 2 4 5.6 4 10 c 0 5.5 8 12 8 12 s 8-6.5 8-12 c 0-4.4-3.6-8-8-8 z" />
                <circle cx="12" cy="10" r="3" />
              </svg>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
                <span style={{ fontSize: 13, color: "rgba(255,255,255,0.55)", letterSpacing: "0.16em", fontWeight: 600 }}>CURRENT LOCATION</span>
                <GPSPill />
              </div>
              {gpsLock ? (
                <div style={{
                  fontFamily: "var(--font-mono)", fontSize: 26, fontWeight: 500,
                  color: "#fff", letterSpacing: "0.02em", lineHeight: 1.1,
                }}>{gpsLat.toFixed(5)}° N · {gpsLon.toFixed(5)}° E</div>
              ) : (
                <div style={{ fontSize: 22, color: "var(--warn)", fontWeight: 500, letterSpacing: "-0.01em" }}
                  className="pulse-warn">Acquiring GPS signal…</div>
              )}
            </div>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 2 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <span style={{ fontSize: 13, color: "rgba(255,255,255,0.5)", letterSpacing: "0.14em", fontWeight: 600 }}>HEADING</span>
                <GPSPill />
              </div>
              <span style={{
                fontFamily: "var(--font-display)", fontSize: 32, fontWeight: 300, color: "#fff",
                letterSpacing: "-0.01em", fontVariantNumeric: "tabular-nums", lineHeight: 1,
              }}>{cardinalLabel(heading)} · {String(Math.round(heading)).padStart(3,"0")}°</span>
            </div>
          </div>
        </div>

        {/* RIGHT COLUMN */}
        <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
          {/* Compass */}
          <div className="card" style={{ padding: 24, display: "flex", alignItems: "center", gap: 24 }}>
            <CompassRose heading={heading} size={220} />
            <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 16 }}>
              <Stat label="Heading" value={cardinalLabel(heading)} sub={`${String(Math.round(heading)).padStart(3,"0")}°`} sourceBadge="GPS" />
              <Stat label="Altitude" value={Math.round(gpsAlt)} unit="m" sourceBadge="GPS" />
            </div>
          </div>

          {/* TPMS */}
          <div className="card" style={{ padding: 24 }}>
            <div className="t-label" style={{ marginBottom: 18 }}>Tire Pressure · TPMS</div>
            {tpmsAvailable ? (
              <TPMSCar tires={tpms} />
            ) : (
              <>
                <TPMSCar tires={null} />
                <div style={{
                  marginTop: 12, fontSize: 13, color: "var(--warn)",
                  letterSpacing: "0.1em", fontWeight: 600, textAlign: "center",
                }}>⚠ TPMS not available on this vehicle</div>
              </>
            )}
          </div>

          {/* Trip stats */}
          <div className="card" style={{ padding: 24, flex: 1 }}>
            <div className="t-label" style={{ marginBottom: 18 }}>Trip</div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 18 }}>
              <Stat label="Trip" value={tripKm.toFixed(1)} unit="km" big />
              <Stat label="Avg Speed" value={Math.round(avgSpeed)} unit="km/h" big />
              <Stat label="Odometer" value={totalKm.toLocaleString()} unit="km" />
              <Stat label="Drive Time" value={`02:14`} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function cardinalLabel(deg) {
  const dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
  return dirs[Math.round(deg / 45) % 8];
}

function Stat({ label, value, unit, sub, big = false, sourceBadge }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <span className="t-label-sm">{label}</span>
        {sourceBadge && <GPSPill label={sourceBadge} />}
      </div>
      <div style={{ display: "flex", alignItems: "baseline", gap: 6 }}>
        <span style={{
          fontFamily: "var(--font-display)",
          fontSize: big ? 44 : 32, fontWeight: 300,
          color: "var(--text)", letterSpacing: "-0.02em", lineHeight: 1,
          fontVariantNumeric: "tabular-nums",
        }}>{value}</span>
        {unit && <span style={{ fontSize: 16, color: "var(--text-tertiary)", fontWeight: 500 }}>{unit}</span>}
      </div>
      {sub && <span style={{ fontSize: 13, color: "var(--text-tertiary)", fontWeight: 500, letterSpacing: "0.06em" }}>{sub}</span>}
    </div>
  );
}

/* Tiny pill marking a value as sourced from GPS / Qt Positioning */
function GPSPill({ label = "GPS" }) {
  return (
    <span style={{
      fontSize: 10, fontWeight: 700, letterSpacing: "0.18em",
      padding: "2px 8px", borderRadius: 999,
      background: "var(--accent-soft)", color: "var(--accent)",
      border: "1px solid var(--accent-soft)",
      fontFamily: "var(--font-display)",
    }}>{label}</span>
  );
}

/* TPMS car-top view. tires=null → N/A state */
function TPMSCar({ tires }) {
  const w = 380, h = 280;
  const REC = 33, LOW = 28, HIGH = 38;
  const NA = tires == null;
  const status = (psi) => {
    if (psi <= LOW) return { color: "var(--crit)", label: "LOW" };
    if (psi >= HIGH) return { color: "var(--warn)", label: "HIGH" };
    return { color: "var(--ok)", label: "OK" };
  };
  const TireLabel = ({ x, y, psi, anchor = "start" }) => {
    if (NA) {
      return (
        <g>
          <text x={x} y={y}
            fill="var(--text-quaternary)" fontSize="32" fontFamily="var(--font-display)" fontWeight="350"
            textAnchor={anchor} style={{ fontVariantNumeric: "tabular-nums", letterSpacing: "-0.02em" }}>
            –.–
          </text>
          <text x={x} y={y + 18}
            fill="var(--text-quaternary)" fontSize="12" fontFamily="var(--font-display)" fontWeight="600"
            textAnchor={anchor} letterSpacing="0.16em">PSI · N/A</text>
        </g>
      );
    }
    const s = status(psi);
    return (
      <g>
        <text x={x} y={y}
          fill={s.color} fontSize="32" fontFamily="var(--font-display)" fontWeight="350"
          textAnchor={anchor} style={{ fontVariantNumeric: "tabular-nums", letterSpacing: "-0.02em" }}>
          {psi.toFixed(1)}
        </text>
        <text x={x} y={y + 18}
          fill="var(--text-tertiary)" fontSize="12" fontFamily="var(--font-display)" fontWeight="600"
          textAnchor={anchor} letterSpacing="0.16em">
          PSI · {s.label}
        </text>
      </g>
    );
  };
  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} style={{ display: "block", margin: "0 auto", opacity: NA ? 0.55 : 1 }}>
      <g transform="translate(120 30)">
        <rect x="0" y="0" width="140" height="220" rx="44"
          fill="var(--hairline)" stroke="var(--card-border-strong)" strokeWidth="1.5" />
        <path d="M 22 36 Q 70 22 118 36 L 110 70 L 30 70 Z" fill="var(--card-border)" opacity="0.5" />
        <path d="M 22 184 Q 70 198 118 184 L 110 150 L 30 150 Z" fill="var(--card-border)" opacity="0.5" />
        <rect x="30" y="78" width="80" height="64" rx="6" fill="none" stroke="var(--card-border)" />
        {[
          { x: -18, y: 24,  psi: NA ? null : tires.fl },
          { x: 142, y: 24,  psi: NA ? null : tires.fr },
          { x: -18, y: 168, psi: NA ? null : tires.rl },
          { x: 142, y: 168, psi: NA ? null : tires.rr },
        ].map((t, i) => {
          if (NA) {
            return <rect key={i} x={t.x} y={t.y} width="16" height="28" rx="4" fill="var(--text-quaternary)" />;
          }
          const s = status(t.psi);
          return (
            <rect key={i} x={t.x} y={t.y} width="16" height="28" rx="4"
              fill={s.color}
              style={{ filter: t.psi <= LOW ? "drop-shadow(0 0 8px var(--crit-glow))" : "none" }}
              className={t.psi <= LOW ? "pulse-warn" : ""} />
          );
        })}
      </g>
      <TireLabel x={100} y={62} psi={NA ? null : tires.fl} anchor="end" />
      <TireLabel x={280} y={62} psi={NA ? null : tires.fr} anchor="start" />
      <TireLabel x={100} y={222} psi={NA ? null : tires.rl} anchor="end" />
      <TireLabel x={280} y={222} psi={NA ? null : tires.rr} anchor="start" />
    </svg>
  );
}

/* Stylized map — fake but coherent. Roads, blocks, water, route line. */
function StylizedMap({ heading, gpsLat = 0, gpsLon = 0 }) {
  // Subtle pan illusion: small fractional movements of lat/lon translate the map,
  // creating the feeling that the world is moving while the ego marker stays fixed.
  // We use sub-degree fractional parts mapped into a small px range and clamp.
  const dx = ((gpsLon * 11000) % 240) - 120;
  const dy = ((gpsLat * 11000) % 240) - 120;
  return (
    <div style={{ width: "100%", height: "100%", overflow: "hidden", position: "absolute", inset: 0 }}>
      <svg width="100%" height="100%" viewBox="0 0 1500 1100" preserveAspectRatio="xMidYMid slice"
        style={{
          display: "block",
          background: "var(--map-bg)",
          transform: `translate(${dx.toFixed(1)}px, ${dy.toFixed(1)}px) scale(1.08)`,
          transformOrigin: "center center",
          transition: "transform 800ms linear",
        }}>
      <defs>
        <pattern id="block" patternUnits="userSpaceOnUse" width="160" height="160" patternTransform="rotate(8)">
          <rect width="160" height="160" fill="var(--map-land)" />
          <rect x="20" y="20" width="60" height="50" rx="2" fill="var(--map-bg)" opacity="0.6" />
          <rect x="90" y="30" width="50" height="80" rx="2" fill="var(--map-bg)" opacity="0.4" />
          <rect x="20" y="90" width="40" height="40" rx="2" fill="var(--map-bg)" opacity="0.5" />
          <rect x="80" y="120" width="60" height="30" rx="2" fill="var(--map-bg)" opacity="0.3" />
        </pattern>
      </defs>
      <rect width="1500" height="1100" fill="url(#block)" />
      {/* Water */}
      <path d="M 0 800 Q 300 760 600 820 T 1200 800 L 1500 820 L 1500 1100 L 0 1100 Z"
        fill="var(--map-water)" />
      <path d="M 0 800 Q 300 760 600 820 T 1200 800 L 1500 820"
        fill="none" stroke="var(--map-water)" strokeWidth="3" opacity="0.8" />
      {/* Major roads */}
      <g stroke="var(--map-road-major)" strokeLinecap="round" fill="none">
        <path d="M -50 200 L 1550 380" strokeWidth="22" />
        <path d="M -50 600 L 1550 580" strokeWidth="18" />
        <path d="M 400 -50 L 480 1150" strokeWidth="20" />
        <path d="M 1100 -50 L 980 1150" strokeWidth="16" />
      </g>
      <g stroke="var(--map-road)" strokeLinecap="round" fill="none">
        <path d="M -50 200 L 1550 380" strokeWidth="14" />
        <path d="M -50 600 L 1550 580" strokeWidth="12" />
        <path d="M 400 -50 L 480 1150" strokeWidth="13" />
        <path d="M 1100 -50 L 980 1150" strokeWidth="11" />
      </g>
      {/* Minor roads */}
      <g stroke="var(--map-road)" strokeWidth="6" strokeLinecap="round" fill="none" opacity="0.7">
        <path d="M 200 -20 L 240 720" />
        <path d="M 700 -20 L 720 720" />
        <path d="M 1300 -20 L 1280 720" />
        <path d="M -20 350 L 1520 480" />
        <path d="M -20 480 L 1520 700" />
      </g>
      {/* Route line and destination pin removed — app does not provide routing */}
      {/* Ego-vehicle position */}
      <g transform={`translate(700 540) rotate(${heading - 45})`}>
        <circle r="38" fill="var(--accent)" opacity="0.18" />
        <circle r="22" fill="var(--accent)" opacity="0.32" />
        <polygon points="0,-18 14,14 0,8 -14,14"
          fill="var(--accent)" stroke="#fff" strokeWidth="2"
          style={{ filter: "drop-shadow(0 0 12px var(--accent-glow))" }} />
      </g>
      {/* Destination pin removed — no routing */}
    </svg>
    </div>
  );
}

Object.assign(window, { Page3Nav });
