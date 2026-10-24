/*
    SPDX-FileCopyrightText: 2021 Vlad Zahorodnii <vlad.zahorodnii@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

// Fork note: not enabled by default, so the stock Overview effect can be
// disabled first. See README.md.

#include "overvieweffect.h"

namespace KWin
{

KWIN_EFFECT_FACTORY_SUPPORTED_ENABLED(OverviewEffect,
                                      "metadata.json",
                                      return OverviewEffect::supported();,
                                      return false;)

} // namespace KWin

#include "main.moc"
