/* global React, ReactDOM, TweaksPanel, useTweaks, TweakSection, TweakRadio, TweakToggle */
const { useState, useEffect, useRef } = React;

/* ---------- helpers ---------- */
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const rand = (a, b) => a + Math.random() * (b - a);

const fmtTime = (ts) => {
  const d = new Date(ts);
  const pad = (n, w = 2) => String(n).padStart(w, '0');
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}.${pad(d.getMilliseconds(), 3).slice(0, 2)}`;
};

const fmtDuration = (ms) => {
  const s = Math.floor(ms / 1000);
  const h = Math.floor(s / 3600);
  const m = Math.floor(s % 3600 / 60);
  const ss = s % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(ss).padStart(2, '0')}`;
};

/* ---------- baseline (PyTorch FP32) — used for speed-up ratio ---------- */
const PT_BASELINE_MS = 68; // YOLO26s PyTorch FP32 reference

/* ---------- live-data simulation ---------- */
function useTelemetry(scenario, paused, optMode, yoloModel) {
  const [t, setT] = useState(() => bootstrap());

  function bootstrap() {
    return {
      ts: Date.now(),
      bootedAt: Date.now() - 1000 * 60 * 14 - 22000, // 14:22 drive time
      // 0x102 — performance + system
      inferenceMs: 22, gpuPct: 48, cpuPct: 36, gpuTempC: 58,
      ramUsedGb: 4.2, ramTotalGb: 8, swapUsedGb: 0.3, swapTotalGb: 4,
      pathDeviationMm: 84,
      // 0x101 — vehicle
      speedKmh: 4.1, steeringDeg: -2.4, driveState: 'AUTO',
      // 0x100 — perception
      obstacleDistM: 8.6, obstacleAngleDeg: -4, obstacleConf: 0.92, obstacleClass: 'car',
      detectLatencyMs: 138,
      sessionDetected: 8, sessionTotal: 10,
      missionSuccess: 7, missionTotal: 10,
      // 0x1FF
      failsafeLevel: 1,
      // CAN/wifi
      wifi: true, can: true, busLoad: 18, frameLossPct: 0.02,
      framesRx: 18234, framesTx: 18230,
      canTxLatencyMs: 3.2,
      // wifi
      wifiPingMs: 12,
      // AMCL
      amclErrorM: 0.21,
      // Pi5
      pi5Online: true, pi5LatencyMs: 28, pi5LossPct: 0.1, pi5LastSeenMs: 0,
      // route
      progressM: 132
    };
  }

  useEffect(() => {
    if (paused) return;
    const id = setInterval(() => {
      setT((prev) => {
        const n = { ...prev };
        n.ts = Date.now();

        // optimization-mode shapes the inference-time floor
        // FP32 ≈ 1.0x, FP16 ≈ 2.2x, INT8 ≈ 3.4x speed-up vs PT_BASELINE_MS
        const optFloor = optMode === 'INT8' ? PT_BASELINE_MS / 3.4 :
        optMode === 'FP16' ? PT_BASELINE_MS / 2.2 :
        PT_BASELINE_MS / 1.0;
        // model size scales it
        const modelMul = yoloModel === 'YOLO26n' ? 0.55 : 1.0;
        let baseInfer = optFloor * modelMul;
        let baseGpu = (optMode === 'INT8' ? 50 : optMode === 'FP16' ? 62 : 78) * (yoloModel === 'YOLO26n' ? 0.7 : 1);
        let baseCpu = 36,baseTemp = 60,baseDev = 110;

        if (scenario === 'warning') {
          baseInfer *= 4.2;
          baseGpu = clamp(baseGpu + 30, 70, 95);
          baseCpu = 70;baseTemp = 78;baseDev = 240;
        } else if (scenario === 'critical') {
          baseInfer = 310;
          baseGpu = 96;baseCpu = 86;baseTemp = 84;baseDev = 380;
        }

        n.inferenceMs = clamp(prev.inferenceMs + (baseInfer - prev.inferenceMs) * 0.35 + rand(-3, 3), 6, 600);
        n.gpuPct = clamp(prev.gpuPct + (baseGpu - prev.gpuPct) * 0.3 + rand(-2, 2), 5, 100);
        n.cpuPct = clamp(prev.cpuPct + (baseCpu - prev.cpuPct) * 0.3 + rand(-2, 2), 5, 100);
        n.gpuTempC = clamp(prev.gpuTempC + (baseTemp - prev.gpuTempC) * 0.15 + rand(-0.4, 0.4), 40, 95);
        n.pathDeviationMm = clamp(prev.pathDeviationMm + (baseDev - prev.pathDeviationMm) * 0.25 + rand(-15, 15), 0, 800);

        // memory — drifts with scenario
        const ramTarget = scenario === 'critical' ? 7.4 : scenario === 'warning' ? 6.6 : 4.4;
        n.ramUsedGb = clamp(prev.ramUsedGb + (ramTarget - prev.ramUsedGb) * 0.2 + rand(-0.05, 0.05), 1.5, 8);
        n.swapUsedGb = clamp(prev.swapUsedGb + ((scenario === 'critical' ? 1.6 : 0.3) - prev.swapUsedGb) * 0.15, 0, 4);

        // vehicle
        const targetSpeed = scenario === 'critical' ? 0 : scenario === 'warning' ? 3.2 : 4.2;
        n.speedKmh = clamp(prev.speedKmh + (targetSpeed - prev.speedKmh) * 0.2 + rand(-0.05, 0.05), 0, 6);
        n.steeringDeg = clamp(prev.steeringDeg * 0.85 + rand(-3, 3), -25, 25);
        n.driveState = scenario === 'critical' ? 'EMERGENCY' : 'AUTO';

        // perception
        n.obstacleDistM = clamp(prev.obstacleDistM - 0.04 + rand(-0.08, 0.08), 1.5, 12);
        if (n.obstacleDistM < 2.0) n.obstacleDistM = 11.5;
        n.obstacleAngleDeg = clamp(prev.obstacleAngleDeg + rand(-0.6, 0.6), -45, 45);
        n.obstacleConf = clamp(0.86 + rand(-0.04, 0.06), 0.4, 0.99);
        n.detectLatencyMs = clamp(prev.detectLatencyMs + (n.inferenceMs * 1.4 + 30 - prev.detectLatencyMs) * 0.2 + rand(-4, 4), 40, 500);

        // fail-safe
        if (scenario === 'critical') n.failsafeLevel = 4;else
        if (n.inferenceMs > 300 && n.gpuPct > 95) n.failsafeLevel = 3;else
        if (n.inferenceMs > 150 && n.gpuPct > 85) n.failsafeLevel = 2;else
        n.failsafeLevel = 1;

        // CAN
        n.busLoad = clamp(prev.busLoad + rand(-1.5, 1.5), 8, 35);
        n.frameLossPct = clamp(prev.frameLossPct + rand(-0.005, 0.006), 0, 0.5);
        n.framesRx = prev.framesRx + Math.round(rand(8, 12));
        n.framesTx = n.framesRx - Math.round(n.framesRx * n.frameLossPct / 100);
        const canTarget = scenario === 'critical' ? 14 : scenario === 'warning' ? 8 : 3.2;
        n.canTxLatencyMs = clamp(prev.canTxLatencyMs + (canTarget - prev.canTxLatencyMs) * 0.25 + rand(-0.5, 0.5), 0.5, 30);

        // Wi-Fi ping (tablet ↔ system)
        const wifiTarget = scenario === 'critical' ? 95 : scenario === 'warning' ? 38 : 14;
        n.wifiPingMs = clamp(prev.wifiPingMs + (wifiTarget - prev.wifiPingMs) * 0.2 + rand(-3, 3), 4, 200);

        // AMCL static error (m)
        const amclTarget = scenario === 'critical' ? 0.62 : scenario === 'warning' ? 0.38 : 0.22;
        n.amclErrorM = clamp(prev.amclErrorM + (amclTarget - prev.amclErrorM) * 0.18 + rand(-0.02, 0.02), 0.05, 1.5);

        // Pi5 link
        const pi5LatTarget = scenario === 'critical' ? 320 : scenario === 'warning' ? 95 : 26;
        n.pi5LatencyMs = clamp(prev.pi5LatencyMs + (pi5LatTarget - prev.pi5LatencyMs) * 0.2 + rand(-5, 5), 8, 600);
        n.pi5LossPct = clamp(prev.pi5LossPct + ((scenario === 'critical' ? 4.5 : scenario === 'warning' ? 1.2 : 0.1) - prev.pi5LossPct) * 0.15 + rand(-0.05, 0.05), 0, 30);
        n.pi5LastSeenMs = scenario === 'critical' ? clamp(prev.pi5LastSeenMs + 100 + rand(0, 80), 0, 1500) : clamp(rand(20, 90), 0, 1500);
        n.pi5Online = n.pi5LastSeenMs < 500;

        // route progress
        n.progressM = (prev.progressM + (n.driveState === 'EMERGENCY' ? 0 : 0.12)) % 250;

        return n;
      });
    }, 100);
    return () => clearInterval(id);
  }, [scenario, paused, optMode, yoloModel]);

  return t;
}

