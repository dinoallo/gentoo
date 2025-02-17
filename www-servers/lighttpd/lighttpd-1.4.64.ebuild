# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

LUA_COMPAT=( lua5-{1..4} )

inherit autotools lua-single readme.gentoo-r1 systemd tmpfiles toolchain-funcs

DESCRIPTION="Lightweight high-performance web server"
HOMEPAGE="https://www.lighttpd.net https://github.com/lighttpd"
SRC_URI="https://download.lighttpd.net/lighttpd/releases-1.4.x/${P}.tar.xz"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~arm64 ~hppa ~ia64 ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="+brotli dbi doc gnutls ipv6 kerberos ldap +lua maxminddb mbedtls mmap mysql +nettle nss +pcre php postgres rrdtool sasl selinux ssl sqlite +system-xxhash test unwind webdav xattr +zlib zstd"
RESTRICT="!test? ( test )"

REQUIRED_USE="lua? ( ${LUA_REQUIRED_USE} )
	mysql? ( dbi )
	postgres? ( dbi )
	sqlite? ( dbi )
	webdav? ( sqlite )
"

COMMON_DEPEND="
	acct-group/lighttpd
	acct-user/lighttpd
	virtual/libcrypt:=
	brotli? ( app-arch/brotli )
	dbi? (
		dev-db/libdbi
		mysql? ( dev-db/libdbi-drivers[mysql] )
		postgres? ( dev-db/libdbi-drivers[postgres] )
		sqlite? ( dev-db/libdbi-drivers[sqlite] )
	)
	gnutls? ( net-libs/gnutls )
	kerberos? ( virtual/krb5 )
	ldap? ( >=net-nds/openldap-2.1.26 )
	lua? ( ${LUA_DEPS} )
	maxminddb? ( dev-libs/libmaxminddb )
	mbedtls? ( net-libs/mbedtls )
	nettle? ( dev-libs/nettle )
	nss? ( dev-libs/nss )
	pcre? ( dev-libs/libpcre2 )
	php? ( dev-lang/php:*[cgi] )
	rrdtool? ( net-analyzer/rrdtool )
	sasl? ( dev-libs/cyrus-sasl )
	ssl? ( >=dev-libs/openssl-0.9.7:0= )
	system-xxhash? ( dev-libs/xxhash )
	unwind? ( sys-libs/libunwind )
	webdav? (
		dev-libs/libxml2
		sys-fs/e2fsprogs
	)
	xattr? ( kernel_linux? ( sys-apps/attr ) )
	zlib? ( >=sys-libs/zlib-1.1 )
	zstd? ( app-arch/zstd )"

BDEPEND="
	virtual/pkgconfig
	doc?  ( dev-python/docutils )
	test? (
		virtual/perl-Test-Harness
	)"

DEPEND="${COMMON_DEPEND}
	elibc_musl? ( sys-libs/queue-standalone )"

RDEPEND="${COMMON_DEPEND}
	selinux? ( sec-policy/selinux-apache )
"

# update certain parts of lighttpd.conf based on conditionals
update_config() {
	local config="${D}/etc/lighttpd/lighttpd.conf"

	# enable php/mod_fastcgi settings
	if use php; then sed -i -e 's|#.*\(include.*fastcgi.*$\)|\1|' ${config} || die; fi

	# automatically listen on IPv6 if built with USE=ipv6. Bug #234987
	if use ipv6; then sed -i -e 's|# server.use-ipv6|server.use-ipv6|' ${config} || die; fi
}

pkg_setup() {
	if use lua; then
		lua-single_pkg_setup
	fi

	if ! use pcre ; then
		ewarn "It is highly recommended that you build ${PN}"
		ewarn "with perl regular expressions support via USE=pcre."
		ewarn "Otherwise you lose support for some core options such"
		ewarn "as conditionals and modules such as mod_re{write,direct}."
	fi

	DOC_CONTENTS="IPv6 migration guide:\n
		http://redmine.lighttpd.net/projects/lighttpd/wiki/IPv6-Config"
}

src_prepare() {
	default
	# dev-python/docutils installs rst2html.py not rst2html
	sed -i -e 's|\(rst2html\)|\1.py|g' doc/outdated/Makefile.am || \
		die "sed doc/Makefile.am failed"
	eautoreconf
}

