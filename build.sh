#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LLVM_DIR="${REPO_DIR}/intel-llvm"
LLVM_BUILD_DIR="${LLVM_DIR}/build"
WORK_DIR="${REPO_DIR}/build"

if [[ ! -d "${LLVM_DIR}" ]]; then
  echo "error: ${LLVM_DIR} is missing; an intel-llvm checkout is required there" >&2
  exit 1
fi

mapfile -t CANDIDATE_TAGS < <(git -C "${LLVM_DIR}" tag --points-at HEAD | grep -E '^(nightly-|v[0-9])')
if [[ ${#CANDIDATE_TAGS[@]} -ne 1 ]]; then
  echo "error: expected exactly one release tag (nightly-* or v*) at intel-llvm HEAD, found: ${CANDIDATE_TAGS[*]:-none}" >&2
  exit 1
fi
TAG="${CANDIDATE_TAGS[0]}"
COMMIT="$(git -C "${LLVM_DIR}" rev-parse HEAD)"
SHORT_COMMIT="${COMMIT:0:8}"

echo "Building libsycl-nativecpu_utils.bc from intel/llvm ${TAG} (${SHORT_COMMIT})"

python3 "${LLVM_DIR}/buildbot/configure.py" --disable-jit --native_cpu
ninja -C "${LLVM_BUILD_DIR}" libsycl-nativecpu_utils-bc llvm-dis llvm-as

BC_INPUT="$(find "${LLVM_BUILD_DIR}/lib" -name libsycl-nativecpu_utils.bc -print -quit)"
if [[ -z "${BC_INPUT}" ]]; then
  echo "error: libsycl-nativecpu_utils.bc was not produced under ${LLVM_BUILD_DIR}/lib" >&2
  exit 1
fi

mkdir -p "${WORK_DIR}"
"${LLVM_BUILD_DIR}/bin/llvm-dis" "${BC_INPUT}" -o "${WORK_DIR}/module.ll"

sed -E -i \
  -e 's|"[^"]*/nativecpu_utils\.cpp"|"nativecpu_utils.cpp"|g' \
  -e 's|\(/[^)]*llvm\.git ([0-9a-f]+)\)|(\1)|g' \
  "${WORK_DIR}/module.ll"

if grep -nE '(^|[^[:alnum:]_])"/' "${WORK_DIR}/module.ll"; then
  echo "error: absolute path remains in the disassembled bitcode" >&2
  exit 1
fi

"${LLVM_BUILD_DIR}/bin/llvm-as" "${WORK_DIR}/module.ll" -o "${WORK_DIR}/libsycl-nativecpu_utils.bc"

rm -rf "${REPO_DIR}/bitcode"
mkdir -p "${REPO_DIR}/bitcode/.hash/${COMMIT}"
cp "${WORK_DIR}/libsycl-nativecpu_utils.bc" "${REPO_DIR}/bitcode/.hash/${COMMIT}/libsycl-nativecpu_utils.bc"
ln -s ".hash/${COMMIT}" "${REPO_DIR}/bitcode/${TAG}"

git -C "${REPO_DIR}" add bitcode
git -C "${REPO_DIR}" commit -m "Add libsycl-nativecpu_utils.bc from intel/llvm ${TAG} (${SHORT_COMMIT})"
