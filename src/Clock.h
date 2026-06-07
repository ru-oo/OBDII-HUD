#pragma once
// Clock.h
#include <QObject>
#include <QTimer>
#include <QDateTime>

class Clock : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString timeStr READ timeStr NOTIFY timeStrChanged)
    Q_PROPERTY(QString dateStr READ dateStr NOTIFY dateStrChanged)
    Q_PROPERTY(int     hour    READ hour    NOTIFY hourChanged)

public:
    explicit Clock(QObject *parent = nullptr);

    QString timeStr() const { return m_timeStr; }
    QString dateStr() const { return m_dateStr; }
    int     hour()    const { return m_hour; }

signals:
    void timeStrChanged(const QString &);
    void dateStrChanged(const QString &);
    void hourChanged(int);

private slots:
    void update();

private:
    QString m_timeStr;
    QString m_dateStr;
    int     m_hour = -1;
    QTimer  m_timer;
};
