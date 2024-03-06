;;; roc-ts-mode.el --- Major mode for Roc using tree-sitter  -*- lexical-binding: t; -*-

;; Copyright (C) 2012-2024 Free Software Foundation, Inc.
;;
;; Author           : miilyn
;; Created          : March 2024
;; Keywords         : roc languages tree-sitter
;; Package-Requires : ((emacs "29.1"))
;; URL              : https://github.com/miilyn/roc-ts-mode
;; Version          : 0.0.1

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; Major mode for the Roc programming language using tree-sitter.


;;; Code:

(require 'treesit)


(defcustom roc-ts-mode-dbg-enabled
  nil
  "Debug verbosity, e.g. enable `treesit--indent-verbose'."
  :type 'boolean
  :group 'roc)


(defcustom roc-ts-mode-grammar-repo
  "https://github.com/faldor20/tree-sitter-roc"
  "`tree-sitter' repo to use as the Roc grammar."
  :type 'string
  :group 'roc)


(defun roc-ts-mode--grandparent-is (type)
  "Check whether the node's grandparent's type matches TYPE.

Helper to be used as a MATCHER within `treesit-simple-indent-rules',
similar to `parent-is' from `treesit-simple-indent-presets'."

  (lambda (_node parent _bol)
    (ignore-errors
      (when-let ((grandparent
                  (treesit-node-parent parent)))

        (string-match-p
         type (treesit-node-type grandparent))))))


(defun roc-ts-mode--prev-line-matches (pattern)
  "Check whether the previous line matches regexp PATTERN.

Helper to be used as a MATCHER within `treesit-simple-indent-rules'."

  (lambda (_node _parent bol)
    (let ((content-line
           (save-excursion
             (goto-char bol)
             (forward-line -1)

             (string-trim-right
              (buffer-substring
               (line-beginning-position)
               (line-end-position))))))

      (string-match-p pattern content-line))))


(defvar roc-ts-mode--font-lock-rules
  '(
    :language roc
    :override t
    :feature feat-conditional
    (
     ;; NOTE handle condtionals while they're "in flux", i.e. temporarily invalid.
     (ERROR
      [
       ["if" (then)] @font-lock-keyword-face
       "then" @font-lock-keyword-face
       (else_if ["else" "if"] @font-lock-keyword-face)
       ])

     ;; NOTE handle partial `"((else) if) ... then"'
     (then "then" @font-lock-keyword-face)

     ;; NOTE "finished", valid conditionals
     (if_expr
      [
       ;; NOTE if ...
       "if" @font-lock-keyword-face
       ;; NOTE then$
       (then
        "then" @font-lock-keyword-face)

       (else_if
        [
         ;; NOTE else (if) ...
         "else" @font-lock-keyword-face

         ;; NOTE (else) if ...
         "if" @font-lock-keyword-face

         ;; NOTE (else if) ... then
         (then "then" @font-lock-keyword-face)
         ])

       ;; NOTE else
       (else
        "else" @font-lock-keyword-face)
       ]))


    :language roc
    :override t
    :feature feat-when
    (
     (when) @font-lock-keyword-face
     (is) @font-lock-keyword-face
     (arrow) @font-lock-operator-face)


    :language roc
    :override t
    :feature feat-app-header
    (
     (ERROR "app" @font-lock-builtin-face)
     (ERROR "packages" @font-lock-builtin-face)

     (app_header
      [
       "app" @font-lock-builtin-face
       (app_name) @font-lock-string-face
       ])

     (packages "packages" @font-lock-builtin-face)

     (imports
      [
       "imports" @font-lock-builtin-face

       (imports_entry
        (identifier) @font-lock-variable-name-face)
       ])

     (provides
      "provides" @font-lock-builtin-face
      (ident) @font-lock-variable-name-face
      (to) @font-lock-builtin-face
      (ident) @font-lock-variable-name-face))


    :language roc
    :override t
    :feature feat-interface
    (
     (ERROR "interface" @font-lock-keyword-face)

     (interface_header
      "interface" @font-lock-keyword-face
      (name) @font-lock-type-face)

     (exposes "exposes" @font-lock-builtin-face)

     (imports
      [
       "imports" @font-lock-builtin-face
       (imports_entry
        (identifier) @font-lock-variable-name-face)
       ]))


    :language roc
    :override t
    :feature feat-general
    ;; NOTE needs to be done in ONE go wtf
    (
     (line_comment) @font-lock-comment-face
     (doc_comment) @font-lock-comment-face
     (string) @font-lock-string-face
     (module) @font-lock-constant-face

     ;; Pipeline
     (operator "|>" @font-lock-operator-face)

     ;; Lambdas
     (backslash) @font-lock-operator-face)


    :language roc
    :override t
    :feature feat-decl
    (
     ;; toplevel decl
     (file (value_declaration (decl_left) @font-lock-function-name-face))

     ;; Signature
     (annotation_type_def
      (annotation_pre_colon (identifier) @font-lock-function-name-face))

     (concrete_type) @font-lock-type-face

     ;; Function args
     (argument_patterns
      (identifier_pattern (identifier) @font-lock-variable-name-face))

     ;; local decl
     (expr_body (value_declaration (decl_left) @font-lock-variable-name-face)))


    :language roc
    :override t
    :feature feat-records
    (
     ;; Signature
     (record_type
      (record_field_type
       (field_name) @font-lock-variable-name-face))

     ;; Data
     (record_expr
      (record_field_expr
       (field_name) @font-lock-variable-name-face))

     ;; Pattern
     (record_pattern
      (record_field_pattern
       (field_name) @font-lock-variable-name-face)))


    :language roc
    :override t
    :feature feat-expect
    (
     (expect
      "expect" @font-lock-builtin-face)

     (ERROR
      "expect" @font-lock-builtin-face))


    :language roc
    :override t
    :feature feat-tags
    (
     ;; Data
     (tag_expr
      (tag) @font-lock-type-face)

     ;; Pattern
     (tag_pattern
      [
       (tag) @font-lock-type-face
       (identifier_pattern) @font-lock-variable-name-face
       ]))))

(defvar roc-ts-mode--treesit-simple-indent-rules
  ;; TODO current line starts with `]' or `}': dedent ?
  ;;
  `(roc
    ;; NOTE multiline strings
    ((roc-ts-mode--prev-line-matches "\"\"\"$") prev-line 0)

    ;; NOTE records
    ((roc-ts-mode--prev-line-matches "{$") prev-line 4)
    ((roc-ts-mode--prev-line-matches ",$") prev-line 0)
    ((roc-ts-mode--prev-line-matches "}$") prev-line 0)

    ;; NOTE lists
    ((roc-ts-mode--prev-line-matches "\\[$") prev-line 4)
    ((roc-ts-mode--prev-line-matches "\\]$") prev-line 0)

    ((roc-ts-mode--prev-line-matches "^\\(app\\|interface\\) ") prev-line 4)
    ((roc-ts-mode--prev-line-matches "^app ") prev-line 4)
    ((roc-ts-mode--prev-line-matches "=$") prev-line 4)

    ;; NOTE expect
    ((roc-ts-mode--prev-line-matches "expect$") prev-line 4)
    ((roc-ts-mode--prev-line-matches "^ +.*[^=]=[^=]") prev-line 0)

    ;; NOTE pipeline
    ((roc-ts-mode--prev-line-matches "^ *|>") prev-line 0)

    ;; NOTE pattern matching
    ((roc-ts-mode--prev-line-matches " is$") prev-line 4)
    ((roc-ts-mode--prev-line-matches "->$") prev-line 4)
    ((roc-ts-mode--prev-line-matches "->") prev-line 0)

    ;; NOTE conditionals
    ((roc-ts-mode--prev-line-matches "then$") prev-line 4)
    ((roc-ts-mode--prev-line-matches "else$") prev-line 4)

    ((roc-ts-mode--grandparent-is "else") parent-bol 4)

    ((parent-is "if_expr") parent-bol 0)
    ((parent-is "then") parent-bol 4)
    ((parent-is "when_is_expr") parent-bol 4)

    ;; NOTE catch-all: "keep current indentation"
    ((parent-is "expr_body") parent-bol 4)

    ((parent-is "app_header") parent-bol 0)
    ((parent-is "interface") parent-bol 0)

    ;; NOTE ideally this should be unreachable
    (no-node parent-bol 0)))


(defun roc-ts-mode--treesitter-setup ()
  "Setup `tree-sitter'."

  (treesit-parser-create 'roc)

  (setq-local
   font-lock-defaults
   nil

   treesit-font-lock-settings
   (apply #'treesit-font-lock-rules roc-ts-mode--font-lock-rules)

   treesit-font-lock-level
   3 ;; yolo

   treesit-font-lock-feature-list
   '(
     ;; NOTE for now, let's enable all features by default,
     ;;      i.e. just define all of them as `treesit-font-lock-level' "1"
     ;;
     ;; TODO DRY plssss ;-(
     (feat-decl
      feat-when
      feat-conditional
      feat-records
      feat-tags
      feat-app-header
      feat-interface
      feat-expect
      feat-general))

   treesit-simple-indent-rules
   `(,roc-ts-mode--treesit-simple-indent-rules)

   treesit--indent-verbose
   roc-ts-mode-dbg-enabled)

  ;; NOTE this isn't really a necessary thing to do
  (treesit-font-lock-recompute-features)

  (treesit-major-mode-setup))


;;;###autoload
(define-derived-mode roc-ts-mode prog-mode "Roc"
  "Major mode for the Roc programming language."
  :group 'roc

  ;; NOTE comments
  (setq-local
   comment-start
   "# "

   comment-start-skip
   "#+ *")

  ;; NOTE `tree-sitter'
  (when (treesit-ready-p 'roc)
    (roc-ts-mode--treesitter-setup)))


;;;###autoload
(defun roc-ts-mode-install-grammar ()
  "Install tree-sitter grammar if necessary."

  (interactive)
  (unless (treesit-language-available-p 'roc)
    (when (y-or-n-p
           (format "Install grammar from %s?"
                   roc-ts-mode-grammar-repo))

      (let ((treesit-language-source-alist
             `((roc ,roc-ts-mode-grammar-repo))))

        (treesit-install-language-grammar 'roc)))))


;;;###autoload
(add-to-list 'auto-mode-alist
             '("\\.roc\\'" . roc-ts-mode))


(provide 'roc-ts-mode)

;;; roc-ts-mode.el ends here
