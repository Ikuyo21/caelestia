#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

class NotifsConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, expire, true)
    CONFIG_GLOBAL_PROPERTY(QString, fullscreen, QStringLiteral("on"))
    CONFIG_GLOBAL_PROPERTY(int, defaultExpireTimeout, 5000)
    CONFIG_GLOBAL_PROPERTY(int, fullscreenExpireTimeout, 2000)
    CONFIG_PROPERTY(qreal, clearThreshold, 0.3)
    // expandThreshold survives for the sidebar notification lists; the popup
    // toast is fixed-height since the minimal redesign (no expand state, no
    // click-to-invoke), so openExpanded/actionOnClick are gone
    CONFIG_PROPERTY(int, expandThreshold, 20)
    CONFIG_PROPERTY(int, groupPreviewNum, 3)

public:
    explicit NotifsConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
