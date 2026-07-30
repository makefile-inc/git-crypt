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
git fetch -a && git checkout v0.5.0
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
git fetch -a && git checkout NEW_TAG
git submodule update --recursive
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

### Utils bash-functions includes

Next definitions add bash functions definitions, which can cal in one line bash targets, like:
```Makefile
_test/echo:
	@${GIT_CRYPT_UNLOCKED_INCLUDES} \
	...
```

**WARNING! When use definition you SHOULD use `\` in the end of line for prevent break one-line script!**

Next definitions can be included multiple times because sh redeclare function without error.

- `GIT_CRYPT_UNLOCKED_INCLUDES` - add next sh functions:
    - `is_repo_unlocked` - check that git repo already unlocked with git-crypt
       if unlocked - return 0; else return 1
    - `is_repo_locked`   - check that git repo locked with git-crypt
      if locked - return 0; else return 1

  Example:
  ```Makefile
  include *.mk
  test/unlocked:
		@${INCLUDE_ECHO} \
		${GIT_CRYPT_UNLOCKED_INCLUDES} \
		if ! is_repo_unlocked; then \
			exit_with_err "Repo is locked!"; \
		fi
  ```

## Targets

### Description

All targets install `git-crypt` with `install/git-crypt` ([see](#targets-list) targets description for current limitations).

Also, another operations check that git repo is clean (has not changes).

#### Add/remove path's

Add/remove operations change `.gitattributes` files to add git filters for encrypted files.
Also, add/remove operations re-add files and dirs with `git rm --cached` and `git add` calls.
If using globs, then script enable (and after finish re-add - disable) next shop for re-add:
- `nullglob`
- `globstar`
- `dotglob`

Also, if using globs targets find all globs with prefix `./**/` to consume all files.
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

##### Attention about partial removing with globs and dirs

**Be careful with exclude part of secrets with `git-crypt/remove`**!

Unfortunately, git-attributes file not support negative `!` patterns.

If you need exclude some files from crypt from dir or glob you **SHOULD** remove
entry dir or all glob, and re-add with `git-crypt/add/file` or `git-crypt/add/dir`.

**ATTENTION!** Because it need multiple operation and every operation commit result,
your git history **will contains commit with non-encrypted files!**.

You **SHOULD** squash commits **before push** to prevent **leak** secrets!

### Targets list

#### Common

- `install/git-crypt` - install git-crypt from https://github.com/makefile-inc/git-crypt repo.
   Binary will download from tag `git-crypt-bin:GIT_CRYPT_VERSION`. 
   `GIT_CRYPT_VERSION` saved in [00-version.mk](./00-versions.mk). 
   Now, https://github.com/makefile-inc/git-crypt repo contains `linux/amd64` static binary only. 
   If you need to use on `MacOS` you can:
   - add symlink to binary with `GIT_CRYPT_VERSION` to [BINARIES_PATH](./makefile-common/README.md#variables) with name 
     `git-crypt`
   - build from source (see [sources](./hack/git-crypt/sources/) directory) and copy to [BINARIES_PATH](./makefile-common/README.md#variables) with name `git-crypt`.

- `git-crypt/repo/lock` - lock local repository.

- `clean/git-crypt` - remove `git-crypt` binary as `GIT_CRYPT_BIN_FULL`.

#### Symmetric key operations

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

- `git-crypt/repo/symmetric/check/locked` - check repo is locked with symmetric key.

- `git-crypt/repo/symmetric/check/unlocked` - check repo is unlocked with symmetric key.

#### Add or remove to/from git-crypt

- `git-crypt/add/file` - add file to crypt and commit to git.
  [See above](#addremove-paths) for more information about mechanic.

  Params:
  - `FILE`=*PATH* - path to add to crypt. Should not be absolute.
    You can use glob for add multiple files like `*.settings.tf`.

- `git-crypt/add/dir` - add directory (with sub-directories) to crypt and commit to git.
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

    Unfortunately, git-attributes file not support negative `!` patterns.
    
    If you need exclude some files from crypt from dir or glob you **SHOULD** remove
    entry dir or all glob, and re-add with `git-crypt/add/file` or `git-crypt/add/dir`.

    **ATTENTION!** Because it need multiple operation and every operation commit result,
    your git history **will contains commit with non-encrypted files!**.
    You **SHOULD** squash commits **before push** to prevent leak secrets!

## Examples

Add `Makefile` and [include](#install) `makefile.inc/git-crypt`.

- init

```bash
make git-crypt/repo/symmetric/init KEY_PATH=../repo.key
```

- unlock

```bash
make git-crypt/repo/symmetric/unlock KEY_PATH="${HOME}/secret-place/repo.key"
```

- add single file `test-1.key`

```bash
make git-crypt/add/file FILE=test-1.key
```

- add single file in sub-directory `subdir/deep/key.txt`

```bash
make git-crypt/add/file FILE=subdir/deep/key.txt
```

- add directory `keys-dir/` with sub-directories

```bash
make git-crypt/add/dir DIR=keys-dir/
```

- add files for all directories with suffix `.settings.tf`

```bash
make git-crypt/add/file FILE=*.settings.tf
```

- remove from crypt single file `test-1.key` add as `make git-crypt/add/file FILE=test-1.key`

```bash
make git-crypt/remove TO_REMOVE=test-1.key
```

- remove from crypt single file in sub-directory `subdir/deep/key.txt` added as `make git-crypt/add/file FILE=subdir/deep/key.txt`

```bash
make git-crypt/remove TO_REMOVE=subdir/deep/key.txt
```

- remove from crypt directory with sub-directories `keys-dir/` added as `make git-crypt/add/dir DIR=keys-dir/`

```bash
make git-crypt/remove TO_REMOVE=keys-dir/
```

- remove from crypt add files for all directories with suffix `.settings.tf` added as `make git-crypt/add/file FILE=*.settings.tf`

```bash
make git-crypt/remove TO_REMOVE=*.settings.tf
```

- remove partial files after add via globs or dir.
  For example, we have next structure:
  ```
  repo/
  ├── no_encrypted.file
  ├── dir-with-keys/
  │   ├── first.key
  │   ├── second.key
  ```
  And you add full dir with `make git-crypt/add/dir DIR=dir-with-keys/` and now you want to exclude `dir-with-keys/first.key`.
  If you want remove permanently, you can remove file and commit. 
  Otherwise, if you want to exclude file, you have next variants:
  - move non-secret file to another directory:
    ```bash
    mkdir not-encrypted-dir
    mv dir-with-keys/first.key not-encrypted-dir/
    ```
  - create new secret directory, add to crypt and move secret files:
    ```bash
    make git-crypt/add/dir DIR=new-secret-dir/
    mkdir new-secret-dir
    mv dir-with-keys/second.key new-secret-dir/
    git add new-secret-dir/ dir-with-keys/
    git commit -m "refact secrets"
    make git-crypt/remove TO_REMOVE=dir-with-keys/
    ```
  - exclude file from crypt. It is not good choice, because, unfortunately,
    git-attributes file not support negative `!` patterns, and after add another secrets
    you **should** add **all** another secrets manually for each secret: 
    ```bash
    make git-crypt/remove TO_REMOVE=dir-with-keys/
    make git-crypt/add/file FILE=dir-with-keys/second.key
    # Find first commit on branch
    git log
    # Squash branch to prevent leak secrets
    git rebase -i HEAD~COUNT_OF_COMMITS
    git push --force
    ```

- lock repo
  ```bash
  make git-crypt/repo/lock
  ```

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
