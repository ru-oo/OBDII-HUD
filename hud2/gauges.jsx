// Gauge primitives — pure SVG, theme-aware via currentColor / CSS vars.
// All gauges are sized via the `size` prop and scale with their container.

const { useId } = React;

/* ───────────────────────────────────────────────────────────────
   ArcGauge — main analog speed/RPM gauge.
   Sweeps from -135° to +135° (270° total).
─────────────────────────────────────────────────────────────── */
function ArcGauge({
  size = 720,
  value = 0,
  min = 0,
  max = 240,
  ticks = 13,
  minorTicksPerMajor = 4,
  redlineFrom = null,        // e.g. 6000 on RPM
  label = "",
  unit = "",
  primaryDigit = null,        // big center number; defaults to round(value)
  subDigit = null,            // small under-line text
  warning = false,
  thickness = 18,
  strokeMode = "gradient",    // "gradient" | "solid"
  centerStyle = "speedo",     // "speedo" | "minimal"
}) {
  const id = useId().replace(/:/g, "");
  const cx = size / 2, cy = size / 2;
  const r = size / 2 - thickness * 1.6;
  const startA = -225;        // degrees, top-left
  const endA = 45;            // top-right
  const sweep = endA - startA; // 270

  const pct = Math.max(0, Math.min(1, (value - min) / (max - min)));
  const valA = startA + sweep * pct;

  const polar = (a, rad = r) => {
    const rr = (a * Math.PI) / 180;
    return [cx + Math.cos(rr) * rad, cy + Math.sin(rr) * rad];
  };
  const arcPath = (a1, a2, rad = r) => {
    const [x1, y1] = polar(a1, rad);
    const [x2, y2] = polar(a2, rad);
    const large = a2 - a1 > 180 ? 1 : 0;
    return `M ${x1} ${y1} A ${rad} ${rad} 0 ${large} 1 ${x2} ${y2}`;
  };

  // Tick marks
  const tickEls = [];
  const totalTicks = (ticks - 1) * minorTicksPerMajor + ticks;
  for (let i = 0; i < totalTicks; i++) {
    const t = i / (totalTicks - 1);
    const a = startA + sweep * t;
    const isMajor = i % (minorTicksPerMajor + 1) === 0;
    const tickLen = isMajor ? thickness * 1.4 : thickness * 0.5;
    const r1 = r - thickness * 0.7 - tickLen;
    const r2 = r - thickness * 0.7;
    const [x1, y1] = polar(a, r1);
    const [x2, y2] = polar(a, r2);
    const inRedline = redlineFrom != null && (min + (max - min) * t) >= redlineFrom;
    tickEls.push(
      <line key={i} x1={x1} y1={y1} x2={x2} y2={y2}
        stroke={inRedline ? "var(--crit)" : (isMajor ? "var(--text-secondary)" : "var(--text-quaternary)")}
        strokeWidth={isMajor ? 2 : 1.2}
        strokeLinecap="round"
        opacity={isMajor ? 0.95 : 0.7} />
    );
  }

  // Major numeric labels
  const numEls = [];
  for (let i = 0; i < ticks; i++) {
    const t = i / (ticks - 1);
    const a = startA + sweep * t;
    const [tx, ty] = polar(a, r - thickness * 1.4 - thickness * 1.7);
    const v = Math.round(min + (max - min) * t);
    const inRedline = redlineFrom != null && v >= redlineFrom;
    numEls.push(
      <text key={i} x={tx} y={ty}
        fill={inRedline ? "var(--crit)" : "var(--text-secondary)"}
        fontSize={size * 0.038}
        fontFamily="var(--font-display)"
        fontWeight="500"
        textAnchor="middle"
        dominantBaseline="central"
        style={{ fontVariantNumeric: "tabular-nums" }}>
        {v >= 1000 ? `${(v/1000).toFixed(v % 1000 === 0 ? 0 : 1)}` : v}
      </text>
    );
  }

  // Redline arc
  let redArc = null;
  if (redlineFrom != null) {
    const rt = (redlineFrom - min) / (max - min);
    const rA = startA + sweep * rt;
    redArc = (
      <path d={arcPath(rA, endA, r - thickness * 0.7 - thickness * 0.1)}
        fill="none" stroke="var(--crit)" strokeWidth={thickness * 0.18}
        strokeLinecap="round" opacity="0.85" />
    );
  }

  const display = primaryDigit != null ? primaryDigit : Math.round(value);

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ display: "block" }}>
      <defs>
        <linearGradient id={`grad-${id}`} x1="0" y1="1" x2="1" y2="0">
          <stop offset="0%"   stopColor="var(--gauge-fill-2)" />
          <stop offset="55%"  stopColor="var(--gauge-fill-1)" />
          <stop offset="85%"  stopColor="var(--gauge-fill-3)" />
          <stop offset="100%" stopColor="var(--gauge-fill-4)" />
        </linearGradient>
        <filter id={`glow-${id}`} x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation={size * 0.012} result="b" />
          <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
      </defs>

      {/* Track */}
      <path d={arcPath(startA, endA)} fill="none"
        stroke="var(--gauge-track)" strokeWidth={thickness} strokeLinecap="round" />

      {/* Redline overlay on track */}
      {redArc}

      {/* Ticks + numbers */}
      <g>{tickEls}</g>
      <g>{numEls}</g>

      {/* Active fill */}
      <path d={arcPath(startA, valA)} fill="none"
        stroke={strokeMode === "gradient" ? `url(#grad-${id})` : (warning ? "var(--crit)" : "var(--accent)")}
        strokeWidth={thickness}
        strokeLinecap="round"
        filter={`url(#glow-${id})`}
        style={{ transition: "stroke 400ms var(--ease-out)" }} />

      {/* Inner ring */}
      <circle cx={cx} cy={cy} r={r - thickness * 1.7}
        fill="none" stroke="var(--hairline)" strokeWidth="1" />

      {/* Center readout */}
      {centerStyle === "speedo" && (
        <>
          <text x={cx} y={cy - size * 0.02}
            fill="var(--text)"
            fontSize={size * 0.28}
            fontFamily="var(--font-display)"
            fontWeight="200"
            textAnchor="middle"
            dominantBaseline="central"
            style={{ fontVariantNumeric: "tabular-nums", letterSpacing: "-0.04em" }}>
            {display}
          </text>
          {unit && (
            <text x={cx} y={cy + size * 0.14}
              fill="var(--text-tertiary)"
              fontSize={size * 0.038}
              fontFamily="var(--font-display)"
              fontWeight="600"
              textAnchor="middle"
              letterSpacing="0.18em">
              {unit.toUpperCase()}
            </text>
          )}
          {label && (
            <text x={cx} y={cy - size * 0.22}
              fill="var(--text-tertiary)"
              fontSize={size * 0.032}
              fontFamily="var(--font-display)"
              fontWeight="600"
              textAnchor="middle"
              letterSpacing="0.2em">
              {label.toUpperCase()}
            </text>
          )}
          {subDigit && (
            <text x={cx} y={cy + size * 0.21}
              fill="var(--text-secondary)"
              fontSize={size * 0.034}
              fontFamily="var(--font-mono)"
              fontWeight="500"
              textAnchor="middle"
              style={{ fontVariantNumeric: "tabular-nums" }}>
              {subDigit}
            </text>
          )}
        </>
      )}
      {centerStyle === "minimal" && (
        <>
          <text x={cx} y={cy + size * 0.01}
            fill="var(--text)"
            fontSize={size * 0.18}
            fontFamily="var(--font-display)"
            fontWeight="250"
            textAnchor="middle"
            dominantBaseline="central"
            style={{ fontVariantNumeric: "tabular-nums", letterSpacing: "-0.03em" }}>
            {display}
          </text>
          {label && (
            <text x={cx} y={cy + size * 0.16}
              fill="var(--text-tertiary)"
              fontSize={size * 0.032}
              fontFamily="var(--font-display)"
              fontWeight="600"
              textAnchor="middle"
              letterSpacing="0.18em">
              {label.toUpperCase()}{unit ? ` · ${unit.toUpperCase()}` : ""}
            </text>
          )}
        </>
      )}
    </svg>
  );
}

