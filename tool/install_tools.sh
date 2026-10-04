#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# install_tools.sh – install the pinned lint/security tools into .toolchain.
#
# Usage:   tool/install_tools.sh           install missing or outdated tools
#          tool/install_tools.sh --check   only verify presence and versions
#
# Installs (Linux x86_64 only; other platforms exit with 2):
#   .toolchain/bin      uv, ShellCheck, shfmt, actionlint, gitleaks,
#                       osv-scanner, ktlint and a detekt wrapper
#                       (ktlint/detekt need java on PATH).
#                       Every download is verified against a SHA-256 sum that
#                       is pinned below and taken from the project's published
#                       checksum file / GitHub release digest.
#   .toolchain/venv     Python tools from tool/requirements-dev.txt (uv, hash
#                       checked with --require-hashes).
#   tool/node           markdownlint-cli via `npm ci` (package-lock.json
#                       carries the integrity hashes).
# Re-running is idempotent: tools that already report the pinned version are
# skipped. A version table is printed at the end.
#
# Needs: bash, curl, tar, sha256sum, Node 24 with npm, and Java
# on PATH (ktlint/detekt). uv itself is installed and verified below.
#
# Exit codes: 0 everything installed/verified, 1 (--check) a tool is missing
#             or has the wrong version, 2 usage, platform, download or
#             checksum error.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
toolchain="${root_dir}/.toolchain"
bin_dir="${toolchain}/bin"
opt_dir="${toolchain}/opt"
venv_dir="${toolchain}/venv"
node_dir="${root_dir}/tool/node"
requirements="${root_dir}/tool/requirements-dev.txt"
gh="https://github.com"
maven="https://repo1.maven.org/maven2"

# name|version|kind|url|sha256
# kind: bin = single executable, tgz = archive containing <name> at its root,
#       tgzdir = archive with one top-level directory, jar = java -jar
tools=(
	"uv|0.12.23|tgzdir|${gh}/astral-sh/uv/releases/download/0.12.23/uv-x86_64-unknown-linux-gnu.tar.gz|9167d72b3319674b6303c4cbe071854bba13ebdf3d76b1a7cbdc175471fb66d6"
	"shellcheck|0.11.0|tgzdir|${gh}/koalaman/shellcheck/releases/download/v0.11.0/shellcheck-v0.11.0.linux.x86_64.tar.gz|b7af85e41cc99489dcc21d66c6d5f3685138f06d34651e6d34b42ec6d54fe6f6"
	"shfmt|3.14.1|bin|${gh}/mvdan/sh/releases/download/v3.14.1/shfmt_v3.14.1_linux_amd64|76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf"
	"actionlint|1.7.12|tgz|${gh}/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_linux_amd64.tar.gz|8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8"
	"gitleaks|8.30.1|tgz|${gh}/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz|551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"
	"osv-scanner|2.6.0|bin|${gh}/google/osv-scanner/releases/download/v2.6.0/osv-scanner_linux_amd64|ca69b3d3cd08f889a49dc0a383122f71cc528b83803671df5fd874d97485b108"
	"ktlint|1.8.0|bin|${gh}/ktlint/ktlint/releases/download/1.8.0/ktlint|a3fd620207d5c40da6ca789b95e7f823c54e854b7fade7f613e91096a3706d75"
	"detekt|1.23.8|jar|${maven}/io/gitlab/arturbosch/detekt/detekt-cli/1.23.8/detekt-cli-1.23.8-all.jar|3afe89a11120303c73c9bdda3d8fe558dd9070a6937d27819ddc04b275381245"
)

check_only=0
failures=0
download_dir=""
table=()
# tree-sitter's CPython extension currently crashes under 3.14 while walking
# larger Bash trees. Pin the newest 3.13 maintenance release until upstream
# declares 3.14 support; the checker must fail safely, never segfault.
python_version="3.13.16"
node_major="24"

