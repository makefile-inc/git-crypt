# git-crypt

Makefiles include for using git-crypt https://github.com/AGWA/git-crypt

Now, support only symmetric key.

## Dependencies

Uses https://github.com/makefile-inc/common

Please [show](https://github.com/makefile-inc/common#dependencies) for install deps. 

## Install

### Manual

You can copy all files in your own repo (for example in subdir `makefile-git-crypt`) 
and include in root Makefile in the next way:

```Makefile
include $(CURDIR)/makefile-git-crypt/include.mk.inc
```

### As submodule

Add submodule:

```bash
git submodule add git@github.com:makefile-inc/git-crypt.git makefile-git-crypt
```

Checkout to target version:

```bash
pushd .
cd makefile-git-crypt
git fetch -a && git checkout v0.1.0 && git pull
git submodule update --recursive --init 
popd
```

Include in root Makefile:

- if you already using https://github.com/makefile-inc/common (or another makefile.inc uses `common`) youse your own version:

```Makefile
include $(CURDIR)/makefile-common/include.mk.inc
include $(CURDIR)/makefile-git-crypt/include.mk.inc
```

- if you will use only `makefile-inc/git-crypt` you can include `common` from `git-crypt`: 

```Makefile
include $(CURDIR)/makefile-git-crypt/include.mk.full.inc
```
**WARNING! If you use submodule and github actions, add to checkout action checkout submodules `submodules: "recursive"`, like:**
```yaml
...
    steps:
      - &checkout_step
        name: Checkout
        uses: actions/checkout@v6.0.2
        with:
          fetch-depth: 0
          submodules: "recursive"
          ref: ${{ github.event.pull_request.head.sha }}
...
```

## Update as submodule

```bash
pushd .
cd makefile-common
git fetch -a && git checkout NEW_TAG && git pull
popd
```

## Post install/update

Please add to `.gitignore` all entries from this repository `.gitignore`.

and run `make common/git/check/gitignore GITIGNORES_WITH_REQUIRED_RULES=makefile-common/.gitignore,makefile-git-crypt/.gitignore`.

Because targets generate some files which do not commit to git repo.

## Pre-definitions

Includes contain some variables and make definitions.

### Variables

Now includes files in `common` repo contains next predefined variables:
- `GIT_CRYPT_BIN_FULL` - full path to `git-crypt` binary.

## Targets

### Description

All targets install `git-crypt` with `install/git-crypt` ([see](#targets-list) targets description for current limitations).

Also, another operations check that git repo is clean (has not changes).

#### Add/remove path's

Add/remove operations change `.gitattributes` files to add git filters for encrypted files.
Also, add/remove operations re-add files and dirs with `git rm --cached` and `git add` calls.
It needs for safe encrypt/decrypt files before commit for prevent keep files as encrypted after
remove and encrypt all files after add.
After operation, changes will commit with commit message like:

```
git-crypt: OPERATION_NAME 'CHANGES_TO_ADD'
```

If operation was failed, you get dirty repo and get attention like: 

```
Cannot 'git rm --cached test-2.key'
ATTENTION!
YOU REPO IN DIRTY STATE!
DO NOT COMMIT CHANGES OTHERWISE YOU LOST FILES!
MANUAL REMOVING IS:
git rm --cached ...
git add ...
git commit ...
Crypt operation 'add file(s)' FAILED!
```

In this case you **SHOULD resolve manually** for prevent lost files!

**Be careful with exclude part of secrets with `git-crypt/remove`**!

If you need exclude some files from crypt from dir or glob you **SHOULD** remove
entry dir or all glob, and re-add with `git-crypt/add/file` or `git-crypt/add/dir`.

**ATTENTION!** Because it need multiple operation and every operation commit result,
your git history **will contains commit with non-encrypted files!**.
You **SHOULD** squash commits **before push** to prevent leak secrets!

### Targets list

- `install/git-crypt` - install git-crypt from https://github.com/makefile-inc/git-crypt repo.
   Binary will download from tag `git-crypt-bin:GIT_CRYPT_VERSION`. 
   `GIT_CRYPT_VERSION` saved in [00-version.mk](./00-versions.mk). 
   Now, https://github.com/makefile-inc/git-crypt repo contains `linux/amd64` static binary only. 
   If you need to use on `MacOS` you can:
   - add symlink to binary with `GIT_CRYPT_VERSION` to [BINARIES_PATH](./makefile-common/README.md#variables) with name 
     `git-crypt`
   - build from source (see [sources](./hack/git-crypt/sources/) directory) and copy to [BINARIES_PATH](./makefile-common/README.md#variables) with name `git-crypt`.

- `git-crypt/repo/symmetric/init` - init local repository with symmetric key and export key.
  Before init, operation checks that repo is clean and not already unlocked.
  Also, operation checks that repo does not contains `.gitattributes` file with `git-crypt` filters
  to prevent break repository.
  After init with `git-crypt` target lock repo and unlock with target `git-crypt/symmetric/unlock`
  for set correct local repo settings.

  Params:
  - `KEY_PATH`=*PATH* - path to save key. Should be outside the repo (current dir).
     Target checks that path is not exist to prevent rewrite key.

- `git-crypt/repo/symmetric/unlock` - unlock local repository with symmetric key.
  If repo already unlocked - exit without error.
  Target call `git-crypt unlock` and change local repo settings with command `git config --local` 
  to use `git-crypt` from [BINARIES_PATH](./makefile-common/README.md#variables).

  Params:
  - `KEY_PATH`=*PATH* - path to key file to unlock.

- `git-crypt/repo/lock` - lock local repository.

- `git-crypt/add/file` - add file to crypt and commit to git.
  [See above](#addremove-paths) for more information about mechanic.

  Params:
  - `FILE`=*PATH* - path to add to crypt. Should not be absolute.
    You can use glob for add multiple files like `*.settings.tf`.

- `git-crypt/add/dir` - add directory to crypt and commit to git.
  [See above](#addremove-paths) for more information about mechanic.

  Params:
  - `DIR`=*PATH* - path to add to crypt. Should not be absolute.

- `git-crypt/remove` - add directory to crypt and commit to git.
  [See above](#addremove-paths) for more information about mechanic.

  Params:
  - `TO_REMOVE`=*PATH* - path to add to crypt. Should not be absolute.
    You **SHOULD** use same patter which used in `git-crypt/add/file` (with glob if needs) or `git-crypt/add/dir`.
    For directories you **SHOULD** add slash `/` to end, like `my-dir/`!
    Patterns can see in `.gitattributes` file.
    
    If you need exclude some files from crypt from dir or glob you **SHOULD** remove
    entry dir or all glob, and re-add with `git-crypt/add/file` or `git-crypt/add/dir`.

    **ATTENTION!** Because it need multiple operation and every operation commit result,
    your git history **will contains commit with non-encrypted files!**.
    You **SHOULD** squash commits **before push** to prevent leak secrets!

- `clean/git-crypt` - remove `git-crypt` binary as `GIT_CRYPT_BIN_FULL`.

## git-crypt sources

Repo also contains sources of https://github.com/AGWA/git-crypt repo with `GNUv3` license.
Version described in [README](./hack/git-crypt/README.md#git-crypt-sources).

This need for prevent lost sources if repo will delete.

Also, sources contains [Dockerfile](./hack/git-crypt/Dockerfile) for build static binary for `linux/adm64`.
Final image contains `/git-crypt` binary for extract.

You can build and extract binary with [build.sh](./hack/git-crypt/build.sh) script like:

```bash
./build.sh "${HOME}/bin/git-crypt"
```

## Test cases

Described in repo https://github.com/makefile-inc/test-git-crypt