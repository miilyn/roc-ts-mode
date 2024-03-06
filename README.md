# M-x roc-ts-mode

Emacs major mode for the [Roc programming language](https://www.roc-lang.org/) using [tree-sitter](https://tree-sitter.github.io/tree-sitter/).

## Disclaimer

This is early wip, so filing issues is greatly appreciated.


# Installation

## Dependencies

This package requires:

1. Emacs 29 or newer built with tree-sitter support
2. [Roc tree-sitter grammar](https://github.com/faldor20/tree-sitter-roc) (c.f. `(roc-ts-mode-install-grammar)`)

## Installation from MELPA

tbd

## Installation from source

Install either via [`use-package`](https://github.com/jwiegley/use-package)

``` emacs-lisp
(use-package roc-ts-mode
  :load-path "<path to repo>"

  :custom
  (roc-ts-mode-grammar-repo
   "https://github.com/faldor20/tree-sitter-roc" ;; default

   roc-ts-mode-dbg-enabled
   t ;; enable `treesit--indent-verbose' et al
   )

  :config
  (roc-ts-mode-install-grammar))
```

or just using plain old `require`

``` emacs-lisp
(add-to-list 'load-path "<path to repo>")
(require 'roc-ts-mode)

...
(roc-ts-mode-install-grammar)
```

# License

GPLv3
