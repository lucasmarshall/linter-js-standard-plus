linter-js-standard-plus
=======================

This linter plugin for [Linter](https://github.com/AtomLinter/Linter) provides an interface for error/warning messages from [standard](https://github.com/feross/standard), [semistandard](https://github.com/Flet/semistandard) or [uber-standard](https://github.com/uber/standard). Inspired by [linter-js-standard](https://atom.io/packages/linter-js-standard)
and [linter-eslint](https://atom.io/packages/linter-eslint)

## Advantages
* Runs the linter asyncronously and in-process, requiring no writing of tmp files to the filesystem.
* Respects .eslintrc or configuration in package.json.
* Supports uber-standard.

## Installation
Linter package must be installed in order to use this plugin. If Linter is not installed, please follow the instructions [here](https://github.com/AtomLinter/Linter).

### Plugin installation
```
$ apm install linter-js-standard-plus
```

## Change module
You can change from standard to semistandard or uber-standard and vice versa in the plugin settings.

## Known issues

### Switching modules
Switching modules requires you to reload your editor or restart Atom.