/* ───────────────────────────────────────────────────────────────
   RadialGauge — compact partial-arc dial. Used for small gauges:
   coolant, fuel, engine load, MAP, MAF, catalyst, etc.
─────────────────────────────────────────────────────────────── */
function RadialGauge({
  size = 280,
  value = 0,
  min = 0,
  max = 100,
  label = "",
  unit = "",
  format = (v) => Math.round(v),
  warning = false,
  critical = false,
  thickness = 14,
  showZones = false,           // green/yellow/red track
  zones = [0.6, 0.85],         // green to 60%, yellow to 85%, red after
  decimals = 0,
}) {
  const id = useId().replace(/:/g, "");
  const cx = size / 2, cy = size / 2;
  const r = size / 2 - thickness * 1.4;
  const startA = -210, endA = 30;
  const sweep = endA - startA;
  const pct = Math.max(0, Math.min(1, (value - min) / (max - min)));
  const valA = startA + sweep * pct;

  const polar = (a, rad = r) => {
    const rr = (a * Math.PI) / 180;
    return [cx + Math.cos(rr) * rad, cy + Math.sin(rr) * rad];
  };
  const arcPath = (a1, a2, rad = r) => {
    const [x1, y1] = polar(a1, rad);
    const [x2, y2] = polar(a2, rad);
    const large = a2 - a1 > 180 ? 1 : 0;
    return `M ${x1} ${y1} A ${rad} ${rad} 0 ${large} 1 ${x2} ${y2}`;
  };

  const fillStroke = critical ? "var(--crit)" : warning ? "var(--warn)" : `url(#rgrad-${id})`;
  const formatted = typeof format === "function" ? format(value) : value.toFixed(decimals);

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ display: "block" }}>
      <defs>
        <linearGradient id={`rgrad-${id}`} x1="0" y1="1" x2="1" y2="0">
          <stop offset="0%"   stopColor="var(--gauge-fill-2)" />
          <stop offset="60%"  stopColor="var(--gauge-fill-1)" />
          <stop offset="100%" stopColor="var(--gauge-fill-3)" />
        </linearGradient>
        <filter id={`rglow-${id}`} x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation={size * 0.014} result="b" />
          <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
      </defs>

      {/* Track or zoned track */}
      {!showZones && (
        <path d={arcPath(startA, endA)} fill="none"
          stroke="var(--gauge-track)" strokeWidth={thickness} strokeLinecap="round" />
      )}
      {showZones && (
        <>
          <path d={arcPath(startA, startA + sweep * zones[0])} fill="none"
            stroke="var(--gauge-fill-2)" strokeOpacity="0.18" strokeWidth={thickness} strokeLinecap="butt" />
          <path d={arcPath(startA + sweep * zones[0], startA + sweep * zones[1])} fill="none"
            stroke="var(--gauge-fill-3)" strokeOpacity="0.20" strokeWidth={thickness} strokeLinecap="butt" />
          <path d={arcPath(startA + sweep * zones[1], endA)} fill="none"
            stroke="var(--crit)" strokeOpacity="0.24" strokeWidth={thickness} strokeLinecap="butt" />
        </>
      )}

      {/* Active */}
      <path d={arcPath(startA, valA)} fill="none"
        stroke={fillStroke}
        strokeWidth={thickness}
        strokeLinecap="round"
        filter={`url(#rglow-${id})`}
        style={{ transition: "stroke 300ms var(--ease-out)" }} />

      {/* Center value */}
      <text x={cx} y={cy - size * 0.02}
        fill={critical ? "var(--crit)" : "var(--text)"}
        fontSize={size * 0.26}
        fontFamily="var(--font-display)"
        fontWeight="250"
        textAnchor="middle"
        dominantBaseline="central"
        style={{ fontVariantNumeric: "tabular-nums", letterSpacing: "-0.03em" }}>
        {formatted}
      </text>
      {unit && (
        <text x={cx} y={cy + size * 0.13}
          fill="var(--text-tertiary)"
          fontSize={size * 0.06}
          fontFamily="var(--font-display)"
          fontWeight="500"
          textAnchor="middle"
          letterSpacing="0.06em">
          {unit}
        </text>
      )}
      {label && (
        <text x={cx} y={cy + size * 0.32}
          fill="var(--text-tertiary)"
          fontSize={size * 0.05}
          fontFamily="var(--font-display)"
          fontWeight="600"
          textAnchor="middle"
          letterSpacing="0.18em">
          {label.toUpperCase()}
        </text>
      )}
    </svg>
  );
}

