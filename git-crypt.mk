GIT_CRYPT_BIN = git-crypt
GIT_CRYPT_BIN_FULL = $(BINARIES_PATH)/$(GIT_CRYPT_BIN)

_GIT_ATTRIBUTES_PATH = $(CURDIR)/.gitattributes

##@ git-crypt

_git-crypt/no-changes:
	@${INCLUDE_ECHO} \
	if ! stt="$$(git status)"; then \
		exit_with_err "Cannot get repo status with 'git status'"; \
	fi; \
	if ! grep -q "nothing to commit, working tree clean" <<<"$$stt"; then \
		echo_err "Git status:"; \
		echo "$$stt"; \
		exit_with_err "Git repo has changes"; \
	fi

install/git-crypt: export INSTALL_BIN_NAME = $(GIT_CRYPT_BIN)
install/git-crypt: export INSTALL_BIN_VERSION = $(GIT_CRYPT_VERSION)
install/git-crypt: export INSTALL_BIN_VERSION_ARG = version
install/git-crypt: export INSTALL_BIN_URL = https://github.com/makefile-inc/git-crypt/releases/download/git-crypt-bin-@BIN_VER@/git-crypt-@BIN_OS@-@BIN_ARCH@
install/git-crypt: ## Install git-crypt from https://github.com/makefile-inc/git-crypt repo
	@$(MAKE) install/binary

git-crypt/symmetric/init: install/git-crypt _git-crypt/no-changes ## Init local repository with symmetric key and export key. Git repo should be clean
	@##~ KEY_PATH=PATH - path to save key
	@${INCLUDE_ECHO} \
	if [ -z "$$KEY_PATH" ]; then \
		exit_with_err "Output key file not specify with 'KEY_PATH' param (env)"; \
	fi; \
	if [ -e "$$KEY_PATH" ]; then \
		exit_with_err "Output key file '$$KEY_PATH' exist"; \
	fi; \
	cur_dir="$(CURDIR)"; \
	if ! cur_dir="$$(realpath "$$cur_dir")"; then \
		exit_with_err "Cannot get realpath for $(CURDIR)"; \
	fi; \
	if ! KEY_PATH="$$(realpath "$$KEY_PATH")"; then \
		exit_with_err "Cannot get realpath for KEY_PATH"; \
	fi; \
	if [[ "$$KEY_PATH" == "$${cur_dir}/"* ]]; then \
    	exit_with_err "Key destination in repo path. Please choice another destination"; \
	fi; \
	if [ -s "$${cur_dir}/.git/git-crypt/keys/default" ] && [ "$$(git config --local --list | grep 'filter.git-crypt' | wc -l)" = "3" ]; then \
		exit_with_err "Repo already unlocked!"; \
	fi; \
	attributes_file="$(_GIT_ATTRIBUTES_PATH)"; \
	if [ -f "$$attributes_file" ]; then \
		if grep "filter=git-crypt" "$$attributes_file"; then \
			exit_with_err ".gitattributes files contains git-crypt filters. Probably you can init repository not unlocked repo"; \
		fi; \
	fi; \
	if ! $(GIT_CRYPT_BIN_FULL) init; then \
		exit_with_err "Cannot init repo"; \
	fi; \
	if ! $(GIT_CRYPT_BIN_FULL) export-key "$$KEY_PATH"; then \
		exit_with_err "Cannot export key to '$$KEY_PATH'"; \
	fi; \
	if [ ! -s "$$KEY_PATH" ]; then \
		exit_with_err "Key file '$$KEY_PATH' is empty"; \
	fi; \
	echo_info "git-crypt init. Next, lock repo and unlock for verify and init local git config with relative path"; \
	if ! $(GIT_CRYPT_BIN_FULL) lock; then \
		exit_with_err "Cannot lock repo"; \
	fi; \
	if ! $(MAKE) git-crypt/symmetric/unlock KEY_PATH="$$KEY_PATH"; then \
		exit_with_err "Cannot unlock repo"; \
	fi; \
	echo_info "git-crypt init fully!"; \
	echo_info "Symmetric key save to $$KEY_PATH"; \
	echo_info "Please save key in the security location and use for unlock repo later"

git-crypt/symmetric/unlock: install/git-crypt ## Unlock local repository with symmetric key
	@##~ KEY_PATH=PATH - path to key file to unlock
	@${INCLUDE_ECHO} \
	if [ -s "$(CURDIR)/.git/git-crypt/keys/default" ] && [ "$$(git config --local --list | grep 'filter.git-crypt' | wc -l)" = "3" ]; then \
		echo_info "Already unlocked!"; \
		exit 0; \
	fi; \
	key="$$KEY_PATH"; \
	if [ -z "$$key" ]; then \
		exit_with_err "Key file not specify with 'KEY_PATH' param (env)"; \
	fi; \
	if [ ! -f "$$key" ]; then \
		exit_with_err "Key file '$$key' is not file or not found"; \
	fi; \
	full_bin_path="$(GIT_CRYPT_BIN_FULL)"; \
	if ! full_bin_path="$$(realpath "$$full_bin_path")"; then \
		exit_with_err "Cannot get realpath for $(GIT_CRYPT_BIN_FULL)"; \
	fi; \
	cur_dir="$(CURDIR)"; \
	if ! cur_dir="$$(realpath "$$cur_dir")"; then \
		exit_with_err "Cannot get realpath for $(CURDIR)"; \
	fi; \
	cur_dir="$${cur_dir}/"; \
	relative_crypt_bin="$${full_bin_path#$$cur_dir}"; \
	if [ -z "$$relative_crypt_bin" ]; then \
		exit_with_err "Relative git-crypt bin path is empty"; \
	fi; \
	relative_crypt_bin="./$${relative_crypt_bin}"; \
	if ! $(GIT_CRYPT_BIN_FULL) unlock "$$key"; then \
		exit_with_err "Cannot unlock repo with '$$key'"; \
	fi; \
	smudge_str="\"$$relative_crypt_bin\" smudge"; \
	if ! git config --local filter.git-crypt.smudge "$$smudge_str"; then \
		exit_with_err "Failed to set to git config smudge filter"; \
	fi; \
	clean_str="\"$$relative_crypt_bin\" clean"; \
	if ! git config --local filter.git-crypt.clean "$$clean_str"; then \
		exit_with_err "Failed to set to git config clean filter"; \
	fi; \
	if ! git config --local filter.git-crypt.required true; then \
		exit_with_err "Failed to set to git config required git crypt filter"; \
	fi; \
	diff_str="\"$$relative_crypt_bin\" diff"; \
	if ! git config --local diff.git-crypt.textconv "$$diff_str"; then \
		exit_with_err "Failed to set to git config git crypt diff"; \
	fi

