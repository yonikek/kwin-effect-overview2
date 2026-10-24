/*
    SPDX-FileCopyrightText: 2021 Vlad Zahorodnii <vlad.zahorodnii@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
#include "overview2effectkcm.h"

#include "config-kwin.h"

#include "overviewconfig.h"

#include <KActionCollection>
#include <KGlobalAccel>
#include <KLocalizedString>
#include <KPluginFactory>

#include <QAction>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>

K_PLUGIN_CLASS(KWin::Overview2EffectConfig)

namespace KWin
{

Overview2EffectConfig::Overview2EffectConfig(QObject *parent, const KPluginMetaData &data)
    : KCModule(parent, data)
{
    ui.setupUi(widget());
    OverviewConfig::instance(KWIN_CONFIG);
    addConfig(OverviewConfig::self(), widget());

    // Fork note: the action names must match the ones the effect registers in
    // src/overvieweffect.cpp so that the shortcuts editor edits the real
    // global shortcuts of this effect. Unlike the stock Overview effect, the
    // fork has no default keybindings.
    auto actionCollection = new KActionCollection(this, QStringLiteral("kwin"));

    actionCollection->setComponentDisplayName(i18n("KWin"));
    actionCollection->setConfigGroup(QStringLiteral("Overview 2"));
    actionCollection->setConfigGlobal(true);

    QAction *cycleAction = actionCollection->addAction(QStringLiteral("Cycle Overview 2"));
    cycleAction->setText(i18nc("@action Overview 2 and Grid View 2 are the name of KWin effects", "Cycle through Overview 2 and Grid View 2"));
    cycleAction->setProperty("isConfigurationAction", true);
    KGlobalAccel::self()->setGlobalShortcut(cycleAction, QList<QKeySequence>());

    QAction *reverseCycleAction = actionCollection->addAction(QStringLiteral("Cycle Overview Opposite 2"));
    reverseCycleAction->setText(i18nc("@action Grid View 2 and Overview 2 are the name of KWin effects", "Cycle through Grid View 2 and Overview 2"));
    reverseCycleAction->setProperty("isConfigurationAction", true);
    KGlobalAccel::self()->setGlobalShortcut(reverseCycleAction, QList<QKeySequence>());

    QAction *overviewAction = actionCollection->addAction(QStringLiteral("Overview 2"));
    overviewAction->setText(i18nc("@action Overview 2 is the name of a KWin effect", "Toggle Overview 2"));
    overviewAction->setProperty("isConfigurationAction", true);
    KGlobalAccel::self()->setGlobalShortcut(overviewAction, QList<QKeySequence>());

    QAction *gridAction = actionCollection->addAction(QStringLiteral("Grid View 2"));
    gridAction->setText(i18nc("@action Grid View 2 is the name of a KWin effect", "Toggle Grid View 2"));
    gridAction->setProperty("isConfigurationAction", true);
    KGlobalAccel::self()->setGlobalShortcut(gridAction, QList<QKeySequence>());

    ui.shortcutsEditor->addCollection(actionCollection);
    connect(ui.shortcutsEditor, &KShortcutsEditor::keyChange, this, &KCModule::markAsChanged);
}

void Overview2EffectConfig::save()
{
    KCModule::save();
    ui.shortcutsEditor->save();

    // Fork note: the stock config module links a generated
    // kwineffects_interface.h from the kwin build tree, which is not available
    // to a standalone plugin build, so call the interface directly.
    QDBusMessage message = QDBusMessage::createMethodCall(
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("/Effects"),
        QStringLiteral("org.kde.kwin.Effects"),
        QStringLiteral("reconfigureEffect"));
    message.setArguments({QVariant(QStringLiteral("kwin4_effect_overview2"))});
    QDBusConnection::sessionBus().asyncCall(message);
}

void Overview2EffectConfig::defaults()
{
    ui.shortcutsEditor->allDefault();
    KCModule::defaults();
}

} // namespace KWin

#include "moc_overview2effectkcm.cpp"
#include "overview2effectkcm.moc"
