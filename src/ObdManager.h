#pragma once
// ObdManager.h
// ELM327 OBD-2 adapter driver
//   – Sends AT init commands on connect
//   – Round-robin polls all supported standard PIDs
//   – Emits valuesUpdated() after each response

#include <QObject>
#include <QUdpSocket>
#include <QNetworkDatagram>
#include <QTimer>
#include <QVariantList>
#include "ObdValues.h"

class ObdManager : public QObject
{
    Q_OBJECT
public:
    explicit ObdManager(QObject *parent = nullptr);

    // UDP binding
    Q_INVOKABLE bool openUdpPort(quint16 port = 35000);
    Q_INVOKABLE void closePort();
    Q_INVOKABLE bool isConnected() const { return m_connected; }

signals:
    void valuesUpdated(const ObdValues &values);
    void dtcListUpdated(const QVariantList &dtcs);
    void connectionChanged(bool connected);
    void logMessage(const QString &msg);

private slots:
    void onReadyRead();

private:
    void checkDtcs(const QByteArray &line);

    QUdpSocket  m_udpSocket;
    QByteArray  m_rxBuf;
    ObdValues   m_values;

    bool m_connected = false;
    uint32_t m_lastProcessedSeqNum = 0;
};
