.SHELLFLAGS: -ec
.PHONY: help install uninstall

SYSTEM = $(shell uname)

INSTALL_DIR = $(PWD)
LOCAL_BIN_DIR = $${HOME}/.local/bin
BASH_COMPLETIONS_DIR = .local/share/bash-completion/completions


help:
	@printf '%s\n' \
		'Usage: make OPTION' \
		'' \
		'OPTION:' \
		'  install   - Install/copy files to appropriate directories.' \
		'  uninstall - Uninstall the files copied by "install".' \
		'  help      - Show this help screen.'


# ifeq ($(SYSTEM), Darwin)
# $(info System is macOS)
# else
# $(info System is $(SYSTEM))
# endif




install:
	@echo "Installing ..."

	@mkdir -p $(LOCAL_BIN_DIR)
	@chmod u+x $(INSTALL_DIR)/exec/*

	@ln -sf $(INSTALL_DIR)/exec/letsgo.bash $(LOCAL_BIN_DIR)/letsgo

# 	@cp res/letsgo-completions.bash $${HOME}/$(BASH_COMPLETIONS_DIR)

	@if ! echo $${PATH} | grep $${HOME}/.local/bin > /dev/null ; then \
		printf "%s\n" \
			"" \
			"$(LOCAL_BIN_DIR) is not in PATH" \
			"Add the following to the rc file (.bashrc/.zshrc) of your shell (bash/zsh):" \
			"" \
			"PATH=\$$HOME/.local/bin:\$$PATH" ;\
	fi

	@printf "%s\n" \
		"" \
		"To use the Bash completions provided, add the following" \
		"to the rc file (.bashrc/.zshrc) of your shell (bash/zsh):" \
		"" \
		"if [[ -d \$$HOME/$(BASH_COMPLETIONS_DIR) ]]; then" \
		"    source \$$HOME/$(BASH_COMPLETIONS_DIR)/*" \
		"fi"


uninstall:
	@echo "Uninstalling ..."

	@rm -f $(LOCAL_BIN_DIR)/letsgo

# 	@rm -f $${HOME}/$(BASH_COMPLETIONS_DIR)/letsgo-completions.bash


%:
	@echo "Unknown target: $@"
	@echo "Try 'make help'"
