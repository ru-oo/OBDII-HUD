// Clock.cpp
#include "Clock.h"

Clock::Clock(QObject *parent) : QObject(parent)
{
    connect(&m_timer, &QTimer::timeout, this, &Clock::update);
    m_timer.start(1000);
    update();
}

void Clock::update()
{
    QDateTime now = QDateTime::currentDateTime();
    QString ts = now.toString("HH:mm");
    QString ds = now.toString("yyyy.MM.dd  ddd");
    int     h  = now.time().hour();

    if (m_timeStr != ts) { m_timeStr = ts; emit timeStrChanged(ts); }
    if (m_dateStr != ds) { m_dateStr = ds; emit dateStrChanged(ds); }
    if (m_hour    != h)  { m_hour    = h;  emit hourChanged(h);     }
}