/* ───────────────────────────────────────────────────────────────
   BarGauge — horizontal or vertical bar. Used for throttle, fuel
   trim, etc. Supports center-zero (for trims) and zones.
─────────────────────────────────────────────────────────────── */
function BarGauge({
  width = 400,
  height = 40,
  value = 0,
  min = 0,
  max = 100,
  centerZero = false,
  label = "",
  unit = "",
  format = (v) => Math.round(v),
  showTrack = true,
  warning = false,
  critical = false,
  thickness,                 // bar thickness; defaults to height * 0.5
  decimals = 0,
}) {
  const id = useId().replace(/:/g, "");
  const t = thickness ?? height * 0.42;
  const trackY = (height - t) / 2;
  const fmt = typeof format === "function" ? format(value) : value.toFixed(decimals);

  let leftPct, fillW;
  if (centerZero) {
    const half = (max - min) / 2;
    const center = min + half;
    const v = Math.max(min, Math.min(max, value));
    if (v >= center) {
      leftPct = 0.5;
      fillW = ((v - center) / half) * width / 2;
    } else {
      leftPct = (1 - (center - v) / half) * 0.5;
      fillW = width / 2 - leftPct * width;
    }
  } else {
    leftPct = 0;
    fillW = ((Math.max(min, Math.min(max, value)) - min) / (max - min)) * width;
  }
  const fillX = leftPct * width;

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 8, width }}>
      {label && (
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
          <span className="t-label-sm">{label}</span>
          <span style={{
            fontFamily: "var(--font-display)",
            fontVariantNumeric: "tabular-nums",
            fontSize: 28, fontWeight: 350, letterSpacing: "-0.01em",
            color: critical ? "var(--crit)" : warning ? "var(--warn)" : "var(--text)"
          }}>
            {fmt}{unit ? <span style={{ fontSize: 16, color: "var(--text-tertiary)", marginLeft: 4 }}>{unit}</span> : null}
          </span>
        </div>
      )}
      <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`}>
        <defs>
          <linearGradient id={`bgrad-${id}`} x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%"   stopColor="var(--gauge-fill-2)" />
            <stop offset="60%"  stopColor="var(--gauge-fill-1)" />
            <stop offset="100%" stopColor="var(--gauge-fill-3)" />
          </linearGradient>
        </defs>
        {showTrack && (
          <rect x="0" y={trackY} width={width} height={t} rx={t/2}
            fill="var(--gauge-track)" />
        )}
        {centerZero && (
          <line x1={width/2} y1={trackY - 3} x2={width/2} y2={trackY + t + 3}
            stroke="var(--text-quaternary)" strokeWidth="1" />
        )}
        <rect x={fillX} y={trackY} width={Math.max(0, fillW)} height={t} rx={t/2}
          fill={critical ? "var(--crit)" : warning ? "var(--warn)" : `url(#bgrad-${id})`}
          style={{ transition: "all 300ms var(--ease-out)" }} />
      </svg>
    </div>
  );
}

