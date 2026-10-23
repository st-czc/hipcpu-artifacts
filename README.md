# hipcpu-artifacts

Prebuilt `libsycl-nativecpu_utils.bc` used by the HIP CPU
(`spvcpu-unknown-hipcpu`) toolchain.

## Layout

```text
.
├── .gitignore
├── LICENSE
├── build.sh
└── bitcode/
    ├── .hash/
    │   └── <commit>/
    │       └── libsycl-nativecpu_utils.bc
    └── <intel-llvm tag> -> .hash/<commit>
```

Only one bitcode version is kept in the tree at a time. Previous versions
remain available in the git history and in the tags of this repository.

## Versions

A release is named after the `intel/llvm` tag it was built from, for example
`nightly-2026-10-16` or `v7.2.0`. The directory name under `bitcode/.hash/`
records the exact commit the bitcode was built from.

## Building

`build.sh` requires an `intel-llvm` checkout at `./intel-llvm` that is checked
out at a tagged commit. It configures intel-llvm, builds
`libsycl-nativecpu_utils-bc`, `llvm-dis` and `llvm-as`, strips the local
absolute paths from the bitcode, rewrites `bitcode/` and commits the result. It
does not create tags or push.

```bash
./build.sh
```

## Consuming

```bash
git clone --depth 1 --branch nightly-2026-10-16 \
  https://github.com/st-czc/hipcpu-artifacts.git
```

The bitcode is at `bitcode/nightly-2026-10-16/libsycl-nativecpu_utils.bc`.