/* ---------- log ---------- */
function useEventLog(t, optMode, yoloModel) {
  const [log, setLog] = useState(() => seed());
  const seenRef = useRef({ lvl: 1, opt: optMode, model: yoloModel });

  function seed() {
    const now = Date.now();
    return [
    { ts: now - 14200, code: 'BOOT', src: '0x000', msg: 'Jetson Orin Nano · JetPack 6.2 SUPER · 67 TOPS', sev: 'info' },
    { ts: now - 13100, code: 'CAN_UP', src: '0x000', msg: 'CAN bus online · 500kbps · 120Ω terminated', sev: 'info' },
    { ts: now - 12200, code: 'SLAM_LOC', src: '0x000', msg: 'AMCL converged · σ 0.34m · 250m basemap', sev: 'good' },
    { ts: now - 11000, code: 'TRT_LOAD', src: '0x102', msg: 'TensorRT engine: yolo26s_int8.engine (19MB)', sev: 'info' },
    { ts: now - 9800, code: 'NAV_PLAN', src: '0x000', msg: 'Hybrid A* path · 250m segment · 1.42s', sev: 'good' },
    { ts: now - 7400, code: 'DRIVE', src: '0x101', msg: 'Drive mode → AUTO', sev: 'info' },
    { ts: now - 5200, code: 'PERCEPT', src: '0x100', msg: 'Obstacle: car · 9.8m · conf 0.94', sev: 'info' }];

  }

  useEffect(() => {
    setLog((prev) => {
      const out = [...prev];const now = Date.now();
      if (t.failsafeLevel !== seenRef.current.lvl) {
        const lvl = t.failsafeLevel;
        out.push({
          ts: now,
          code: lvl >= 4 ? 'EMERGENCY' : lvl === 3 ? 'AI_BYPASS' : lvl === 2 ? 'OVERLOAD' : 'RECOVER',
          src: '0x1FF',
          msg: lvl === 4 ? 'Emergency stop · motor PWM = 0' :
          lvl === 3 ? 'GPU>95%, infer>300ms · LiDAR DBSCAN only' :
          lvl === 2 ? 'GPU>85%, infer>150ms · Heavy → Light' :
          'Recovered to normal · resume Heavy',
          sev: lvl === 4 ? 'critical' : lvl >= 2 ? 'warning' : 'good'
        });
        seenRef.current.lvl = lvl;
      }
      if (optMode !== seenRef.current.opt) {
        out.push({ ts: now, code: 'OPT_MODE', src: '0x102',
          msg: `Optimization → ${optMode} · re-loading engine`, sev: 'info' });
        seenRef.current.opt = optMode;
      }
      if (yoloModel !== seenRef.current.model) {
        out.push({ ts: now, code: 'MODEL', src: '0x101',
          msg: `Model → ${yoloModel} (${yoloModel === 'YOLO26n' ? 'Light' : 'Heavy'})`, sev: 'info' });
        seenRef.current.model = yoloModel;
      }
      return out.slice(-80);
    });
  }, [t.failsafeLevel, optMode, yoloModel]);

  // perception heartbeat
  useEffect(() => {
    const id = setInterval(() => {
      setLog((prev) => {
        if (Math.random() > 0.35) return prev;
        return [...prev, {
          ts: Date.now(), code: 'PERCEPT', src: '0x100',
          msg: `Obstacle: car · ${t.obstacleDistM.toFixed(1)}m · ${t.obstacleAngleDeg.toFixed(0)}° · conf ${t.obstacleConf.toFixed(2)}`,
          sev: 'info'
        }].slice(-80);
      });
    }, 1500);
    return () => clearInterval(id);
  }, [t]);

  return log;
}

/* ---------- shared chrome ---------- */
const cardBase = {
  background: 'var(--tile-2)', borderRadius: 18,
  border: '1px solid var(--hairline)', padding: 20
};

function Card({ children, style, ...rest }) {
  return <div style={{ ...cardBase, ...style }} {...rest}>{children}</div>;
}

function Pill({ children, color = 'var(--body-muted)', bg = 'rgba(255,255,255,0.06)', border = 'var(--hairline)', size = 12, mono = false }) {
  return (
    <span className={mono ? 'mono' : ''} style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      borderRadius: 9999, background: bg, color,
      border: `1px solid ${border}`,
      padding: '5px 10px', fontSize: size, fontWeight: 500,
      letterSpacing: '-0.005em', whiteSpace: 'nowrap'
    }}>{children}</span>);

}

function Dot({ color = 'var(--good)', size = 8, pulse = false }) {
  return (
    <span style={{
      display: 'inline-block', width: size, height: size, borderRadius: 9999,
      background: color,
      animation: pulse ? 'pulse 1.6s ease-out infinite' : 'none'
    }} />);

}

function ActiveBtn({ children, primary = false, ...rest }) {
  return (
    <button {...rest} className="active-btn" style={{
      padding: '7px 14px', borderRadius: 9999,
      background: primary ? 'var(--primary-on-dark)' : 'rgba(255,255,255,0.08)',
      color: primary ? '#fff' : 'var(--body)',
      border: primary ? '1px solid var(--primary-on-dark)' : '1px solid var(--hairline-strong)',
      fontFamily: 'inherit', fontSize: 12, fontWeight: 500, cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', gap: 6,
      transition: 'transform 0.08s ease',
      ...(rest.style || {})
    }}>{children}</button>);

}

