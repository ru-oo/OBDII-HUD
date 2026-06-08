#pragma once
// VehicleData.h  – QML context property exposing all OBD-2 values + GPS
// Source: openUdpPort(port) receives telemetry via ObdManager (UDP);
// GPS via QGeoPositionInfoSource. Emits a *Changed signal only on value change.

#include "ObdManager.h"
#include "ObdValues.h"
#include <QCoreApplication>
#include <QGeoPositionInfo>
#include <QGeoPositionInfoSource>
#include <QObject>
#include <QPermissions>
#include <QTimer>

class VehicleData : public QObject {
  Q_OBJECT

  // ── Core driving
  Q_PROPERTY(double rpm READ rpm NOTIFY rpmChanged)
  Q_PROPERTY(double speed READ speed NOTIFY speedChanged)
  Q_PROPERTY(double throttle READ throttle NOTIFY throttleChanged)
  Q_PROPERTY(double accelPedal READ accelPedal NOTIFY accelPedalChanged)

  // ── Engine
  Q_PROPERTY(double engineLoad READ engineLoad NOTIFY engineLoadChanged)
  Q_PROPERTY(double coolantTemp READ coolantTemp NOTIFY coolantTempChanged)
  Q_PROPERTY(double intakeTemp READ intakeTemp NOTIFY intakeTempChanged)
  Q_PROPERTY(double oilTemp READ oilTemp NOTIFY oilTempChanged)
  Q_PROPERTY(double timingAdv READ timingAdv NOTIFY timingAdvChanged)
  Q_PROPERTY(double mafRate READ mafRate NOTIFY mafRateChanged)
  Q_PROPERTY(double manifoldPres READ manifoldPres NOTIFY manifoldPresChanged)
  Q_PROPERTY(
      double engineTorqPct READ engineTorqPct NOTIFY engineTorqPctChanged)
  Q_PROPERTY(double runTimeSec READ runTimeSec NOTIFY runTimeSecChanged)

  // ── Fuel
  Q_PROPERTY(double fuelLevel READ fuelLevel NOTIFY fuelLevelChanged)
  Q_PROPERTY(double fuelPressure READ fuelPressure NOTIFY fuelPressureChanged)
  Q_PROPERTY(double fuelRate READ fuelRate NOTIFY fuelRateChanged)
  Q_PROPERTY(
      double shortFuelTrim1 READ shortFuelTrim1 NOTIFY shortFuelTrim1Changed)
  Q_PROPERTY(
      double longFuelTrim1 READ longFuelTrim1 NOTIFY longFuelTrim1Changed)
  Q_PROPERTY(double absLoad READ absLoad NOTIFY absLoadChanged)
  Q_PROPERTY(double cmdAFR READ cmdAFR NOTIFY cmdAFRChanged)

  // ── Throttle / pedal
  Q_PROPERTY(double relThrottle READ relThrottle NOTIFY relThrottleChanged)
  Q_PROPERTY(double cmdThrottle READ cmdThrottle NOTIFY cmdThrottleChanged)

  // ── Environment
  Q_PROPERTY(double ambientTemp READ ambientTemp NOTIFY ambientTempChanged)
  Q_PROPERTY(double baroPressure READ baroPressure NOTIFY baroPressureChanged)

  // ── GPS / Navigation
  Q_PROPERTY(double lat READ lat NOTIFY gpsChanged)
  Q_PROPERTY(double lon READ lon NOTIFY gpsChanged)
  Q_PROPERTY(double altM READ altM NOTIFY gpsChanged)
  Q_PROPERTY(double heading READ heading NOTIFY gpsChanged)
  Q_PROPERTY(double tripKm READ tripKm NOTIFY gpsChanged)
  Q_PROPERTY(double odoKm READ odoKm NOTIFY gpsChanged)

  // ── TPMS (Tire Pressure)
  Q_PROPERTY(double tpmsFl READ tpmsFl NOTIFY tpmsChanged)
  Q_PROPERTY(double tpmsFr READ tpmsFr NOTIFY tpmsChanged)
  Q_PROPERTY(double tpmsRl READ tpmsRl NOTIFY tpmsChanged)
  Q_PROPERTY(double tpmsRr READ tpmsRr NOTIFY tpmsChanged)

  // ── Electrical
  Q_PROPERTY(double ctrlVoltage READ ctrlVoltage NOTIFY ctrlVoltageChanged)

  // ── Catalyst
  Q_PROPERTY(double catalystTemp READ catalystTemp NOTIFY catalystTempChanged)

