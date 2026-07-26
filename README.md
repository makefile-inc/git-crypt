# git-crypt

Makefiles include for using git-crypt https://github.com/AGWA/git-crypt

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
git fetch -a && git checkout v0.4.0 && git pull
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