usage() {
	sed -n '5,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'
}

die() {
	echo "error: $*" >&2
	exit 2
}

parse_args() {
	case "${1:-}" in
	"") ;;
	--check) check_only=1 ;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		usage >&2
		exit 2
		;;
	esac
	[[ $# -le 1 ]] || die "too many arguments"
}

require_platform() {
	if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
		die "only Linux x86_64 is supported (got $(uname -s) $(uname -m))"
	fi
	# ktlint and detekt are JVM tools; their versions cannot be verified without java.
	command -v java >/dev/null 2>&1 || die "java not found on PATH (needed by ktlint and detekt)"
	command -v node >/dev/null 2>&1 || die "Node ${node_major} not found on PATH"
	command -v npm >/dev/null 2>&1 || die "npm not found on PATH"
	[[ "$(node --version)" == "v${node_major}."* ]] || die "Node must be major ${node_major}"
}

# Prints the version a binary tool reports (empty if it is missing/broken).
installed_version() {
	local name="$1" exe="${bin_dir}/$1" out
	[[ -x "${exe}" ]] || return 0
	case "${name}" in
	uv | shellcheck | shfmt | ktlint | osv-scanner | detekt) out="$("${exe}" --version 2>/dev/null)" || true ;;
	actionlint) out="$("${exe}" -version 2>/dev/null)" || true ;;
	gitleaks) out="$("${exe}" version 2>/dev/null)" || true ;;
	esac
	grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<<"${out:-}" | head -n 1 || true
}

# download <url> <sha256> <target>: fetch and verify, never keep bad files.
download() {
	local url="$1" sha="$2" target="$3"
	curl -sSfL --retry 3 -o "${target}" "${url}" || die "download failed: ${url}"
	if ! sha256sum --check --status <<<"${sha}  ${target}"; then
		rm -f "${target}"
		die "SHA-256 mismatch for ${url}"
	fi
}

# write_detekt_wrapper <jar path relative to .toolchain>; relocatable.
write_detekt_wrapper() {
	local jar="$1"
	cat >"${bin_dir}/detekt" <<EOF
#!/usr/bin/env bash
# Generated by tool/install_tools.sh – runs the pinned detekt-cli jar.
exec java -jar "\$(dirname "\${BASH_SOURCE[0]}")/../${jar}" "\$@"
EOF
	chmod +x "${bin_dir}/detekt"
}

install_binary() {
	local name="$1" version="$2" kind="$3" url="$4" sha="$5" file dest
	file="${download_dir}/${url##*/}"
	dest="${opt_dir}/${name}-${version}"
	download "${url}" "${sha}" "${file}"
	mkdir -p "${dest}" "${bin_dir}"
	case "${kind}" in
	bin) install -m 0755 "${file}" "${dest}/${name}" ;;
	tgz) tar -xzf "${file}" -C "${dest}" "${name}" ;;
	tgzdir) tar -xzf "${file}" --strip-components=1 -C "${dest}" ;;
	jar) install -m 0644 "${file}" "${dest}/${url##*/}" ;;
	esac
	rm -f "${file}"
	# Relative links keep .toolchain relocatable (e.g. bind mounts in Docker).
	if [[ "${kind}" == "jar" ]]; then
		write_detekt_wrapper "opt/${name}-${version}/${url##*/}"
	else
		ln -sfn "../opt/${name}-${version}/${name}" "${bin_dir}/${name}"
	fi
}

handle_binaries() {
	local entry name version kind url sha found
	mkdir -p "${toolchain}"
	download_dir="$(mktemp -d "${toolchain}/download.XXXXXX")"
	trap 'rm -rf "${download_dir}"' EXIT
	for entry in "${tools[@]}"; do
		IFS='|' read -r name version kind url sha <<<"${entry}"
		found="$(installed_version "${name}")"
		if [[ "${found}" != "${version}" && ${check_only} -eq 0 ]]; then
			echo "Installing ${name} ${version} …" >&2
			install_binary "${name}" "${version}" "${kind}" "${url}" "${sha}"
			found="$(installed_version "${name}")"
		fi
		record "${name}" "${version}" "${found}"
	done
}