/* ---------- top nav ---------- */
function TopNav({ t, optMode, lightMode, setLightMode, onEStop }) {
  const lvl = t.failsafeLevel;
  const lvlColor = lvl === 1 ? 'var(--good)' : lvl === 2 ? 'var(--warning)' : 'var(--critical)';
  const lvlLabel = lvl === 1 ? 'L1 Heavy' : lvl === 2 ? 'L2 Light' : lvl === 3 ? 'L3 AI Bypass' : 'L4 E-Stop';
  const wifiWarn = t.wifiPingMs > 50, wifiCrit = t.wifiPingMs > 80;
  const wifiColor = wifiCrit ? 'var(--critical)' : wifiWarn ? 'var(--warning)' : 'var(--good)';
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, []);

  return (
    <div style={{
      height: 48, background: lightMode ? '#fff' : '#000', borderBottom: '1px solid var(--hairline)',
      display: 'flex', alignItems: 'center', padding: '0 24px',
      position: 'sticky', top: 0, zIndex: 10
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, flex: 1 }}>
        <div style={{
          width: 22, height: 22, borderRadius: 6,
          background: 'linear-gradient(135deg, var(--primary-on-dark), var(--primary))',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 13, fontWeight: 700, color: '#fff', letterSpacing: '-0.04em'
        }}>K</div>
        <span style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.01em', color: lightMode ? '#000' : 'var(--body)' }}>KPI Monitor</span>
        <span style={{ color: 'var(--body-dim)', fontSize: 13 }}>·</span>
        <span style={{ color: 'var(--body-dim)', fontSize: 13 }}>Jetson Orin Nano · YOLO26 · Team 02</span>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <Pill mono size={11} color="var(--body-muted)">
          <span style={{ color: 'var(--body-dim)' }}>DRIVE</span>
          <span style={{ color: lightMode ? '#000' : 'var(--body)', fontWeight: 600 }}>{fmtDuration(now - t.bootedAt)}</span>
        </Pill>
        <Pill color={wifiColor} border={wifiColor} bg="rgba(0,0,0,0)">
          <Dot color={wifiColor} pulse />
          <span style={{ fontWeight: 600 }} className="mono">WIFI {t.wifiPingMs.toFixed(0)}ms</span>
        </Pill>
        <Pill color={t.can ? (lightMode ? '#000' : 'var(--body)') : 'var(--critical)'}>
          <Dot color={t.can ? 'var(--good)' : 'var(--critical)'} pulse={t.can} />CAN · 500k
        </Pill>
        <Pill color={lvlColor} border={lvlColor} bg="rgba(0,0,0,0)">
          <Dot color={lvlColor} pulse={lvl > 1} />
          <span style={{ fontWeight: 600 }}>FS · {lvlLabel}</span>
        </Pill>
        <ActiveBtn onClick={() => setLightMode(!lightMode)} title="Toggle light mode for outdoor visibility">
          {lightMode ? '☀ Light' : '◐ Dark'}
        </ActiveBtn>
      </div>
    </div>);

}

/* ---------- sparkline ---------- */
function Sparkline({ data, color, height = 44 }) {
  if (!data || data.length < 2) return <div style={{ height }} />;
  const min = Math.min(...data),max = Math.max(...data);
  const range = max - min || 1;
  const w = 100,h = 100;
  const pts = data.map((v, i) => {
    const x = i / (data.length - 1) * w;
    const y = h - (v - min) / range * h;
    return `${x.toFixed(2)},${y.toFixed(2)}`;
  }).join(' ');
  const last = data[data.length - 1];
  const lastY = h - (last - min) / range * h;
  const id = `sg-${color.replace(/[^a-z0-9]/gi, '')}`;
  return (
    <svg width="100%" height={height} viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none" style={{ display: 'block' }}>
      <defs>
        <linearGradient id={id} x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.25" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      <polyline fill={`url(#${id})`} stroke="none" points={`0,${h} ${pts} ${w},${h}`} />
      <polyline fill="none" stroke={color} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" points={pts} vectorEffect="non-scaling-stroke" />
      <circle cx={w} cy={lastY} r="1.6" fill={color} />
    </svg>);

}

function useHistory(value, len = 60) {
  const ref = useRef([]);
  ref.current = [...ref.current, value].slice(-len);
  return ref.current;
}

/* ---------- Hero KPIs ---------- */
function HeroInference({ t, optMode, history }) {
  const isCrit = t.inferenceMs > 300;
  const isWarn = !isCrit && t.inferenceMs > 150;
  const color = isCrit ? 'var(--critical)' : isWarn ? 'var(--warning)' : 'var(--body)';
  return (
    <div style={{ ...cardBase, padding: 28, display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontSize: 12, color: 'var(--body-dim)', fontWeight: 500, letterSpacing: '0.04em', textTransform: 'uppercase' }}>Inference Delay</span>
        <Pill size={11} color={isWarn || isCrit ? color : 'var(--body-dim)'} bg="rgba(255,255,255,0.04)">target &lt; 150 ms</Pill>
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginTop: 4 }}>
        <span className="tnum" style={{ fontSize: 96, fontWeight: 600, letterSpacing: '-0.04em', color, lineHeight: 0.95 }}>
          {t.inferenceMs.toFixed(0)}
        </span>
        <span style={{ fontSize: 22, color: 'var(--body-muted)', fontWeight: 500, letterSpacing: '-0.02em' }}>ms</span>
      </div>
      <Sparkline data={history} color={color} />
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 12, color: 'var(--body-dim)' }}>
        <span style={{ display: 'inline-flex', gap: 8, alignItems: 'center' }}>
          <Pill size={11} color="var(--primary-on-dark)" bg="rgba(41,151,255,0.10)" border="rgba(41,151,255,0.32)">
            <Dot color="var(--primary-on-dark)" />{optMode}
          </Pill>
          <span>vs PT FP32 baseline {PT_BASELINE_MS} ms</span>
        </span>
        <span className="mono">10Hz · 0x102</span>
      </div>
    </div>);

}

function HeroSpeedup({ t, optMode, history }) {
  const ratio = PT_BASELINE_MS / Math.max(t.inferenceMs, 1);
  const target = 3.0;
  const isWarn = ratio < target;
  const color = isWarn ? 'var(--warning)' : 'var(--good)';
  return (
    <div style={{ ...cardBase, padding: 28, display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontSize: 12, color: 'var(--body-dim)', fontWeight: 500, letterSpacing: '0.04em', textTransform: 'uppercase' }}>Speed-up Ratio</span>
        <Pill size={11} color={isWarn ? color : 'var(--body-dim)'} bg="rgba(255,255,255,0.04)">target ≥ 3.0×</Pill>
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginTop: 4 }}>
        <span className="tnum" style={{ fontSize: 96, fontWeight: 600, letterSpacing: '-0.04em', color, lineHeight: 0.95 }}>
          {ratio.toFixed(2)}
        </span>
        <span style={{ fontSize: 22, color: 'var(--body-muted)', fontWeight: 500, letterSpacing: '-0.02em' }}>×</span>
      </div>
      <Sparkline data={history} color={color} />
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 12, color: 'var(--body-dim)' }}>
        <span>{optMode} vs PyTorch FP32 (YOLO26s · {PT_BASELINE_MS} ms)</span>
        <span className="mono">live</span>
      </div>
    </div>);

}

