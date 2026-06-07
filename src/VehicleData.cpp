#include "VehicleData.h"
#include <QtMath>
#include <QDebug>

VehicleData::VehicleData(QObject *parent) : QObject(parent)
{
    connect(&m_obd, &ObdManager::valuesUpdated, this, &VehicleData::onObdValues);
    connect(&m_obd, &ObdManager::dtcListUpdated, this, &VehicleData::onDtcList);
    connect(&m_obd, &ObdManager::connectionChanged, this, [this](bool c) {
        ObdValues next = v;
        next.connected = c;
        applyValues(next);
    });

    // Do NOT request location permissions in constructor.
    // iOS will ignore it or crash if UI is not fully loaded.
    // Call initHardwarePermissions() from QML Component.onCompleted.

    // setDummyMode(true); // User wants to test with real car data over Wi-Fi
}

void VehicleData::initHardwarePermissions()
{
    requestLocationPermission();
}

void VehicleData::requestLocationPermission()
{
#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
    QLocationPermission permission;
    permission.setAccuracy(QLocationPermission::Precise);

    switch (qApp->checkPermission(permission)) {
    case Qt::PermissionStatus::Undetermined:
        qApp->requestPermission(permission, this, [this](const QPermission &p) {
            if (p.status() == Qt::PermissionStatus::Granted) {
                startGps();
            } else {
                qWarning() << "Location permission denied by user.";
            }
        });
        break;
    case Qt::PermissionStatus::Denied:
        qWarning() << "Location permission previously denied.";
        break;
    case Qt::PermissionStatus::Granted:
        startGps();
        break;
    }
#else
    startGps();
#endif
}

void VehicleData::startGps()
{
    m_geoSource = QGeoPositionInfoSource::createDefaultSource(this);
    if (m_geoSource) {
        connect(m_geoSource, &QGeoPositionInfoSource::positionUpdated,
                this, &VehicleData::onPositionUpdated);
        m_geoSource->startUpdates();
        qDebug() << "GPS tracking started.";
    } else {
        qWarning() << "No default GPS source found. GPS will run in simulated mode.";
    }
}

VehicleData::~VehicleData() { closePort(); }

bool VehicleData::openUdpPort(quint16 port)
{
    return m_obd.openUdpPort(port);
}

void VehicleData::closePort()
{
    m_obd.closePort();
}

// Removed dummy mode logic to ensure zero-initialization and clean launch.

void VehicleData::onObdValues(const ObdValues &next)
{
    applyValues(next);
}

void VehicleData::onDtcList(const QVariantList &dtcs)
{
    if (m_dtcList != dtcs) {
        m_dtcList = dtcs;
        emit dtcListChanged();
    }
}

void VehicleData::onPositionUpdated(const QGeoPositionInfo &info)
{
    if (info.isValid()) {
        QGeoCoordinate coord = info.coordinate();
        if (coord.isValid()) {
            m_lat = coord.latitude();
            m_lon = coord.longitude();
            m_altM = coord.altitude();
        }
        if (info.hasAttribute(QGeoPositionInfo::Direction)) {
            m_heading = info.attribute(QGeoPositionInfo::Direction);
        }
        // Calculate trip locally or use external values if available
        emit gpsChanged();
    }
}

// ── Emit only changed signals
#define EMIT_IF(field, sig) \
    if (v.field != next.field) { v.field = next.field; emit sig(v.field); }

void VehicleData::applyValues(const ObdValues &next)
{
    EMIT_IF(rpm,           rpmChanged)
    EMIT_IF(speed,         speedChanged)
    EMIT_IF(throttle,      throttleChanged)
    EMIT_IF(accelPedalD,   accelPedalChanged)
    EMIT_IF(engineLoad,    engineLoadChanged)
    EMIT_IF(coolantTemp,   coolantTempChanged)
    EMIT_IF(intakeTemp,    intakeTempChanged)
    EMIT_IF(oilTemp,       oilTempChanged)
    EMIT_IF(timingAdv,     timingAdvChanged)
    EMIT_IF(mafRate,       mafRateChanged)
    EMIT_IF(manifoldPres,  manifoldPresChanged)
    EMIT_IF(engineTorqPct, engineTorqPctChanged)
    EMIT_IF(runTimeSec,    runTimeSecChanged)
    EMIT_IF(fuelLevel,     fuelLevelChanged)
    EMIT_IF(fuelPressure,  fuelPressureChanged)
    EMIT_IF(fuelRate,      fuelRateChanged)
    EMIT_IF(shortFuelTrim1,shortFuelTrim1Changed)
    EMIT_IF(longFuelTrim1, longFuelTrim1Changed)
    EMIT_IF(absLoad,       absLoadChanged)
    EMIT_IF(cmdAFR,        cmdAFRChanged)
    EMIT_IF(relThrottle,   relThrottleChanged)
    EMIT_IF(cmdThrottle,   cmdThrottleChanged)
    EMIT_IF(ambientTemp,   ambientTempChanged)
    EMIT_IF(baroPressure,  baroPressureChanged)
    EMIT_IF(ctrlVoltage,   ctrlVoltageChanged)
    EMIT_IF(catalystTemp,  catalystTempChanged)
    EMIT_IF(milOn,         milOnChanged)
    EMIT_IF(distMilOn,     distMilOnChanged)
    EMIT_IF(connected,     connectedChanged)
}
