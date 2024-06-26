# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A tool for enumerating information from Windows and Samba systems"
HOMEPAGE="https://labs.portcullis.co.uk/application/enum4linux/"
SRC_URI="https://github.com/CiscoCXSecurity/enum4linux/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm64 x86"
IUSE="+polenum ldap"

RDEPEND="
	dev-lang/perl:0=
	net-fs/samba
	polenum? ( net-analyzer/polenum )
	ldap? ( net-nds/openldap )"

src_prepare () {
	sed -i -e 's/polenum.py/polenum/' ${PN}.pl || die "Sed failed!"
	default
}

src_install () {
	newbin ${PN}.pl ${PN}
	insinto "/usr/share/${PN}"
	doins share-list.txt
	dodoc CHANGELOG
}
