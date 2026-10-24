# SPDX-FileCopyrightText: 2026 kwin-effect-overview2 contributors
# SPDX-License-Identifier: BSD-3-Clause

# Overview effect, forked from kwin's src/plugins/overview (v6.8.1)
set(kwin4_effect_overview2_SOURCES
    main.cpp
    overvieweffect.cpp
)

kconfig_add_kcfg_files(kwin4_effect_overview2_SOURCES
    overviewconfig.kcfgc
)

kcoreaddons_add_plugin(kwin4_effect_overview2
    INSTALL_NAMESPACE "kwin/effects/plugins"
    SOURCES ${kwin4_effect_overview2_SOURCES}
)
target_compile_definitions(kwin4_effect_overview2 PRIVATE -DTRANSLATION_DOMAIN=\"kwin\")

qt6_add_qml_module(kwin4_effect_overview2
    NO_PLUGIN
    URI org.kde.kwin.overview2
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        DesktopBar.qml
        DesktopView.qml
        Main.qml
)

target_link_libraries(kwin4_effect_overview2 PRIVATE
    KWin::kwin

    KF6::ConfigGui
    KF6::GlobalAccel
    KF6::I18n
    KF6::Runner

    Qt6::Quick
)

### Fork note: the configuration KCM ("Configure…" button in the Desktop
### Effects systemsettings module). Discovered through the fork effect's
### metadata.json "X-KDE-ConfigModule" key, installed in kwin/effects/configs
### like the stock effect config modules.
set(kwin4_effect_overview2_config_SOURCES
    kcm/overview2effectkcm.cpp
)
ki18n_wrap_ui(kwin4_effect_overview2_config_SOURCES
    kcm/overview2effectkcm.ui
)
kconfig_add_kcfg_files(kwin4_effect_overview2_config_SOURCES
    overviewconfig.kcfgc
)

kcoreaddons_add_plugin(kwin4_effect_overview2_config
    INSTALL_NAMESPACE "kwin/effects/configs"
    SOURCES ${kwin4_effect_overview2_config_SOURCES}
)
target_compile_definitions(kwin4_effect_overview2_config PRIVATE -DTRANSLATION_DOMAIN=\"kwin\")

target_link_libraries(kwin4_effect_overview2_config PRIVATE
    KWin::kwin

    KF6::KCMUtils
    KF6::CoreAddons
    KF6::GlobalAccel
    KF6::I18n
    KF6::XmlGui

    Qt6::DBus
    Qt6::Widgets
)
