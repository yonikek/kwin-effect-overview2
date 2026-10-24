/*
    SPDX-FileCopyrightText: 2021 Vlad Zahorodnii <vlad.zahorodnii@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
#pragma once

// Fork note: configuration KCM for the Overview 2 effect, ported from kwin's
// src/plugins/overview/kcm (v6.8.1). Renamed so that it does not collide with
// the stock Overview config module, exposed through the fork effect's
// metadata.json "X-KDE-ConfigModule" key.

#include <KCModule>

#include "ui_overview2effectkcm.h"

namespace KWin
{

class Overview2EffectConfig : public KCModule
{
    Q_OBJECT

public:
    explicit Overview2EffectConfig(QObject *parent, const KPluginMetaData &data);

public Q_SLOTS:
    void save() override;
    void defaults() override;

private:
    ::Ui::Overview2EffectConfig ui;
};

} // namespace KWin