/* ---------- metric tile ---------- */
function MetricTile({ label, value, unit, max, warn, crit, hint, ringColor }) {
  const numeric = typeof value === 'number' ? value : parseFloat(value);
  const pct = max ? clamp(numeric / max * 100, 0, 100) : 0;
  const isCrit = crit !== undefined && numeric >= crit;
  const isWarn = !isCrit && warn !== undefined && numeric >= warn;
  const ring = isCrit ? 'var(--critical)' : isWarn ? 'var(--warning)' : ringColor || 'var(--primary-on-dark)';
  const valColor = isCrit ? 'var(--critical)' : isWarn ? 'var(--warning)' : 'var(--body)';
  return (
    <div style={{ ...cardBase, display: 'flex', flexDirection: 'column', gap: 14, padding: 18 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 11, color: 'var(--body-dim)', fontWeight: 500, letterSpacing: '0.04em', textTransform: 'uppercase' }}>{label}</span>
        {(isWarn || isCrit) && <Dot color={ring} pulse />}
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
        <span className="tnum" style={{ fontSize: 34, fontWeight: 600, letterSpacing: '-0.03em', color: valColor, lineHeight: 1 }}>{value}</span>
        <span style={{ fontSize: 13, color: 'var(--body-muted)', fontWeight: 500 }}>{unit}</span>
      </div>
      {max !== undefined &&
      <div style={{ height: 4, background: 'rgba(255,255,255,0.06)', borderRadius: 9999, overflow: 'hidden' }}>
          <div style={{ width: `${pct}%`, height: '100%', background: ring, borderRadius: 9999, transition: 'width 0.2s linear' }} />
        </div>
      }
      {hint && <span style={{ fontSize: 11, color: 'var(--body-dim)' }}>{hint}</span>}
    </div>);

}

/* ---------- Memory tile (dual: RAM + Swap) ---------- */
function MemoryTile({ t }) {
  const ramPct = t.ramUsedGb / t.ramTotalGb * 100;
  const swapPct = t.swapUsedGb / t.swapTotalGb * 100;
  const ramWarn = ramPct >= 85,ramCrit = ramPct >= 95;
  const ramColor = ramCrit ? 'var(--critical)' : ramWarn ? 'var(--warning)' : 'var(--primary-on-dark)';
  return (
    <div style={{ ...cardBase, display: 'flex', flexDirection: 'column', gap: 14, padding: 18 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 11, color: 'var(--body-dim)', fontWeight: 500, letterSpacing: '0.04em', textTransform: 'uppercase' }}>Memory · Orin 8GB</span>
        {(ramWarn || ramCrit) && <Dot color={ramColor} pulse />}
      </div>
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span style={{ fontSize: 11, color: 'var(--body-muted)' }}>RAM</span>
          <span className="tnum" style={{ fontSize: 18, fontWeight: 600, color: ramCrit ? 'var(--critical)' : ramWarn ? 'var(--warning)' : 'var(--body)' }}>
            {t.ramUsedGb.toFixed(1)} <span style={{ fontSize: 11, color: 'var(--body-muted)', fontWeight: 500 }}>/ {t.ramTotalGb} GB</span>
          </span>
        </div>
        <div style={{ marginTop: 6, height: 4, background: 'rgba(255,255,255,0.06)', borderRadius: 9999, overflow: 'hidden' }}>
          <div style={{ width: `${ramPct}%`, height: '100%', background: ramColor, borderRadius: 9999, transition: 'width 0.2s linear' }} />
        </div>
      </div>
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span style={{ fontSize: 11, color: 'var(--body-muted)' }}>Swap (NVMe)</span>
          <span className="tnum" style={{ fontSize: 14, fontWeight: 600 }}>
            {t.swapUsedGb.toFixed(1)} <span style={{ fontSize: 11, color: 'var(--body-muted)', fontWeight: 500 }}>/ {t.swapTotalGb} GB</span>
          </span>
        </div>
        <div style={{ marginTop: 6, height: 3, background: 'rgba(255,255,255,0.06)', borderRadius: 9999, overflow: 'hidden' }}>
          <div style={{ width: `${swapPct}%`, height: '100%', background: 'var(--body-muted)', borderRadius: 9999, transition: 'width 0.2s linear' }} />
        </div>
      </div>
    </div>);

}

