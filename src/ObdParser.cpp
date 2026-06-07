#include "ObdParser.h"

bool ObdParser::parseElm327Line(const QByteArray &line, ObdValues &out)
{
    // Skip error responses
    if (line.contains("NO DATA") || line.contains("ERROR") ||
        line.contains("UNABLE") || line.contains("BUS"))
        return false;

    // Split hex bytes, e.g. "41 0C 1A F8" → [0x41, 0x0C, 0x1A, 0xF8]
    QList<QByteArray> parts = line.trimmed().split(' ');
    parts.removeAll("");

    if (parts.size() < 3) return false;

    bool ok;
    quint8 mode = parts[0].toUShort(&ok, 16);
    if (!ok || mode != 0x41) return false;    // Mode 01 positive response

    quint8 pid = parts[1].toUShort(&ok, 16);
    if (!ok) return false;

    auto byte = [&](int idx) -> quint8 {
        if (idx < parts.size()) {
            bool o; quint8 v = parts[idx].toUShort(&o, 16); return o ? v : 0;
        }
        return 0;
    };

    return applyPid(pid, byte(2), byte(3), byte(4), byte(5), out);
}

bool ObdParser::applyPid(quint8 pid,
                          quint8 a, quint8 b, quint8 c, quint8 d,
                          ObdValues &out)
{
    Q_UNUSED(c); Q_UNUSED(d);
    switch (pid) {
    // ── Engine
    case 0x04: out.engineLoad    = pct255(a);         return true;
    case 0x05: out.coolantTemp   = temp(a);            return true;
    case 0x06: out.shortFuelTrim1= pct128(a);          return true;
    case 0x07: out.longFuelTrim1 = pct128(a);          return true;
    case 0x08: out.shortFuelTrim2= pct128(a);          return true;
    case 0x09: out.longFuelTrim2 = pct128(a);          return true;
    case 0x0A: out.fuelPressure  = kpaA(a);            return true;
    case 0x0B: out.manifoldPres  = a;                  return true;  // kPa
    case 0x0C: out.rpm           = rpm(a, b);          return true;
    case 0x0D: out.speed         = speed(a);           return true;
    case 0x0E: out.timingAdv     = timing(a);          return true;
    case 0x0F: out.intakeTemp    = temp(a);            return true;
    case 0x10: out.mafRate       = maf(a, b);          return true;
    case 0x11: out.throttle      = pct255(a);          return true;

    // ── Fuel
    case 0x1F: out.runTimeSec    = a * 256.0 + b;     return true;
    case 0x21: out.distMilOn     = a * 256.0 + b;     return true;
    case 0x22: out.fuelRailPres  = kpaAB(a, b);       return true;
    case 0x2C: out.cmdEGR        = pct255(a);          return true;
    case 0x2D: out.egrError      = pct128(a);          return true;
    case 0x2E: out.cmdEvapPurge  = pct255(a);          return true;
    case 0x2F: out.fuelLevel     = pct255(a);          return true;
    case 0x30: out.warmups       = a;                  return true;
    case 0x31: out.distCleaned   = a * 256.0 + b;     return true;
    case 0x33: out.baroPressure  = a;                  return true;  // kPa

    // ── Catalyst
    case 0x3C: out.catalystTemp  = catalystT(a, b);   return true;

    // ── Electrical / misc
    case 0x42: out.ctrlVoltage   = voltage(a, b);     return true;
    case 0x43: out.absLoad       = (a * 256.0 + b) * 100.0 / 65535.0; return true;
    case 0x44: out.cmdAFR        = (a * 256.0 + b) / 32768.0;          return true;
    case 0x45: out.relThrottle   = pct255(a);          return true;
    case 0x46: out.ambientTemp   = temp(a);            return true;
    case 0x47: out.absThrottleB  = pct255(a);          return true;
    case 0x49: out.accelPedalD   = pct255(a);          return true;
    case 0x4A: out.accelPedalE   = pct255(a);          return true;
    case 0x4C: out.cmdThrottle   = pct255(a);          return true;
    case 0x4D: out.timeMilOn     = a * 256.0 + b;     return true;
    case 0x4E: out.timeCleaned   = a * 256.0 + b;     return true;
    case 0x5C: out.oilTemp       = temp(a);            return true;
    case 0x5E: out.fuelRate      = (a * 256.0 + b) / 20.0; return true;
    case 0x62: out.engineTorqPct = a - 125.0;          return true;

    default: return false;
    }
}

bool ObdParser::parseUartLine(const QByteArray &line, ObdValues &out)
{
    // "RPM:2500,SPD:80,TEMP:90,THROTTLE:45,LOAD:60,FUEL:70"
    bool anyOk = false;
    for (const QByteArray &token : line.trimmed().split(',')) {
        const QList<QByteArray> kv = token.split(':');
        if (kv.size() != 2) continue;
        const QString key = QString(kv[0]).trimmed().toUpper();
        bool ok = false;
        double val = kv[1].trimmed().toDouble(&ok);
        if (!ok) continue;

        if      (key == "RPM")      { out.rpm        = val; anyOk = true; }
        else if (key == "SPD")      { out.speed       = val; anyOk = true; }
        else if (key == "TEMP")     { out.coolantTemp = val; anyOk = true; }
        else if (key == "THROTTLE") { out.throttle    = val; anyOk = true; }
        else if (key == "LOAD")     { out.engineLoad  = val; anyOk = true; }
        else if (key == "FUEL")     { out.fuelLevel   = val; anyOk = true; }
        else if (key == "OAT")      { out.ambientTemp = val; anyOk = true; }
        else if (key == "VOLT")     { out.ctrlVoltage = val; anyOk = true; }
        else if (key == "OIL")      { out.oilTemp     = val; anyOk = true; }
        else if (key == "MAF")      { out.mafRate     = val; anyOk = true; }
    }
    return anyOk;
}
