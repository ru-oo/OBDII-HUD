// Telemetry simulator — a small driving model. Returns the live data each tick.

function useTelemetry(simSpeed = 1) {
  const [data, setData] = React.useState(() => initial());
  React.useEffect(() => {
    let raf;
    let last = performance.now();
    const tick = (now) => {
      const dt = Math.min(0.1, (now - last) / 1000) * simSpeed;
      last = now;
      setData(prev => step(prev, dt));
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [simSpeed]);
  return data;
}

function initial() {
  return {
    // p1
    speed: 84, rpm: 2800, coolantC: 92, fuel: 12, gear: "D",
    throttle: 28, batteryV: 14.2, ambientC: 18.5, intakeC: 32,
    // p2
    engineLoad: 42, mapKpa: 78, mafGs: 14.6,
    o2b1: 0.62, o2b2: 0.58,
    ftStB1: 1.2, ftLtB1: -3.4, ftStB2: 0.8, ftLtB2: -2.9,
    ignAdv: 18.5, catTemp: 642,
    // p3
    gpsLat: 48.13743, gpsLon: 11.57549, gpsAlt: 412, heading: 124, avgSpeed: 67,
    tripKm: 142.7, totalKm: 38421, etaMin: 24,
    // internal
    _phase: 0, _targetSpeed: 90, _targetThrottle: 28,
  };
}

function step(d, dt) {
  // randomly retarget speed/throttle every few seconds
  let phase = d._phase + dt;
  let targetSpeed = d._targetSpeed;
  let targetThrottle = d._targetThrottle;
  if (phase > 4) {
    phase = 0;
    targetSpeed = 60 + Math.random() * 80;
    targetThrottle = 12 + Math.random() * 50;
  }

  const speed = lerp(d.speed, targetSpeed, dt * 0.4);
  const throttle = lerp(d.throttle, targetThrottle, dt * 1.2) + (Math.random() - 0.5) * 0.5;
  // RPM follows speed + throttle
  const targetRpm = 800 + speed * 28 + throttle * 18;
  const rpm = lerp(d.rpm, targetRpm, dt * 1.5) + (Math.random() - 0.5) * 30;

  const gear = speed < 5 ? "D" : speed < 25 ? "2" : speed < 50 ? "3" : speed < 80 ? "4" : speed < 120 ? "5" : "6";

  const coolantC = clamp(lerp(d.coolantC, 90 + throttle * 0.15, dt * 0.05), 80, 115);
  const fuel = Math.max(0, d.fuel - dt * 0.0008 * (1 + throttle / 50));
  const batteryV = 13.9 + Math.sin(phase * 2) * 0.15 + (Math.random() - 0.5) * 0.05;
  const ambientC = d.ambientC + (Math.random() - 0.5) * 0.02;
  // IAT — runs warmer than ambient, climbs with engine load
  const intakeC = clamp(lerp(d.intakeC, ambientC + 14 + throttle * 0.18, dt * 0.15) + (Math.random() - 0.5) * 0.1, ambientC, 80);

  // Engine page
  const engineLoad = clamp(lerp(d.engineLoad, throttle * 1.2 + 18, dt * 1.5), 0, 100);
  const mapKpa = clamp(30 + throttle * 1.6 + Math.random() * 4, 25, 220);
  const mafGs = clamp(2 + throttle * 0.3 + speed * 0.05 + Math.random() * 0.6, 1, 50);
  const o2b1 = clamp(0.45 + Math.sin(phase * 6) * 0.3 + (Math.random() - 0.5) * 0.05, 0.05, 0.95);
  const o2b2 = clamp(0.45 + Math.sin(phase * 6 + 1.2) * 0.3 + (Math.random() - 0.5) * 0.05, 0.05, 0.95);
  const ftStB1 = clamp(d.ftStB1 + (Math.random() - 0.5) * 0.4, -8, 8);
  const ftLtB1 = clamp(d.ftLtB1 + (Math.random() - 0.5) * 0.05, -8, 4);
  const ftStB2 = clamp(d.ftStB2 + (Math.random() - 0.5) * 0.4, -8, 8);
  const ftLtB2 = clamp(d.ftLtB2 + (Math.random() - 0.5) * 0.05, -8, 4);
  const ignAdv = clamp(lerp(d.ignAdv, 12 + (1 - throttle / 100) * 22, dt * 1.5), 0, 45);
  const catTemp = clamp(lerp(d.catTemp, 500 + engineLoad * 4, dt * 0.08), 400, 880);

  // Nav
  const heading = (d.heading + dt * 4) % 360;
  const tripKm = d.tripKm + (speed / 3600) * dt;
  const totalKm = d.totalKm + (speed / 3600) * dt;
  const avgSpeed = d.avgSpeed + (speed - d.avgSpeed) * dt * 0.02;
  const gpsLat = d.gpsLat + Math.cos(heading * Math.PI / 180) * speed * 0.0000003 * dt;
  const gpsLon = d.gpsLon + Math.sin(heading * Math.PI / 180) * speed * 0.0000003 * dt;
  const gpsAlt = d.gpsAlt + Math.sin(phase * 0.4) * 0.3 + (Math.random() - 0.5) * 0.4;

  return {
    ...d,
    _phase: phase, _targetSpeed: targetSpeed, _targetThrottle: targetThrottle,
    speed, rpm, throttle, gear, coolantC, fuel, batteryV, ambientC, intakeC,
    engineLoad, mapKpa, mafGs, o2b1, o2b2, ftStB1, ftLtB1, ftStB2, ftLtB2,
    ignAdv, catTemp,
    heading, tripKm, totalKm, avgSpeed, gpsLat, gpsLon, gpsAlt,
    etaMin: d.etaMin,
  };
}

function lerp(a, b, t) { return a + (b - a) * Math.min(1, Math.max(0, t)); }
function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

const DTC_LIST = [
  { code: "P0420", desc: "Catalyst System Efficiency Below Threshold (Bank 1)", module: "ECM", status: "Active",   sev: "crit" },
  { code: "P0171", desc: "System Too Lean (Bank 1)",                          module: "ECM", status: "Pending",  sev: "warn" },
  { code: "P0301", desc: "Cylinder 1 Misfire Detected",                       module: "ECM", status: "Pending",  sev: "warn" },
  { code: "C1234", desc: "Wheel Speed Sensor Front-Left · Intermittent",      module: "ABS", status: "Stored",   sev: "info" },
  { code: "U0100", desc: "Lost Communication With ECM/PCM \"A\"",             module: "BCM", status: "Stored",   sev: "info" },
  { code: "B1318", desc: "Battery Voltage Low",                                module: "BCM", status: "Cleared",  sev: "info" },
];

Object.assign(window, { useTelemetry, DTC_LIST });
