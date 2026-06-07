#include "ObdManager.h"
#include "ObdParser.h"
#include <QDebug>


ObdManager::ObdManager(QObject *parent) : QObject(parent), m_lastProcessedSeqNum(0)
{
    connect(&m_udpSocket, &QUdpSocket::readyRead, this, &ObdManager::onReadyRead);
}

bool ObdManager::openUdpPort(quint16 port)
{
    closePort();
    m_lastProcessedSeqNum = 0; // Reset sequence tracker on new connection
    
    if (m_udpSocket.bind(QHostAddress::AnyIPv4, port, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
        m_connected = true;
        m_values.connected = true;
        emit connectionChanged(true);
        qDebug() << "[UDP] Listening for incoming data on port:" << port;
        return true;
    }
    
    qWarning() << "[UDP] Failed to bind to port:" << port;
    return false;
}

void ObdManager::closePort()
{
    m_udpSocket.close();
    m_connected = false;
    emit connectionChanged(false);
}


void ObdManager::checkDtcs(const QByteArray &line)
{
    // DTC lines start with "DTCS:" (sent as a separate line from sensor data).
    // Format: DTCS:<code>|<desc>|<ecu>|<status>|<sev>;...
    // An empty value (DTCS:) clears the list.
    const QByteArray prefix = "DTCS:";
    if (!line.trimmed().startsWith(prefix))
        return;

    QByteArray value = line.trimmed().mid(prefix.size()).trimmed();
    QVariantList dtcs;

    if (!value.isEmpty()) {
        for (const QByteArray &entry : value.split(';')) {
            QList<QByteArray> f = entry.trimmed().split('|');
            if (f.size() < 5) continue;
            QVariantMap dtc;
            dtc["code"]   = QString(f[0].trimmed());
            dtc["desc"]   = QString(f[1].trimmed());
            dtc["ecu"]    = QString(f[2].trimmed());
            dtc["status"] = QString(f[3].trimmed());
            dtc["sev"]    = f[4].trimmed().toInt();
            dtcs << dtc;
        }
    }

    emit dtcListUpdated(dtcs);
}

void ObdManager::onReadyRead()
{
    while (m_udpSocket.hasPendingDatagrams()) {
        QNetworkDatagram datagram = m_udpSocket.receiveDatagram();
        m_rxBuf += datagram.data();
        
        while (m_rxBuf.contains('\n')) {
            int idx = static_cast<int>(m_rxBuf.indexOf('\n'));
            QByteArray line = m_rxBuf.left(idx).trimmed();
            m_rxBuf.remove(0, idx + 1);
            
            if (!line.isEmpty()) {
                // Task 2: Sequence Number Validation
                int commaIdx = static_cast<int>(line.indexOf(','));
                if (commaIdx != -1) {
                    bool ok = false;
                    uint32_t seq = line.left(commaIdx).toUInt(&ok);
                    if (ok) {
                        // Allow packet if sequence is greater, OR if it's vastly smaller (indicating STM32 rebooted and reset its sequence to 0)
                        if (seq <= m_lastProcessedSeqNum && (m_lastProcessedSeqNum - seq) < 1000) {
                            // emit logMessage(QString("[UDP] Dropping out-of-order packet. Seq: %1").arg(seq));
                            continue;
                        }
                        m_lastProcessedSeqNum = seq;
                        line = line.mid(commaIdx + 1);
                    }
                }

                emit logMessage("[RX UDP] " + line);
                checkDtcs(line);
                if (ObdParser::parseElm327Line(line, m_values)) {
                    emit valuesUpdated(m_values);
                }
            }
        }
    }
}