/* ───────────────────────────────────────────────────────────────
   FuelGauge — vertical bar with low-fuel pulsing glow.
─────────────────────────────────────────────────────────────── */
function FuelGauge({ value = 0, height = 240, lowThreshold = 15 }) {
  const id = useId().replace(/:/g, "");
  const w = 60;
  const pct = Math.max(0, Math.min(100, value)) / 100;
  const fillH = pct * (height - 8);
  const low = value <= lowThreshold;

  return (
    <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
      <svg width={w + 28} height={height} viewBox={`-28 0 ${w + 28} ${height}`} style={{ overflow: "visible" }}>
        <defs>
          <linearGradient id={`fgrad-${id}`} x1="0" y1="1" x2="0" y2="0">
            <stop offset="0%" stopColor="var(--crit)" />
            <stop offset="20%" stopColor="var(--gauge-fill-3)" />
            <stop offset="50%" stopColor="var(--gauge-fill-2)" />
            <stop offset="100%" stopColor="var(--gauge-fill-1)" />
          </linearGradient>
        </defs>
        <rect x="0" y="0" width={w} height={height} rx="14"
          fill="var(--gauge-track)" />
        <rect x="4" y={height - 4 - fillH} width={w - 8} height={fillH} rx="10"
          fill={low ? "var(--crit)" : `url(#fgrad-${id})`}
          style={{
            filter: low ? "drop-shadow(0 0 18px var(--crit-glow))" : "none",
            transition: "all 400ms var(--ease-out)"
          }}
          className={low ? "pulse-warn" : ""} />
        {/* Tick marks + labels: F (top) / 1/2 (mid) / E (bottom) */}
        {[
          { t: 1,   l: "F" },
          { t: 0.5, l: "\u00bd" },
          { t: 0,   l: "E" },
        ].map((m, i) => (
          <g key={i}>
            <line x1={-10} y1={height - height * m.t} x2={-2} y2={height - height * m.t}
              stroke="var(--text-tertiary)" strokeWidth="1.5" />
            <text x={-14} y={height - height * m.t}
              fill={m.l === "E" && low ? "var(--crit)" : "var(--text-secondary)"}
              fontSize="13" fontWeight="600"
              fontFamily="var(--font-display)" letterSpacing="0.04em"
              textAnchor="end" dominantBaseline="central">{m.l}</text>
          </g>
        ))}
      </svg>
      <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
        <span className="t-label-sm">Fuel</span>
        <span style={{
          fontFamily: "var(--font-display)", fontSize: 56, fontWeight: 250,
          letterSpacing: "-0.02em", color: low ? "var(--crit)" : "var(--text)",
          fontVariantNumeric: "tabular-nums", lineHeight: 1
        }}>
          {Math.round(value)}<span style={{ fontSize: 24, color: "var(--text-tertiary)", marginLeft: 4 }}>%</span>
        </span>
        {low && (
          <span style={{ fontSize: 14, fontWeight: 600, color: "var(--crit)", letterSpacing: "0.12em" }}
            className="pulse-warn">
            ⚠ LOW FUEL
          </span>
        )}
      </div>
    </div>
  );
}

