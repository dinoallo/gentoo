# Copyright 2020-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..10} )
inherit distutils-r1

DESCRIPTION="python classes generated from the common protos in the googleapis repository"
HOMEPAGE="https://pypi.org/project/googleapis-common-protos/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

RDEPEND="
	dev-python/namespace-google[${PYTHON_USEDEP}]
	>=dev-python/protobuf-python-3.12.0[${PYTHON_USEDEP}]
"

python_install_all() {
	distutils-r1_python_install_all
	find "${D}" -name '*.pth' -delete || die
}

# no tests as this is all generated code
