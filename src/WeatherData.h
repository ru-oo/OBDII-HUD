#pragma once
// WeatherData.h
// OpenWeatherMap API → QML 바인딩

#include <QObject>
#include <QTimer>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class WeatherData : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString desc   READ desc   NOTIFY descChanged)
    Q_PROPERTY(double  temp   READ temp   NOTIFY tempChanged)
    Q_PROPERTY(QString icon   READ icon   NOTIFY iconChanged)
    Q_PROPERTY(bool    isDay  READ isDay  NOTIFY isDayChanged)

public:
    explicit WeatherData(const QString &apiKey = "YOUR_API_KEY",
                         const QString &city   = "Daegu",
                         QObject       *parent  = nullptr);

    QString desc()  const { return m_desc; }
    double  temp()  const { return m_temp; }
    QString icon()  const { return m_icon; }
    bool    isDay() const { return m_isDay; }

    Q_INVOKABLE void refresh();

signals:
    void descChanged(const QString &);
    void tempChanged(double);
    void iconChanged(const QString &);
    void isDayChanged(bool);

private slots:
    void onReply(QNetworkReply *reply);

private:
    QString iconFromMain(const QString &main) const;

    QString m_apiKey;
    QString m_city;
    QString m_desc  = "맑음";
    double  m_temp  = 22.0;
    QString m_icon  = "clear";
    bool    m_isDay = true;

    QNetworkAccessManager m_nam;
    QTimer                m_timer;
};
