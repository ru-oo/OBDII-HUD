#include "ThemeManager.h"

// ── 4 built-in themes ─────────────────────────────────────────────
//  name | bg | panel | border | text | dim | acc1 | acc2 |
//  track | fill | warn | danger | divider | leftAcc | rightAcc
const ThemeManager::Theme ThemeManager::s_themes[ThemeManager::kThemeCount] = {
    {   // 0 – Tesla Dark
        "Tesla Dark",
        "#0A0A0A", "#141414", "#2A2A2A",
        "#FFFFFF",  "#707070",
        "#E82127",  "#FF4444",
        "#1E1E1E",  "#E82127",
        "#FFC107",  "#FF5252",
        "#252525",
        "#E82127",  "#CC1A1F"
    },
    {   // 1 – Ocean Blue
        "Ocean Blue",
        "#010B18", "#041628", "#0A3050",
        "#E0F4FF",  "#4080A0",
        "#00D4FF",  "#0080FF",
        "#051020",  "#00D4FF",
        "#FFD600",  "#FF5252",
        "#0A2040",
        "#00D4FF",  "#0080FF"
    },
    {   // 2 – Carbon Amber
        "Carbon Amber",
        "#080808", "#100A00", "#2A1800",
        "#FFEEDD",  "#806040",
        "#FF8C00",  "#FFC107",
        "#1A0E00",  "#FF8C00",
        "#FFDD00",  "#FF3030",
        "#1E1000",
        "#FF8C00",  "#FFC107"
    },
    {   // 3 – Arctic White
        "Arctic White",
        "#E8EDF5", "#FFFFFF", "#CDD5E0",
        "#1A1A2E",  "#606080",
        "#0066CC",  "#004499",
        "#D0D8E8",  "#0066CC",
        "#FF8F00",  "#D32F2F",
        "#C0C8D8",
        "#0066CC",  "#004499"
    }
};

ThemeManager::ThemeManager(QObject *parent) : QObject(parent) {}

void ThemeManager::setThemeIndex(int idx)
{
    m_idx = ((idx % kThemeCount) + kThemeCount) % kThemeCount;
    emit themeChanged();
}

void ThemeManager::nextTheme() { setThemeIndex(m_idx + 1); }
void ThemeManager::prevTheme() { setThemeIndex(m_idx - 1); }

#define THEME s_themes[m_idx]
QString ThemeManager::themeName()   const { return THEME.name; }
QColor  ThemeManager::bgColor()     const { return QColor(THEME.bg); }
QColor  ThemeManager::panelBg()     const { return QColor(THEME.panel); }
QColor  ThemeManager::panelBorder() const { return QColor(THEME.border); }
QColor  ThemeManager::textColor()   const { return QColor(THEME.text); }
QColor  ThemeManager::dimText()     const { return QColor(THEME.dim); }
QColor  ThemeManager::accent()      const { return QColor(THEME.acc1); }
QColor  ThemeManager::accent2()     const { return QColor(THEME.acc2); }
QColor  ThemeManager::gaugeTrack()  const { return QColor(THEME.track); }
QColor  ThemeManager::gaugeFill()   const { return QColor(THEME.fill); }
QColor  ThemeManager::gaugeWarn()   const { return QColor(THEME.warn); }
QColor  ThemeManager::gaugeDanger() const { return QColor(THEME.danger); }
QColor  ThemeManager::divider()     const { return QColor(THEME.divider); }
QColor  ThemeManager::leftAccent()  const { return QColor(THEME.leftAcc); }
QColor  ThemeManager::rightAccent() const { return QColor(THEME.rightAcc); }
