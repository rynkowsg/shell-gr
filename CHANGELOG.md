# Changelog

## [Unreleased]

[Unreleased]: https://github.com/rynkowsg/shell-gr/compare/v0.2.2..main

- **normalize**: Add function to unset overridden `cd`

## [0.2.2](https://github.com/rynkowsg/shell-gr/commits/v0.2.2) (2024-03-26)

BREAKING CHANGES:

- **error**: Restore 'set -e' state immediately in `run_with_unset_e`

## [0.2.1](https://github.com/rynkowsg/shell-gr/commits/v0.2.1) (2024-03-25)

FIXES:

- **asdf**: Fix path initialization when `SHELL_GR_DIR` not defined
- **text:** Fix `append_if_not_exists` for non-existing files

## [0.2.0](https://github.com/rynkowsg/shell-gr/commits/v0.2.0) (2024-03-23)

FIXES:
- Fix `SHELL_GR_DIR` for `$0=/usr/local/bin/bash`
- Fix `BASH_SOURCE[0]: unbound variable` (2024-03-18)

NEW:
- **circleci:** Add `fix_home_in_old_images` & `print_common_debug_info`
- **error:** Add `error_exit` & `assert_command_exist`
- **git_checkout_advanced:** Add `git_checkout_advanced`
- **git_lfs:** Add `setup_git_lfs`
- **github:** Add `github_authorized_repo_url`
- **ssh**: Add `setup_ssh`
- **temp:** Add `temp_file` & `temp_dir`

List of changes: [`v0.1.0..v0.2.0`](https://github.com/rynkowsg/shell-gr/commit/v0.1.0..v0.2.0)

## [0.1.0](https://github.com/rynkowsg/shell-gr/commits/v0.1.0) (2024-03-15)

The initial version contain following libraries:
```text
% tree lib
lib
├── color.bash
├── dict.bash
├── error.bash
├── fs.bash
├── install
│   ├── asdf.bash
│   └── asdf_circleci.bash
├── install_common.bash
├── log.bash
├── log_detailed.bash
├── log_utils.bash
├── text.bash
├── tool
│   ├── format.bash
│   └── lint.bash
└── trap.bash
```
