#pragma once
#include <QtCore>

// All standard OBD-2 Mode 01 PID values
struct ObdValues {
    // ── Core driving (polled every cycle)
    double rpm           = 0;      // 0x0C  Engine RPM (rpm)
    double speed         = 0;      // 0x0D  Vehicle speed (km/h)
    double throttle      = 0;      // 0x11  Absolute throttle position (%)
    double accelPedalD   = 0;      // 0x49  Accelerator pedal position D (%)

    // ── Engine
    double engineLoad    = 0;      // 0x04  Calculated engine load (%)
    double coolantTemp   = 0;      // 0x05  Engine coolant temperature (°C)
    double intakeTemp    = 0;      // 0x0F  Intake air temperature (°C)
    double oilTemp       = 0;      // 0x5C  Engine oil temperature (°C)
    double timingAdv     = 0;      // 0x0E  Timing advance (° BTDC)
    double mafRate       = 0;      // 0x10  MAF air flow rate (g/s)
    double manifoldPres  = 0;      // 0x0B  Intake manifold absolute pressure (kPa)
    double engineTorqPct = 0;      // 0x62  Actual engine - percent torque (%)
    double runTimeSec    = 0;      // 0x1F  Run time since engine start (s)

    // ── Fuel system
    double fuelLevel     = 0;      // 0x2F  Fuel tank level input (%)
    double fuelPressure  = 0;      // 0x0A  Fuel pressure (kPa)
    double fuelRailPres  = 0;      // 0x22  Fuel rail pressure (kPa)
    double fuelRate      = 0;      // 0x5E  Engine fuel rate (L/h)
    double shortFuelTrim1= 0;      // 0x06  Short term fuel trim Bank 1 (%)
    double longFuelTrim1 = 0;      // 0x07  Long term fuel trim Bank 1 (%)
    double shortFuelTrim2= 0;      // 0x08  Short term fuel trim Bank 2 (%)
    double longFuelTrim2 = 0;      // 0x09  Long term fuel trim Bank 2 (%)
    double cmdEvapPurge  = 0;      // 0x2E  Commanded evaporative purge (%)
    double absLoad       = 0;      // 0x43  Absolute load value (%)
    double cmdAFR        = 0;      // 0x44  Commanded Air-Fuel equiv ratio (λ)

    // ── Throttle / pedal
    double relThrottle   = 0;      // 0x45  Relative throttle position (%)
    double absThrottleB  = 0;      // 0x47  Absolute throttle position B (%)
    double accelPedalE   = 0;      // 0x4A  Accelerator pedal position E (%)
    double cmdThrottle   = 0;      // 0x4C  Commanded throttle actuator (%)

    // ── Atmosphere / environment
    double ambientTemp   = 0;      // 0x46  Ambient air temperature (°C)
    double baroPressure  = 0;      // 0x33  Barometric pressure (kPa)

    // ── Electrical
    double ctrlVoltage   = 0;      // 0x42  Control module voltage (V)

    // ── Catalyst
    double catalystTemp  = 0;      // 0x3C  Catalyst temp Bank 1 Sensor 1 (°C)

    // ── EGR
    double cmdEGR        = 0;      // 0x2C  Commanded EGR (%)
    double egrError      = 0;      // 0x2D  EGR error (%)

    // ── Diagnostics
    bool   milOn         = false;  // MIL (Check Engine) illuminated
    double distMilOn     = 0;      // 0x21  Distance traveled with MIL on (km)
    double distCleaned   = 0;      // 0x31  Distance since codes cleared (km)
    double timeMilOn     = 0;      // 0x4D  Time run with MIL on (min)
    double timeCleaned   = 0;      // 0x4E  Time since codes cleared (min)
    int    warmups       = 0;      // 0x30  Warm-ups since codes cleared

    // ── Connection
    bool connected = false;
};
