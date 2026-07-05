#pragma once

#include "configobject.hpp"

#include <qdir.h>
#include <qstandardpaths.h>
#include <qstring.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class UserPaths : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    // setup.sh sparse-checks the dharmx/walls set into ~/Pictures/Wallpapers/
    // caelestia; pointing the default there gives the picker clean per-folder
    // categories (anime, boccha, ...). Override via shell.json or the
    // CAELESTIA_WALLPAPERS_DIR env var.
    CONFIG_GLOBAL_PROPERTY(QString, wallpaperDir,
        QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + u"/Wallpapers/caelestia"_s)
    CONFIG_PROPERTY(QString, noNotifsPic, u"root:/assets/dino.png"_s)
    CONFIG_PROPERTY(QString, lockNoNotifsPic, u"root:/assets/dino.png"_s)

public:
    explicit UserPaths(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
