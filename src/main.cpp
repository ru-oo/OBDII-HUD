#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSurfaceFormat>

#include "VehicleData.h"
#include "WeatherData.h"
#include "Clock.h"
#include "ThemeManager.h"

int main(int argc, char *argv[])
{
    QSurfaceFormat fmt;
    fmt.setSamples(4);
    fmt.setDepthBufferSize(24);
    QSurfaceFormat::setDefaultFormat(fmt);

    QGuiApplication app(argc, argv);
    app.setApplicationName("HMI Cluster");

    VehicleData  vehicle;
    WeatherData  weather("YOUR_API_KEY", "Daegu");
    Clock        clock;
    ThemeManager theme;

    QQmlApplicationEngine engine;
    QQmlContext *ctx = engine.rootContext();
    ctx->setContextProperty("vehicleData", &vehicle);
    ctx->setContextProperty("weatherData", &weather);
    ctx->setContextProperty("clock",       &clock);
    ctx->setContextProperty("theme",       &theme);

    const QUrl url(QStringLiteral("qrc:/qt/qml/HudProject/qml/main.qml"));

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    engine.load(url);
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