  // ── Diagnostics
  Q_PROPERTY(bool milOn READ milOn NOTIFY milOnChanged)
  Q_PROPERTY(double distMilOn READ distMilOn NOTIFY distMilOnChanged)
  Q_PROPERTY(QVariantList dtcList READ dtcList NOTIFY dtcListChanged)

  // ── Status
  Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

public:
  explicit VehicleData(QObject *parent = nullptr);
  ~VehicleData();

  Q_INVOKABLE void initHardwarePermissions();
  Q_INVOKABLE bool openUdpPort(quint16 port = 35000);
  Q_INVOKABLE void closePort();

  // Getters
  double rpm() const { return v.rpm; }
  double speed() const { return v.speed; }
  double throttle() const { return v.throttle; }
  double accelPedal() const { return v.accelPedalD; }
  double engineLoad() const { return v.engineLoad; }
  double coolantTemp() const { return v.coolantTemp; }
  double intakeTemp() const { return v.intakeTemp; }
  double oilTemp() const { return v.oilTemp; }
  double timingAdv() const { return v.timingAdv; }
  double mafRate() const { return v.mafRate; }
  double manifoldPres() const { return v.manifoldPres; }
  double engineTorqPct() const { return v.engineTorqPct; }
  double runTimeSec() const { return v.runTimeSec; }
  double fuelLevel() const { return v.fuelLevel; }
  double fuelPressure() const { return v.fuelPressure; }
  double fuelRate() const { return v.fuelRate; }
  double shortFuelTrim1() const { return v.shortFuelTrim1; }
  double longFuelTrim1() const { return v.longFuelTrim1; }
  double absLoad() const { return v.absLoad; }
  double cmdAFR() const { return v.cmdAFR; }
  double relThrottle() const { return v.relThrottle; }
  double cmdThrottle() const { return v.cmdThrottle; }
  double ambientTemp() const { return v.ambientTemp; }
  double baroPressure() const { return v.baroPressure; }
  double ctrlVoltage() const { return v.ctrlVoltage; }
  double catalystTemp() const { return v.catalystTemp; }
  bool milOn() const { return v.milOn; }
  double distMilOn() const { return v.distMilOn; }
  bool connected() const { return v.connected; }

  double lat() const { return m_lat; }
  double lon() const { return m_lon; }
  double altM() const { return m_altM; }
  double heading() const { return m_heading; }
  double tripKm() const { return m_tripKm; }
  double odoKm() const { return m_odoKm; }

  double tpmsFl() const { return m_tpmsFl; }
  double tpmsFr() const { return m_tpmsFr; }
  double tpmsRl() const { return m_tpmsRl; }
  double tpmsRr() const { return m_tpmsRr; }
  QVariantList dtcList() const { return m_dtcList; }

signals:
  void rpmChanged(double);
  void speedChanged(double);
  void throttleChanged(double);
  void accelPedalChanged(double);
  void engineLoadChanged(double);
  void coolantTempChanged(double);
  void intakeTempChanged(double);
  void oilTempChanged(double);
  void timingAdvChanged(double);
  void mafRateChanged(double);
  void manifoldPresChanged(double);
  void engineTorqPctChanged(double);
  void runTimeSecChanged(double);
  void fuelLevelChanged(double);
  void fuelPressureChanged(double);
  void fuelRateChanged(double);
  void shortFuelTrim1Changed(double);
  void longFuelTrim1Changed(double);
  void absLoadChanged(double);
  void cmdAFRChanged(double);
  void relThrottleChanged(double);
  void cmdThrottleChanged(double);
  void ambientTempChanged(double);
  void baroPressureChanged(double);
  void ctrlVoltageChanged(double);
  void catalystTempChanged(double);
  void milOnChanged(bool);
  void distMilOnChanged(double);
  void connectedChanged(bool);
  void gpsChanged();
  void tpmsChanged();
  void dtcListChanged();

private slots:
  void onObdValues(const ObdValues &next);
  void onDtcList(const QVariantList &dtcs);
  void onPositionUpdated(const QGeoPositionInfo &info);

private:
  void requestLocationPermission();
  void startGps();
  void applyValues(const ObdValues &next);

  ObdValues v = {};
  ObdManager m_obd;

  // GPS
  QGeoPositionInfoSource *m_geoSource = nullptr;
  double m_lat = 0.0;
  double m_lon = 0.0;
  double m_altM = 0.0;
  double m_heading = 0.0;
  double m_tripKm = 0.0;
  double m_odoKm = 0.0;

  double m_tpmsFl = 0.0;
  double m_tpmsFr = 0.0;
  double m_tpmsRl = 0.0;
  double m_tpmsRr = 0.0;

  QVariantList m_dtcList;
};
