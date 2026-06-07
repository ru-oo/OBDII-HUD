#include <QApplication>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QSerialPort>
#include <QTextEdit>
#include <QThread>
#include <QTime>
#include <QUdpSocket>
#include <QVBoxLayout>
#include <QWidget>

class BridgeWorker : public QObject {
  Q_OBJECT
public:
  BridgeWorker(const QString &port, const QString &targetIp, int udpPort,
               QObject *parent = nullptr)
      : QObject(parent), m_port(port), m_targetIp(targetIp), m_udpPort(udpPort),
        m_serial(nullptr), m_udpSocket(nullptr) {}

public slots:
  void startBridge() {
    m_serial = new QSerialPort(this);
    m_serial->setPortName(m_port);
    m_serial->setBaudRate(115200);
    m_serial->setDataBits(QSerialPort::Data8);
    m_serial->setParity(QSerialPort::NoParity);
    m_serial->setStopBits(QSerialPort::OneStop);
    m_serial->setFlowControl(QSerialPort::NoFlowControl);

    if (!m_serial->open(QIODevice::ReadWrite)) {
      emit logMessage("ERROR: Failed to open serial port " + m_port + " -> " +
                      m_serial->errorString());
      emit stopped();
      return;
    }

    m_udpSocket = new QUdpSocket(this);

    connect(m_serial, &QSerialPort::readyRead, this,
            &BridgeWorker::onSerialReadyRead);

    emit logMessage("UDP Bridge started! Sending data to IP: " + m_targetIp +
                    " Port: " + QString::number(m_udpPort));
  }

  void stopBridge() {
    if (m_serial && m_serial->isOpen()) {
      m_serial->close();
    }
    if (m_udpSocket) {
      m_udpSocket->close();
    }
    emit logMessage("Bridge stopped.");
    emit stopped();
  }

signals:
  void logMessage(const QString &msg);
  void stopped();

private slots:
  void onSerialReadyRead() {
    m_serialBuffer.append(m_serial->readAll());

    // 데이터 조각(Fragment)이 하나로 온전해질 때까지 모았다가 \n 단위로만 전송
    while (m_serialBuffer.contains('\n')) {
      int idx = m_serialBuffer.indexOf('\n');
      QByteArray completeLine = m_serialBuffer.left(idx + 1); // \n 포함
      m_serialBuffer.remove(0, idx + 1);

      QString text = QString::fromUtf8(completeLine).trimmed();
      if (!text.isEmpty()) {
        emit logMessage("[STM32 -> UDP] " + text);
      }

      // 온전한 한 줄(예: 1234,41 0C 1A F8\n)만 전송
      QHostAddress targetAddress(m_targetIp);
      if (m_targetIp == "192.168.0.x" || m_targetIp.isEmpty() || targetAddress.isNull()) {
          // If invalid or default, send Broadcast
          m_udpSocket->writeDatagram(completeLine, QHostAddress::Broadcast, m_udpPort);
      } else {
          // If valid IP provided, send specifically to that IP
          m_udpSocket->writeDatagram(completeLine, targetAddress, m_udpPort);
      }
    }
  }

private:
  QString m_port;
  QString m_targetIp;
  int m_udpPort;
  QSerialPort *m_serial;
  QUdpSocket *m_udpSocket;
  QByteArray m_serialBuffer;
};

class BridgeWindow : public QWidget {
  Q_OBJECT
public:
  BridgeWindow(QWidget *parent = nullptr)
      : QWidget(parent), m_workerThread(nullptr), m_worker(nullptr) {
    setWindowTitle("OBD2 Laptop Bridge (STM32 to Wi-Fi UDP)");
    resize(700, 400);

    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    QHBoxLayout *topLayout = new QHBoxLayout();

    topLayout->addWidget(new QLabel("COM Port:"));
    m_portEdit = new QLineEdit("COM4");
    m_portEdit->setFixedWidth(60);
    topLayout->addWidget(m_portEdit);

    topLayout->addWidget(new QLabel("iPad IP:"));
    m_ipEdit = new QLineEdit("192.168.0.x");
    topLayout->addWidget(m_ipEdit);

    topLayout->addWidget(new QLabel("UDP Port:"));
    m_udpPortEdit = new QLineEdit("35000");
    m_udpPortEdit->setFixedWidth(60);
    topLayout->addWidget(m_udpPortEdit);

    m_startBtn = new QPushButton("Start Bridge");
    topLayout->addWidget(m_startBtn);
    mainLayout->addLayout(topLayout);

    m_logEdit = new QTextEdit();
    m_logEdit->setReadOnly(true);
    mainLayout->addWidget(m_logEdit);

    connect(m_startBtn, &QPushButton::clicked, this,
            &BridgeWindow::toggleBridge);

    logMessage("Ready. Set COM port, iPad IP, and click Start.");
  }

  ~BridgeWindow() {
    if (m_workerThread) {
      m_workerThread->quit();
      m_workerThread->wait();
    }
  }

private slots:
  void toggleBridge() {
    if (m_workerThread) {
      QMetaObject::invokeMethod(m_worker, "stopBridge", Qt::QueuedConnection);
      m_startBtn->setEnabled(false);
    } else {
      QString portName = m_portEdit->text();
      QString targetIp = m_ipEdit->text();
      int udpPort = m_udpPortEdit->text().toInt();

      m_workerThread = new QThread(this);
      m_worker = new BridgeWorker(portName, targetIp, udpPort);
      m_worker->moveToThread(m_workerThread);

      connect(m_workerThread, &QThread::started, m_worker,
              &BridgeWorker::startBridge);
      connect(m_worker, &BridgeWorker::logMessage, this,
              &BridgeWindow::logMessage, Qt::QueuedConnection);
      connect(m_worker, &BridgeWorker::stopped, this,
              &BridgeWindow::onBridgeStopped, Qt::QueuedConnection);

      m_workerThread->start();
      m_startBtn->setText("Stop Bridge");
    }
  }

  void onBridgeStopped() {
    if (m_workerThread) {
      m_workerThread->quit();
      m_workerThread->wait();
      m_worker->deleteLater();
      m_workerThread->deleteLater();
      m_workerThread = nullptr;
      m_worker = nullptr;
    }
    m_startBtn->setText("Start Bridge");
    m_startBtn->setEnabled(true);
  }

  void logMessage(const QString &msg) {
    QString timeStr = QTime::currentTime().toString("hh:mm:ss.zzz");
    m_logEdit->append(QString("[%1] %2").arg(timeStr, msg));
  }

private:
  QLineEdit *m_portEdit;
  QLineEdit *m_ipEdit;
  QLineEdit *m_udpPortEdit;
  QPushButton *m_startBtn;
  QTextEdit *m_logEdit;

  QThread *m_workerThread;
  BridgeWorker *m_worker;
};

int main(int argc, char *argv[]) {
  QApplication a(argc, argv);
  BridgeWindow w;
  w.show();
  return a.exec();
}

#include "main.moc"