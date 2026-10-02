# Dotfiles
# Usage:
#   make install   - Create symlinks from repo to $HOME
#   make uninstall - Remove symlinks from $HOME
#   make update    - Git pull and reinstall
#   make packages  - Export package lists (official / aur / flatpak)
#   make check     - 审计系统侧软链是否都指向仓库

DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
CONFIG_DIR  := $(DOTFILES_DIR)/config
HOME_DIR    := $(DOTFILES_DIR)/home

# All items under config/ to symlink into ~/.config/
# Directories get symlinked as directories, files get symlinked as files
CONFIGS := kitty niri fish fuzzel fastfetch btop matugen yazi mpv satty \
           pacseek fontconfig gtk-3.0 gtk-4.0 qt5ct qt6ct xsettingsd \
           xdg-desktop-portal environment.d cava fcitx5 nvim starship.toml \
           autostart chrome-flags.conf mimeapps.list user-dirs.dirs

# All items under home/ to symlink into ~/
# 注意：.gtkrc-2.0 不在列表内（见 维护指南 4.5）——KDE 的 kde-gtk-config 每次同步
# GTK 外观都会用 temp+rename 重写它，软链会被打回普通文件，还会在 ~ 留下 .bak。
# 仓库里仍保留 home/.gtkrc-2.0 作为快照，改动后手动同步。
HOMEFILES := .zshrc .zprofile .bash_profile .profile .gitconfig \
             .Xresources bin

.PHONY: install uninstall update packages check

check:
	@bash scripts/audit-links.sh

install:
	@echo "==> Installing dotfiles..."
	@mkdir -p $(HOME)/.config
	@# Symlink config directories/files
	@for cfg in $(CONFIGS); do \
		if [ -e "$(CONFIG_DIR)/$$cfg" ]; then \
			target="$(HOME)/.config/$$cfg"; \
			link="$(CONFIG_DIR)/$$cfg"; \
			if [ -L "$$target" ] && [ "$$(readlink $$target)" = "$$link" ]; then \
				echo "  [SKIP] $$target (already linked)"; \
			elif [ -e "$$target" ] || [ -L "$$target" ]; then \
				backup="$$target.bak.$$(date +%s)"; \
				echo "  [BACKUP] $$target -> $$backup"; \
				mv "$$target" "$$backup"; \
				ln -s "$$link" "$$target"; \
				echo "  [LINK] $$target"; \
			else \
				ln -s "$$link" "$$target"; \
				echo "  [LINK] $$target"; \
			fi; \
		fi; \
	done
	@# Symlink systemd user units individually (whole dir has system-owned files)
	@for f in $$(find $(CONFIG_DIR)/systemd -type f 2>/dev/null); do \
		rel="$${f#$(CONFIG_DIR)/systemd/}"; \
		target="$(HOME)/.config/systemd/$$rel"; \
		mkdir -p "$$(dirname "$$target")"; \
		if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$f" ]; then \
			echo "  [SKIP] $$target (already linked)"; \
		elif [ -e "$$target" ] || [ -L "$$target" ]; then \
			backup="$$target.bak.$$(date +%s)"; \
			echo "  [BACKUP] $$target -> $$backup"; \
			mv "$$target" "$$backup"; \
			ln -s "$$f" "$$target"; \
			echo "  [LINK] $$target"; \
		else \
			ln -s "$$f" "$$target"; \
			echo "  [LINK] $$target"; \
		fi; \
	done
	@# Symlink home dotfiles
	@for file in $(HOMEFILES); do \
		if [ -e "$(HOME_DIR)/$$file" ]; then \
			target="$(HOME)/$$file"; \
			link="$(HOME_DIR)/$$file"; \
			if [ -L "$$target" ] && [ "$$(readlink $$target)" = "$$link" ]; then \
				echo "  [SKIP] $$target (already linked)"; \
			elif [ -e "$$target" ] || [ -L "$$target" ]; then \
				backup="$$target.bak.$$(date +%s)"; \
				echo "  [BACKUP] $$target -> $$backup"; \
				mv "$$target" "$$backup"; \
				ln -s "$$link" "$$target"; \
				echo "  [LINK] $$target"; \
			else \
				ln -s "$$link" "$$target"; \
				echo "  [LINK] $$target"; \
			fi; \
		fi; \
	done
	@echo "==> Done. Run 'matugen' to regenerate theme colors if needed."

uninstall:
	@echo "==> Removing dotfile symlinks..."
	@for cfg in $(CONFIGS); do \
		target="$(HOME)/.config/$$cfg"; \
		if [ -L "$$target" ]; then \
			link="$$(readlink $$target)"; \
			if echo "$$link" | grep -q "$(DOTFILES_DIR)"; then \
				rm "$$target"; \
				echo "  [REMOVE] $$target"; \
			else \
				echo "  [SKIP] $$target (not managed by dotfiles)"; \
			fi; \
		fi; \
	done
	@# Remove systemd user unit symlinks
	@for f in $$(find $(CONFIG_DIR)/systemd -type f 2>/dev/null); do \
		rel="$${f#$(CONFIG_DIR)/systemd/}"; \
		target="$(HOME)/.config/systemd/$$rel"; \
		if [ -L "$$target" ] && echo "$$(readlink "$$target")" | grep -q "$(DOTFILES_DIR)"; then \
			rm "$$target"; \
			echo "  [REMOVE] $$target"; \
		fi; \
	done
	@for file in $(HOMEFILES); do \
		target="$(HOME)/$$file"; \
		if [ -L "$$target" ]; then \
			link="$$(readlink $$target)"; \
			if echo "$$link" | grep -q "$(DOTFILES_DIR)"; then \
				rm "$$target"; \
				echo "  [REMOVE] $$target"; \
			else \
				echo "  [SKIP] $$target (not managed by dotfiles)"; \
			fi; \
		fi; \
	done
	@echo "==> Done. Backups (if any) are at *.bak.* files."

update:
	@echo "==> Updating dotfiles..."
	@cd $(DOTFILES_DIR) && git pull
	@$(MAKE) install
	@echo "==> Done."

packages:
	@echo "==> Exporting package lists..."
	@mkdir -p $(DOTFILES_DIR)/packages
	@pacman -Qqen > $(DOTFILES_DIR)/packages/official.txt
	@pacman -Qqem > $(DOTFILES_DIR)/packages/aur.txt
	@echo "  official.txt: $$(wc -l < $(DOTFILES_DIR)/packages/official.txt) packages"
	@echo "  aur.txt:      $$(wc -l < $(DOTFILES_DIR)/packages/aur.txt) packages"
	@if command -v flatpak >/dev/null 2>&1; then \
		LC_ALL=C flatpak list --app --columns=application,origin 2>/dev/null \
			| awk '/\./ {printf "%s\t%s\n", $$1, ($$2 == "" ? "flathub" : $$2)}' \
			> $(DOTFILES_DIR)/packages/flatpak.txt; \
		echo "  flatpak.txt:  $$(grep -c . $(DOTFILES_DIR)/packages/flatpak.txt) apps"; \
	else \
		echo "  flatpak.txt:  skipped (flatpak not installed)"; \
	fi
	@echo "==> Done. Run 'make install' to symlink if not already done."
