# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: pam.eclass
# @MAINTAINER:
# No maintainer <maintainer-needed@gentoo.org>
# @AUTHOR:
# Diego Pettenò <flameeyes@gentoo.org>
# @SUPPORTED_EAPIS: 6 7 8
# @BLURB: Handles pam related tasks
# @DESCRIPTION:
# This eclass contains functions to install pamd configuration files and
# pam modules.

case ${EAPI:-0} in
	[678]) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_PAM_ECLASS} ]]; then
_PAM_ECLASS=1

inherit flag-o-matic

# @FUNCTION: dopamd
# @USAGE: <file> [more files]
# @DESCRIPTION:
# Install pam auth config file in /etc/pam.d
dopamd() {
	[[ -z $1 ]] && die "dopamd requires at least one argument"

	if has pam ${IUSE} && ! use pam; then
		return 0;
	fi

	( # dont want to pollute calling env
		insinto /etc/pam.d
		insopts -m 0644
		doins "$@"
	) || die "failed to install $@"
	cleanpamd "$@"
}

# @FUNCTION: newpamd
# @USAGE: <old name> <new name>
# @DESCRIPTION:
# Install pam file <old name> as <new name> in /etc/pam.d
newpamd() {
	[[ $# -ne 2 ]] && die "newpamd requires two arguments"

	if has pam ${IUSE} && ! use pam; then
		return 0;
	fi

	( # dont want to pollute calling env
		insinto /etc/pam.d
		insopts -m 0644
		newins "$1" "$2"
	) || die "failed to install $1 as $2"
	cleanpamd $2
}

# @FUNCTION: dopamsecurity
# @USAGE: <section> <file> [more files]
# @DESCRIPTION:
# Installs the config files in /etc/security/<section>/
dopamsecurity() {
	[[ $# -lt 2 ]] && die "dopamsecurity requires at least two arguments"

	if has pam ${IUSE} && ! use pam; then
		return 0
	fi

	( # dont want to pollute calling env
		insinto /etc/security/$1
		insopts -m 0644
		doins "${@:2}"
	) || die "failed to install ${@:2}"
}

# @FUNCTION: newpamsecurity
# @USAGE: <section> <old name> <new name>
# @DESCRIPTION:
# Installs the config file <old name> as <new name> in /etc/security/<section>/
newpamsecurity() {
	[[ $# -ne 3 ]] && die "newpamsecurity requires three arguments"

	if has pam ${IUSE} && ! use pam; then
		return 0;
	fi

	( # dont want to pollute calling env
		insinto /etc/security/$1
		insopts -m 0644
		newins "$2" "$3"
	) || die "failed to install $2 as $3"
}

# @FUNCTION: getpam_mod_dir
# @DESCRIPTION:
# Returns the pam modules' directory for current implementation
getpam_mod_dir() {
	PAM_MOD_DIR=/$(get_libdir)/security

	echo ${PAM_MOD_DIR}
}

# @FUNCTION: pammod_hide_symbols
# @DESCRIPTION:
# Hide all non-PAM-used symbols from the module; this function creates a
# simple ld version script that hides all the symbols that are not
# necessary for PAM to load the module, then uses append-flags to make
# sure that it gets used.
pammod_hide_symbols() {
	cat - > "${T}"/pam-eclass-pam_symbols.ver <<EOF
{
	global: pam_sm_*;
	local: *;
};
EOF

	append-ldflags -Wl,--version-script="${T}"/pam-eclass-pam_symbols.ver
}

# @FUNCTION: dopammod
# @USAGE: <file> [more files]
# @DESCRIPTION:
# Install pam module file in the pam modules' dir for current implementation
dopammod() {
	[[ -z $1 ]] && die "dopammod requires at least one argument"

	if has pam ${IUSE} && ! use pam; then
		return 0;
	fi

	exeinto $(getpam_mod_dir)
	doexe "$@" || die "failed to install $@"
}

# @FUNCTION: newpammod
# @USAGE: <old name> <new name>
# @DESCRIPTION:
# Install pam module file <old name> as <new name> in the pam
# modules' dir for current implementation
newpammod() {
	[[ $# -ne 2 ]] && die "newpammod requires two arguements"

	if has pam ${IUSE} && ! use pam; then
		return 0;
	fi

	exeinto $(getpam_mod_dir)
	newexe "$1" "$2" || die "failed to install $1 as $2"
}

# @FUNCTION: pamd_mimic_system
# @USAGE: <pamd file> [auth levels]
# @DESCRIPTION:
# This function creates a pamd file which mimics system-auth file
# for the given levels in the /etc/pam.d directory.
pamd_mimic_system() {
	[[ $# -lt 2 ]] && die "pamd_mimic_system requires at least two argments"
	pamd_mimic system-auth "$@"
}

# @FUNCTION: pamd_mimic
# @USAGE: <stack> <pamd file> [auth levels]
# @DESCRIPTION:
# This function creates a pamd file which mimics the given stack
# for the given levels in the /etc/pam.d directory.
pamd_mimic() {
	[[ $# -lt 3 ]] && die "pamd_mimic requires at least three argments"

	if has pam ${IUSE} && ! use pam; then
		return 0;
	fi

	dodir /etc/pam.d
	pamdfile=${D}/etc/pam.d/$2
	echo -e "# File autogenerated by pamd_mimic in pam eclass\n\n" >> \
		$pamdfile

	originalstack=$1
	authlevels="auth account password session"

	mimic="\tsubstack\t\t${originalstack}"

	shift; shift

	while [[ -n $1 ]]; do
		has $1 ${authlevels} || die "unknown level type"

		echo -e "$1${mimic}" >> ${pamdfile}

		shift
	done
}

# @FUNCTION: cleanpamd
# @USAGE: <pamd file>
# @DESCRIPTION:
# Cleans a pam.d file from modules that might not be present on the system
# where it's going to be installed
cleanpamd() {
	while [[ -n $1 ]]; do
		if ! has_version sys-libs/pam; then
			sed -i -e '/pam_shells\|pam_console/s:^:#:' "${D}/etc/pam.d/$1" || die
		fi

		shift
	done
}

fi
