# Copyright 2019-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Handy scripts for ebuild development and more"
HOMEPAGE="https://github.com/mgorny/mgorny-dev-scripts"
SRC_URI="https://github.com/mgorny/mgorny-dev-scripts/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~hppa ~ppc ~ppc64 ~riscv ~sparc x86 ~x64-macos"

RDEPEND="
	app-portage/gentoolkit
	dev-perl/URI
	dev-util/pkgcheck
	dev-vcs/git
	net-misc/wget
	sys-apps/portage
	x11-misc/xdg-utils
	!dev-util/pkgdiff"

src_install() {
	dodoc README.rst
	rm -f COPYING README.rst || die
	dobin *
}
