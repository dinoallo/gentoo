# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools toolchain-funcs

DESCRIPTION="C library providing BLAKE2b, BLAKE2s, BLAKE2bp, BLAKE2sp"
HOMEPAGE="https://github.com/BLAKE2/libb2"
GITHASH="73d41c8255a991ed2adea41c108b388d9d14b449"
SRC_URI="https://github.com/BLAKE2/libb2/archive/${GITHASH}.tar.gz -> ${P}.tar.gz"

LICENSE="CC0-1.0"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~ppc64 ~amd64-linux ~x86-linux ~x64-macos ~sparc-solaris ~x64-solaris"
IUSE="static native-cflags openmp"

DEPEND="
	openmp? (
		|| ( >=sys-devel/gcc-4.2:*[openmp] sys-devel/clang-runtime:*[openmp] )
	)
"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${PN}-${GITHASH}

pkg_setup() {
	if [[ ${MERGE_TYPE} != "binary" ]] && use openmp && ! tc-has-openmp; then
		ewarn "You are using a compiler without OpenMP support"
		die "Need an OpenMP capable compiler"
	fi
}

src_prepare() {
	default
	# fix bashism
	sed -i -e 's/ == / = /' configure.ac || die
	eautoreconf  # upstream doesn't make releases
}

src_configure() {
	econf \
		$(use_enable static) \
		$(use_enable native-cflags native) \
		$(use_enable openmp)
}

do_make() {
	# respect our CFLAGS when native-cflags is not in effect
	local openmp=$(use openmp && echo -fopenmp)
	emake $(use native-cflags && echo no)CFLAGS="${CFLAGS} ${openmp}" "$@"
}

src_compile() {
	do_make
}

src_test() {
	do_make check
}

src_install() {
	default
	use static || find "${ED}" -name '*.la' -type f -delete || die
}
