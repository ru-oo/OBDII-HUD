// WeatherData.cpp
#include "WeatherData.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QDebug>

WeatherData::WeatherData(const QString &apiKey,
                         const QString &city,
                         QObject       *parent)
    : QObject(parent)
    , m_apiKey(apiKey)
    , m_city(city)
{
    connect(&m_nam,   &QNetworkAccessManager::finished,
            this,     &WeatherData::onReply);

    // 5분마다 자동 갱신
    connect(&m_timer, &QTimer::timeout,
            this,     &WeatherData::refresh);
    m_timer.start(300'000);

    refresh();
}

void WeatherData::refresh()
{
    if (m_apiKey == "YOUR_API_KEY") {
        // API 키 없으면 더미 데이터 유지
        return;
    }
    QString url = QString(
        "https://api.openweathermap.org/data/2.5/weather"
        "?q=%1&appid=%2&units=metric&lang=kr"
    ).arg(m_city, m_apiKey);

    m_nam.get(QNetworkRequest(QUrl(url)));
}

void WeatherData::onReply(QNetworkReply *reply)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "[WeatherData]" << reply->errorString();
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    if (doc.isNull()) return;

    QJsonObject root    = doc.object();
    QJsonObject weather = root["weather"].toArray().first().toObject();
    QJsonObject main    = root["main"].toObject();

    QString desc    = weather["description"].toString();
    double  temp    = main["temp"].toDouble();
    QString iconCode= weather["icon"].toString();
    bool    day     = iconCode.endsWith('d');
    QString icon    = iconFromMain(weather["main"].toString().toLower());

    if (m_desc  != desc)  { m_desc  = desc;  emit descChanged(m_desc);   }
    if (m_temp  != temp)  { m_temp  = temp;  emit tempChanged(m_temp);   }
    if (m_icon  != icon)  { m_icon  = icon;  emit iconChanged(m_icon);   }
    if (m_isDay != day)   { m_isDay = day;   emit isDayChanged(m_isDay); }
}

QString WeatherData::iconFromMain(const QString &main) const
{
    if (main.contains("clear"))        return "clear";
    if (main.contains("cloud"))        return "cloudy";
    if (main.contains("rain"))         return "rain";
    if (main.contains("drizzle"))      return "rain";
    if (main.contains("thunderstorm")) return "thunder";
    if (main.contains("snow"))         return "snow";
    if (main.contains("mist")  ||
        main.contains("fog")   ||
        main.contains("haze"))         return "fog";
    return "clear";
}