src_configure() {
	# The lua bit requires a bit of explanation. The lighttpd autoconf script
	# handles the value passed to --with-lua as follows:
	#  - "no" - do nothing
	#  - "yes" - query pkgconfig for VERSIONED lua packages, starting with 5.3
	#    and going down; only if lua5.1 cannot be found plain "lua" is tried
	#  - any other value is passed to pkgconfig as the exact package name to use.
	# We want a specific implementation to be used even if a newer one is present
	# in the system so we use the latter mode.
	econf \
		CC_FOR_BUILD=$(tc-getBUILD_CC) \
		--libdir=/usr/$(get_libdir)/${PN} \
		--enable-lfs \
		$(use_enable ipv6) \
		$(use_enable mmap) \
		$(use_with brotli) \
		$(use_with dbi) \
		$(use_with gnutls ) \
		$(use_with kerberos krb5) \
		$(use_with ldap) \
		$(use_with lua lua ${ELUA}) \
		$(use_with maxminddb) \
		$(use_with mbedtls) \
		$(use_with nettle) \
		$(use_with nss) \
		$(use_with pcre pcre2) \
		$(use_with sasl) \
		$(use_with ssl openssl) \
		$(use_with system-xxhash xxhash) \
		$(use_with webdav webdav-props) \
		$(use_with webdav webdav-locks) \
		$(use_with xattr attr) \
		$(use_with zlib) \
		$(use_with zstd) \
		$(use_with unwind libunwind)
}

src_compile() {
	emake

	if use doc ; then
		einfo "Building HTML documentation"
		cd doc || die
		emake html
	fi
}

src_test() {
	if [[ ${EUID} -eq 0 ]]; then
		default_src_test
	else
		ewarn "test skipped, please re-run as root if you wish to test ${PN}"
	fi
}

src_install() {
	default

	find "${D}" -name '*.la' -delete || die

	# init script stuff
	newinitd "${FILESDIR}"/lighttpd.initd-r1 lighttpd
	newconfd "${FILESDIR}"/lighttpd.confd lighttpd

	# configs
	insinto /etc/lighttpd
	newins "${FILESDIR}"/conf/lighttpd.conf-r1 lighttpd.conf
	doins "${FILESDIR}"/conf/mime-types.conf
	doins "${FILESDIR}"/conf/mod_cgi.conf
	doins "${FILESDIR}"/conf/mod_fastcgi.conf

	# update lighttpd.conf directives based on conditionals
	update_config

	# docs
	dodoc AUTHORS README NEWS doc/scripts/*.sh
	newdoc doc/config//lighttpd.conf lighttpd.conf.distrib
	if use ipv6; then readme.gentoo_create_doc; fi

	if use doc; then dodoc -r doc; fi

	docinto txt
	dodoc doc/outdated/*.txt

	# logrotate
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/lighttpd.logrotate-r1 lighttpd

	keepdir /var/l{ib,og}/lighttpd /var/www/localhost/htdocs
	fowners lighttpd:lighttpd /var/l{ib,og}/lighttpd
	fperms 0750 /var/l{ib,og}/lighttpd

	systemd_dounit "${FILESDIR}/${PN}.service"
	newtmpfiles "${FILESDIR}/${PN}.tmpfiles.conf" "${PN}.conf"
}

pkg_postinst() {
	tmpfiles_process ${PN}.conf

	if use ipv6; then readme.gentoo_print_elog; fi

	if [[ -f ${ROOT}/etc/lighttpd.conf ]] ; then
		elog
		elog "Gentoo has a customized configuration,"
		elog "which is now located in ${EROOT}/etc/lighttpd. Please migrate your"
		elog "existing configuration."
	fi

	if use brotli || use zstd || use zlib; then
		elog
		elog "Remember to clean your cache directory when using"
		elog "output compression!"
		elog "https://wiki.lighttpd.net/Docs_ModDeflate"
	fi

	if use mysql; then
		elog
		elog "Note that upstream has moved away from using mysql directly"
		elog "via mod_mysql and is now accessing it through mod_dbi. You"
		elog "may need to update your configuration"
	fi

	elog
	elog "Upstream has deprecated a number of features. They are not missing"
	elog "but have been migrated to other mechanisms. Please see upstream"
	elog "changelog for details."
	elog "https://www.lighttpd.net/2022/1/19/1.4.64/"
}