git-crypt/add/file: install/git-crypt _git-crypt/no-changes ## Add file to crypt and commit to git. Git repo should be clean
	@##~ FILE=PATH - path to add to crypt. Should not be absolute
	@${INCLUDE_ECHO} \
	if [ -z "$$FILE" ]; then \
		exit_with_err "File not specify with 'FILE' param (env)"; \
	fi; \
	if [[ "$$FILE" == /* ]]; then \
    	exit_with_err "Path '$$FILE' should not be absolute"; \
	fi; \
	attributes_file="$(_GIT_ATTRIBUTES_PATH)"; \
	if [ ! -f "$$attributes_file" ]; then \
		touch "$$attributes_file"; \
	fi; \
	trimmed="$${FILE#/}"; \
	if grep "^$$trimmed" "$$attributes_file"; then \
		echo_info "'$$FILE' already added!"; \
		exit 0; \
	fi; \
	echo "$$trimmed filter=git-crypt diff=git-crypt" >> "$$attributes_file"; \
	if ! git add "$$attributes_file"; then \
		exit_with_err "Cannot commit add file"; \
	fi; \
	if ! git commit -m "Add file '$$FILE' to crypt"; then \
		exit_with_err "Cannot commit add file"; \
	fi

git-crypt/add/dir: install/git-crypt _git-crypt/no-changes ## Add dir to crypt and commit to git. Git repo should be clean
	@##~ DIR=PATH - dir path to add to crypt. Should not be absolute
	@${INCLUDE_ECHO} \
	if [ -z "$$DIR" ]; then \
		exit_with_err "Dir path not specify with 'DIR' param (env)"; \
	fi; \
	if [[ "$$DIR" == /* ]]; then \
    	exit_with_err "Path '$$DIR' should not be absolute"; \
	fi; \
	attributes_file="$(_GIT_ATTRIBUTES_PATH)"; \
	if [ ! -f "$$attributes_file" ]; then \
		touch "$$attributes_file"; \
	fi; \
	dir_path="$${DIR%*}"; \
	dir_path="$${dir_path%*}"; \
	dir_path="$${dir_path#/}"; \
	if grep "^$$dir_path/**" "$$attributes_file"; then \
		echo_info "$$dir_path already added!"; \
		exit 0; \
	fi; \
	echo "$$dir_path/** filter=git-crypt diff=git-crypt" >> "$$attributes_file"; \
	if ! git add "$$attributes_file"; then \
		exit_with_err "Cannot commit add dir"; \
	fi; \
	if ! git commit -m "Add dir '$$dir_path' to crypt"; then \
		exit_with_err "Cannot commit add dir"; \
	fi

git-crypt/remove: install/git-crypt _git-crypt/no-changes ## Remove path from crypt and commit to git. Git repo should be clean
	@##~ TO_REMOVE=PATH - path to remove from crypt. Should not be absolute
	@${INCLUDE_ECHO} \
	if [ -z "$$TO_REMOVE" ]; then \
		exit_with_err "Path to remove not specify with 'TO_REMOVE' param (env)"; \
	fi; \
	if [[ "$$TO_REMOVE" == /* ]]; then \
    	exit_with_err "Path '$$TO_REMOVE' should not be absolute"; \
	fi; \
	attributes_file="$(_GIT_ATTRIBUTES_PATH)"; \
	if [ ! -f "$$attributes_file" ]; then \
		touch "$$attributes_file"; \
	fi; \
	trimmed="$${TO_REMOVE%*}"; \
	trimmed="$${trimmed%*}"; \
	trimmed="$${trimmed#/}"; \
	if ! grep "^$$trimmed" "$$attributes_file"; then \
		echo_info "$$TO_REMOVE already removed"; \
		exit 0; \
	fi; \
	escaped="$$(printf '%s\n' "$$trimmed" | sed -e 's/[\/&]/\\&/g')"; \
	if ! sed -i "/$$escaped\/\?\*\?\*\? /d" "$$attributes_file"; then \
		exit_with_err "Cannot remove attribute with sed"; \
	fi; \
	if ! git add "$$attributes_file"; then \
		exit_with_err "Cannot commit remove path"; \
	fi; \
	if ! git commit -m "Remove path '$$TO_REMOVE' from crypt"; then \
		exit_with_err "Cannot commit remove path"; \
	fi