/* ───────────────────────────────────────────────────────────────
   GearIndicator — P R N D 1-6 column.
─────────────────────────────────────────────────────────────── */
function GearIndicator({ gear = "D" }) {
  const gears = ["P", "R", "N", "D", "1", "2", "3", "4", "5", "6"];
  return (
    <div style={{
      display: "flex", flexDirection: "column", alignItems: "center",
      gap: 14, padding: "20px 16px",
    }}>
      <div className="t-label-sm" style={{ marginBottom: 4 }}>Gear</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 10, alignItems: "center" }}>
        {gears.map(g => {
          const active = g === String(gear);
          return (
            <div key={g} style={{
              fontFamily: "var(--font-display)",
              fontSize: active ? 56 : 22,
              fontWeight: active ? 300 : 500,
              color: active ? "var(--accent)" : "var(--text-quaternary)",
              letterSpacing: "0.04em",
              lineHeight: 1,
              textShadow: active ? "0 0 24px var(--accent-glow)" : "none",
              transition: "all 240ms var(--ease-out)",
            }}>{g}</div>
          );
        })}
      </div>
    </div>
  );
}

/* ───────────────────────────────────────────────────────────────
   CompassRose — heading indicator.
─────────────────────────────────────────────────────────────── */
function CompassRose({ heading = 0, size = 220 }) {
  const cx = size / 2, cy = size / 2, r = size / 2 - 14;
  const cardinals = [
    { l: "N", a: 0 }, { l: "E", a: 90 }, { l: "S", a: 180 }, { l: "W", a: 270 },
  ];
  const minor = [];
  for (let a = 0; a < 360; a += 15) {
    const isCardinal = a % 90 === 0;
    if (isCardinal) continue;
    const len = a % 30 === 0 ? 8 : 4;
    minor.push({ a, len });
  }
  const polar = (a, rad) => {
    const rr = ((a - 90) * Math.PI) / 180;
    return [cx + Math.cos(rr) * rad, cy + Math.sin(rr) * rad];
  };
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <circle cx={cx} cy={cy} r={r} fill="none" stroke="var(--card-border)" strokeWidth="1" />
      <g transform={`rotate(${-heading} ${cx} ${cy})`}>
        {minor.map((m, i) => {
          const [x1, y1] = polar(m.a, r);
          const [x2, y2] = polar(m.a, r - m.len);
          return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke="var(--text-quaternary)" strokeWidth="1" />;
        })}
        {cardinals.map((c, i) => {
          const [tx, ty] = polar(c.a, r - 24);
          return (
            <text key={i} x={tx} y={ty}
              fill={c.l === "N" ? "var(--accent)" : "var(--text-secondary)"}
              fontSize={size * 0.13}
              fontWeight={c.l === "N" ? 600 : 500}
              fontFamily="var(--font-display)"
              textAnchor="middle"
              dominantBaseline="central">
              {c.l}
            </text>
          );
        })}
      </g>
      {/* Fixed pointer */}
      <polygon
        points={`${cx},${cy - r - 2} ${cx - 8},${cy - r + 14} ${cx + 8},${cy - r + 14}`}
        fill="var(--accent)" style={{ filter: "drop-shadow(0 0 10px var(--accent-glow))" }} />
      <circle cx={cx} cy={cy} r="4" fill="var(--text-secondary)" />
      <text x={cx} y={cy + size * 0.2}
        fill="var(--text)" fontSize={size * 0.16}
        fontFamily="var(--font-display)" fontWeight="300"
        textAnchor="middle" style={{ fontVariantNumeric: "tabular-nums" }}>
        {String(Math.round(heading)).padStart(3, "0")}°
      </text>
    </svg>
  );
}

Object.assign(window, { ArcGauge, RadialGauge, BarGauge, FuelGauge, GearIndicator, CompassRose });