# record <name> <pinned> <found>: add a table row and count mismatches.
record() {
	local status="ok"
	if [[ "$3" != "$2" ]]; then
		status="MISSING/MISMATCH"
		failures=$((failures + 1))
	fi
	table+=("$(printf '%-26s %-10s %-10s %s' "$1" "$2" "${3:--}" "${status}")")
}

find_uv() {
	[[ -x "${bin_dir}/uv" ]] || die "pinned uv is missing from ${bin_dir}"
	echo "${bin_dir}/uv"
}

handle_venv() {
	local uv marker="${venv_dir}/.requirements.sha256" found_python="" want
	want="$(
		printf '%s  ' "${python_version}"
		sha256sum "${requirements}"
	)"
	if [[ -x "${venv_dir}/bin/python" ]]; then
		found_python="$("${venv_dir}/bin/python" --version | cut -d' ' -f2)"
	fi
	if [[ ${check_only} -eq 0 && "$(cat "${marker}" 2>/dev/null)" != "${want}" ]]; then
		echo "Syncing Python venv from tool/requirements-dev.txt …" >&2
		uv="$(find_uv)"
		if [[ "${found_python}" != "${python_version}" ]]; then
			rm -rf "${venv_dir}"
			"${uv}" venv --quiet --python "${python_version}" "${venv_dir}"
		fi
		"${uv}" pip sync --quiet --require-hashes --python "${venv_dir}/bin/python" "${requirements}"
		printf '%s\n' "${want}" >"${marker}"
	fi
	record "Python (venv)" "${python_version}" "$("${venv_dir}/bin/python" --version 2>/dev/null | cut -d' ' -f2)"
	record_python_pins
}

# Compares every pin in requirements-dev.in with the installed distribution.
record_python_pins() {
	local name version found
	while IFS='=' read -r name version; do
		found=""
		if [[ -x "${venv_dir}/bin/python" ]]; then
			found="$("${venv_dir}/bin/python" -c 'import importlib.metadata as m, sys
try:
    print(m.version(sys.argv[1]))
except m.PackageNotFoundError:
    pass' "${name}")"
		fi
		record "${name} (venv)" "${version#=}" "${found}"
	done < <(grep -E '^[A-Za-z0-9_.-]+==' "${root_dir}/tool/requirements-dev.in")
}

handle_node() {
	local exe="${node_dir}/node_modules/.bin/markdownlint" pinned found=""
	pinned="$(sed -n 's/.*"markdownlint-cli": *"\([^"]*\)".*/\1/p' "${node_dir}/package.json")"
	if [[ -x "${exe}" ]]; then
		found="$("${exe}" --version 2>/dev/null || true)"
	fi
	if [[ "${found}" != "${pinned}" && ${check_only} -eq 0 ]]; then
		echo "Installing markdownlint-cli ${pinned} (npm ci) …" >&2
		npm ci --prefix "${node_dir}" --ignore-scripts --no-audit --no-fund >/dev/null
		found="$("${exe}" --version)"
	fi
	record "markdownlint-cli" "${pinned}" "${found}"
}

print_table() {
	printf '%-26s %-10s %-10s %s\n' "TOOL" "PINNED" "FOUND" "STATUS"
	printf '%s\n' "${table[@]}"
}

main() {
	parse_args "$@"
	require_platform
	handle_binaries
	handle_venv
	handle_node
	print_table
	if [[ ${failures} -gt 0 ]]; then
		echo "${failures} tool(s) missing or not at the pinned version" >&2
		[[ ${check_only} -eq 1 ]] && exit 1
		exit 2
	fi
}

main "$@"
