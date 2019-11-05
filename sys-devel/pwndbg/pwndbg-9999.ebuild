# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# TODO: it can be works fine with python3_{5,6} too but dev-util/unicorn only python2_7 support
PYTHON_COMPAT=( python2_7 )

inherit eutils linux-info python-single-r1

DESCRIPTION="A GDB plug-in that makes debugging with GDB suck less"
HOMEPAGE="https://github.com/pwndbg/pwndbg"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/pwndbg/pwndbg"
else
	HASH_COMMIT="b64674d032850c37603ef51c63d34efa7790f256" # 20191004

	SRC_URI="https://github.com/pwndbg/pwndbg/archive/${HASH_COMMIT}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${HASH_COMMIT}"
fi

LICENSE="MIT"
SLOT="0"

# TODO: Add tests and docs support
# * tests is works fine outside portage sandbox
# * in the current moment, docs are failing
#IUSE="doc test"

CDEPEND="${PYTHON_DEPS}"
RDEPEND="${CDEPEND}
	app-exploits/ROPgadget
	dev-libs/capstone[python,${PYTHON_USEDEP}]
	!!dev-libs/capstone-bindings
	dev-python/future[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
	dev-python/psutil[${PYTHON_USEDEP}]
	dev-python/pygments[${PYTHON_USEDEP}]
	dev-python/pycparser[${PYTHON_USEDEP}]
	dev-python/pyelftools[${PYTHON_USEDEP}]
	dev-python/python-ptrace[${PYTHON_USEDEP}]
	dev-python/isort[${PYTHON_USEDEP}]
	dev-util/unicorn[python,unicorn_targets_x86(+),${PYTHON_USEDEP}]
	sys-devel/gdb[python,${PYTHON_USEDEP}]"

DEPEND="${CDEPEND}"
#	test? ( dev-python/pytest )
#	doc? (
#		dev-python/sphinx
#		dev-python/sphinxcontrib-napoleon )"

pkg_setup() {
	local CONFIG_CHECK="~DEBUG_INFO"

	python-single-r1_pkg_setup
	check_extra_config
}

src_prepare() {
	if [[ ${PV} != *9999 ]]; then
		sed -e "s/__version__ = '\(.*\)'/__version__ = '${PV}'/" \
			-i pwndbg/version.py || die
	fi

	# fix typo... (may be rm -f ida_script.py ??)
	sed -e "s/type(0L)/type(0)/g" \
		-i ida_script.py || die

	python_fix_shebang "${S}"
	default
}

src_install() {
	insinto "/usr/share/${PN}"
	doins -r pwndbg/ gdbinit.py # ida_script.py

	python_optimize "${D}/usr/share/${PN}"

	cat > "${D}/usr/share/${PN}/init-pwndbg" <<-_EOF_ || die
		echo For enabling pwndbg put the 'init-pwndbg' command!\n
		define init-pwndbg
		source /usr/share/${PN}/gdbinit.py
		end
		document init-pwndbg
		Initializes PwnGDB
		end
	_EOF_

	make_wrapper "pwndbg" \
		"gdb -x /usr/share/${PN}/init-pwndbg"

	#if use doc; then
	#	pushd docs/ >/dev/null || die
	#	emake man html
	#	popd >/dev/null || die
	#fi

	dodoc {README,DEVELOPING,FEATURES}.md
}

#src_test() {
#	pushd tests/binaries >/dev/null || die
#	emake clean && rm -vf *.out || die
#	popd >/dev/null || die
#
#	./tests.sh || die
#}

pkg_postinst() {
	einfo "\nUsage:"
	einfo "    ~$ alias pwndbg='pwndbg -ex init-pwndbg'"
	einfo "    ~$ pwndbg <program>"
	ewarn "\nWARNING!!!"
	ewarn "Some pwndbg commands only works with libc debug symbols.\n"
	ewarn "See also:"
	ewarn " * https://github.com/pentoo/pentoo-overlay/issues/521#issuecomment-548975884"
	ewarn " * https://sourceware.org/gdb/onlinedocs/gdb/Separate-Debug-Files.html"
	ewarn " * https://wiki.gentoo.org/wiki/Debugging\n"
}
