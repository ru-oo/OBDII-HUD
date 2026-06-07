#pragma once
// ThemeManager.h  – 4-theme system exposed to QML as context property
// Themes: 0=Tesla Dark  1=Ocean Blue  2=Carbon Amber  3=Arctic White
// Cycle with nextTheme() or set themeIndex directly.

#include <QObject>
#include <QColor>

class ThemeManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int     themeIndex   READ themeIndex   WRITE setThemeIndex NOTIFY themeChanged)
    Q_PROPERTY(QString themeName    READ themeName    NOTIFY themeChanged)

    // Background / surface
    Q_PROPERTY(QColor bgColor       READ bgColor       NOTIFY themeChanged)
    Q_PROPERTY(QColor panelBg       READ panelBg       NOTIFY themeChanged)
    Q_PROPERTY(QColor panelBorder   READ panelBorder   NOTIFY themeChanged)

    // Text
    Q_PROPERTY(QColor textColor     READ textColor     NOTIFY themeChanged)
    Q_PROPERTY(QColor dimText       READ dimText       NOTIFY themeChanged)

    // Accent colors
    Q_PROPERTY(QColor accent        READ accent        NOTIFY themeChanged)
    Q_PROPERTY(QColor accent2       READ accent2       NOTIFY themeChanged)

    // Gauge
    Q_PROPERTY(QColor gaugeTrack    READ gaugeTrack    NOTIFY themeChanged)
    Q_PROPERTY(QColor gaugeFill     READ gaugeFill     NOTIFY themeChanged)
    Q_PROPERTY(QColor gaugeWarn     READ gaugeWarn     NOTIFY themeChanged)
    Q_PROPERTY(QColor gaugeDanger   READ gaugeDanger   NOTIFY themeChanged)

    // Bar / divider
    Q_PROPERTY(QColor divider       READ divider       NOTIFY themeChanged)

    // Special: left gauge accent, right gauge accent
    Q_PROPERTY(QColor leftAccent    READ leftAccent    NOTIFY themeChanged)
    Q_PROPERTY(QColor rightAccent   READ rightAccent   NOTIFY themeChanged)

public:
    explicit ThemeManager(QObject *parent = nullptr);

    int     themeIndex()  const { return m_idx; }
    QString themeName()   const;
    QColor  bgColor()     const;
    QColor  panelBg()     const;
    QColor  panelBorder() const;
    QColor  textColor()   const;
    QColor  dimText()     const;
    QColor  accent()      const;
    QColor  accent2()     const;
    QColor  gaugeTrack()  const;
    QColor  gaugeFill()   const;
    QColor  gaugeWarn()   const;
    QColor  gaugeDanger() const;
    QColor  divider()     const;
    QColor  leftAccent()  const;
    QColor  rightAccent() const;

    Q_INVOKABLE void setThemeIndex(int idx);
    Q_INVOKABLE void nextTheme();
    Q_INVOKABLE void prevTheme();

signals:
    void themeChanged();

private:
    int m_idx = 0;
    static constexpr int kThemeCount = 4;

    struct Theme {
        const char *name;
        const char *bg, *panel, *border;
        const char *text, *dim;
        const char *acc1, *acc2;
        const char *track, *fill;
        const char *warn, *danger;
        const char *divider;
        const char *leftAcc, *rightAcc;
    };
    static const Theme s_themes[kThemeCount];
};
