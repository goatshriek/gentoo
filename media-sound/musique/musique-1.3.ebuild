# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"

inherit eutils qt4-r2

DESCRIPTION="Qt4 music player"
HOMEPAGE="http://flavio.tordini.org/musique"
# Same tarball for every release. We repackage it
SRC_URI="https://dev.gentoo.org/~hwoarang/distfiles/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	dev-qt/qtcore:4
	dev-qt/qtdbus:4
	dev-qt/qtgui:4[gtkstyle]
	dev-qt/qtsingleapplication[qt4]
	dev-qt/qtsql:4[sqlite]
	|| ( dev-qt/qtphonon:4 media-libs/phonon[qt4] )
	media-libs/taglib
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${PN}"

DOCS="CHANGES TODO"

src_prepare () {
	epatch "${FILESDIR}"/${PN}-1.1-gcc47.patch
	qt4-r2_src_prepare
}

src_configure() {
	eqmake4 ${PN}.pro PREFIX="/usr"
}

src_install() {
	qt4-r2_src_install
	doicon data/${PN}.svg
}
