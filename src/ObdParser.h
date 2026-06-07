#pragma once
#include "ObdValues.h"

class ObdParser
{
public:
    // Parse ELM327 response (ATH0, ATS1 mode: "41 0C 1A F8")
    // Returns true if any value was updated
    static bool parseElm327Line(const QByteArray &line, ObdValues &out);

    // Legacy UART format: "RPM:2500,SPD:80,TEMP:90,THROTTLE:45,LOAD:60,FUEL:70"
    static bool parseUartLine(const QByteArray &line, ObdValues &out);

private:
    static bool applyPid(quint8 pid,
                         quint8 a, quint8 b, quint8 c, quint8 d,
                         ObdValues &out);

    // PID formula helpers
    static double rpm      (quint8 a, quint8 b) { return (a * 256.0 + b) / 4.0; }
    static double speed    (quint8 a)            { return a; }
    static double temp     (quint8 a)            { return a - 40.0; }
    static double pct255   (quint8 a)            { return a * 100.0 / 255.0; }
    static double pct128   (quint8 a)            { return (a - 128) * 100.0 / 128.0; }
    static double kpaA     (quint8 a)            { return a * 3.0; }
    static double kpaAB    (quint8 a, quint8 b)  { return (a * 256.0 + b) * 0.079; }
    static double voltage  (quint8 a, quint8 b)  { return (a * 256.0 + b) / 1000.0; }
    static double timing   (quint8 a)            { return a / 2.0 - 64.0; }
    static double maf      (quint8 a, quint8 b)  { return (a * 256.0 + b) / 100.0; }
    static double catalystT(quint8 a, quint8 b)  { return (a * 256.0 + b) / 10.0 - 40.0; }
};