/* ---------- vehicle state strip ---------- */
function VehicleState({ t, yoloModel, optMode }) {
  return (
    <div style={{ ...cardBase, padding: 20, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 24 }}>
      <div>
        <div style={{ fontSize: 11, color: 'var(--body-dim)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 500 }}>Linear Velocity</div>
        <div style={{ marginTop: 8, display: 'flex', alignItems: 'baseline', gap: 6 }}>
          <span className="tnum" style={{ fontSize: 34, fontWeight: 600, letterSpacing: '-0.03em' }}>{t.speedKmh.toFixed(1)}</span>
          <span style={{ fontSize: 13, color: 'var(--body-muted)' }}>km/h</span>
        </div>
        <div style={{ fontSize: 11, color: 'var(--body-dim)', marginTop: 4 }}>target 3 — 5 km/h</div>
      </div>
      <div>
        <div style={{ fontSize: 11, color: 'var(--body-dim)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 500 }}>Steering Angle</div>
        <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 14 }}>
          <SteeringDial deg={t.steeringDeg} />
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
            <span className="tnum" style={{ fontSize: 28, fontWeight: 600, letterSpacing: '-0.03em' }}>
              {t.steeringDeg >= 0 ? '+' : ''}{t.steeringDeg.toFixed(1)}
            </span>
            <span style={{ fontSize: 12, color: 'var(--body-muted)' }}>°</span>
          </div>
        </div>
      </div>
      <div>
        <div style={{ fontSize: 11, color: 'var(--body-dim)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 500 }}>Engine</div>
        <div style={{ marginTop: 8, display: 'flex', alignItems: 'baseline', gap: 6 }}>
          <span className="mono" style={{ fontSize: 22, fontWeight: 600, letterSpacing: '-0.02em', color: 'var(--primary-on-dark)' }}>{optMode}</span>
          <span style={{ fontSize: 12, color: 'var(--body-muted)' }}>· {yoloModel}</span>
        </div>
        <div style={{ fontSize: 11, color: 'var(--body-dim)', marginTop: 4 }}>{yoloModel === 'YOLO26n' ? 'Light' : 'Heavy'} engine · TensorRT</div>
      </div>
      <div>
        <div style={{ fontSize: 11, color: 'var(--body-dim)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 500 }}>Drive State · Fail-safe</div>
        <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 6 }}>
          <FailsafeLadder level={t.failsafeLevel} />
        </div>
      </div>
    </div>);

}

/* ---------- 4-stage Fail-safe ladder ---------- */
function FailsafeLadder({ level }) {
  const stages = [
    { id: 1, label: 'Heavy', sub: 'YOLO26s · all sensors', color: 'var(--good)' },
    { id: 2, label: 'Light', sub: 'YOLO26n · downscale', color: 'var(--warning)' },
    { id: 3, label: 'AI Bypass', sub: 'LiDAR DBSCAN only', color: 'var(--critical)' },
    { id: 4, label: 'E-Stop', sub: 'Motor PWM = 0', color: 'var(--critical)' }
  ];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      {stages.map((s) => {
        const active = s.id === level;
        const past = s.id < level;
        return (
          <div key={s.id} style={{
            display: 'flex', alignItems: 'center', gap: 8,
            padding: '4px 8px', borderRadius: 7,
            background: active ? `color-mix(in oklab, ${s.color} 18%, transparent)` : 'transparent',
            border: active ? `1px solid ${s.color}` : '1px solid transparent',
            opacity: past ? 0.45 : 1
          }}>
            <span className="mono" style={{ fontSize: 10, color: active ? s.color : 'var(--body-dim)', fontWeight: 700, width: 18 }}>L{s.id}</span>
            <span style={{ fontSize: 12, fontWeight: 600, color: active ? 'var(--body)' : 'var(--body-muted)', flex: 1 }}>{s.label}</span>
            {active && <Dot color={s.color} pulse />}
          </div>);
      })}
    </div>);
}

/* ---------- TouchControls — compact inline KPI control bar ---------- */
function TouchSegment({ label, value, options, onChange }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
      <span style={{ fontSize: 10, color: 'var(--body-dim)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600, flex: 'none' }}>{label}</span>
      <div style={{ display: 'flex', gap: 2, padding: 3, background: 'rgba(0,0,0,0.32)', borderRadius: 11, border: '1px solid var(--hairline)' }}>
        {options.map((opt) => {
          const active = value === opt;
          return (
            <button
              key={opt}
              onClick={() => onChange(opt)}
              className="touch-seg mono"
              style={{
                appearance: 'none', WebkitAppearance: 'none',
                border: 'none', cursor: 'pointer',
                fontFamily: 'JetBrains Mono, ui-monospace, monospace', fontWeight: 600, fontSize: 13, letterSpacing: '0.02em',
                minHeight: 44, minWidth: 64, padding: '0 16px', borderRadius: 8,
                background: active ? 'var(--primary-on-dark)' : 'transparent',
                color: active ? '#fff' : 'var(--body-muted)',
                transition: 'background 0.15s ease, transform 0.08s ease, color 0.15s ease',
                touchAction: 'manipulation', WebkitTapHighlightColor: 'transparent'
              }}>
              {opt}
            </button>);
        })}
      </div>
    </div>);
}

function TouchControls({ tweaks, setTweak, onAmclInit, onEStop }) {
  return (
    <div style={{
      background: 'var(--tile-2)', borderRadius: 14, border: '1px solid var(--hairline)',
      padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 20, flexWrap: 'wrap'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, flex: 'none' }}>
        <Dot color="var(--primary-on-dark)" pulse />
        <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: '-0.01em' }}>KPI Controls</span>
      </div>
      <div style={{ width: 1, height: 30, background: 'var(--hairline)' }} />
      <TouchSegment label="Precision" value={tweaks.optMode}
        options={['FP32', 'FP16', 'INT8']}
        onChange={(v) => setTweak('optMode', v)} />
      <TouchSegment label="Model" value={tweaks.yoloModel}
        options={['YOLO26s', 'YOLO26n']}
        onChange={(v) => setTweak('yoloModel', v)} />
      <div style={{ flex: 1 }} />
      <button onClick={onAmclInit} className="touch-seg" style={{
        appearance: 'none', border: '1px solid var(--hairline-strong)', cursor: 'pointer',
        fontFamily: 'inherit', fontWeight: 600, fontSize: 13,
        minHeight: 44, padding: '0 18px', borderRadius: 10,
        background: 'rgba(41,151,255,0.10)', color: 'var(--primary-on-dark)',
        display: 'inline-flex', alignItems: 'center', gap: 8,
        touchAction: 'manipulation', WebkitTapHighlightColor: 'transparent'
      }}>
        <span style={{ fontSize: 14 }}>⊕</span> AMCL Init
      </button>
      <button onClick={onEStop} className="touch-seg" style={{
        appearance: 'none', border: '1px solid var(--critical)', cursor: 'pointer',
        fontFamily: 'inherit', fontWeight: 700, fontSize: 13, letterSpacing: '0.04em',
        minHeight: 44, padding: '0 22px', borderRadius: 10,
        background: 'var(--critical)', color: '#fff',
        touchAction: 'manipulation', WebkitTapHighlightColor: 'transparent',
        boxShadow: '0 0 0 0 var(--critical)', animation: 'estopGlow 2.4s ease-in-out infinite'
      }}>E-STOP</button>
    </div>);

}

function SteeringDial({ deg }) {
  const angle = clamp(deg, -25, 25);
  return (
    <svg width="46" height="46" viewBox="0 0 46 46">
      <circle cx="23" cy="23" r="20" fill="none" stroke="var(--hairline-strong)" strokeWidth="1.2" />
      <line x1="23" y1="3" x2="23" y2="9" stroke="var(--body-dim)" strokeWidth="1.2" />
      <g transform={`rotate(${angle * 2.5} 23 23)`} style={{ transition: 'transform 0.18s linear' }}>
        <line x1="23" y1="23" x2="23" y2="6" stroke="var(--primary-on-dark)" strokeWidth="2" strokeLinecap="round" />
        <circle cx="23" cy="23" r="3.2" fill="var(--primary-on-dark)" />
      </g>
    </svg>);

}

/* ---------- Accuracy tracker (mAP loss across optimization stages) ---------- */
function AccuracyTracker({ optMode }) {
  const stages = [
  { id: 'FP32', mAP: 47.20, baseline: true },
  { id: 'FP16', mAP: 47.05 },
  { id: 'INT8', mAP: 45.86 }];

  const baseline = stages[0].mAP;
  const max = 50,min = 44;
  const w = 240,h = 96,pad = 12;
  const xs = stages.map((_, i) => pad + i * (w - pad * 2) / (stages.length - 1));
  const ys = stages.map((s) => pad + (1 - (s.mAP - min) / (max - min)) * (h - pad * 2));
  const pts = stages.map((s, i) => `${xs[i]},${ys[i]}`).join(' ');

  return (
    <Card style={{ padding: 20 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, letterSpacing: '-0.01em' }}>Accuracy Tracker</div>
          <div style={{ fontSize: 11, color: 'var(--body-dim)', marginTop: 2 }}>mAP loss across quantization · COCO val</div>
        </div>
        <Pill size={11} color="var(--body-muted)">target loss ≤ 1.5%</Pill>
      </div>

      <div style={{ marginTop: 14, display: 'flex', gap: 16, alignItems: 'center' }}>
        <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} style={{ flex: 'none' }}>
          {/* baseline line */}
          <line x1={pad} x2={w - pad} y1={ys[0]} y2={ys[0]} stroke="rgba(255,255,255,0.12)" strokeWidth="1" strokeDasharray="3 3" />
          {/* curve */}
          <polyline points={pts} fill="none" stroke="var(--primary-on-dark)" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
          {/* points */}
          {stages.map((s, i) => {
            const isCur = optMode === s.id;
            return (
              <g key={s.id}>
                <circle cx={xs[i]} cy={ys[i]} r={isCur ? 5 : 3.4}
                fill={isCur ? 'var(--primary-on-dark)' : 'var(--tile-2)'}
                stroke="var(--primary-on-dark)" strokeWidth="1.4" />
                <text x={xs[i]} y={h - 2} textAnchor="middle" fontSize="9.5" fontFamily="JetBrains Mono"
                fill={isCur ? 'var(--body)' : 'var(--body-dim)'}>{s.id}</text>
              </g>);

          })}
        </svg>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, flex: 1 }}>
          {stages.map((s) => {
            const loss = baseline - s.mAP;
            const lossPct = loss / baseline * 100;
            const cur = optMode === s.id;
            const lossWarn = lossPct > 1.5;
            return (
              <div key={s.id} style={{
                display: 'grid', gridTemplateColumns: '50px 1fr auto', gap: 10, alignItems: 'baseline',
                padding: '6px 10px', borderRadius: 8,
                background: cur ? 'rgba(41,151,255,0.08)' : 'transparent',
                border: cur ? '1px solid rgba(41,151,255,0.24)' : '1px solid transparent'
              }}>
                <span className="mono" style={{ fontSize: 11, color: cur ? 'var(--primary-on-dark)' : 'var(--body-muted)', fontWeight: 600 }}>{s.id}</span>
                <span className="tnum" style={{ fontSize: 13, color: 'var(--body)', fontWeight: 500 }}>
                  {s.mAP.toFixed(2)}<span style={{ color: 'var(--body-dim)', fontSize: 11 }}> mAP</span>
                </span>
                <span className="tnum" style={{ fontSize: 11, color: s.baseline ? 'var(--body-dim)' : lossWarn ? 'var(--warning)' : 'var(--good)', fontWeight: 500 }}>
                  {s.baseline ? 'baseline' : `−${lossPct.toFixed(2)}%`}
                </span>
              </div>);

          })}
        </div>
      </div>
    </Card>);

}

