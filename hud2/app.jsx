// App shell — pages, swipe, theme state, tweaks panel, telemetry binding.

const { useState, useEffect, useRef, useCallback } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "dark",
  "simSpeed": 1.0,
  "showWarnings": true,
  "glassIntensity": 24,
  "page": 0,
  "singleBank": false,
  "catTempSupported": true,
  "tpmsAvailable": true,
  "gpsLock": true
}/*EDITMODE-END*/;

function App() {
  const [tweaks, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [page, setPage] = useState(tweaks.page || 0);
  const [sheetOpen, setSheetOpen] = useState(false);
  const [now, setNow] = useState(new Date());

  // Apply theme
  useEffect(() => {
    document.documentElement.setAttribute("data-theme", tweaks.theme);
    document.documentElement.style.setProperty("--card-blur", `${tweaks.glassIntensity}px`);
  }, [tweaks.theme, tweaks.glassIntensity]);

  // Update clock once a minute
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 30000);
    return () => clearInterval(id);
  }, []);

  // Telemetry
  const data = useTelemetry(tweaks.simSpeed);

  // Inject one warning state when toggled on
  const fuelDisplay = tweaks.showWarnings ? Math.min(data.fuel, 11) : Math.max(data.fuel, 45);
  const tpms = tweaks.showWarnings
    ? { fl: 32.4, fr: 33.1, rl: 26.2, rr: 32.8 }   // RL low
    : { fl: 33.0, fr: 33.2, rl: 32.8, rr: 33.1 };
  const dtcs = tweaks.showWarnings ? DTC_LIST : DTC_LIST.filter(d => d.sev === "info");

  const dataDisplayed = { ...data, fuel: fuelDisplay };
  if (tweaks.singleBank) {
    dataDisplayed.o2b2 = null;
    dataDisplayed.ftStB2 = null;
    dataDisplayed.ftLtB2 = null;
  }
  if (!tweaks.catTempSupported) {
    dataDisplayed.catTemp = null;
  }

  // Swipe handlers
  const startX = useRef(null);
  const startY = useRef(null);
  const dragging = useRef(false);
  const onPointerDown = (e) => {
    startX.current = e.clientX; startY.current = e.clientY; dragging.current = false;
  };
  const onPointerMove = (e) => {
    if (startX.current == null) return;
    if (Math.abs(e.clientX - startX.current) > 8) dragging.current = true;
  };
  const onPointerUp = (e) => {
    if (startX.current == null) return;
    const dx = e.clientX - startX.current;
    const dy = e.clientY - startY.current;
    if (Math.abs(dx) > 80 && Math.abs(dx) > Math.abs(dy) * 1.4) {
      if (dx < 0 && page < 2) setPage(p => p + 1);
      else if (dx > 0 && page > 0) setPage(p => p - 1);
    }
    startX.current = null; startY.current = null;
  };

  // Keyboard
  useEffect(() => {
    const onKey = (e) => {
      if (e.key === "ArrowLeft" && page > 0) setPage(p => p - 1);
      if (e.key === "ArrowRight" && page < 2) setPage(p => p + 1);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [page]);

  // Auto-fit canvas to viewport
  const stageRef = useRef(null);
  const canvasRef = useRef(null);
  useEffect(() => {
    const fit = () => {
      if (!canvasRef.current) return;
      const sx = window.innerWidth / 2388;
      const sy = window.innerHeight / 1668;
      const s = Math.min(sx, sy);
      canvasRef.current.style.transform = `scale(${s})`;
    };
    fit();
    window.addEventListener("resize", fit);
    return () => window.removeEventListener("resize", fit);
  }, []);

  return (
    <div className="hud-stage" ref={stageRef}>
      <div className="hud-canvas" ref={canvasRef}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}>

        <StatusBar gpsLock={tweaks.gpsLock} obdConnected batteryV={data.batteryV} time={now} />

        <div style={{ position: "absolute", top: 56, left: 0, right: 0, bottom: 0, overflow: "hidden" }}>
          <div className="pages-track" style={{ transform: `translateX(${-page * 2388}px)` }}>
            <div className="page" style={{ width: 2388 }}>
              <Page1Driving data={dataDisplayed} />
            </div>
            <div className="page" style={{ width: 2388 }}>
              <Page2Engine data={dataDisplayed} dtcs={dtcs} />
            </div>
            <div className="page" style={{ width: 2388 }}>
              <Page3Nav data={dataDisplayed} tpms={tpms}
                gpsLock={tweaks.gpsLock} tpmsAvailable={tweaks.tpmsAvailable} />
            </div>
          </div>
        </div>

        <PageDots count={3} current={page} onSelect={setPage} />
        <ThemeFAB onClick={() => setSheetOpen(true)} />
        <ThemeSheet
          open={sheetOpen}
          onClose={() => setSheetOpen(false)}
          theme={tweaks.theme}
          onTheme={(t) => setTweak("theme", t)}
          accent={null}
          onAccent={() => {}}
          simSpeed={tweaks.simSpeed}
          onSimSpeed={(v) => setTweak("simSpeed", v)} />

        {/* Tweaks panel — host-controlled */}
        <TweaksPanel title="Tweaks">
          <TweakSection title="Theme">
            <TweakRadio
              value={tweaks.theme}
              onChange={(v) => setTweak("theme", v)}
              options={[
                { value: "dark", label: "Dark" },
                { value: "light", label: "Light" },
                { value: "night", label: "Night" },
              ]} />
          </TweakSection>
          <TweakSection title="Simulation">
            <TweakSlider label="Speed" min={0} max={3} step={0.1}
              value={tweaks.simSpeed} onChange={(v) => setTweak("simSpeed", v)}
              format={(v) => `${v.toFixed(1)}×`} />
            <TweakToggle label="Show warnings"
              value={tweaks.showWarnings}
              onChange={(v) => setTweak("showWarnings", v)} />
          </TweakSection>
          <TweakSection title="Glass">
            <TweakSlider label="Blur" min={0} max={40} step={1}
              value={tweaks.glassIntensity} onChange={(v) => setTweak("glassIntensity", v)}
              format={(v) => `${v}px`} />
          </TweakSection>
          <TweakSection title="Vehicle PIDs">
            <TweakToggle label="Single-bank engine (no Bank 2)"
              value={tweaks.singleBank}
              onChange={(v) => setTweak("singleBank", v)} />
            <TweakToggle label="Catalyst temp PID 0x3C"
              value={tweaks.catTempSupported}
              onChange={(v) => setTweak("catTempSupported", v)} />
            <TweakToggle label="TPMS available"
              value={tweaks.tpmsAvailable}
              onChange={(v) => setTweak("tpmsAvailable", v)} />
            <TweakToggle label="GPS signal lock"
              value={tweaks.gpsLock}
              onChange={(v) => setTweak("gpsLock", v)} />
          </TweakSection>
          <TweakSection title="Page">
            <TweakRadio
              value={String(page)}
              onChange={(v) => setPage(parseInt(v, 10))}
              options={[
                { value: "0", label: "Drive" },
                { value: "1", label: "Engine" },
                { value: "2", label: "Map" },
              ]} />
          </TweakSection>
        </TweaksPanel>
      </div>
    </div>
  );
}

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(<App />);
