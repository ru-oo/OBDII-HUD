// Page 1 — Driving Core
// Layout: hero speedo center; RPM left of speedo; right column has fuel,
// coolant temp, fuel %; bottom strip: gear, throttle, battery, ambient.

function Page1Driving({ data }) {
  const { speed, rpm, coolantC, fuel, throttle, batteryV, ambientC, intakeC, engineLoad } = data;

  // Battery status from raw voltage (OBD PID 0x42 — voltage only)
  let batStatus, batColor, batBg;
  if (batteryV > 15) {
    batStatus = "HIGH"; batColor = "var(--crit)"; batBg = "rgba(255,59,48,0.16)";
  } else if (batteryV >= 13.5 && batteryV <= 14.8) {
    batStatus = "OK"; batColor = "var(--ok)"; batBg = "rgba(48,209,88,0.16)";
  } else if (batteryV < 12.4) {
    batStatus = "LOW"; batColor = "var(--warn)"; batBg = "rgba(255,179,64,0.16)";
  } else {
    batStatus = "OK"; batColor = "var(--text-secondary)"; batBg = "var(--hairline)";
  }

  return (
    <div className="page" style={{ padding: "84px 40px 92px" }}>
      <div style={{
        display: "grid",
        gridTemplateColumns: "180px 720px 1fr 320px",
        gridTemplateRows: "auto 1fr auto",
        gap: 24,
        height: "100%",
      }}>
        {/* INTAKE AIR TEMP — left column (OBD PID 0x0F) */}
        <div className="card" style={{
          gridColumn: "1", gridRow: "1 / span 2",
          display: "flex", flexDirection: "column", alignItems: "center",
          justifyContent: "center", padding: 20,
        }}>
          <RadialGauge size={220} value={intakeC} min={-20} max={80}
            label="Intake Air" unit="°C" decimals={0}
            showZones zones={[0.6, 0.85]}
            warning={intakeC > 60} critical={intakeC > 70} />
          <div style={{
            marginTop: 8, fontSize: 11, color: "var(--text-tertiary)",
            letterSpacing: "0.14em", fontWeight: 500, textAlign: "center",
          }}>PID 0x0F</div>
        </div>

        {/* RPM — second column top? No: HERO speedo spans col 2 across 2 rows */}
        <div style={{
          gridColumn: "2", gridRow: "1 / span 2",
          display: "flex", alignItems: "center", justifyContent: "center",
          position: "relative",
        }}>
          {/* outer halo */}
          <div style={{
            position: "absolute", width: 920, height: 920, borderRadius: "50%",
            background: "radial-gradient(circle, var(--accent-soft) 0%, transparent 60%)",
            opacity: 0.5, pointerEvents: "none",
          }} />
          <ArcGauge size={920} value={speed} min={0} max={240}
            ticks={13} minorTicksPerMajor={4}
            unit="km/h" label="Speed"
            subDigit={`IAT: ${Math.round(intakeC)}°C`}
            thickness={20} />
        </div>

        {/* RPM — right of speedo, with engine-load bar beneath */}
        <div style={{ gridColumn: "3", gridRow: "1 / span 2",
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
          gap: 16,
        }}>
          <ArcGauge size={520} value={rpm} min={0} max={8000}
            ticks={9} minorTicksPerMajor={4}
            redlineFrom={6000}
            label="RPM × 1000" unit=""
            primaryDigit={(rpm / 1000).toFixed(1)}
            subDigit={`${Math.round(rpm)} rpm`}
            thickness={14}
            centerStyle="speedo" />
          <div className="card" style={{ padding: "20px 28px", width: 520 }}>
            <BarGauge width={464} height={28} value={engineLoad} min={0} max={100}
              label="Engine Load" unit="%" />
          </div>
        </div>

        {/* RIGHT column: Fuel + Coolant stack */}
        <div style={{
          gridColumn: "4", gridRow: "1 / span 2",
          display: "flex", flexDirection: "column", gap: 24,
        }}>
          {/* Coolant */}
          <div className="card" style={{
            padding: 24, display: "flex", flexDirection: "column", alignItems: "center",
            flex: 1,
          }}>
            <RadialGauge size={260} value={coolantC} min={40} max={130}
              label="Coolant" unit="°C"
              showZones zones={[0.55, 0.85]}
              warning={coolantC > 105} critical={coolantC > 115} />
            <div style={{
              marginTop: 8, fontSize: 13, color: "var(--text-tertiary)",
              letterSpacing: "0.12em", fontWeight: 500,
            }}>NORMAL · 40–105°C</div>
          </div>

          {/* Fuel */}
          <div className={`card ${fuel <= 15 ? "pulse-crit" : ""}`} style={{
            padding: 24, display: "flex", alignItems: "center", justifyContent: "center",
            flex: 1,
            borderColor: fuel <= 15 ? "var(--crit)" : "var(--card-border)",
          }}>
            <FuelGauge value={fuel} height={220} lowThreshold={15} />
          </div>
        </div>

        {/* BOTTOM STRIP — throttle, battery, ambient */}
        <div style={{
          gridColumn: "1 / -1", gridRow: "3",
          display: "grid", gridTemplateColumns: "1.6fr 1fr 1fr", gap: 24,
        }}>
          {/* Throttle */}
          <div className="card" style={{ padding: "28px 32px" }}>
            <BarGauge
              width={760} height={36}
              value={throttle} min={0} max={100}
              label="Throttle Position" unit="%" />
            <div style={{
              marginTop: 14, display: "flex", justifyContent: "space-between",
              fontSize: 12, color: "var(--text-quaternary)", letterSpacing: "0.16em", fontWeight: 600,
            }}>
              <span>0</span><span>25</span><span>50</span><span>75</span><span>WOT</span>
            </div>
          </div>

          {/* Battery */}
          <div className="card" style={{ padding: "28px 32px",
            display: "flex", flexDirection: "column", justifyContent: "center", gap: 8 }}>
            <span className="t-label-sm">Battery</span>
            <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
              <span style={{
                fontFamily: "var(--font-display)", fontSize: 64, fontWeight: 250,
                letterSpacing: "-0.02em", color: "var(--text)",
                fontVariantNumeric: "tabular-nums", lineHeight: 1,
              }}>{batteryV.toFixed(1)}</span>
              <span style={{ fontSize: 22, color: "var(--text-tertiary)", fontWeight: 500 }}>V</span>
              <span style={{
                marginLeft: "auto", fontSize: 14, padding: "6px 14px",
                borderRadius: 999, fontWeight: 600, letterSpacing: "0.1em",
                background: batBg, color: batColor,
              }}>{batStatus}</span>
            </div>
            <div style={{
              fontSize: 13, color: "var(--text-tertiary)", letterSpacing: "0.06em", fontWeight: 500,
            }}>13.5–14.8 V nominal</div>
          </div>

          {/* Ambient */}
          <div className="card" style={{ padding: "28px 32px",
            display: "flex", flexDirection: "column", justifyContent: "center", gap: 8 }}>
            <span className="t-label-sm">Ambient Air</span>
            <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
              <span style={{
                fontFamily: "var(--font-display)", fontSize: 64, fontWeight: 250,
                letterSpacing: "-0.02em", color: "var(--text)",
                fontVariantNumeric: "tabular-nums", lineHeight: 1,
              }}>{ambientC.toFixed(1)}</span>
              <span style={{ fontSize: 22, color: "var(--text-tertiary)", fontWeight: 500 }}>°C</span>
            </div>
            <div style={{
              fontSize: 13, letterSpacing: "0.06em", fontWeight: 500,
              color: ambientC < 4 ? "var(--crit)" : "var(--text-tertiary)",
            }}>{ambientC < 4 ? "⚠ ICE RISK" : "Normal"}</div>
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { Page1Driving });
