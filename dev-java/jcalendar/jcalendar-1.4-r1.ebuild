# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

JAVA_PKG_IUSE="doc source"

inherit java-pkg-2 java-ant-2

DESCRIPTION="Java date chooser bean for graphically picking a date"
HOMEPAGE="https://www.toedter.com/en/jcalendar/"
SRC_URI="https://www.toedter.com/download/${P}.zip"

LICENSE="LGPL-2.1"
SLOT="1.2"
KEYWORDS="~amd64 ~x86"

CDEPEND="dev-java/jgoodies-looks:2.6"

DEPEND="
	${CDEPEND}
	>=virtual/jdk-1.8:*"

RDEPEND="
	${CDEPEND}
	>=virtual/jre-1.8:*"

BDEPEND="app-arch/unzip"

S="${WORKDIR}"

RESTRICT="test"

JAVA_ANT_REWRITE_CLASSPATH="true"
EANT_GENTOO_CLASSPATH="jgoodies-looks-2.6"
EANT_BUILD_XML="src/build.xml"
EANT_BUILD_TARGET="jar"
EANT_DOC_TARGET=""

src_prepare() {
	default
	java-pkg_clean
}

src_install() {
	java-pkg_newjar lib/${P}.jar

	dodoc readme.txt

	use doc && java-pkg_dohtml -r doc/*
	use source && java-pkg_dosrc src/com
}
