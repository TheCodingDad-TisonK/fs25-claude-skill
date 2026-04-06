# Makefile for FS25 Claude Skill

SKILL_DIR = skill/fs25-modding-skill/
OUTPUT_DIR = releases/
PACKAGE_SCRIPT = skill/package_skill.py
VERSION = $(shell cat VERSION)

.PHONY: all package clean help

all: package

package:
	@echo "📦 Packaging FS25 Claude Skill v$(VERSION)..."
	python $(PACKAGE_SCRIPT) $(SKILL_DIR) --output $(OUTPUT_DIR)
	@echo "✅ Package created in $(OUTPUT_DIR)"

clean:
	@echo "🧹 Cleaning up..."
	rm -rf dist/
	rm -rf build/
	@echo "✨ Done."

help:
	@echo "Available commands:"
	@echo "  make package - Package the skill into $(OUTPUT_DIR)"
	@echo "  make clean   - Remove build artifacts"
	@echo "  make help    - Show this help message"
