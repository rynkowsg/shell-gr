.PHONY: lint format-check format-apply format-update-patches test

format:
	\@bin/format.bash check

format-apply:
	\@bin/format.bash apply

# Since formatting doesn't allow to ignore some parts, I apply patches before and after formatting to overcome this.
# Here are commands to update these patches
format-update-patches:
	APPLY_PATCHES=0 make format-apply
	git commit -a --no-gpg-sign -m "patch"
	git revert --no-commit HEAD
	git commit -a --no-gpg-sign -m "patch revert"
	mkdir -p @bin/res
	git diff HEAD~2..HEAD~1 > @bin/res/pre-format.patch
	git diff HEAD~1..HEAD > @bin/res/post-format.patch
	git reset HEAD~2
	\[ -f @bin/res/pre-format.patch \] && git add @bin/res/pre-format.patch
	\[ -f @bin/res/post-format.patch \] && git add @bin/res/post-format.patch
	git commit -m "ci: Update patches"

lint:
	\@bin/lint.bash

test:
	bats ./test/*

test-verbose:
	bats --show-output-of-passing-tests ./test/*