/* ---------- Detection panel (accuracy + latency + radar) ---------- */
function DetectionPanel({ t }) {
  const r = 100;
  const obs = {
    x: Math.sin(t.obstacleAngleDeg * Math.PI / 180) * (t.obstacleDistM / 12) * r,
    y: -Math.cos(t.obstacleAngleDeg * Math.PI / 180) * (t.obstacleDistM / 12) * r
  };
  const detRate = t.sessionDetected / t.sessionTotal * 100;
  const latWarn = t.detectLatencyMs > 200;

  return (
    <Card style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, letterSpacing: '-0.01em' }}>Perception · Detection</div>
          <div style={{ fontSize: 11, color: 'var(--body-dim)', marginTop: 2 }}>YOLO26 + LiDAR DBSCAN · 0x100</div>
        </div>
        <Pill size={11}>10 Hz</Pill>
      </div>

      <div style={{ position: 'relative', aspectRatio: '1', background: 'var(--tile-3)',
        borderRadius: 14, border: '1px solid var(--hairline)', overflow: 'hidden' }}>
        <svg viewBox="-110 -110 220 220" width="100%" height="100%">
          {[0.25, 0.5, 0.75, 1].map((s) =>
          <circle key={s} cx="0" cy="0" r={r * s} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="0.6" />
          )}
          <line x1="-110" y1="0" x2="110" y2="0" stroke="rgba(255,255,255,0.05)" strokeWidth="0.5" />
          <line x1="0" y1="-110" x2="0" y2="110" stroke="rgba(255,255,255,0.05)" strokeWidth="0.5" />
          {[3, 6, 9, 12].map((m, i) =>
          <text key={m} x="2" y={-r * (i + 1) / 4 - 2} fill="rgba(255,255,255,0.25)" fontSize="6" fontFamily="JetBrains Mono">{m}m</text>
          )}
          <path d={`M0 0 L${100 * Math.sin(-Math.PI / 3)} ${-100 * Math.cos(-Math.PI / 3)} A100 100 0 0 1 ${100 * Math.sin(Math.PI / 3)} ${-100 * Math.cos(Math.PI / 3)} Z`}
          fill="rgba(41,151,255,0.06)" stroke="rgba(41,151,255,0.18)" strokeWidth="0.5" strokeDasharray="2 2" />
          <circle cx="0" cy="0" r="3.2" fill="var(--primary-on-dark)" />
          <circle cx="0" cy="0" r="6" fill="none" stroke="var(--primary-on-dark)" strokeWidth="0.5" opacity="0.4" />
          <g transform={`translate(${obs.x.toFixed(1)} ${obs.y.toFixed(1)})`}>
            <rect x="-7" y="-4" width="14" height="8" rx="2" fill={t.obstacleDistM < 4 ? 'var(--warning)' : 'var(--body)'} opacity="0.88" />
            <text x="9" y="2" fill="var(--body-muted)" fontSize="6" fontFamily="JetBrains Mono">{t.obstacleClass}</text>
          </g>
        </svg>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <MiniStat label="Live Confidence" val={(t.obstacleConf * 100).toFixed(0)} unit="%" />
        <MiniStat label="Session Rate" val={`${t.sessionDetected}/${t.sessionTotal}`} unit={`· ${detRate.toFixed(0)}%`} good={detRate >= 80} />
        <MiniStat label="Detect Latency" val={t.detectLatencyMs.toFixed(0)} unit="ms" warn={latWarn} hint="target < 200 ms" />
        <MiniStat label="Distance" val={t.obstacleDistM.toFixed(1)} unit="m" warn={t.obstacleDistM < 4} />
      </div>
    </Card>);

}

