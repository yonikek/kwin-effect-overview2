# SPDX-FileCopyrightText: 2026 kwin-effect-overview2 contributors
# SPDX-License-Identifier: BSD-3-Clause
#
# Out-of-tree build of the KWin "Overview" effect fork. Matches the stock
# plugin definition in kwin's src/plugins/overview, but links against the
# system KWin libraries (find_package(KWin)) instead of building inside kwin.

cmake_minimum_required(VERSION 3.26)

project(kwin-effect-overview2
    VERSION 1.0.0
    DESCRIPTION "Overview effect fork: visible panel, no workspace delete/rename"
    LANGUAGES CXX
)

set(KWIN_MIN_VERSION 6.8.1)
set(KF6_MIN_VERSION "6.0.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(FeatureSummary)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 CONFIG REQUIRED COMPONENTS
    Core
    Quick
    Widgets
    DBus
)

find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    CoreAddons
    Config
    GlobalAccel
    I18n
    Runner
    KCMUtils
    XmlGui
)

find_package(KWin ${KWIN_MIN_VERSION} CONFIG REQUIRED)

add_subdirectory(src)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