function MiniStat({ label, val, unit, warn, good, hint }) {
  const color = warn ? 'var(--warning)' : good ? 'var(--good)' : 'var(--body)';
  return (
    <div style={{ background: 'var(--tile-3)', border: '1px solid var(--hairline)', borderRadius: 12, padding: 12 }}>
      <div style={{ fontSize: 10, color: 'var(--body-dim)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 500 }}>{label}</div>
      <div style={{ marginTop: 6, display: 'flex', alignItems: 'baseline', gap: 4 }}>
        <span className="tnum" style={{ fontSize: 18, fontWeight: 600, letterSpacing: '-0.02em', color }}>{val}</span>
        <span style={{ fontSize: 11, color: 'var(--body-muted)' }}>{unit}</span>
      </div>
      {hint && <div style={{ fontSize: 10, color: 'var(--body-dim)', marginTop: 3 }}>{hint}</div>}
    </div>);

}

/* ---------- Mission Success ---------- */
function MissionTile({ t }) {
  const pct = t.missionSuccess / t.missionTotal * 100;
  return (
    <div style={{ ...cardBase, padding: 18 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontSize: 11, color: 'var(--body-dim)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 500 }}>Mission Success</div>
          <div style={{ marginTop: 8, display: 'flex', alignItems: 'baseline', gap: 6 }}>
            <span className="tnum" style={{ fontSize: 30, fontWeight: 600, letterSpacing: '-0.03em' }}>{t.missionSuccess}</span>
            <span style={{ fontSize: 14, color: 'var(--body-muted)' }}>/ {t.missionTotal}</span>
            <span className="tnum" style={{ fontSize: 13, color: 'var(--body-dim)', marginLeft: 8 }}>{pct.toFixed(0)}%</span>
          </div>
        </div>
        <Pill size={11} color="var(--body-muted)">target ≥ 70%</Pill>
      </div>
      <div style={{ marginTop: 14, display: 'flex', gap: 4 }}>
        {Array.from({ length: t.missionTotal }).map((_, i) => {
          const ok = i < t.missionSuccess;
          return <div key={i} style={{
            flex: 1, height: 6, borderRadius: 3,
            background: ok ? 'var(--good)' : 'rgba(255,255,255,0.08)'
          }} />;
        })}
      </div>
      <div style={{ marginTop: 10, fontSize: 11, color: 'var(--body-dim)' }}>
        Path Deviation <span className="tnum" style={{ color: t.pathDeviationMm > 300 ? 'var(--warning)' : 'var(--body)' }}>{t.pathDeviationMm.toFixed(0)} mm</span> · target &lt; 300 mm
      </div>
    </div>);

}

/* ---------- Log panel ---------- */
function LogPanel({ log }) {
  const scrollRef = useRef(null);
  useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [log]);
  const sevColor = (s) => s === 'critical' ? 'var(--critical)' : s === 'warning' ? 'var(--warning)' : s === 'good' ? 'var(--good)' : 'var(--body-dim)';
  return (
    <Card style={{ display: 'flex', flexDirection: 'column', padding: 0, height: '100%', overflow: 'hidden', background: 'rgba(42,42,44,0.62)', backdropFilter: 'saturate(180%) blur(20px)', WebkitBackdropFilter: 'saturate(180%) blur(20px)' }}>
      <div style={{ padding: '16px 18px 14px', borderBottom: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, letterSpacing: '-0.01em' }}>Fail-safe Event Stream</div>
          <div style={{ fontSize: 11, color: 'var(--body-dim)', marginTop: 2 }}>CAN 0x1FF · live</div>
        </div>
        <Pill size={11}><Dot color="var(--good)" pulse /> rec</Pill>
      </div>
      <div ref={scrollRef} style={{ flex: 1, overflowY: 'auto', padding: '8px 0' }}>
        {log.map((e, i) =>
        <div key={i} style={{
          padding: '8px 18px',
          display: 'grid', gridTemplateColumns: '70px 92px 1fr', gap: 10, alignItems: 'baseline',
          borderBottom: i === log.length - 1 ? 'none' : '1px solid rgba(255,255,255,0.03)'
        }}>
            <span className="mono" style={{ fontSize: 11, color: 'var(--body-dim)' }}>{fmtTime(e.ts)}</span>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
              <Dot color={sevColor(e.sev)} size={6} />
              <span className="mono" style={{ fontSize: 11, color: sevColor(e.sev), fontWeight: 500, letterSpacing: '0.02em' }}>{e.code}</span>
            </span>
            <span style={{ fontSize: 12, color: 'var(--body-muted)', lineHeight: 1.45 }}>{e.msg}</span>
          </div>
        )}
      </div>
      <div style={{ padding: '12px 18px', borderTop: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: 11, color: 'var(--body-dim)' }}>
        <span>{log.length} events · last 80</span>
        <span className="mono">rosbag2 + SavvyCAN</span>
      </div>
    </Card>);

}

/* ---------- Route ---------- */
function RouteProgress({ t }) {
  const pct = t.progressM / 250 * 100;
  const amclWarn = t.amclErrorM > 0.5;
  return (
    <Card style={{ padding: 18 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, letterSpacing: '-0.01em' }}>Route · 250m straight segment</div>
          <div style={{ fontSize: 11, color: 'var(--body-dim)', marginTop: 2 }}>SLAM (slam_toolbox) + AMCL · σ 0.34m</div>
        </div>
        <div style={{ display: 'flex', gap: 16, alignItems: 'baseline' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
            <span style={{ fontSize: 10, color: 'var(--body-dim)', textTransform: 'uppercase', letterSpacing: '0.04em', marginRight: 4 }}>AMCL err</span>
            <span className="tnum" style={{ fontSize: 18, fontWeight: 600, color: amclWarn ? 'var(--warning)' : 'var(--good)' }}>{(t.amclErrorM * 100).toFixed(0)}</span>
            <span style={{ fontSize: 11, color: 'var(--body-muted)' }}>cm · target ≤ 50</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
            <span className="tnum" style={{ fontSize: 22, fontWeight: 600, letterSpacing: '-0.02em' }}>{t.progressM.toFixed(0)}</span>
            <span style={{ fontSize: 12, color: 'var(--body-muted)' }}>/ 250 m</span>
          </div>
        </div>
      </div>
      <div style={{ position: 'relative', height: 30 }}>
        <div style={{ position: 'absolute', left: 0, right: 0, top: 14, height: 2, background: 'rgba(255,255,255,0.08)', borderRadius: 9999 }} />
        <div style={{ position: 'absolute', left: 0, top: 14, height: 2, width: `${pct}%`, background: 'var(--primary-on-dark)', borderRadius: 9999, transition: 'width 0.2s linear' }} />
        {[42, 110, 188].map((m) =>
        <div key={m} title={`parked car @ ${m}m`} style={{
          position: 'absolute', left: `${m / 250 * 100}%`, top: 6, transform: 'translateX(-50%)',
          width: 14, height: 18, borderRadius: 3, background: 'var(--tile-4)', border: '1px solid var(--hairline-strong)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, color: 'var(--body-dim)'
        }}>▮</div>
        )}
        <div style={{ position: 'absolute', left: `${pct}%`, top: 7, transform: 'translateX(-50%)',
          width: 16, height: 16, borderRadius: 9999, background: 'var(--primary-on-dark)',
          border: '3px solid var(--tile-1)', boxShadow: '0 0 0 1px var(--primary-on-dark)',
          transition: 'left 0.2s linear' }} />
        <div style={{ position: 'absolute', left: 0, top: 24, fontSize: 10, color: 'var(--body-dim)' }} className="mono">START</div>
        <div style={{ position: 'absolute', right: 0, top: 24, fontSize: 10, color: 'var(--body-dim)' }} className="mono">GOAL</div>
      </div>
    </Card>);

}

/* ---------- CAN bus ---------- */
function CanStatus({ t }) {
  const canLatWarn = t.canTxLatencyMs > 10;
  return (
    <Card style={{ padding: 18 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, letterSpacing: '-0.01em' }}>CAN Bus</div>
          <div style={{ fontSize: 11, color: 'var(--body-dim)', marginTop: 2 }}>500 kbps · 120Ω terminated</div>
        </div>
        <Pill size={11} color="var(--good)" border="rgba(48,209,88,0.32)" bg="rgba(48,209,88,0.10)">
          <Dot color="var(--good)" pulse /> online
        </Pill>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 12 }}>
        <KV label="TX latency" val={`${t.canTxLatencyMs.toFixed(1)} ms`} warn={canLatWarn} />
        <KV label="Bus load" val={`${t.busLoad.toFixed(0)}%`} />
        <KV label="Loss" val={`${t.frameLossPct.toFixed(2)}%`} warn={t.frameLossPct > 0.1} />
        <KV label="TX" val={t.framesTx.toLocaleString()} mono />
        <KV label="RX" val={t.framesRx.toLocaleString()} mono />
      </div>
      <div style={{ marginTop: 10, fontSize: 11, color: 'var(--body-dim)' }}>target TX latency ≤ 10 ms</div>
      <div style={{ marginTop: 12, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        {['0x100 perception', '0x101 vehicle', '0x102 kpi', '0x1FF events'].map((id) =>
        <span key={id} className="mono" style={{
          fontSize: 10.5, padding: '4px 8px', borderRadius: 6,
          background: 'var(--tile-3)', border: '1px solid var(--hairline)',
          color: 'var(--body-muted)', letterSpacing: '0.02em'
        }}>{id}</span>
        )}
      </div>
    </Card>);

}

/* ---------- Pi5 link ---------- */
function Pi5Status({ t }) {
  const latWarn = t.pi5LatencyMs > 100, latCrit = t.pi5LatencyMs > 250 || !t.pi5Online;
  const color = latCrit ? 'var(--critical)' : latWarn ? 'var(--warning)' : 'var(--good)';
  return (
    <Card style={{ padding: 18 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, letterSpacing: '-0.01em' }}>Raspberry Pi 5 · Aux Cameras ×3</div>
          <div style={{ fontSize: 11, color: 'var(--body-dim)', marginTop: 2 }}>UDP · fail-safe trigger if &gt; 500ms silent</div>
        </div>
        <Pill size={11} color={color} border={color} bg="rgba(0,0,0,0)">
          <Dot color={color} pulse /> {t.pi5Online ? 'online' : 'lost'}
        </Pill>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
        <KV label="UDP latency" val={`${t.pi5LatencyMs.toFixed(0)} ms`} warn={latWarn} />
        <KV label="Loss" val={`${t.pi5LossPct.toFixed(2)}%`} warn={t.pi5LossPct > 1} />
        <KV label="Last seen" val={`${t.pi5LastSeenMs.toFixed(0)} ms`} warn={t.pi5LastSeenMs > 300} />
      </div>
    </Card>);

}

function KV({ label, val, mono, warn }) {
  return (
    <div>
      <div style={{ fontSize: 10, color: 'var(--body-dim)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 500 }}>{label}</div>
      <div className={mono ? 'mono' : 'tnum'} style={{
        marginTop: 4, fontSize: 16, fontWeight: 600, letterSpacing: '-0.01em',
        color: warn ? 'var(--warning)' : 'var(--body)'
      }}>{val}</div>
    </div>);

}

/* ---------- main app ---------- */
function App() {
  const [tweaks, setTweak] = useTweaks({
    scenario: 'normal',
    optMode: 'INT8',
    yoloModel: 'YOLO26s',
    paused: false
  });
  const [lightMode, setLightMode] = useState(false);

  const t = useTelemetry(tweaks.scenario, tweaks.paused, tweaks.optMode, tweaks.yoloModel);
  const log = useEventLog(t, tweaks.optMode, tweaks.yoloModel);

  const inferHist = useHistory(t.inferenceMs);
  const ratio = PT_BASELINE_MS / Math.max(t.inferenceMs, 1);
  const ratioHist = useHistory(ratio);

  const onAmclInit = () => alert('AMCL → 2D Pose Estimate sent (initialpose, frame_id=map)');
  const onEStop = () => {
    if (confirm('Send software E-Stop? Motor PWM will be forced to 0.')) {
      setTweak('scenario', 'critical');
    }
  };

  return (
    <div style={{ minHeight: '100vh', background: lightMode ? '#f5f5f7' : 'var(--tile-1)', color: lightMode ? '#1d1d1f' : 'var(--body)' }} className={lightMode ? 'light-mode' : ''}>
      <TopNav t={t} optMode={tweaks.optMode} lightMode={lightMode} setLightMode={setLightMode} onEStop={onEStop} />

      <div style={{ padding: '20px 24px 32px', display: 'grid', gridTemplateColumns: 'minmax(0, 1fr) 380px', gap: 20, maxWidth: 1680, margin: '0 auto' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          <TouchControls tweaks={tweaks} setTweak={setTweak} onAmclInit={onAmclInit} onEStop={onEStop} />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
            <HeroInference t={t} optMode={tweaks.optMode} history={inferHist} />
            <HeroSpeedup t={t} optMode={tweaks.optMode} history={ratioHist} />
          </div>

          <VehicleState t={t} yoloModel={tweaks.yoloModel} optMode={tweaks.optMode} />

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
            <MetricTile label="GPU Usage" value={t.gpuPct.toFixed(0)} unit="%" max={100} warn={85} crit={95} hint="Ampere · 1024 CUDA" />
            <MetricTile label="CPU Usage" value={t.cpuPct.toFixed(0)} unit="%" max={100} warn={85} crit={95} hint="Cortex-A78AE × 6" />
            <MetricTile label="GPU Temp" value={t.gpuTempC.toFixed(0)} unit="°C" max={95} warn={75} crit={85} hint="active cooling" />
            <MemoryTile t={t} />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1.4fr) minmax(0, 1fr)', gap: 16 }}>
            <AccuracyTracker optMode={tweaks.optMode} />
            <MissionTile t={t} />
          </div>

          <RouteProgress t={t} />
          <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1.4fr) minmax(0, 1fr)', gap: 16 }}>
            <CanStatus t={t} />
            <Pi5Status t={t} />
          </div>
        </div>

        <div style={{ position: 'sticky', top: 64, alignSelf: 'start', height: 'calc(100vh - 84px)', display: 'flex', flexDirection: 'column', gap: 20 }}>
          <DetectionPanel t={t} />
          <div style={{ flex: 1, minHeight: 320 }}>
            <LogPanel log={log} />
          </div>
        </div>
      </div>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Stream">
          <TweakToggle label="Pause" value={tweaks.paused}
          onChange={(v) => setTweak('paused', v)} />
        </TweakSection>
      </TweaksPanel>

      <style>{`
        @keyframes pulse {
          0%   { box-shadow: 0 0 0 0 currentColor; opacity: 1; }
          70%  { box-shadow: 0 0 0 6px transparent; opacity: 0.6; }
          100% { box-shadow: 0 0 0 0 transparent; opacity: 1; }
        }
        @keyframes estopGlow {
          0%, 100% { box-shadow: 0 0 0 0 rgba(255,69,58,0.6); }
          50%      { box-shadow: 0 0 0 8px rgba(255,69,58,0); }
        }
        .active-btn:active { transform: scale(0.95); }
        .touch-seg:active { transform: scale(0.97); }
        .light-mode { --tile-1: #f5f5f7; --tile-2: #ffffff; --tile-3: #ebebef; --tile-4: #e0e0e5; --hairline: rgba(0,0,0,0.10); --hairline-strong: rgba(0,0,0,0.18); --body: #1d1d1f; --body-muted: #424245; --body-dim: #6e6e73; --primary-on-dark: #0066cc; }
      `}</style>
    </div>);

}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);