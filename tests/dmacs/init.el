;;; init.el --- user-init-file                    -*- lexical-binding: t -*-

(defvar before-user-init-time (current-time)
  "Value of `current-time' when Emacs begins loading `user-init-file'.")
(message "Loading Emacs...done (%.3fs)"
         (float-time (time-subtract before-user-init-time
                                    before-init-time)))

(setq gc-cons-threshold (* 256 1024 1024))

(defvar file-name-handler-alist-old file-name-handler-alist)
(setq file-name-handler-alist nil)

(setq message-log-max 16384)

(setq byte-compile-warnings '(not free-vars unresolved noruntime lexical make-local))

(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

(fringe-mode '(3 . 1))

(setq inhibit-startup-buffer-menu t)
(setq inhibit-startup-screen t)
(setq inhibit-startup-echo-area-message "daniel")
(setq initial-buffer-choice t)
(setq initial-scratch-message nil)

(setq package-enable-at-startup nil)
;; (package-initialize)
;; (setq load-prefer-newer t)

(setq user-init-file (or load-file-name buffer-file-name))
(setq user-emacs-directory (file-name-directory user-init-file))
(add-to-list 'load-path (expand-file-name "lib/borg" user-emacs-directory))
(require 'borg)
(borg-initialize)

;;(defvar use-package-enable-imenu-support t)
(require 'use-package)
(if nil  ; Toggle init debug
      (setq use-package-verbose t
            use-package-expand-minimally nil
            use-package-compute-statistics t
            debug-on-error t)
    (setq use-package-verbose nil
          use-package-expand-minimally t))

;; For the :bind keyword
(use-package bind-key :defer t)
;;(autoload #'use-package-autoload-keymap "use-package")

(use-package epkg :defer t)

(use-package no-littering
  :demand t
  :config
  ;; /etc is version controlled and I want to store mc-lists in git
  (setq mc/list-file (no-littering-expand-etc-file-name "mc-list.el"))
  ;; Put the auto-save files in the var directory to the other data files
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))

(use-package custom
  :config
  ;; We don't use custom and don't have to set custom-file even
  ;; in the case when we "accidentally" click save in a custom buffer,
  ;; `init.el' would get modified which gets overwrite the next time
  ;; we run `make'.

  ;; Treat all themes as safe
  (setf custom-safe-themes t))

(use-package color-theme-sanityinc-tomorrow
  :disabled t
  :unless noninteractive
  :config
  (load-theme 'sanityinc-tomorrow-night 'no-confirm)
  (let ((line (face-attribute 'mode-line :underline)))
    (set-face-attribute 'mode-line nil :overline line)
    (set-face-attribute 'mode-line-inactive nil :overline line)
    (set-face-attribute 'mode-line-inactive nil :underline line)
    (set-face-attribute 'mode-line nil :box nil)
    (set-face-attribute 'mode-line-inactive nil :box nil)))

(use-package moe-theme
  :unless noninteractive
  :config (load-theme 'moe-dark t))

(use-package moody
  :unless noninteractive
  :defer 1
  :config
  (setq x-underline-at-descent-line t)
  (setq moody-mode-line-height 20)
  (moody-replace-mode-line-buffer-identification)
  (moody-replace-vc-mode))

(use-package minions
  :unless noninteractive
  :defer 2
  :config
  (setq minions-mode-line-lighter "+")
  (setq minions-direct '(projectile-mode flycheck-mode multiple-cursors-mode sticky-buffer-mode))
  (minions-mode))

(setq user-full-name "Daniel Kraus"
      user-mail-address "daniel@kraus.my")

(defun get-envvar-name (envvar)
  "Return environment variable name for ENVVAR.
Code from `read-envvar-name'."
  (let ((str (substring envvar 0
                        (string-match "=" envvar))))
    (if (multibyte-string-p str)
        (decode-coding-string
         str locale-coding-system t)
      str)))

(defun create-safe-env-p (&rest keys)
  "Return predicate function that's non-NIL when it's argument KEY is in KEYS."
  (lambda (envlist)
    (-all-p (lambda (key)
              (-any-p (lambda (k)
                        (string= (get-envvar-name key) k)) keys)) envlist)))

;; Don't quit Emacs on C-x C-c
(when (daemonp)
  (global-set-key (kbd "C-x C-c") 'kill-buffer-and-window))
;; Always just use left-to-right text
;; This makes Emacs a bit faster for very long lines
(setq-default bidi-display-reordering nil)

(setq-default indent-tabs-mode nil)   ; don't use tabs to indent
(setq-default tab-width 8)            ; but maintain correct appearance
;; smart tab behavior - indent or complete
(setq tab-always-indent 'complete)

;; Newline at end of file
(setq require-final-newline t)

;; Default to utf-8 unix encoding
(prefer-coding-system 'utf-8-unix)

;; Delete the selection with a keypress
(delete-selection-mode t)

;; Activate character folding in searches i.e. searching for 'a' matches 'ä' as well
(setq search-default-mode 'char-fold-to-regexp)

;; Only split vertically on very tall screens
(setq split-height-threshold 110)

;; Paste with middle mouse button doesn't move the curser
(setq mouse-yank-at-point t)

;; Save whatever’s in the current (system) clipboard before
;; replacing it with the Emacs’ text.
;; https://github.com/dakrone/eos/blob/master/eos.org
(setq save-interprogram-paste-before-kill t)

(setq ffap-machine-p-known 'reject)  ; don't "ping Germany" when typing test.de<TAB>

;; Accept 'UTF-8' (uppercase) as a valid encoding in the coding header
(define-coding-system-alias 'UTF-8 'utf-8)

;; Put authinfo.gpg first so new secrets will be stored there by default and not in plain text
(setq auth-sources '("~/.authinfo.gpg" "~/.authinfo" "~/.netrc"))

;; Silence ad-handle-definition about advised functions getting redefined
(setq ad-redefinition-action 'accept)

;; Increase the 'Limit on number of Lisp variable bindings and unwind-protects.'
;; mu4e seems to need more sometimes and it can be safely increased.
(setq max-specpdl-size 2048)

;; allow horizontal scrolling with "M-x >"
(put 'scroll-left 'disabled nil)
;; enable narrowing commands
(put 'narrow-to-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)
(put 'narrow-to-defun 'disabled nil)
;; enabled change region case commands
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; enable erase-buffer command
(put 'erase-buffer 'disabled nil)

;; The blinking cursor is nothing, but an annoyance
(blink-cursor-mode -1)

;; Disable the annoying bell ring
(setq ring-bell-function 'ignore)

;; Nicer scrolling
(setq scroll-margin 0
      scroll-conservatively 100000
      scroll-preserve-screen-position 1)

;; mode line settings
(line-number-mode t)
(column-number-mode t)
(size-indication-mode t)

;; Disable auto vscroll (makes scrolling down a bit faster?)
(setq auto-window-vscroll nil)

;; Enable y/n answers
(fset 'yes-or-no-p 'y-or-n-p)

;; Some things don't work well with fish, just always use posix compatible shell (dash)
(setq shell-file-name "/bin/sh")

;; highlight the current line
(global-hl-line-mode +1)

(use-package simple
  :bind (("C-x k" . dakra-kill-this-buffer)
         ("M-u" . dakra-upcase-dwim)
         ("M-l" . dakra-downcase-dwim)
         ("M-c" . dakra-capitalize-dwim))
  :hook (text . turn-on-auto-fill)  ; Use auto-fill in all text modes
  :config
  ;; Autofill (e.g. M-x autofill-paragraph or M-q) to 80 chars (default 70)
  (setq-default fill-column 80)

  (defun dakra-kill-this-buffer ()
    "Like (kill-this-buffer) but independent of the menu bar."
    (interactive)
    (kill-buffer (current-buffer)))

  (defmacro dakra-define-up/downcase-dwim (case)
    (let ((func (intern (concat "dakra-" case "-dwim")))
          (doc (format "Like `%s-dwim' but %s from beginning when no region is active." case case))
          (case-region (intern (concat case "-region")))
          (case-word (intern (concat case "-word"))))
      `(defun ,func (arg)
         ,doc
         (interactive "*p")
         (save-excursion
           (if (use-region-p)
               (,case-region (region-beginning) (region-end))
             (beginning-of-thing 'symbol)
             (,case-word arg))))))
  (dakra-define-up/downcase-dwim "upcase")
  (dakra-define-up/downcase-dwim "downcase")
  (dakra-define-up/downcase-dwim "capitalize"))

(use-package autorevert
  :defer 1
  ;;:hook (find-file . auto-revert-mode)
  :config
  ;; We only really need auto revert for git files
  ;; and we use magits `magit-auto-revert-mode' for that
  ;;; revert buffers automatically when underlying files are changed externally
  (global-auto-revert-mode nil)

  ;; Turn off auto revert messages
  (setq auto-revert-verbose nil))

(use-package epa
  :defer t
  :config
  ;; Always replace encrypted text with plain text version
  (setq epa-replace-original-text t))
(use-package epg
  :defer t
  :config
  ;; Let Emacs query the passphrase through the minibuffer
  (setq epg-pinentry-mode 'loopback))

(use-package saveplace
  :unless noninteractive
  :config (save-place-mode))

(use-package savehist
  :unless noninteractive
  :defer 1
  :config
  (setq savehist-additional-variables '(compile-command regexp-search-ring))
  (savehist-mode 1))

(use-package ansi-color
  :commands ansi-color-display
  :hook (compilation-filter . colorize-compilation-buffer)
  :config
  (defun ansi-color-display (start end)
    "Display ansi colors in region or whole buffer."
    (interactive (if (region-active-p)
                     (list (region-beginning) (region-end))
                   (list (point-min) (point-max))))
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region start end)))

  ;; Colorize output of Compilation Mode, see
  ;; http://stackoverflow.com/a/3072831/355252
  (defun colorize-compilation-buffer ()
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region (point-min) (point-max)))))

(use-package compile
  :bind (:map compilation-mode-map
         ("C-c -" . compilation-add-separator)
         ("-" . compilation-add-separator)
         :map comint-mode-map
         ("C-c -" . compilation-add-separator))
  :init
  (put 'compilation-environment 'safe-local-variable (create-safe-env-p "SENTRY_DSN"))
  :config
  (defun compilation-add-separator ()
    "Insert separator in read-only buffer."
    (interactive)
    (let ((inhibit-read-only t))
      (insert "\n------------------------\n\n")))

  ;; Always save before compiling
  (setq compilation-ask-about-save nil)
  ;; Just kill old compile processes before starting the new one
  (setq compilation-always-kill t)
  ;; Scroll with the compilation output
  ;; Set to 'first-error to stop scrolling on first error
  (setq compilation-scroll-output t))

(use-package comint
  :defer t
  :config
  ;; Increase comint buffer size.
  (setq comint-buffer-maximum-size 8192))

(message "Loading early birds...done (%.3fs)"
         (float-time (time-subtract (current-time) before-user-init-time)))

(use-package subword
  :hook ((python-mode yaml-mode go-mode clojure-mode cider-repl-mode) . subword-mode))

(use-package shr
  :defer t
  :config
  (setq shr-width 80)
  (setq shr-external-browser 'eww-browse-url)
  (setq shr-color-visible-luminance-min 80))

(use-package help
  :disabled t  ; I actually prefer larger help windows
  :config (temp-buffer-resize-mode))

(use-package make-mode
  ;; Files like `Makefile.docker' are also gnu make
  :mode (("Makefile" . makefile-gmake-mode)))

(use-package goto-addr
  :hook ((compilation-mode . goto-address-mode)
         (prog-mode . goto-address-prog-mode)
         (eshell-mode . goto-address-mode)
         (shell-mode . goto-address-mode))
  :bind (:map goto-address-highlight-keymap
         ("<RET>" . goto-address-at-point)
         ("M-<RET>" . newline)))

(use-package time
  :defer 10
  :config
  ;; Only show loads of above 0.9 in the modeline
  (setq display-time-load-average-threshold 0.9)
  ;; A list of timezones to show for `display-time-world`
  (setq zoneinfo-style-world-list
        '(("Asia/Kuala_Lumpur" "Kuala Lumpur")
          ("Europe/Berlin" "Berlin")
          ("America/Los_Angeles" "Los Angeles")
          ("America/New_York" "New York")
          ("Australia/Sydney" "Sydney")))

  (setq display-time-24hr-format t)
  ;; Show time in modeline
  (display-time-mode))

(use-package calendar
  :hook (calendar-today-visible . calendar-mark-today)
  :config
  ;;(setq calendar-latitude 34.103
  ;;      calendar-longitude -118.337
  ;;      calendar-location-name "Los Angeles, USA")
  ;;(setq calendar-latitude -37.841
  ;;      calendar-longitude 144.939
  ;;      calendar-location-name "Melbourne, Australia")
  ;;(setq calendar-latitude 3.143
  ;;      calendar-longitude 101.686
  ;;      calendar-location-name "Kuala Lumpur, Malaysia")
  (setq calendar-latitude 48.97
        calendar-longitude 8.45
        calendar-location-name "Karlsruhe, Germany")
  ;; Highlight public holidays
  (setq calendar-holiday-marker t))

(use-package alert :defer t
  :config
  ;; send alerts by default to D-Bus
  (setq alert-default-style 'notifications))

(use-package sauron
  :disabled t
  :if (daemonp)
  :defer 5
  :bind (("<f12>" . sauron-toggle-hide-show)
         ("C-c <f12>" . sauron-clear))
  :config
  ;; Feed sauron events into alert
  (add-hook 'sauron-event-added-functions 'sauron-alert-el-adapter)

  (setq sauron-max-line-length 110)
  (setq sauron-separate-frame nil)
  ;;(setq sauron-sticky-frame t)

  (setq sauron-watch-nicks '("dakra"))
  (sauron-start-hidden))

(use-package eldoc
  :hook (prog-mode . eldoc-mode))

(use-package dimmer
  :unless noninteractive
  :defer 10
  :config
  (setq dimmer-fraction 0.25)
  ;;(setq dimmer-use-colorspace ':rgb)
  (dimmer-mode))

(use-package hl-todo
  :defer 2
  :config (global-hl-todo-mode))

(use-package fill-column-indicator
  :hook ((emacs-lisp git-commit-setup) . fci-mode))

(use-package volatile-highlights
  :defer 10
  :config (volatile-highlights-mode t))

(use-package beacon
  :defer 5
  :config (beacon-mode 1))

(use-package which-key
  :defer 10
  :config (which-key-mode 1))

(use-package which-func
  :defer 5
  :config (which-function-mode 1))

(use-package uniquify
  :defer 5
  :config
  (setq uniquify-ignore-buffers-re "^\\*") ; don't muck with special buffers
  (setq uniquify-buffer-name-style 'forward)
  (setq uniquify-separator "/"))

;; highlight indentations in python
(use-package highlight-indent-guides
  :hook ((python-mode sass-mode yaml-mode) . highlight-indent-guides-mode)
  :config
  ;; Don't highlight first level (that would be a line at column 1)
  (defun my-highlighter (level responsive display)
    (if (> 1 level) ; replace `1' with the number of guides you want to hide
        nil
      (highlight-indent-guides--highlighter-default level responsive display)))

  (setq highlight-indent-guides-highlighter-function 'my-highlighter)
  (setq highlight-indent-guides-method 'character)
  (setq highlight-indent-guides-character ?\|)
  (setq highlight-indent-guides-auto-odd-face-perc 15)
  (setq highlight-indent-guides-auto-even-face-perc 15)
  (setq highlight-indent-guides-auto-character-face-perc 20))

;; emoji font
;; package ttf-symbola has to be installed
;; Just use "C-x 8 RET <type name>" insead
(defun --set-emoji-font (frame)
  "Adjust the font settings of FRAME so Emacs can display emoji properly."
  (set-fontset-font t 'symbol (font-spec :family "Symbola") frame 'prepend))
;; For when Emacs is started in GUI mode:
(--set-emoji-font nil)
;; Hook for when a frame is created with emacsclient
;; see https://www.gnu.org/software/emacs/manual/html_node/elisp/Creating-Frames.html
(add-hook 'after-make-frame-functions '--set-emoji-font)

(use-package ws-butler
  :hook ((text-mode prog-mode) . ws-butler-mode)
  :config (setq ws-butler-keep-whitespace-before-point nil))

(use-package whitespace
  :hook (prog-mode . whitespace-mode)
  :config
  (setq whitespace-style '(face tabs empty trailing lines-tail))
  ;; highlight lines with more than `fill-column' characters
  (setq whitespace-line-column nil))

(use-package zone
  :defer t
  :config
  (defvar zone--window-config nil
    "Window configuration before running `zone'.")
  (defadvice zone (before zone-ad-clean-ui)
    "Maximize window before `zone' starts."
    (setq zone--window-config (current-window-configuration))
    (delete-other-windows)
    ;; Lock screen when we're in X and `xtrlock' is installed
    (when (and (eq window-system 'x) (executable-find "xtrlock"))
      (start-process "xtrlock" nil "xtrlock")))
  (defadvice zone (after zone-ad-restore-ui)
    "Restore window configuration."
    (when zone--window-config
      (set-window-configuration zone--window-config)
      (setq zone--window-config nil)))
  (ad-activate 'zone))

(use-package zone-matrix
  :disabled t  ; Too slow on big screens
  :defer t
  :config
  (setq zone-programs (vconcat zone-programs [zone-matrix]))
  (setq zmx-unicode-mode t))

(define-minor-mode sticky-buffer-mode
  "Make the current window always display this buffer."
  nil " sticky" nil
  (set-window-dedicated-p (selected-window) sticky-buffer-mode))

(defun update-lossage-buffer ()
  "Update the \"Lossage\" buffer.
For this to work, visit the lossage buffer, and call
M-x rename-buffer Lossage RET"
  (save-excursion
    (let ((b (get-buffer "Lossage")))
      (when (buffer-live-p b)
        (with-current-buffer b
          (revert-buffer nil 'noconfirm))))))

(defun view-lossage-live ()
  "Update lossage"
  (interactive)
  (add-hook 'post-command-hook #'update-lossage-buffer nil 'local))

(use-package hippie-exp
  :bind (("M-/" . hippie-expand))
  :config
  (setq hippie-expand-try-functions-list '(try-expand-dabbrev
                                           try-expand-dabbrev-all-buffers
                                           try-expand-dabbrev-from-kill
                                           try-complete-file-name-partially
                                           try-complete-file-name
                                           try-expand-all-abbrevs
                                           try-expand-list
                                           try-expand-line
                                           try-complete-lisp-symbol-partially
                                           try-complete-lisp-symbol)))

(use-package rainbow-delimiters
  :commands rainbow-delimiters-mode
  :hook ((emacs-lisp-mode lisp-mode hy-mode clojure-mode cider-repl-mode) . rainbow-delimiters-mode))

(use-package fancy-narrow
  :bind (("C-x n" . fancy-narrow-or-widen-dwim)
         ("C-x N" . narrow-or-widen-dwim))
  :config
    ;;; toggle narrow or widen (region or defun) with C-x n
  (defun fancy-narrow-or-widen-dwim (p)
    "Widen if buffer is narrowed, narrow-dwim otherwise.
Dwim means: region, org-src-block, org-subtree, or
defun, whichever applies first.  Narrowing to
org-src-block actually calls `org-edit-src-code'.

With prefix P, don't widen, just narrow even if buffer
is already narrowed."
    (interactive "P")
    (declare (interactive-only))
    (cond ((and (fancy-narrow-active-p) (not p)) (fancy-widen))
          ((region-active-p)
           (fancy-narrow-to-region (region-beginning)
                                   (region-end)))
          ((derived-mode-p 'org-mode)
           ;; `org-edit-src-code' is not a real narrowing
           ;; command. Remove this first conditional if
           ;; you don't want it.
           (cond ((ignore-errors (org-edit-src-code) t))
                 ((ignore-errors (org-fancy-narrow-to-block) t))
                 (t (org-narrow-to-subtree))))
          ((derived-mode-p 'latex-mode)
           (LaTeX-narrow-to-environment))
          (t (fancy-narrow-to-defun))))

  ;; Make swiper work with fancy-narow
  (fancy-narrow--advise-function 'swiper)

  (defun narrow-or-widen-dwim (p)
    "Widen if buffer is narrowed, narrow-dwim otherwise.
Dwim means: region, org-src-block, org-subtree, or
defun, whichever applies first.  Narrowing to
org-src-block actually calls `org-edit-src-code'.

With prefix P, don't widen, just narrow even if buffer
is already narrowed."
    (interactive "P")
    (declare (interactive-only))
    (cond ((and (buffer-narrowed-p) (not p)) (widen))
          ((region-active-p)
           (narrow-to-region (region-beginning)
                             (region-end)))
          ((derived-mode-p 'org-mode)
           ;; `org-edit-src-code' is not a real narrowing
           ;; command. Remove this first conditional if
           ;; you don't want it.
           (cond ((ignore-errors (org-edit-src-code) t))
                 ((ignore-errors (org-narrow-to-block) t))
                 (t (org-narrow-to-subtree))))
          ((derived-mode-p 'latex-mode)
           (LaTeX-narrow-to-environment))
          (t (narrow-to-defun)))))

(use-package crux
  :bind (("C-c u" . crux-view-url)
         ("C-c f c" . write-file)
         ("C-c f r" . crux-rename-buffer-and-file)
         ("C-c f d" . crux-delete-file-and-buffer)
         ;;("s-k"   . crux-kill-whole-line)
         ;;("s-o"   . crux-smart-open-line-above)
         ("C-a"   . crux-move-beginning-of-line)
         ([(shift return)] . crux-smart-open-line)
         ([(control shift return)] . crux-smart-open-line-above)))

(use-package smartparens
  :defer 1
  :hook ((
          emacs-lisp-mode lisp-mode hy-mode go-mode
          python-mode typescript-mode javascript-mode
          ) . smartparens-strict-mode)
  ;; :hook (prog-mode . smartparens-strict-mode)
  :bind (:map smartparens-mode-map
         ;; This is the paredit mode map minus a few key bindings
         ;; that I use in other modes (e.g. M-?)
         ("C-M-f" . sp-forward-sexp) ;; navigation
         ("C-M-b" . sp-backward-sexp)
         ("C-M-u" . sp-backward-up-sexp)
         ("C-M-d" . sp-down-sexp)
         ("C-M-p" . sp-backward-down-sexp)
         ("C-M-n" . sp-up-sexp)
         ("M-s" . sp-splice-sexp) ;; depth-changing commands
         ("M-r" . sp-splice-sexp-killing-around)
         ("M-(" . sp-wrap-round)
         ("C-)" . sp-forward-slurp-sexp) ;; barf/slurp
         ("C-<right>" . sp-forward-slurp-sexp)
         ("C-}" . sp-forward-barf-sexp)
         ("C-<left>" . sp-forward-barf-sexp)
         ("C-(" . sp-backward-slurp-sexp)
         ("C-M-<left>" . sp-backward-slurp-sexp)
         ("C-{" . sp-backward-barf-sexp)
         ("C-M-<right>" . sp-backward-barf-sexp)
         ("M-S" . sp-split-sexp) ;; misc
         ("M-j" . sp-join-sexp))
  :config
  (require 'smartparens-config)
  (setq sp-base-key-bindings 'paredit)
  (setq sp-autoskip-closing-pair 'always)

  ;; Always highlight matching parens
  (show-smartparens-global-mode +1)
  (setq blink-matching-paren nil)  ;; Don't blink matching parens

  ;; Create keybindings to wrap symbol/region in pairs
  (defun prelude-wrap-with (s)
    "Create a wrapper function for smartparens using S."
    `(lambda (&optional arg)
       (interactive "P")
       (sp-wrap-with-pair ,s)))
  (define-key prog-mode-map (kbd "M-(") (prelude-wrap-with "("))
  (define-key prog-mode-map (kbd "M-[") (prelude-wrap-with "["))
  (define-key prog-mode-map (kbd "M-{") (prelude-wrap-with "{"))
  (define-key prog-mode-map (kbd "M-\"") (prelude-wrap-with "\""))
  (define-key prog-mode-map (kbd "M-'") (prelude-wrap-with "'"))
  (define-key prog-mode-map (kbd "M-`") (prelude-wrap-with "`"))

  ;; smart curly braces
  (sp-pair "{" nil :post-handlers
           '(((lambda (&rest _ignored)
                (crux-smart-open-line-above)) "RET")))
  (sp-pair "[" nil :post-handlers
           '(((lambda (&rest _ignored)
                (crux-smart-open-line-above)) "RET")))
  (sp-pair "(" nil :post-handlers
           '(((lambda (&rest _ignored)
                (crux-smart-open-line-above)) "RET")))

  ;; use smartparens-mode everywhere
  (smartparens-global-mode))

;; comment-dwim-2 is a replacement for the Emacs' built-in command
;; comment-dwim which includes more comment features, including:
;; - commenting/uncommenting the current line (or region, if active)
;; - inserting an inline comment
;; - killing the inline comment
;; - reindenting the inline comment
;; comment-dwim-2 picks one behavior depending on the context but
;; contrary to comment-dwim can also be repeated several times to
;; switch between the different behaviors
(use-package comment-dwim-2
  :bind ("M-;" . comment-dwim-2))

;; Do action that normally works on a region to the whole line if no region active.
;; That way you can just C-w to copy the whole line for example.
(use-package whole-line-or-region
  :defer 1
  :config (whole-line-or-region-global-mode t))

(use-package operate-on-number
  :defer t)
(use-package smartrep
  :defer 5
  :config
  (smartrep-define-key global-map "C-x"
    '(("{" . shrink-window-horizontally)
      ("}" . enlarge-window-horizontally)
      ("^" . enlarge-window)
      ("%" . shrink-window)))

  (smartrep-define-key global-map "C-c ."
    '(("+" . apply-operation-to-number-at-point)
      ("-" . apply-operation-to-number-at-point)
      ("*" . apply-operation-to-number-at-point)
      ("/" . apply-operation-to-number-at-point)
      ("\\" . apply-operation-to-number-at-point)
      ("^" . apply-operation-to-number-at-point)
      ("<" . apply-operation-to-number-at-point)
      (">" . apply-operation-to-number-at-point)
      ("#" . apply-operation-to-number-at-point)
      ("%" . apply-operation-to-number-at-point)
      ("'" . operate-on-number-at-point))))

(use-package copy-as-format
  :bind (("C-c w g" . copy-as-format-github)
         ("C-c w h" . copy-as-format-hipchat-pidgin)
         ("C-c w j" . copy-as-format-jira)
         ("C-c w m" . copy-as-format-markdown)
         ("C-c w o" . copy-as-format-org-mode)
         ("C-c w s" . copy-as-format-slack))
  :config
  ;; Define own format since pidgin doesn't allow to begin a message with `/code'
  (defun copy-as-format--hipchat-pidgin (text _multiline)
    (format "/say /code %s" text))
  (add-to-list 'copy-as-format-format-alist '("hipchat-pidgin" copy-as-format--hipchat-pidgin))
  (defun copy-as-format-hipchat-pidgin ()
    (interactive)
    (setq copy-as-format-default "hipchat-pidgin")
    (copy-as-format)))

;; Replace zap-to-char functionaity with the more powerful zop-to-char
(use-package zop-to-char
  :bind (("M-z" . zop-up-to-char)
         ("M-Z" . zop-to-char)))

;; Minor mode to selectively hide/show code and comment blocks
(use-package hideshow
  :hook (prog-mode  . hs-minor-mode))

(use-package outline
  :hook ((prog-mode message-mode markdown-mode) . outline-minor-mode))

(use-package bicycle
  :after outline
  :bind (:map outline-minor-mode-map
         ([C-tab] . bicycle-cycle)
         ([backtab] . bicycle-cycle-global)))

(use-package edit-indirect
  :bind (("C-c '" . edit-indirect-dwim)
         :map edit-indirect-mode-map
         ("C-x n" . edit-indirect-commit))
  :config
  (defvar edit-indirect-string nil)
  (put 'edit-indirect-string 'end-op
       (lambda ()
         (while (nth 3 (syntax-ppss))
           (forward-char))
         (backward-char)))
  (put 'edit-indirect-string 'beginning-op
       (lambda ()
         (let ((forward (nth 3 (syntax-ppss))))
           (while (nth 3 (syntax-ppss))
             (backward-char))
           (when forward
             (forward-char)))))

  (defun edit-indirect-dwim (beg end &optional display-buffer)
    "DWIM version of edit-indirect-region.
When region is selected, behave like `edit-indirect-region'
but when no region is selected and the cursor is in a 'string' syntax
mark the string and call `edit-indirect-region' with it."
    (interactive
     (if (or (use-region-p) (not transient-mark-mode))
         (prog1 (list (region-beginning) (region-end) t)
           (deactivate-mark))
       (if (nth 3 (syntax-ppss))
           (list (beginning-of-thing 'edit-indirect-string)
                 (end-of-thing 'edit-indirect-string)
                 t)
         (user-error "No region marked and not inside a string."))))
    (edit-indirect-region beg end display-buffer))

  (defvar edit-indirect-guess-mode-history nil)
  (defun edit-indirect-guess-mode-fn (_buffer _beg _end)
    (let* ((lang (completing-read "Mode: "
                                  '("typescript" "python" "sql" "js2" "web" "scss" "emacs-lisp")
                                  nil nil nil 'edit-indirect-guess-mode-history))
           (mode-str (concat lang "-mode"))
           (mode (intern mode-str)))
      (unless (functionp mode)
        (error "Invalide mode `%s'" mode-str))
      (funcall mode)))
  (setq edit-indirect-guess-mode-function #'edit-indirect-guess-mode-fn))

(use-package with-editor
  ;; Use local Emacs instance as $EDITOR (e.g. in `git commit' or `crontab -e')
  :hook ((shell-mode eshell-mode term-exec) . with-editor-export-editor))

(use-package move-text
  :bind (([(control shift up)]   . move-text-up)
         ([(control shift down)] . move-text-down)
         ([(meta shift up)]      . move-text-up)
         ([(meta shift down)]    . move-text-down)))

(use-package wgrep
  :bind (:map grep-mode-map
         ("C-x C-q" . wgrep-change-to-wgrep-mode))
  :config (setq wgrep-auto-save-buffer t))
(use-package wgrep-ag
  :after wgrep)

(use-package grep-context
  :after ivy
  :bind (:map compilation-mode-map
         ("+" . grep-context-more-around-point)
         ("-" . grep-context-less-around-point)
         :map grep-mode-map
         ("+" . grep-context-more-around-point)
         ("-" . grep-context-less-around-point)
         :map ivy-occur-grep-mode-map
         ("+" . grep-context-more-around-point)
         ("-" . grep-context-less-around-point)))

;; You can change syntax in regex-builder with "C-c TAB"
;; "read" is 'code' syntax
;; "string" is already read and no extra escaping. Like what Emacs prompts interactively
(use-package re-builder
  :defer t
  :config (setq reb-re-syntax 'string))

(use-package visual-regexp
  :bind (("C-c r s" . query-replace)
         ("C-c r R" . vr/replace)
         ("C-c r r" . vr/query-replace)
         ("C-c r m" . vr/mc-mark)))

(use-package visual-regexp-steroids
  :after visual-regexp)

(use-package prescient
  :defer t
  :config (prescient-persist-mode))
(use-package ivy-prescient
  :after ivy
  :config (ivy-prescient-mode))
(use-package company-prescient
  :after company
  :config (company-prescient-mode))

(use-package deadgrep
  :bind ("<f5>" . deadgrep))

(use-package company
  :defer 1
  :bind (:map company-active-map
         ([return] . nil)
         ("RET" . nil)
         ("TAB" . company-select-next)
         ([tab] . company-select-next)
         ("S-TAB" . company-select-previous)
         ([backtab] . company-select-previous)
         ("C-j" . company-complete-selection))
  :config
  ;; company-tng (tab and go) allows you to use TAB to both select a
  ;; completion candidate from the list and to insert it into the
  ;; buffer.
  ;;
  ;; It cycles the candidates like `yank-pop' or `dabbrev-expand' or
  ;; Vim: Pressing TAB selects the first item in the completion menu and
  ;; inserts it in the buffer. Pressing TAB again selects the second
  ;; item and replaces the inserted item with the second one. This can
  ;; continue as long as the user wishes to cycle through the menu.
  (require 'company-tng)
  (setq company-frontends '(company-tng-frontend
                            company-pseudo-tooltip-frontend
                            company-echo-metadata-frontend))

  (setq company-idle-delay 0.1)
  (setq company-tooltip-limit 10)
  (setq company-minimum-prefix-length 1)
  ;; Aligns annotation to the right hand side
  (setq company-tooltip-align-annotations t)
  ;;(setq company-dabbrev-downcase nil)
  ;; invert the navigation direction if the the completion popup-isearch-match
  ;; is displayed on top (happens near the bottom of windows)
  ;;(setq company-tooltip-flip-when-above t)
  ;; start autocompletion only after typing
  (setq company-begin-commands '(self-insert-command))
  (global-company-mode 1)

  (use-package company-emoji
    :disabled t
    :config (add-to-list 'company-backends 'company-emoji))

  (use-package company-quickhelp
    :disabled t
    :config (company-quickhelp-mode 1))

  ;; Add yasnippet support for all company backends
  (defvar company-mode/enable-yas t
    "Enable yasnippet for all backends.")
  (defun company-mode/backend-with-yas (backend)
    (if (or (not company-mode/enable-yas) (and (listp backend) (member 'company-yasnippet backend)))
        backend
      (append (if (consp backend) backend (list backend))
              '(:with company-yasnippet))))
  (setq company-backends (mapcar #'company-mode/backend-with-yas company-backends)))

(use-package company-box
  :disabled t
  :hook (company-mode . company-box-mode))

(use-package helpful
  :bind (("C-h f" . helpful-function)
         ("C-h v" . helpful-variable)
         ("C-h s" . helpful-symbol)
         ("C-h k" . helpful-key)
         ("C-c h f" . helpful-function)
         ("C-c h v" . helpful-variable)
         ("C-c h c" . helpful-command)
         ("C-c h m" . helpful-macro)
         ("<C-tab>" . backward-button)
         :map helpful-mode-map
         ("M-?" . helpful-at-point)
         ("RET" . helpful-jump-to-org)
         :map emacs-lisp-mode-map
         ("M-?" . helpful-at-point)
         :map lisp-interaction-mode-map  ; Scratch buffer
         ("M-?" . helpful-at-point))
  :config
  (defun helpful-visit-reference ()
    "Go to the reference at point."
    (interactive)
    (let* ((sym helpful--sym)
           (path (get-text-property (point) 'helpful-path))
           (pos (get-text-property (point) 'helpful-pos))
           (pos-is-start (get-text-property (point) 'helpful-pos-is-start)))
      (when (and path pos)
        ;; If we're looking at a source excerpt, calculate the offset of
        ;; point, so we don't just go the start of the excerpt.
        (when pos-is-start
          (save-excursion
            (let ((offset 0))
              (while (and
                      (get-text-property (point) 'helpful-pos)
                      (not (eobp)))
                (backward-char 1)
                (setq offset (1+ offset)))
              ;; On the last iteration we moved outside the source
              ;; excerpt, so we overcounted by one character.
              (setq offset (1- offset))

              ;; Set POS so we go to exactly the place in the source
              ;; code where point was in the helpful excerpt.
              (setq pos (+ pos offset)))))

        (find-file path)
        (when (or (< pos (point-min))
                  (> pos (point-max)))
          (widen))
        (goto-char pos)
        (recenter 0)
        (save-excursion
          (let ((defun-end (scan-sexps (point) 1)))
            (while (re-search-forward
                    (rx-to-string `(seq symbol-start ,(symbol-name sym) symbol-end))
                    defun-end t)
              (helpful--flash-region (match-beginning 0) (match-end 0)))))
        t)))

  (defun helpful-jump-to-org ()
    (interactive)
    (when (helpful-visit-reference)
      (org-babel-tangle-jump-to-org))))

(use-package projectile
  :defer t
  :bind-keymap (("s-p"   . projectile-command-map)
                ("C-c p" . projectile-command-map))
  :init
  ;; Allow all file-local values for project root
  (put 'projectile-project-root 'safe-local-variable 'stringp)
  :config
  (add-to-list 'projectile-other-file-alist '("py" "sql" "py"))
  (add-to-list 'projectile-other-file-alist '("sql" "py"))

  ;; Shorten the mode line to only "P" and do not include the project type
  (defun projectile-short-mode-line ()
    "Short version of the default projectile mode line."
    (format " P[%s]" (projectile-project-name)))
  (setq projectile-mode-line-function 'projectile-short-mode-line)

  ;; https://sideshowcoder.com/2017/10/24/projectile-and-tramp/
  (defadvice projectile-on (around exlude-tramp activate)
    "This should disable projectile when visiting a remote file"
    (unless  (--any? (and it (file-remote-p it))
                     (list
                      (buffer-file-name)
                      list-buffers-directory
                      default-directory
                      dired-directory))
      ad-do-it))
  ;; cache projectile project files
  ;; projectile-find-files will be much faster for large projects.
  ;; C-u C-c p f to clear cache before search.
  (setq projectile-enable-caching nil)
  (counsel-projectile-mode))

(use-package treemacs
  :bind (([f8]        . treemacs-toggle-or-select)
         :map treemacs-mode-map
         ("C-t a" . treemacs-add-project)
         ("C-t d" . treemacs-remove-project)
         ("C-t r" . treemacs-rename-project)
         ;; If we only hide the treemacs buffer (default binding) then, when we switch
         ;; a frame to a different project and toggle treemacs again we still get the old project
         ("q" . treemacs-kill-buffer))
  :config
  (defun treemacs-toggle-or-select ()
    "Initialize or toggle treemacs.
- If the treemacs window is visible and selected, hide it.
- If the treemacs window is visible select it.
- If a treemacs buffer exists, but is not visible show it.
- If no treemacs buffer exists for the current frame create and show it.
- If the workspace is empty additionally ask for the root path of the first
  project to add."
    (interactive)
    (pcase (treemacs-current-visibility)
      ('visible (if (equal (current-buffer) (cdr (assoc (selected-frame) treemacs--buffer-access)))
                    (delete-window (treemacs-get-local-window))
                  (treemacs--select-visible-window)))
      ('exists  (treemacs-select-window))
      ('none    (treemacs--init (treemacs--read-first-project-path)))))

  (defun treemacs-ignore-python-files (file _)
    (or (s-ends-with-p ".pyc" file)
        (string= file "__pycache__")))
  (add-to-list 'treemacs-ignored-file-predicates 'treemacs-ignore-python-files)

  (setq treemacs-follow-after-init          t
        treemacs-collapse-dirs              3
        treemacs-silent-refresh             nil
        treemacs-never-persist              t
        treemacs-is-never-other-window      t)
  (treemacs-filewatch-mode t)
  (treemacs-follow-mode -1)
  (treemacs-git-mode 'simple))

(use-package treemacs-projectile
  :after (treemacs)
  :bind (:map treemacs-mode-map
         ("C-p p" . nil)
         ("C-p" . nil)  ; I often still type C-p for UP
         ("C-t p" . treemacs-projectile))
  :config (setq treemacs-header-function #'treemacs-projectile-create-header))

(use-package flx :defer t)

(use-package smex
  :disabled t
  :defer t)

(use-package ivy
  :bind (("C-x b"   . dakra-ivy-switch-buffer)
         ("C-x B"   . ivy-switch-buffer-other-window)
         ("C-c C-r" . ivy-resume)
         ("C-c e"   . ivy-switch-buffer-eshell)
         ("M-H"     . ivy-resume)
         :map ivy-minibuffer-map
         ("C-j" . ivy-partial-or-done)
         ("<S-return>" . ivy-call)
         ("C-r" . ivy-previous-line-or-history)
         ("M-r" . ivy-reverse-i-search))
  :config
  (defun ivy-ignore-non-eshell-buffers (str)
    (let ((buf (get-buffer str)))
      (if buf
          (with-current-buffer buf
            (not (eq major-mode 'eshell-mode)))
        t)))

  (defun ivy-switch-buffer-eshell ()
    "Like ivy-switch-buffer but only shows eshell buffers."
    (interactive)
    (let ((ivy-ignore-buffers (append ivy-ignore-buffers '(ivy-ignore-non-eshell-buffers))))
      (ivy-switch-buffer)))

  (defun ivy-ignore-exwm-buffers (str)
    (let ((buf (get-buffer str)))
      (when buf
        (with-current-buffer buf
          (eq major-mode 'exwm-mode)))))

  (defun ivy-ignore-non-exwm-buffers (str)
    (let ((buf (get-buffer str)))
      (if buf
          (with-current-buffer buf
            (not (eq major-mode 'exwm-mode)))
        t)))

  (defun ivy-switch-buffer-exwm ()
    "Like ivy-switch-buffer but only shows EXWM buffers."
    (interactive)
    (let ((ivy-ignore-buffers (append ivy-ignore-buffers '(ivy-ignore-non-exwm-buffers))))
      (ivy-switch-buffer)))

  (defun ivy-switch-buffer-non-exwm ()
    "Like ivy-switch-buffer but hides all EXWM buffers."
    (interactive)
    (let ((ivy-ignore-buffers (append ivy-ignore-buffers '(ivy-ignore-exwm-buffers))))
      (ivy-switch-buffer)))

  (defun dakra-ivy-switch-buffer (p)
    "Like ivy-switch-buffer but by defaults hides all EXWM buffers.
With one prefix arg, show only EXWM buffers. With two, show all buffers."
    (interactive "p")
    (back-button-push-mark-local-and-global)
    (case p
      (1 (ivy-switch-buffer-non-exwm))
      (4 (ivy-switch-buffer-exwm))
      (16 (ivy-switch-buffer))))

  ;; Extend searching to bookmarks and recentf
  (setq ivy-use-virtual-buffers t)
  ;; Show full path for virtual buffers
  (setq ivy-virtual-abbreviate 'full)

  ;; Display count displayed and total
  (setq ivy-count-format "%d/%d ")
  (setq ivy-height 18)
  ;; Press C-p when you're on the first candidate to select your input
  (setq ivy-use-selectable-prompt t)

  ;; FIXME: ignore space for fuzzy matching
  ;;(require 's)
  ;;(defun dakra-ivy--regex-fuzzy (str)
  ;;  "Like ivy--regex-fuzzy but remove all spaces first."
  ;;  (ivy--regex-fuzzy (s-replace " " "" str)))
  ;;(add-to-list 'ivy-highlight-functions-alist
  ;;             '(dakra-ivy--regex-fuzzy . ivy--highlight-fuzzy))

  ;;(setq ivy-re-builders-alist
  ;;      '((counsel-M-x . ivy--regex-fuzzy) ; Only counsel-M-x use flx fuzzy search
  ;;        (t . ivy--regex-plus)))
  (setq ivy-initial-inputs-alist '((Man-completion-table . "^")
                                   (woman . "^")))

  ;; Don't quit ivy when pressing backspace on already empty input
  (setq ivy-on-del-error-function nil)

  (ivy-mode 1))

(use-package ivy-hydra
  :after (ivy hydra))

(use-package ivy-rich
  ;;:defer 5
  :after ivy
  :config
  (ivy-rich-set-display-transformer)
  ;; Show only basic info for tramp buffers to make it faster
  (setq ivy-rich-parse-remote-buffer nil)
  (setq ivy-rich-switch-buffer-align-virtual-buffer t
        ivy-rich-path-style 'abbrev))

(use-package swiper
  :bind (;;("C-s" . swiper)  ; Use counsel-grep-or-swiper
         :map swiper-map
         ("M-h" . swiper-avy)
         ("M-c" . swiper-mc)))

(use-package counsel
  :bind (("C-s"     . counsel-grep-or-swiper)
         ("C-o"     . nil)  ; Remove old keybinding (open-line)
         ("C-o o"   . counsel-org-agenda-headlines)
         ("C-o g"   . counsel-org-agenda-headlines)
         ("C-o G"   . counsel-org-goto)
         ("C-c o o" . counsel-org-agenda-headlines)
         ("C-c o g" . counsel-org-agenda-headlines)
         ("C-c o G" . counsel-org-goto)
         ("C-x C-f" . counsel-find-file)
         ("M-y"     . counsel-yank-pop)
         ("M-i"     . counsel-imenu)
         ("M-x"     . counsel-M-x))
  :init
  (define-key minibuffer-local-map (kbd "M-r")
    'counsel-minibuffer-history)
  :config
  ;; Use rg as backend for counsel-git
  (setq counsel-git-cmd "rg -S --files")
  ;; Only show max 160 characters per line
  (setq counsel-rg-base-command
        "rg -S -M 160 --no-heading --line-number --color never %s .")
  ;; Use rg even for single files
  (setq counsel-grep-base-command
        "rg -S -M 160 --no-heading --line-number --color never %s %s")
  ;; Make ivy faster/more responsive
  ;; Update filter every 10ms and wait 20ms to refresh dynamic collection
  (setq counsel-async-filter-update-time 10000)
  (setq ivy-dynamic-exhibit-delay-ms 20)

  (counsel-mode 1))

(use-package counsel-projectile
  :bind (:map projectile-command-map
         (("s s" . dakra/counsel-search-project-empty)
          ("s S" . dakra/counsel-search-project)))
  :config
  ;; Always use ripgrep instead of ag
  (define-key projectile-mode-map [remap projectile-ag] #'counsel-projectile-rg)

  (defun parent-directory (dir &optional l)
    "Go up L many directories from DIR. Go 1 parent up when L is nil."
    (let ((l (or l 1)))
      (if (or (equal "/" dir) (<= l 0))
          dir
        (parent-directory (file-name-directory (directory-file-name dir)) (1- l)))))

  ;; https://github.com/purcell/emacs.d/blob/4e487d4ef2ab39875d96fd413fca3b075faf9612/lisp/init-ivy.el#L49
  (defun dakra/counsel-search-project (initial-input &optional use-current-dir)
    "Search using `counsel-rg' from the project root for INITIAL-INPUT.
If there is no project root, or if the prefix argument USE-CURRENT-DIR is set,
then search from the current directory instead.
With multiple prefix arguments, or a numeric prefix argument
go up multiple parent directories."
    (interactive (list (thing-at-point 'symbol)
                       current-prefix-arg))
    (let ((current-prefix-arg)
          (ignored (mapconcat (lambda (i)
                                (concat "--glob "
                                        (shell-quote-argument (concat "!" i))
                                        " "))
                              (append (projectile-ignored-files-rel)
                                      (projectile-ignored-directories-rel))
                              ""))
          (dir (cond
                ((equal use-current-dir nil) ; no prefix: use project root
                 (condition-case _err
                     (projectile-project-root)
                   (error default-directory)))
                ((equal use-current-dir '(4)) ; C-u: use current dir
                 (parent-directory default-directory 0))
                ((equal use-current-dir '(16)) ; C-u C-u: use parent dir
                 (parent-directory default-directory 1))
                ((equal use-current-dir '(64)) ; C-u C-u C-u: go 2 up
                 (parent-directory default-directory 2))
                (t  ; Numeric prefix: Go specified prefix up
                 (parent-directory default-directory use-current-dir)))))
      (counsel-rg initial-input dir ignored (projectile-prepend-project-name "rg"))))

  (defun dakra/counsel-search-project-empty (&optional use-current-dir)
    "Like dakra/counsel-search-project but with no initial input."
    (interactive "P")
    (dakra/counsel-search-project "" use-current-dir))

  (defun counsel-projectile-find-file-occur ()
    (cd (projectile-project-root))
    (counsel-cmd-to-dired
     (format
      "find . | grep -i -E '%s' | xargs -d '\n' ls"
      (counsel-unquote-regex-parens ivy--old-re))))
  (ivy-set-occur 'counsel-projectile-find-file 'counsel-projectile-find-file-occur)
  (ivy-set-occur 'counsel-projectile 'counsel-projectile-find-file-occur)

  (counsel-projectile-mode))

(use-package bookmark
  :defer t
  :config (setq bookmark-save-flag 1))
;; Nicer mark ring navigation (C-x C-SPC or C-x C-Left/Right)
(use-package back-button
  :defer 2
  :config (back-button-mode))

;; Goto last change
(use-package goto-chg
  :bind (("C-c \\" . goto-last-change)
         ("C-c |" . goto-last-change-reverse)))

(use-package ace-window
  :bind ("s-a" . ace-window))

(use-package ibuffer
  :bind ("C-x C-b" . ibuffer))

(use-package ibuffer-projectile
  :hook (ibuffer . ibuffer-projectile-init)
  :commands ibuffer-projectile-init
  :config
  (defun ibuffer-projectile-init()
    (ibuffer-projectile-set-filter-groups)
    (unless (eq ibuffer-sorting-mode 'alphabetic)
      (ibuffer-do-sort-by-alphabetic))))

(use-package imenu
  :defer t
  ;;:hook (emacs-lisp-mode . imenu-use-package)
  :config
  ;; Recenter window after imenu jump so cursor doesn't end up on the last line
  (add-hook 'imenu-after-jump-hook 'recenter)  ; or 'reposition-window
  (set-default 'imenu-auto-rescan t))
  ;; Use use-package-enable-imenu-support
  ;;(defun imenu-use-package ()
  ;;  (add-to-list 'imenu-generic-expression
  ;;               '("Packages" "\\(^\\s-*(use-package +\\)\\(\\_<.+\\_>\\)" 2))))

(use-package imenu-anywhere
  :bind (("M-I" . ivy-imenu-anywhere)
         ("C-c i" . ivy-imenu-anywhere)))

(use-package recentf
  :defer 2
  :config
  (add-to-list 'recentf-exclude "^/\\(?:ssh\\|su\\|sudo\\)?:")
  (add-to-list 'recentf-exclude no-littering-var-directory)

  (setq recentf-max-saved-items 500
        recentf-max-menu-items 15
        ;; disable recentf-cleanup on Emacs start, because it can cause
        ;; problems with remote files
        recentf-auto-cleanup 'never)

  (recentf-mode))

;; View Large Files
(use-package vlf-setup
  ;; Require vlf-setup which autoloads `vlf'
  ;; to have vlf offered as choice when opening large files
  :config
  ;; warn when opening files bigger than 30MB
  (setq large-file-warning-threshold 30000000))

;; Logview provides syntax highlighting, filtering and other features for various log files
(use-package logview
  :defer t)

;; Better pdf viewer with search, annotate, highlighting etc
;; 'poppler' and 'poppler-glib' must be installed
(use-package pdf-tools
  ;; manually update
  ;; after each update we have to call:
  ;; Install pdf-tools but don't ask or raise error (otherwise daemon mode will wait for input)
  ;; (pdf-tools-install t t t)
  :magic ("%PDF" . pdf-view-mode)
  :mode (("\\.pdf\\'" . pdf-view-mode))
  :bind (:map pdf-view-mode-map
         ("C-s" . isearch-forward)
         ("M-p" . print-pdf))
  :config
  ;; Use `gtklp' to print as it has better cups support
  (defun print-pdf (&optional pdf)
    "Print PDF using external program `gtklp'."
    (interactive "P")
    (start-process-shell-command "gtklp" nil (format "gtklp %s" (shell-quote-argument (buffer-file-name)))))

  ;; more fine-grained zooming; +/- 10% instead of default 25%
  (setq pdf-view-resize-factor 1.1)
  ;; Always use midnight-mode and almost same color as default font.
  ;; Just slightly brighter background to see the page boarders
  (setq pdf-view-midnight-colors '("#c6c6c6" . "#363636"))
  (add-hook 'pdf-view-mode-hook (lambda ()
                                  (pdf-view-midnight-minor-mode))))

(use-package edit-server
  :if (daemonp)
  :defer 10
  :config
  (setq edit-server-new-frame nil)
  (setq edit-server-url-major-mode-alist
        '(("reddit\\.com" . markdown-mode)
          ("github\\.com" . gfm-mode)
          ("gitlab\\.com" . gfm-mode)
          ("gitlab\\.paesslergmbh\\.de" . gfm-mode)
          ("lab\\.ebenefuenf\\.com" . gfm-mode)
          ("jira.paesslergmbh.de" . jira-markup-mode)))
  (edit-server-start))

(use-package fabric
  :defer t)

(use-package calc
  :bind ("<XF86Calculator>" . quick-calc))

;; Type like a hacker
(use-package hacker-typer
  :defer t
  :config (setq hacker-typer-remove-comments t))

;; dired config mostly from https://github.com/Fuco1/.emacs.d/blob/master/files/dired-defs.org
(use-package dired
  :bind (("C-x d" . dired)
         :map dired-mode-map
         ("M-RET" . emms-play-dired)
         ("e" . dired-ediff-files)
         ("C-c C-e" . dired-toggle-read-only))
  :config
  ;; When point is on a file name only search file names
  (setq dired-isearch-filenames 'dwim)

  ;; dired - reuse current buffer by pressing 'a'
  (put 'dired-find-alternate-file 'disabled nil)

  ;; always delete and copy recursively
  (setq dired-recursive-deletes 'always)
  (setq dired-recursive-copies 'always)

  ;; if there is a dired buffer displayed in the next window, use its
  ;; current subdir, instead of the current subdir of this dired buffer
  (setq dired-dwim-target t)

  (defconst my-dired-media-files-extensions
    '("mp3" "mp4" "MP3" "MP4" "avi" "mpg" "flv" "ogg")
    "Media files.")

  ;; dired list size in human-readable format and list directories first
  (setq dired-listing-switches "-hal --group-directories-first")

  ;; Easily diff 2 marked files in dired
  ;; https://oremacs.com/2017/03/18/dired-ediff/
  (defun dired-ediff-files ()
    (interactive)
    (let ((files (dired-get-marked-files))
          (wnd (current-window-configuration)))
      (if (<= (length files) 2)
          (let ((file1 (car files))
                (file2 (if (cdr files)
                           (cadr files)
                         (read-file-name
                          "file: "
                          (dired-dwim-target-directory)))))
            (if (file-newer-than-file-p file1 file2)
                (ediff-files file2 file1)
              (ediff-files file1 file2))
            (add-hook 'ediff-after-quit-hook-internal
                      (lambda ()
                        (setq ediff-after-quit-hook-internal nil)
                        (set-window-configuration wnd))))
        (error "no more than 2 files should be marked")))))

(use-package dired-x
  :bind ("C-x C-j" . dired-jump)
  :config
  (add-to-list 'dired-guess-shell-alist-user
               (list (concat "\\."
                             (regexp-opt my-dired-media-files-extensions)
                             "\\'")
                     "mpv")))

;; Needs to be after dired-x as it binds "Y" too
(use-package dired-rsync
  :after dired-x
  :bind (:map dired-mode-map
         ("Y" . dired-rsync)))

(use-package dired+
  :after dired
  :bind (:map dired-mode-map
         ("M-u" . diredp-up-directory-reuse-dir-buffer))
  :init
  ;; Show details by default  (diredp hides it)
  (setq diredp-hide-details-initially-flag nil)
  :config
  ;; Reuse dired buffers
  ;; We use dired-open and also overwrite the dired-find-file there
  (diredp-toggle-find-file-reuse-dir 1))

;; Display the recursive size of directories in Dired
(use-package dired-du
  :after dired
  :config
  ;; human readable size format
  (setq dired-du-size-format t))

(use-package async)
(use-package dired-async  ; Part of async
  :after dired
  :config (dired-async-mode 1))

(use-package dired-rainbow
  :after dired
  :config
  (dired-rainbow-define html "#4e9a06" ("htm" "html" "xhtml"))
  (dired-rainbow-define xml "#b4fa70" ("xml" "xsd" "xsl" "xslt" "wsdl"))

  (dired-rainbow-define document font-lock-function-name-face ("doc" "docx" "odt" "pdb" "pdf" "ps" "rtf" "djvu" "epub"))
  (dired-rainbow-define excel "#3465a4" ("xlsx"))
  ;; FIXME: my-dired-media-files-extensions not defined?
  ;;(dired-rainbow-define media "#ce5c00" my-dired-media-files-extensions)
  (dired-rainbow-define image "#ff4b4b" ("jpg" "png" "jpeg" "gif"))

  (dired-rainbow-define log "#c17d11" ("log"))
  (dired-rainbow-define sourcefile "#fcaf3e" ("py" "c" "cc" "cpp" "h" "java" "pl" "rb" "R"
                                              "php" "go" "rust" "js" "ts" "hs"))

  (dired-rainbow-define executable "#8cc4ff" ("exe" "msi"))
  (dired-rainbow-define compressed "#ad7fa8" ("zip" "bz2" "tgz" "txz" "gz" "xz" "z" "Z" "jar"
                                              "war" "ear" "rar" "sar" "xpi" "apk" "xz" "tar"))
  (dired-rainbow-define packaged "#e6a8df" ("deb" "rpm"))
  (dired-rainbow-define encrypted "LightBlue" ("gpg" "pgp"))

  (dired-rainbow-define-chmod executable-unix "Green" "-.*x.*"))

(use-package dired-collapse
  :hook (dired-mode . dired-collapse-mode))

;; Browse compressed archives in dired (requires `avfs' to be installed)
;; Run `mountavfs' to start `avfsd' which is needed for it to work.
(use-package dired-avfs
  :after dired
  :config
  ;; Don't warn about opening archives less than 512MB (default 100)
  (setq dired-avfs-file-size-threshold 512))

(use-package dired-open
  :after dired
  :bind (:map dired-mode-map
         ("RET" . dired-open-file)
         ([return] . dired-open-file)
         ("f" . dired-open-file))
  :config
  ;; Reuse existing dired buffer
  (setq dired-open-find-file-function 'diredp-find-file-reuse-dir-buffer)
  (setq dired-open-functions '(dired-open-by-extension dired-open-guess-shell-alist dired-open-subdir)))

(use-package dired-ranger
  :after dired
  :init
  (bind-keys :map dired-mode-map
             :prefix "c"
             :prefix-map dired-ranger-map
             :prefix-docstring "Map for ranger operations."
             ("c" . dired-ranger-copy)
             ("p" . dired-ranger-paste)
             ("m" . dired-ranger-move))

  (bind-keys :map dired-mode-map
    ("'" . dired-ranger-bookmark)
    ("`" . dired-ranger-bookmark-visit)))

;;narrow dired to match filter
(use-package dired-narrow
  :after dired
  :bind (:map dired-mode-map
         ("/" . dired-narrow)))

(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map
         ("i" . dired-subtree-insert)
         ("I" . dired-subtree-remove)))

;;; Helm config
(use-package helm
  :disabled t
  :commands (helm-M-x helm-mini helm-imenu helm-resume helm-execute-persistent-action helm-select-action)
  ;;:bind (("M-x"     . helm-M-x)
  ;;       ("C-x C-m" . helm-M-x)
  ;;       ("M-y"     . helm-show-kill-ring)
  ;;       ("C-x b"   . helm-mini)
  ;;       ("C-x C-b" . helm-buffers-list)
  ;;       ("C-x C-f" . helm-find-files)
  ;;       ("C-h r"   . helm-info-emacs)
  ;;       ("C-h C-l" . helm-locate_library)
  ;;       ("C-x r b" . helm-filtered-bookmarks)  ; Use helm bookmarks
  ;;       ("C-c f"   . helm-recentf)
  ;;       ("C-c j"   . helm-imenu)
  ;;       ("C-x C-b" . helm-buffers-list)
  ;;       ("C-c C-r" . helm-resume)
  ;;       :map helm-map
  ;;       ("<tab>" . helm-execute-persistent-action)  ; Rebind tab to run persistent action
  ;;       ("C-i"   . helm-execute-persistent-action)  ; Make TAB work in terminals
  ;;       ("C-z"   . helm-select-action)  ; List actions
  ;;       :map shell-mode-map  ;; Shell history
  ;;       ("C-c C-l" . helm-comint-input-ring)
  ;;       )
  :config
  ;; See https://github.com/bbatsov/prelude/pull/670 for a detailed
  ;; discussion of these options.
  (setq helm-split-window-inside-p            t
        helm-buffers-fuzzy-matching           t
        helm-move-to-line-cycle-in-source     t
        helm-ff-search-library-in-sexp        t
        helm-ff-file-name-history-use-recentf t)

  (setq helm-google-suggest-use-curl-p t)

  ;; keep follow-mode in between helm sessions once activated
  (setq helm-follow-mode-persistent t)

  ;; Smaller helm window
  (setq helm-autoresize-max-height 0)
  (setq helm-autoresize-min-height 30)
  (helm-autoresize-mode 1)

  ;; Don't show details in helm-mini for tramp buffers
  (setq helm-buffer-skip-remote-checking t)

  (require 'helm-bookmark)
  ;; Show bookmarks (and create bookmarks) in helm-mini
  (setq helm-mini-default-sources '(helm-source-buffers-list
                                    helm-source-recentf
                                    helm-source-bookmarks
                                    helm-source-bookmark-set
                                    helm-source-buffer-not-found))

  ;;(substitute-key-definition 'find-tag 'helm-etags-select global-map)
  ;;(setq projectile-completion-system 'helm)

  ;;(helm-mode 1)
)

(use-package helm-ag
  :disabled t
  :after helm
  :commands (helm-ag helm-ag-this-file helm-do-ag helm-do-ag-this-file helm-do-ag-project-root))

(use-package helm-descbinds
  :disabled t
  :after helm
  :bind (("C-h b" . helm-descbinds)))

(use-package helm-projectile
  :disabled t
  :after (helm projectile)
  :defer 2)
  ;;:config (helm-projectile-on))

;; helm "hacks" like better path expandsion
(use-package helm-ext
  :disabled t
  :after helm
  :config
  ;; Skip . and .. for non empty dirs
  (helm-ext-ff-enable-skipping-dots t)

  ;; Enable zsh/fish shell like path expansion
  (helm-ext-ff-enable-zsh-path-expansion t)
  (helm-ext-ff-enable-auto-path-expansion t)

  ;; Don't use minibuffer if there's something there already
  (helm-ext-minibuffer-enable-header-line-maybe t))
(use-package helm-make
  :disabled t
  :after helm
  :commands (helm-make helm-make-projectile))

(use-package helm-backup :load-path "repos/helm-backup"
  :disabled t
  :after helm
  :commands (helm-backup-versioning helm-backup)
  :hook (after-save . helm-backup-versioning))

;; use swiper with helm backend for search
(use-package swiper-helm
  :disabled t
  :after helm
  :bind ("\C-s" . swiper-helm)
  )

;; Switch on 'umlaut-mode' for easier Umlaut usage
(define-minor-mode umlaut-mode
  "A mode for conveniently using Umlauts in Emacs"
  nil
  :lighter " äöü"
  :keymap '(("\M-a" . (lambda () (interactive) (insert ?ä)))
            ("\M-o" . (lambda () (interactive) (insert ?ö)))
            ("\M-u" . (lambda () (interactive) (insert ?ü)))
            ("\M-s" . (lambda () (interactive) (insert ?ß)))
            ("\M-A" . (lambda () (interactive) (insert ?Ä)))
            ("\M-O" . (lambda () (interactive) (insert ?Ö)))
            ("\M-U" . (lambda () (interactive) (insert ?Ü)))
            ("\M-e" . (lambda () (interactive) (insert ?€)))
            ("\M-p" . (lambda () (interactive) (insert ?£)))
            ("\M-S" . (lambda () (interactive) (insert "SS")))))

(use-package hydra
  :bind (("C-c S" . hydra-scratchpad/body)
         ("C-x t" . hydra-toggle-stuff/body)
         ("C-x 9" . hydra-unicode/body)
         ("C-x l" . hydra-emacs-launcher/body)
         ("C-x C-l" . hydra-emacs-launcher/body)
         ("C-x L" . hydra-external-launcher/body))
  :config
  (hydra-add-font-lock)

  (defhydra hydra-scratchpad (:hint nil)
    "
     _p_ython    _e_lisp        _s_ql
     _g_o        _j_avascript   _t_ypescript
     _r_ust      _R_est-client  _h_tml
     _o_rg-mode  _T_ext         _m_arkdown
     "
    ("p" (switch-to-buffer "*python*scratchpad.py"))
    ("e" (switch-to-buffer "*elisp*scratchpad.el"))
    ("s" (switch-to-buffer "*sql*scratchpad.sql"))
    ("g" (switch-to-buffer "*go*scratchpad.go"))
    ("j" (switch-to-buffer "*js*scratchpad.js"))
    ("t" (switch-to-buffer "*ts*scratchpad.ts"))
    ("r" (switch-to-buffer "*rust*scratchpad.rs"))
    ("R" (switch-to-buffer "*rest*scratchpad.rest"))
    ("h" (switch-to-buffer "*html*scratchpad.html"))
    ("o" (switch-to-buffer "*org*scratchpad.org"))
    ("T" (switch-to-buffer "*text*scratchpad.txt"))
    ("m" (switch-to-buffer "*markdown*scratchpad.md")))

  (defhydra hydra-toggle-stuff (:color blue :hint nil)
    "Toggle"
    ("b" dakra-toggle-browser "browser - toggle eww/firefox" :column "Misc")
    ("d" toggle-debug-on-error "debug-on-error")
    ("s" sticky-buffer-mode "Sticky buffer mode")
    ("c" column-number-mode "column-number-mode" :column "Text")
    ("f" auto-fill-mode "fill-mode")
    ("F" web-server-file-server-toggle  "Toggle file file-server")
    ("w" whitespace-mode "whitespace-mode")
    ("l" toggle-truncate-lines "truncate-lines")
    ("ol" org-toggle-link-display "org link-display" :column "Org")
    ("op" org-toggle-pretty-entities "org pretty-entities")
    ("oi" org-toggle-inline-images "org inline-images"))

  (defun ansi-term-bash ()
    "Start ansi-term with bash."
    (interactive)
    (ansi-term "/bin/bash"))

  ;; Start different emacs packages (like elfeed or mu4e)
  (defhydra hydra-emacs-launcher (:color blue :hint nil)
    "Launch emacs package"
    ("e" elfeed "Elfeed - RSS/Atom Newsreader" :column "Apps")
    ("t" transmission "Transmission - Torrent")
    ("m" mu4e "mu4e - Mail")
    ("p" proced "proced")
    ("v" ovpn "VPN")
    ("c" quick-calc "calc - Quick calc" :column "Utils")
    ("C" calendar "calendar")
    ("T" display-time-world "time - Display world time")
    ("s" hydra-systemctl/body "Systemctl")
    ("a" ansi-term-bash "Ansi Terminal"  :column "Misc")
    ("b" brain-fm-play "brain.fm - Stream music")
    ("E" elisp-index-search "elisp-index-search")
    ("w" woman "woman - Man page viewer")
    ("y" (dired youtube-dl-directory) "YouTube - Open dired buffer with youtube downloads")
    ("z" zone "Zone - Screensaver"))

  ;; Start different external programs (like Termite or Firefox).
  (defhydra hydra-external-launcher (:color blue :hint nil)
    "Start external program"
    ("p" (start-process-shell-command "pavucontrol" nil "pavucontrol") "pavucontrol - sound settings")
    ("f" (start-process-shell-command "firefox-developer-edition" nil "env GTK_THEME=Arc firefox-developer-edition") "Firefox Developer Edition")
    ("k" (start-process-shell-command "keepassxc" nil "keepassxc") "keepassxc - Password Manager")
    ("l" (start-process-shell-command "i3lock-fancy-dualmonitor" nil "i3lock-fancy-dualmonitor") "Lock screen")
    ("n" (start-process-shell-command "networkmanager_dmenu" nil "networkmanager_dmenu") "Networkmanager")
    ("s" (start-process-shell-command "shutter" nil "shutter") "shutter - Screenshot")
    ("t" (start-process-shell-command "termite" nil "termite") "termite - Terminal" ))

  (defun dakra/insert-unicode (unicode-name)
    "Same as C-x 8 enter UNICODE-NAME."
    (insert-char (gethash unicode-name (ucs-names))))

  (defhydra hydra-unicode (:color blue :hint nil)
    "
     Unicode  _c_ €   _a_ ä   _A_ Ä
              _d_ °   _o_ ö   _O_ Ö
              _e_ €   _u_ Ü   _U_ Ü
              _p_ £   _s_ ß
              _m_ µ
              _r_ →
     "
    ("a" (dakra/insert-unicode "LATIN SMALL LETTER A WITH DIAERESIS"))
    ("A" (dakra/insert-unicode "LATIN CAPITAL LETTER A WITH DIAERESIS"))
    ("o" (dakra/insert-unicode "LATIN SMALL LETTER O WITH DIAERESIS")) ;;
    ("O" (dakra/insert-unicode "LATIN CAPITAL LETTER O WITH DIAERESIS"))
    ("u" (dakra/insert-unicode "LATIN SMALL LETTER U WITH DIAERESIS")) ;;
    ("U" (dakra/insert-unicode "LATIN CAPITAL LETTER U WITH DIAERESIS"))
    ("s" (dakra/insert-unicode "LATIN SMALL LETTER SHARP S"))
    ("c" (dakra/insert-unicode "COPYRIGHT SIGN"))
    ("d" (dakra/insert-unicode "DEGREE SIGN"))
    ("e" (dakra/insert-unicode "EURO SIGN"))
    ("p" (dakra/insert-unicode "POUND SIGN"))
    ("r" (dakra/insert-unicode "RIGHTWARDS ARROW"))
    ("m" (dakra/insert-unicode "MICRO SIGN"))))

(use-package tramp
  :defer t
  :config
  (setq tramp-default-method "ssh")

  ;; Only for debugging slow tramp connections
  ;;(setq tramp-verbose 7)

  ;; Skip version control for tramp files
  (setq vc-ignore-dir-regexp
        (format "\\(%s\\)\\|\\(%s\\)"
                vc-ignore-dir-regexp
                tramp-file-name-regexp))

  ;; Use ControlPath from .ssh/config
  (setq tramp-ssh-controlmaster-options "")

  ;; Backup tramp files like local files and don't litter the remote
  ;; file system with my emacs backup files
  (setq tramp-backup-directory-alist backup-directory-alist)

  ;; See https://www.gnu.org/software/tramp/#Ad_002dhoc-multi_002dhops
  ;; For all hosts, except my local one, first connect via ssh, and then apply sudo -u root:
  (dolist (tramp-proxies '((nil "\\`root\\'" "/ssh:%h:")
                           ((regexp-quote (system-name)) nil nil)
                           ("localhost" nil nil)
                           ("blif\\.vpn" nil nil)
                           ;; Add tramp proxy for atomx user
                           (nil "atomx" "/ssh:%h:")))
    (add-to-list 'tramp-default-proxies-alist tramp-proxies)))

;; Always show file size in human readable format
(setq eshell-ls-initial-args "-h")

;; We're in emacs, so 'cat' is nicer there than 'less'
(setenv "PAGER" "cat")

;; Fixme eshell-mode-map maps to global keybindings? Check "C-d"
;; Isssue: https://github.com/jwiegley/use-package/issues/332
(use-package eshell
  :bind (("C-x m" . eshell)
         ("C-x M" . dakra-eshell-split)
         ;;:map eshell-mode-map
         ;;("M-P" . eshell-previous-prompt)
         ;;("C-d" . dakra-eshell-quit-or-delete-char)
         ;;("M-N" . eshell-next-prompt)
         ;;("M-R" . eshell-list-history)
         ;;("M-r" . dakra-eshell-read-history)
         )
  :init (setq eshell-aliases-file (no-littering-expand-etc-file-name "eshell-aliases"))
  :config
  (defun dakra-eshell-split (&optional arg)
    "Like eshell but use pop-to-buffer to display."
    (interactive "P")
    (interactive)
    (let ((cur-buf (buffer-name))
          (eshell-buf (eshell arg)))
      (pop-to-buffer-same-window cur-buf)
      (pop-to-buffer eshell-buf)))

  ;; Don't print the welcome banner and
  ;; use native 'sudo', system sudo asks for password every time.
  (require 'em-tramp)
  (setq eshell-modules-list
        '(eshell-alias
          eshell-basic
          eshell-cmpl
          eshell-dirs
          eshell-glob
          eshell-hist
          eshell-ls
          eshell-pred
          eshell-prompt
          eshell-script
          eshell-term
          eshell-tramp
          eshell-unix))

  (require 'em-smart)
  (setq-default eshell-where-to-jump 'begin)
  (setq-default eshell-review-quick-commands nil)
  (setq-default eshell-smart-space-goes-to-end t)

  (require 'em-hist)
  ;; Some ideas from https://github.com/howardabrams/dot-files/blob/master/emacs-eshell.org
  (setq-default eshell-scroll-to-bottom-on-input 'all
                eshell-error-if-no-glob t
                eshell-hist-ignoredups t
                eshell-visual-commands '("ptpython" "ipython" "pshell" "tail" "vi" "vim" "watch"
                                         "nmtui" "dstat" "mycli" "pgcli" "vue" "ngrok"
                                         "castnow" "mitmproxy"
                                         "tmux" "screen" "top" "htop" "less" "more" "ncftp")
                eshell-prefer-lisp-functions nil)

  ;; Increase eshell history size from default of only 128
  (setq eshell-history-size 8192)

  (defun dakra-eshell-read-history ()
    (interactive)
    (insert
     (completing-read "Eshell history: "
                      (delete-dups
                       (ring-elements eshell-history-ring)))))

  ;; Used to C-d exiting from a shell? Want it to keep working, but still allow deleting a character?
  ;; We can have it both
  (require 'em-prompt)
  (defun dakra-eshell-quit-or-delete-char (arg)
    (interactive "p")
    (if (and (eolp) (looking-back eshell-prompt-regexp nil))
        (progn
          (eshell-life-is-too-much) ; Why not? (eshell/exit)
          (ignore-errors
            (when (= arg 4)  ; With prefix argument, also remove eshell frame/window
              (progn
                ;; Remove frame if eshell is only window (otherwise just close window)
                (if (one-window-p)
                    (delete-frame)
                  (delete-window))))))
      (delete-char arg)))

  (defun eshell-delete-backward-char (n)
    "Only call (delete-backward-char N) when not at beginning of prompt."
    (interactive "p")
    (if (looking-back eshell-prompt-regexp nil)
        (message "Beginning of prompt")
      (delete-char (- n))))

  ;; Fixme eshell-mode-map maps to global keybindings? Check "C-d"
  ;; Isssue: https://github.com/jwiegley/use-package/issues/332
  (add-hook 'eshell-mode-hook (lambda ()
                                (local-set-key (kbd "M-P") 'eshell-previous-prompt)
                                (local-set-key (kbd "M-N") 'eshell-next-prompt)
                                (local-set-key (kbd "M-R") 'eshell-list-history)
                                (local-set-key (kbd "M-r") 'dakra-eshell-read-history)
                                (local-set-key (kbd "C-r") 'dakra-eshell-read-history)
                                (local-set-key (kbd "C-d") 'dakra-eshell-quit-or-delete-char)
                                (local-set-key (kbd "DEL") 'eshell-delete-backward-char)
                                ;; Use helm as completion menu
                                ;;(local-set-key [remap eshell-pcomplete] 'helm-esh-pcomplete)
                                ;; or ivy
                                (local-set-key [remap eshell-pcomplete] 'completion-at-point)

                                ;;(eshell-smart-initialize)
                                ;; Integrate eshell with bookmark.el
                                (eshell-bookmark-setup)
                                ;; Emacs bug where * gets removed
                                ;; See https://github.com/company-mode/company-mode/issues/218
                                ;; https://debbugs.gnu.org/cgi/bugreport.cgi?bug=18951
                                ;;(require 'company)
                                ;;(setq-local company-idle-delay 0.1)
                                ;;(setq-local company-backends '(company-capf company-eshell-autosuggest))
                                ;; (setq-local company-backends '(company-capf))
                                ;; (setq-local company-frontends '(company-preview-frontend))
                                ))
  ;; Functions starting with `eshell/' can be called directly from eshell
  ;; with only the last part. E.g. (eshell/foo) will call `$ foo'
  (defun eshell/d (&rest args)
    "Open dired in current directory."
    (dired (pop args) "."))

  (defun eshell/ccat (file)
    "Like `cat' but output with Emacs syntax highlighting."
    (with-temp-buffer
      (insert-file-contents file)
      (let ((buffer-file-name file))
        (delay-mode-hooks
          (set-auto-mode)
          (if (fboundp 'font-lock-ensure)
              (font-lock-ensure)
            (with-no-warnings
              (font-lock-fontify-buffer)))))
      (buffer-string)))

  (defun eshell/lcd (&optional directory)
    "Like regular 'cd' but don't jump out of a tramp directory.
When on a remote directory with tramp don't jump 'out' of the server.
So if we're connected with sudo to 'remotehost'
'$ lcd /etc' would go to '/sudo:remotehost:/etc' instead of just
'/etc' on localhost."
    (if (file-remote-p default-directory)
        (with-parsed-tramp-file-name default-directory nil
          (eshell/cd
           (tramp-make-tramp-file-name
            method user nil host nil (or directory "") hop)))
      (eshell/cd directory)))

  (defun eshell/gst (&rest args)
    (magit-status-internal (or (pop args) default-directory))
    (eshell/echo))   ;; The echo command suppresses output

  (defun eshell/f (filename &optional dir try-count)
    "Searches for files matching FILENAME in either DIR or the
current directory. Just a typical wrapper around the standard
`find' executable.

Since any wildcards in FILENAME need to be escaped, this wraps the shell command.

If not results were found, it calls the `find' executable up to
two more times, wrapping the FILENAME pattern in wildcat
matches. This seems to be more helpful to me."
    (let* ((cmd (concat
                 (executable-find "find")
                 " " (or dir ".")
                 "      -not -path '*/.git*'"
                 " -and -not -path '*node_modules*'"
                 " -and -not -path '*classes*'"
                 " -and "
                 " -type f -and "
                 "-iname '" filename "'"))
           (results (shell-command-to-string cmd)))

      (if (not (s-blank-str? results))
          results
        (cond
         ((or (null try-count) (= 0 try-count))
          (eshell/f (concat filename "*") dir 1))
         ((or (null try-count) (= 1 try-count))
          (eshell/f (concat "*" filename) dir 2))
         (t "")))))

  (defun eshell/ef (filename &optional dir)
    "Searches for the first matching filename and loads it into a
file to edit."
    (let* ((files (eshell/f filename dir))
           (file (car (s-split "\n" files))))
      (find-file file)))

  (defun eshell/find (&rest args)
    "Wrapper around the ‘find’ executable."
    (let ((cmd (concat "find " (string-join args))))
      (shell-command-to-string cmd)))

  (defun execute-command-on-file-buffer (cmd)
    "Execute command on current buffer file."
    (interactive "sCommand to execute: ")
    (let* ((file-name (buffer-file-name))
           (full-cmd (concat cmd " " file-name)))
      (shell-command full-cmd)))

  (defun execute-command-on-file-directory (cmd)
    "Execute command on current buffer directory."
    (interactive "sCommand to execute: ")
    (let* ((dir-name (file-name-directory (buffer-file-name)))
           (full-cmd (concat "cd " dir-name "; " cmd)))
      (shell-command full-cmd))))

(use-package eshell-bookmark
  :after eshell)

;; Show git info in prompt
(use-package eshell-git-prompt
  :disabled t  ; Use eshell-prompt-extras
  :after eshell
  :config ;;(eshell-git-prompt-use-theme 'powerline)
  ;; FIXME: Wait for powerline font https://github.com/powerline/fonts/issues/154
  (eshell-git-prompt-use-theme 'robbyrussell))

(use-package eshell-prompt-extras
  :after esh-opt
  :config
  (require 'virtualenvwrapper)  ; We want python venv support
  (autoload 'epe-theme-dakrone "eshell-prompt-extras")
  (setq eshell-highlight-prompt nil
        eshell-prompt-function 'epe-theme-dakrone))

(use-package eshell-z
  :after eshell)

(use-package eshell-up
  :after eshell)

(use-package eshell-fringe-status
  :hook (eshell-mode . eshell-fringe-status-mode)
  :config
  (define-fringe-bitmap 'efs-line-bitmap
    [#b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     #b1111
     ] 18 4 'center)
  (setq eshell-fringe-status-success-bitmap 'efs-line-bitmap)
  (setq eshell-fringe-status-failure-bitmap 'efs-line-bitmap))

(use-package fish-completion
  :if (executable-find "fish")
  :after eshell
  :config (global-fish-completion-mode))

;; `company-mode' backend to provide eshell history suggestion
(use-package esh-autosuggest
  :hook (eshell-mode . esh-autosuggest-mode))

;; Autocomplete for git commands in shell and
;; the git command from magit ('!')
(use-package pcmpl-git
  :after pcomplete)

(use-package pcmpl-pip
  :after pcomplete)

;; Nicer diff (should be taken from global .config/git/config)
(setq vc-git-diff-switches '("--indent-heuristic"))

(use-package diff-mode
  :config
  ;; Shorten file headers like Magit's diff format.
  (setq diff-font-lock-prettify t))

(use-package ediff
  :defer t
  :config
  ;; Do everything in one frame
  (setq ediff-window-setup-function 'ediff-setup-windows-plain)
  ;; Split ediff windows horizontally by default
  (setq ediff-split-window-function 'split-window-horizontally))

;; Highlight and link issue IDs to website
;; bug-reference-url-format has to be set in dir-locals (S-p E)
;; E.g. for github: (bug-reference-url-format . "https://github.com/atomx/api/issues/%s")
(use-package bug-reference
  :hook ((prog-mode . bug-reference-prog-mode)
         ((log-view-mode git-commit-setup) . bug-reference-mode))
  :init (add-hook 'prog-mode-hook 'bug-reference-prog-mode)
  :config
  ;; (setq bug-reference-bug-regexp "\\([Bb]ug\\|[Pp]ull request\\|[Ii]ssue\\|[PpMm][Rr]\\|[Ff]ix\\) #\\([0-9]+\\(?:#[0-9]+\\)?\\)")
  (setq bug-reference-bug-regexp "#\\(?2:[0-9]+\\)"))

(use-package diff-hl
  :hook (((prog-mode conf-mode vc-dir-mode ledger-mode) . turn-on-diff-hl-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  ;; XXX: maybe set draw-borders to nil and set background color like
  ;; `(diff-added ((,class (:foreground ,green-4 :background ,green-00 :bold t))))
  ;; `(diff-changed ((,class (:foreground ,yellow-4 :background ,yellow-00 :bold t))))
  ;; `(diff-removed ((,class (:foreground ,red-3 :background ,red-00 :bold t))))
  (setq diff-hl-draw-borders t))

(use-package diff-hl-dired  ;; in diff-hl package
  :after dired
  :hook (dired-mode . diff-hl-dired-mode))

;; XXX: not sure if git gutter is really nicer than diff-hl
;; diff-hl comes pre-packaged with prelude but doesn't
;; have those *-hunk commands

;;;; disable diff-hl that's enabled in prelude-editor.el:393
;;(global-diff-hl-mode -1)
;;(remove-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
;;;; use git-gutter everywhere
;;(global-git-gutter-mode t)
;;(global-set-key (kbd "C-x v =") 'git-gutter:popup-hunk)
;;(global-set-key (kbd "C-x v s") 'git-gutter:stage-hunk)
;;(global-set-key (kbd "C-x v r") 'git-gutter:revert-hunk)

(use-package gitconfig-mode
  :mode ("/\\.gitconfig\\'"      "/\\.git/config\\'"
         "/modules/.*/config\\'" "/git/config\\'"
         "/\\.gitmodules\\'"     "/etc/gitconfig\\'"))
(use-package gitignore-mode
  :mode ("/\\.gitignore\\'"  "gitignore_global\\'"
         "/info/exclude\\'" "/git/ignore\\'"))

(use-package git-commit
  ;; Highlight issue ids in commit messages and spellcheck
  :hook (git-commit-setup . git-commit-turn-on-flyspell)
  :init
  ;; Mark a few major modes as safe
  (put 'git-commit-major-mode 'safe-local-variable
       (lambda (m) (or (eq m 'gfm-mode)
                       (eq m 'text-mode)
                       (eq m 'git-commit-elisp-text-mode))))
  :config (setq git-commit-major-mode 'gfm-mode))

(use-package magit
  :bind (("C-x g" . magit-status)
         ("C-x G" . magit-dispatch-popup)
         ("C-x M-g" . magit-dispatch-popup)
         ("s-m p" . magit-list-repositories)
         ("s-m m" . magit-status)
         ("s-m f" . magit-file-popup)
         ("s-m l" . magit-log-popup)
         ("s-m L" . magit-log-buffer-file)
         ("s-m b" . magit-blame))
  :defines (magit-ediff-dwim-show-on-hunks)
  :init
  (defcustom magit-push-protected-branch nil
    "When set, ask for confirmation before pushing to this branch (e.g. master)."
    :type 'string
    :safe #'stringp
    :group 'magit)
  :config
  (defun magit-push--protected-branch (magit-push-fun &rest args)
    "Ask for confirmation before pushing a protected branch."
    (if (equal magit-push-protected-branch (magit-get-current-branch))
        ;; Arglist is (BRANCH TARGET ARGS)
        (if (yes-or-no-p (format "Push branch %s? " (magit-get-current-branch)))
            (apply magit-push-fun args)
          (error "Push aborted by user"))
      (apply magit-push-fun args)))

  (advice-add 'magit-push-current-to-pushremote :around #'magit-push--protected-branch)
  (advice-add 'magit-push-current-to-upstream :around #'magit-push--protected-branch)

  ;; Add switch to invert the filter e.g. show all authors but `--author=foo'
  (magit-define-popup-switch 'magit-log-popup
    ?i "Invert filter" "--invert-grep")

  (add-hook 'after-save-hook 'magit-after-save-refresh-status t)

  ;; Show gravatars
  (setq magit-revision-show-gravatars '("^Author:     " . "^Commit:     "))

  ;; Always show recent/unpushed/unpulled commits
  (setq magit-section-initial-visibility-alist '((unpushed . show)
                                                 (unpulled . show)))

  (setq magit-repository-directories
        '(("~/atomx" . 5)
          ("~/e5" . 5)
          ("~/projects" . 5)))

  ;; Add action to easily create a release tag to tag popup
  (magit-define-popup-action 'magit-tag-popup
    ?r "Release" 'magit-tag-release)

  ;; "b b" is only for checkout and doesn't automatically create a new branch
  ;; remap to `magit-branch-or-checkout' that checks out an existing branch
  ;; or asks to create a new one if it doesn't exist
  (magit-remove-popup-key 'magit-branch-popup :action ?b)
  (magit-define-popup-action 'magit-branch-popup
    ?b "Checkout or create" 'magit-branch-or-checkout
    'magit-branch t)

  ;; Add reshelve command to commit popup to change date of commit
  (magit-define-popup-action 'magit-commit-popup
    ?n "Reshelve" 'magit-commit-reshelve)

  ;; Show submodules section to magit status
  (magit-add-section-hook 'magit-status-sections-hook
                          'magit-insert-modules
                          'magit-insert-stashes
                          'append)

  ;; Add more operations to the file popup
  (magit-define-popup-action 'magit-file-popup
    ?R "Rename file" 'magit-file-rename)
  (magit-define-popup-action 'magit-file-popup
    ?K "Delete file" 'magit-file-delete)
  (magit-define-popup-action 'magit-file-popup
    ?U "Untrack file" 'magit-file-untrack)
  (magit-define-popup-action 'magit-file-popup
    ?C "Checkout file" 'magit-file-checkout)

  ;; Show ignored files section to magit status
  (magit-add-section-hook 'magit-status-sections-hook
                          'magit-insert-ignored-files
                          'magit-insert-untracked-files
                          nil)
  ;; Disable safety nets
  (setq magit-commit-squash-confirm nil)
  (setq magit-save-repository-buffers 'dontask)
  (setf (nth 2 (assq 'magit-stash-pop  magit-dwim-selection)) t)
  ;;(setf (nth 2 (assq 'magit-stash-drop magit-dwim-selection)) t)
  (add-to-list 'magit-no-confirm 'rename t)
  (add-to-list 'magit-no-confirm 'resurrect t)
  (add-to-list 'magit-no-confirm 'trash t)

  ;; Don't override date for extend or reword
  (setq magit-commit-extend-override-date nil)
  (setq magit-commit-reword-override-date nil)

  ;; Set remote.pushDefault
  (setq magit-push-current-set-remote-if-missing 'default)

  ;; Show color and graph in magit-log. Since color makes it a bit slow, only show the last 128 commits
  (setq magit-log-arguments '("--graph" "--color" "--decorate" "-n128"))
  ;; Always highlight word differences in diff
  (setq magit-diff-refine-hunk 'all)

  ;; Only show 2 ediff panes
  (setq magit-ediff-dwim-show-on-hunks t)

  ;; Don't change my window layout after quitting magit
  ;; Ofter I invoke magit and then do a lot of things in other windows
  ;; On quitting, magit would then "restore" the window layout like it was
  ;; when I first invoked magit. Don't do that!
  (setq magit-bury-buffer-function 'magit-mode-quit-window)

  ;; Show magit status in the same window
  (setq magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  ;; Display magit status in full frame
  ;;(setq magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  )

(use-package magit-wip
  :after magit
  :config
  ;; Disable more safety nets that can be reverted with WIP mode
  (add-to-list 'magit-no-confirm 'safe-with-wip t)

  ;; Access WIP logs from log popup
  (magit-define-popup-action 'magit-log-popup
    ?w "Log WIP current" 'magit-wip-log-current)
  (magit-define-popup-action 'magit-log-popup
    ?W "Log WIP" 'magit-wip-log)

  (magit-wip-before-change-mode)
  (magit-wip-after-apply-mode)
  (magit-wip-after-save-mode))

(use-package magithub
  :disabled t
  :after magit
  :hook (prog-mode magithub-bug-reference-mode-on)
  :config
  ;; Don't query github api all the time. This causes magit-status to freeze
  ;; Wait for async support https://github.com/vermiculus/magithub/issues/37
  (setq magithub-cache t)
  (setq magithub-api-timeout 5)
  (magithub-feature-autoinject t))

;; open current line/region/dired/commit in github
(use-package browse-at-remote
  :bind (("C-c G" . dakra-browse-at-remote))
  :config
  (defun dakra-browse-at-remote (p)
    "Like browse-at-remote but will also copy the url in the kill ring.
When called with one prefix argument only copy the url in the kill ring
and don't open in the brower.
When called with 2 prefix arguments only open in browser and don't copy."
    (interactive "p")
    (case p
      (4  (browse-at-remote-kill))
      (16 (browse-at-remote))
      (t  (browse-at-remote-kill) (browse-at-remote))))

  (add-to-list 'browse-at-remote-remote-type-domains '("gitlab.bis" . "gitlab"))
  (add-to-list 'browse-at-remote-remote-type-domains '("gitlab.paesslergmbh.de" . "gitlab"))
  (add-to-list 'browse-at-remote-remote-type-domains '("git.ebenefuenf.com" . "gitlab"))
  (add-to-list 'browse-at-remote-remote-type-domains '("lab.ebenefuenf.com" . "gitlab"))
  (setq browse-at-remote-prefer-symbolic nil))

;; Increase fill-column for programming to 100
(defun dakra-prog-mode-init ()
  ;; Only auto-fill comments in prog-mode
  (set (make-local-variable 'comment-auto-fill-only-comments) t)
  (setq fill-column 110))
(add-hook 'prog-mode-hook 'dakra-prog-mode-init)

(use-package cmake-font-lock
  :hook (cmake-mode . cmake-font-lock-activate))

(use-package cmake-mode
  :mode ("CMakeLists.txt" "\\.cmake\\'"))

(use-package irony
  :hook (((c++-mode c-mode objc-mode) . irony-mode-on-maybe)
         (irony-mode . irony-cdb-autosetup-compile-options))
  :config
  (defun irony-mode-on-maybe ()
    ;; avoid enabling irony-mode in modes that inherits c-mode, e.g: solidity-mode
    (when (member major-mode irony-supported-major-modes)
      (irony-mode 1))))

(use-package company-irony
  :after irony
  :config (add-to-list 'company-backends 'company-irony))

(use-package irony-eldoc
  :hook (irony-mode))

(use-package glsl-mode
  :mode ("\\.vert\\'" "\\.frag\\'" "\\.glsl\\'" "\\.geom\\'"))

(use-package company-glsl
  :after glsl-mode
  :config (add-to-list 'company-backends 'company-glsl))

;; Associate more files with conf-mode
(use-package conf-mode
  :mode ("mbsyncrc\\'" "msmtprc\\'" "pylintrc\\'" "\\.cnf\\'"
         "\\.ini\\.\\(tmpl\\|sample\\)\\'" "\\.service\\'"))

(use-package pkgbuild-mode
  :mode "PKGBUILD\\'")

(use-package graphviz-dot-mode
  :mode ("\\.dot\\'"))

;; Edit GNU gettext PO files
(use-package po-mode
  :mode ("\\.po\\'" "\\.po\\."))

(use-package csv-mode
  :mode "\\.csv\\'"
  :init (setq csv-separators '("," "	" ";" "|")))

(use-package toml-mode
  :mode ("\\.toml\\'" "Cargo.lock\\'"))

(use-package yaml-mode
  :mode ("\\.yaml\\'" "\\.yml\\'")
  :config
  (add-hook 'yaml-mode-hook #'dakra-prog-mode-init)
  (add-hook 'yaml-mode-hook
            (lambda () (add-hook 'before-save-hook 'whitespace-cleanup nil t))))

(use-package systemd
  :mode ("\\.service\\'" "\\.timer\\'"))

(use-package nginx-mode
  :mode ("/etc/nginx/conf.d/.*" "/etc/nginx/.*\\.conf\\'"))

(use-package apache-mode
  :mode ("\\.htaccess\\'" "httpd\\.conf\\'" "srm\\.conf\\'" "access\\.conf\\'"))

(use-package docker
  :bind-keymap ("C-c d" . docker-command-map)
  :init
  ;; Mark all docker-compose-arguments as safe for dir local usage
  (put 'docker-compose-arguments 'safe-local-variable 'listp)
  :config
  (setq docker-images-default-sort-key '("Created" . t))
  (setq docker-containers-default-sort-key '("Status" . t)))
(use-package dockerfile-mode
  :defer t)
(use-package docker-compose-mode
  :defer t)
(use-package docker-tramp
  :after tramp)

(use-package realgud
  :defer t)

(use-package elixir-mode
  :mode ("\\.ex\\'" "\\.exs\\'" "\\.elixir\\'")
  :config
  (require 'smartparens)
  (sp-with-modes '(elixir-mode)
    (sp-local-pair "fn" "end"
                   :when '(("SPC" "RET"))
                   :actions '(insert navigate))
    (sp-local-pair "do" "end"
                   :when '(("SPC" "RET"))
                   :post-handlers '(sp-ruby-def-post-handler)
                   :actions '(insert navigate)))
  (use-package alchemist))

(use-package fish-mode
  :mode "\\.fish\\'")

;; Go
;; For better support install:
;; arch package `go-tools' for goimports, guru and godoc
;; `gocode' (arch gocode-git package) for autocomplete
;; `godef' (arch godef-git package) for godoc-at-point
;; `golint' (arch go-lint-git)
;; XXX: `errcheck' (go get -u github.com/kisielk/errcheck) to check for missing error checks
(use-package go-mode
  :mode "\\.go\\'"
  :bind (:map go-mode-map
         ("M-?" . godoc-at-point)
         ("M-." . godef-jump)
         ("M-*" . pop-tag-mark)  ;; Jump back after godef-jump
         ("C-c m r" . go-run))
  :config
  ;; Prefer goimports to gofmt if installed
  (let ((goimports (executable-find "goimports")))
    (when goimports
      (setq gofmt-command goimports)))

  ;; For autocompeltion in the `godoc' command we need 'godoc' and not 'go doc'
  ;;(setq godoc-command "go doc")
  (setq godoc-use-completing-read t)

  ;; Syntax highlighting for code in godoc
  ;; https://github.com/dominikh/go-mode.el/pull/88#issuecomment-98448284
  (defun godoc-highlight ()
    (let ((st (make-syntax-table go-mode-syntax-table)))
      (modify-syntax-entry ?\' "w" st)
      (set-syntax-table st))
    (set (make-local-variable 'font-lock-defaults) '(go--build-font-lock-keywords)))
  (add-hook 'godoc-mode-hook 'godoc-highlight)

  (add-hook 'go-mode-hook
            '(lambda ()
               (setq tab-width 4)
               ;; gofmt on save
               (add-hook 'before-save-hook 'gofmt-before-save nil t)
               ;; stop whitespace being highlighted
               (whitespace-toggle-options '(tabs)))))

(use-package helm-go-package
  :disabled t
  :after (helm go-mode)
  :config
  ;; Re-order helm actions (so ENTER is 'Display GoDoc')
  (setq helm-go-package-actions (helm-make-actions
                                 "Display GoDoc" 'helm-go-package--godoc-browse-url
                                 "Show documentation" 'godoc
                                 "Visit package's directory" 'helm-go-package--visit-package-directory
                                 "Add a new import"  (lambda (candidate) (go-import-add nil candidate))
                                 "Add a new import as"  (lambda (candidate) (go-import-add t candidate))))
  (substitute-key-definition 'go-import-add 'helm-go-package go-mode-map))

(use-package company-go
  :after (company go-mode)
  :config (add-to-list 'company-backends 'company-go))

(use-package gotest
  :after go-mode
  :bind (:map go-mode-map
         ("C-x t" . go-test-current-test)))

(use-package go-eldoc
  :hook (go-mode . go-eldoc-setup))

(use-package go-projectile
  :after (projectile go-mode))

(use-package haskell-mode
  :hook (haskell-mode . haskell-indentation-mode))

(use-package intero
  :hook (haskell-mode . intero-mode))

(use-package prettier-js
  :defer t
  ;;:init (add-hook 'js2-mode-hook (lambda () (add-hook 'before-save-hook 'prettier-before-save)))
  :init
  (put 'prettier-js-args 'safe-local-variable 'listp)
  :config
  (setq prettier-js-args '(
                           "--trailing-comma" "all"
                           ;;"--tab-width" "4"
                           "--single-quote" "true"
                           "--bracket-spacing" "false"
                           ))
  ;; prettier "--print-width" argument is read from 'fill-column' variable
  (setq prettier-js-width-mode 'fill))

(use-package json-mode
  :mode "\\.json\\'")

(use-package js2-mode
  :interpreter "node"
  :mode ("\\.js\\'" "\\.pac\\'" "\\.node\\'")
  :init
  (add-hook 'js2-mode-hook (lambda ()
                             ;; electric-layout-mode doesn't play nice with smartparens
                             ;;(setq-local electric-layout-rules '((?\; . after)))
                             (setq mode-name "JS2")))
  :config
  ;; Don't warn about trailing commas
  (setq js2-strict-trailing-comma-warning nil)

  (setq js2-basic-offset 2)  ; set javascript indent to 2 spaces
  )

(use-package js2-imenu-extras
  :hook (js2-mode . js2-imenu-extras-mode))

;; Connect to chrome
;; chromium --remote-debugging-port=9222 https://localhost:3000
;; then in emacs
;; M-x indium-connect-to-chrome

;; or node
;; node --inspect myfile.js
;; node with breakpoint at first line
;; node --inspect --debug-brk myfile.js
;; then open the url that node prints:
;; chrome-devtools://inspector.html?...&ws=127.0.0.1:PORT/PATH
;; then in emacs:
;; M-x indium-connect-to-nodejs RET 127.0.0.1 RET PORT RET PATH, PORT, PATH

;; place `.indium' file in static root folder.

(use-package indium
  :hook (js-mode . indium-interaction-mode)
  :config
  (setq indium-update-script-on-save t)
  (setq indium-chrome-executable "google-chrome-stable"))

(use-package js2-refactor
  :hook (js2-mode . js2-refactor-mode)
  :config
  (define-key js2-mode-map (kbd "C-k") #'js2r-kill)
  (define-key js2-refactor-mode-map (kbd "C-c r")
    (defhydra js2-refactor-hydra (:color blue :hint nil)
      "
^Functions^                    ^Variables^               ^Buffer^                      ^sexp^               ^Debugging^
------------------------------------------------------------------------------------------------------------------------------
[_lp_] Localize Parameter      [_ev_] Extract variable   [_wi_] Wrap buffer in IIFE    [_k_]  js2 kill      [_lt_] log this
[_ef_] Extract function        [_iv_] Inline variable    [_ig_] Inject global in IIFE  [_ss_] split string  [_dt_] debug this
[_ip_] Introduce parameter     [_rv_] Rename variable    [_ee_] Expand node at point   [_sl_] forward slurp
[_em_] Extract method          [_vt_] Var to this        [_cc_] Contract node at point [_ba_] forward barf
[_ao_] Arguments to object     [_sv_] Split var decl.    [_uw_] unwrap
[_tf_] Toggle fun exp and decl [_ag_] Add var to globals
[_ta_] Toggle fun expr and =>  [_ti_] Ternary to if
[_q_]  quit"
      ("ee" js2r-expand-node-at-point)
      ("cc" js2r-contract-node-at-point)
      ("ef" js2r-extract-function)
      ("em" js2r-extract-method)
      ("tf" js2r-toggle-function-expression-and-declaration)
      ("ta" js2r-toggle-arrow-function-and-expression)
      ("ip" js2r-introduce-parameter)
      ("lp" js2r-localize-parameter)
      ("wi" js2r-wrap-buffer-in-iife)
      ("ig" js2r-inject-global-in-iife)
      ("ag" js2r-add-to-globals-annotation)
      ("ev" js2r-extract-var)
      ("iv" js2r-inline-var)
      ("rv" js2r-rename-var)
      ("vt" js2r-var-to-this)
      ("ao" js2r-arguments-to-object)
      ("ti" js2r-ternary-to-if)
      ("sv" js2r-split-var-declaration)
      ("ss" js2r-split-string)
      ("uw" js2r-unwrap)
      ("lt" js2r-log-this)
      ("dt" js2r-debug-this)
      ("sl" js2r-forward-slurp)
      ("ba" js2r-forward-barf)
      ("k" js2r-kill)
      ("q" nil)
      )))

;; use tern for js autocompletion
(use-package tern
  :disabled t  ; We use tide (typescript) also for javascript files
  :commands tern-mode
  :init (add-hook 'js-mode-hook 'tern-mode)
  :config
  (use-package company-tern
    :config
    (setq company-tern-property-marker "")  ; don't show circles for properties
    (add-to-list 'company-backends 'company-tern)))

(use-package skewer-mode
  :disabled t  ; Use indium
  :commands skewer-mode
  :init
  (setq httpd-port 8079)  ; set port for simple-httpd used by skewer
  (add-hook 'js2-mode-hook 'skewer-mode)
  (add-hook 'css-mode-hook 'skewer-css-mode)
  (add-hook 'html-mode-hook 'skewer-html-mode))

;; Adds the node_modules/.bin directory to the buffer exec_path.
;; E.g. support project local eslint installations.
;; XXX: Maybe add autoload for web and js2 mode?
;; (eval-after-load 'js2-mode
;;   '(add-hook 'js2-mode-hook #'add-node-modules-path))
(use-package add-node-modules-path :defer t)

(use-package ng2-mode :defer t)

;; Nicer elisp regex syntax highlighting
(use-package easy-escape
  :hook ((emacs-lisp-mode lisp-mode) . easy-escape-minor-mode))

;; From: https://github.com/Fuco1/.emacs.d/blob/af82072196564fa57726bdbabf97f1d35c43b7f7/site-lisp/redef.el#L20-L94
;; redefines the silly indent of keyword lists
;; before
;;   (:foo bar
;;         :baz qux)
;; after
;;   (:foo bar
;;    :baz qux)
(eval-after-load "lisp-mode"
  '(defun lisp-indent-function (indent-point state)
     "This function is the normal value of the variable `lisp-indent-function'.
The function `calculate-lisp-indent' calls this to determine
if the arguments of a Lisp function call should be indented specially.
INDENT-POINT is the position at which the line being indented begins.
Point is located at the point to indent under (for default indentation);
STATE is the `parse-partial-sexp' state for that position.
If the current line is in a call to a Lisp function that has a non-nil
property `lisp-indent-function' (or the deprecated `lisp-indent-hook'),
it specifies how to indent.  The property value can be:
- `defun', meaning indent `defun'-style
  \(this is also the case if there is no property and the function
  has a name that begins with \"def\", and three or more arguments);
- an integer N, meaning indent the first N arguments specially
  (like ordinary function arguments), and then indent any further
  arguments like a body;
- a function to call that returns the indentation (or nil).
  `lisp-indent-function' calls this function with the same two arguments
  that it itself received.
This function returns either the indentation to use, or nil if the
Lisp function does not specify a special indentation."
     (let ((normal-indent (current-column))
           (orig-point (point)))
       (goto-char (1+ (elt state 1)))
       (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
       (cond
        ;; car of form doesn't seem to be a symbol, or is a keyword
        ((and (elt state 2)
              (or (not (looking-at "\\sw\\|\\s_"))
                  (looking-at ":")))
         (if (not (> (save-excursion (forward-line 1) (point))
                     calculate-lisp-indent-last-sexp))
             (progn (goto-char calculate-lisp-indent-last-sexp)
                    (beginning-of-line)
                    (parse-partial-sexp (point)
                                        calculate-lisp-indent-last-sexp 0 t)))
         ;; Indent under the list or under the first sexp on the same
         ;; line as calculate-lisp-indent-last-sexp.  Note that first
         ;; thing on that line has to be complete sexp since we are
         ;; inside the innermost containing sexp.
         (backward-prefix-chars)
         (current-column))
        ((and (save-excursion
                (goto-char indent-point)
                (skip-syntax-forward " ")
                (not (looking-at ":")))
              (save-excursion
                (goto-char orig-point)
                (looking-at ":")))
         (save-excursion
           (goto-char (+ 2 (elt state 1)))
           (current-column)))
        (t
         (let ((function (buffer-substring (point)
                                           (progn (forward-sexp 1) (point))))
               method)
           (setq method (or (function-get (intern-soft function)
                                          'lisp-indent-function)
                            (get (intern-soft function) 'lisp-indent-hook)))
           (cond ((or (eq method 'defun)
                      (and (null method)
                           (> (length function) 3)
                           (string-match "\\`def" function)))
                  (lisp-indent-defform state indent-point))
                 ((integerp method)
                  (lisp-indent-specform method state
                                        indent-point normal-indent))
                 (method
                  (funcall method indent-point state)))))))))

(use-package subr-x
  :defer t
  :config
  (put 'if-let   'byte-obsolete-info nil)
  (put 'when-let 'byte-obsolete-info nil))

(use-package elisp-mode
  :bind (:map emacs-lisp-mode-map
         ("C-c C-c" . eval-defun)
         ("C-c C-b" . eval-buffer))
  :config
  (add-hook 'emacs-lisp-mode-hook (lambda ()
                                    ;;(eldoc-mode +1)
                                    (setq mode-name "EL"))))

(use-package dash  :defer t
  :config (dash-enable-font-lock))

(use-package s  :defer t)

(use-package request
  :defer t)

(use-package auto-compile
  :disabled t  ; I rather trigger a new compile by hand
  :defer 10
  :config
  (auto-compile-on-load-mode)
  (auto-compile-on-save-mode)
  (setq auto-compile-display-buffer               nil)
  (setq auto-compile-mode-line-counter            t)
  (setq auto-compile-source-recreate-deletes-dest t)
  (setq auto-compile-toggle-deletes-nonlib-dest   t)
  (setq auto-compile-update-autoloads             t)
  (add-hook 'auto-compile-inhibit-compile-hook
            'auto-compile-inhibit-compile-detached-git-head))

(use-package litable
  :defer t)

(use-package package-lint
  :defer t)
(use-package flycheck-package
  :after flycheck
  :config (flycheck-package-setup))

(use-package el2markdown
  :defer t)

(use-package slime
  :hook (lisp-mode slime-lisp-mode-hook)
  :bind (:map slime-mode-indirect-map
         ("M-?" . slime-describe-symbol))
  :config
  (setq slime-contribs '(slime-fancy))
  (setq inferior-lisp-program "sbcl")
  (setq slime-lisp-implementations
        `((sbcl ("sbcl" "--core" ,(no-littering-expand-var-file-name "sbcl.core-for-slime"))))))
(use-package slime-company
  :after (slime company)
  :config (slime-setup '(slime-fancy slime-company)))

(use-package clojure-mode
  :defer t)

(use-package cider
  :hook ((cider-mode cider-repl-mode) . cider-company-enable-fuzzy-completion))

;;; Lisp in python vm
(use-package hy-mode
  :mode "\\.hy\\'")

(use-package lua-mode
  :mode "\\.lua\\'"
  :interpreter ("lua" . lua-mode)
  :hook (lua-mode . lua-outline-mode)
  :bind (:map lua-mode-map
         ("M-." . dumb-jump-go))
  :config
  (defun lua-outline-mode ()
    (setq-local outline-regexp "function")))

(use-package company-lua
  :hook (lua-mode . my-lua-mode-company-init)
  :config
  (defun my-lua-mode-company-init ()
    (setq-local company-backends '((company-lua
                                    company-etags
                                    company-dabbrev-code
                                    company-yasnippet)))))

(use-package jira-markup-mode
  :mode ("\\.confluence\\'" "/itsalltext/.*jira.*\\.txt$"))

(use-package markdown-mode
  :mode (("/itsalltext/.*\\(gitlab\\|github\\).*\\.txt$" . gfm-mode)
         ("\\.markdown\\'" . gfm-mode)
         ("\\.md\\'" . gfm-mode))
  :config
  ;; Enable fontification for code blocks
  (setq markdown-fontify-code-blocks-natively t)
  (add-to-list 'markdown-code-lang-modes '("ini" . conf-mode))
  ;; use pandoc with source code syntax highlighting to preview markdown (C-c C-c p)
  (setq markdown-command "pandoc -s --highlight-style pygments -f markdown_github -t html5"))

(use-package octave
  :mode ("\\.m\\'" . octave-mode)
  :interpreter ("octave" . octave-mode)
  :bind (:map octave-mode-map
         ("C-x C-e" . octave-send-region-or-line))
  :config
  (setq octave-block-offset 4)
  (defun octave-send-region-or-line ()
    (interactive)
    (if (region-active-p)
        (octave-send-region (region-beginning) (region-end))
      (octave-send-line))))

(use-package php-mode
  :defer t)

(use-package cython-mode
  :mode ("\\.pyd\\'" "\\.pyi\\'" "\\.pyx\\'"))
(use-package flycheck-cython
  :after (cython-mode flycheck))

(use-package python
  :mode (("\\.py\\'" . python-mode)
         ("\\.xsh\\'" . python-mode))  ; Xonsh script files
  :interpreter ("python" . python-mode)
  :bind (:map python-mode-map
         ("C-x C-e" . python-shell-send-whole-line-or-region)
         ("C-c C-p" . hydra-python/body)
         ("C-c C-t" . hydra-python/body)
         )
  :hook (python-mode . python-flat-imenu-index)
  :init
  ;; Allow setting some python variables via dir-locals.
  ;; This can be dangerous if someone makes you open an untrusted
  ;; file with a malicious `.dir-locals' and execute some more
  ;; malicious python code. But I'm not too worried
  ;; and I change these often enough that I don't want to save
  ;; for each variable I allow.
  ;; TODO: Make the check for extra-pythonpaths more strict.
  (put 'python-shell-extra-pythonpaths 'safe-local-variable 'listp)
  (put 'python-shell-process-environment
       'safe-local-variable (create-safe-env-p "DJANGO_SETTINGS_MODULE" "ENV_INI_PATH"))
  :config
  ;; Don't spam message buffer when python-mode can't guess indent-offset
  (setq python-indent-guess-indent-offset-verbose nil)

  (defun python-shell-send-whole-line-or-region ()
    "Send whole line or region to inferior Python process."
    (interactive)
    (whole-line-or-region-call-with-region 'python-shell-send-region)
    (deactivate-mark))

  (defhydra hydra-python-test (python-mode-map "C-c C-t" :color blue)
    "Run Python Tests"
    ("f" python-test-function "Function")
    ("m" python-test-method "Method")
    ("c" python-test-class "Class")
    ("F" python-test-file "File")
    ("p" python-test-project "Project")
    ("q" nil "Cancel"))

  (defun py-isort-add-import-whole-line-or-region ()
    "Import module(s) from region or whole line."
    (interactive)
    (whole-line-or-region-call-with-region 'py-isort-add-import-region))

  (defun python-run-server ()
    "Start pyramid pserve or django runserver."
    (interactive)
    (if (pyramid-project-root)
        (pyramid-serve)
      (djangonaut-run-management-command "runserver")))

  (defhydra hydra-python (python-mode-map "C-c C-p" :color blue :hint nil)
    "
           ^Tests^           ^Import^                ^Other^
    ----------------------------------------------------------------
    [_f_]   Function    [_a_] From ... import     [_P_] Run Python
    [_m_]   Method      [_i_] Import              [_I_] Pippel
    [_c_]   Class       [_l_] Import line/region  [_R_] Runserver
    [_F_]   File        [_r_] Remove imports      [_!_] Start Python
    [_p_]   Project     [_s_] Sort imports        [_q_] Cancel
    "
    ("a" py-isort-add-from-import)
    ("i" py-isort-add-import)
    ("l" py-isort-add-import-whole-line-or-region)
    ("r" py-isort-remove-import)
    ("s" py-isort-buffer)

    ("f" python-test-function)
    ("m" python-test-method)
    ("c" python-test-class)
    ("F" python-test-file)
    ("p" python-test-project)

    ("P" run-python)
    ("I" pippel-list-packages)
    ("R" python-run-server)
    ("!" run-python)
    ("q" nil))

  (require 'thingatpt)
  (require 'projectile)
  (defun projectile-find-sql-file ()
    "Find sql file for symbol at point."
    (interactive)
    (let* ((project-files (projectile-current-project-files))
           (file (if (region-active-p)
                     (format "%s.sql" (buffer-substring (region-beginning) (region-end)))
                   (when (thing-at-point 'symbol)
                     (format "%s.sql" (thing-at-point 'symbol)))))
           (candidates
            (cl-remove-if-not
             (lambda (f)
               (let ((name (file-name-nondirectory f)))
                 (string-equal name file))) project-files)))
      (when candidates
        ;; Just take the first candidate
        (find-file (expand-file-name (car candidates) (projectile-project-root)))
        (run-hooks 'projectile-find-file-hook)
        t)))

  (defun python-flat-imenu-index ()
    (setq-local imenu-create-index-function
                #'python-imenu-create-flat-index)))

(use-package anaconda-mode
  :bind (:map anaconda-mode-map
         ("M-." . python-goto-sql-file-or-definition)
         ("M-," . anaconda-mode-find-assignments))
  :hook ((python-mode . anaconda-mode)
         (python-mode . anaconda-eldoc-mode))
  :config
  (defun python-goto-sql-file-or-definition (&optional arg)
    "Call anaconda find-definitions or with prefix ARG find sql file."
    (interactive "P")
    (back-button-push-mark-local-and-global)
    (if arg
        (projectile-find-sql-file)
      (anaconda-mode-find-definitions)
      (recenter))))

(use-package company-anaconda
  :after anaconda-mode
  :config (add-to-list 'company-backends 'company-anaconda))

;; package-list-packages like interface for python packages
(use-package pippel :defer t)

;; Syntax highlighting for requirements.txt files
(use-package pip-requirements
  :mode (("\\.pip\\'" . pip-requirements-mode)
         ("requirements.*\\.txt\\'" . pip-requirements-mode)
         ("requirements\\.in" . pip-requirements-mode)))

;; This adds a few sphinx features and fontification for rst buffers.
;; You can do `sphinx-compile` (`C-c C-x C-c`) to compile the sphinx docs or
;; `sphinx-compile-and-view` (`C-c C-x C-v`) to compile and view.
(use-package sphinx-mode
  :hook (rst-mode . sphinx-mode))

(use-package python-test
  ;; FIXME: Use :defer but then, when not loaded yet, dir local vars appear as unsafe
  :after python
  :config
  ;; Set default test backend to pytest
  (setq python-test-backend 'pytest))

(use-package pyramid
  ;; FIXME: Use :defer but then, when not loaded yet, dir local vars appear as unsafe
  :after python)

(use-package djangonaut
  ;; FIXME: Use :defer but then, when not loaded yet, dir local vars appear as unsafe
  :after python)


;; Enable (restructured) syntax highlighting for python docstrings
(use-package python-docstring
  :hook (python-mode . python-docstring-mode))

(use-package pydoc
  :bind (:map anaconda-mode-map
         ("M-?" . pydoc-at-point)))

;; Automatically sort and format python imports
(use-package py-isort
  ;; FIXME: Use :defer but then, when not loaded yet, dir local vars appear as unsafe
  :after python
  :config
  ;;(add-hook 'before-save-hook 'py-isort-before-save)
  (setq py-isort-options '("--line-width=100"
                           "--multi-line=3"
                           "--trailing-comma"
                           "--force-grid-wrap=2"
                           "--thirdparty=rethinkdb")))

;; activate virtualenv for flycheck
;; (from https://github.com/lunaryorn/.emacs.d/blob/master/lisp/flycheck-virtualenv.el)

(use-package flycheck
  :hook ((prog-mode ledger-mode) . flycheck-mode)
  :config
  ;; Use the load-path from running Emacs when checking elisp files
  (setq flycheck-emacs-lisp-load-path 'inherit)

  ;; Only do flycheck when I actually safe the buffer
  (setq flycheck-check-syntax-automatically '(save mode-enable))

  (declare-function python-shell-calculate-exec-path "python")

  (defun flycheck-virtualenv-executable-find (executable)
    "Find an EXECUTABLE in the current virtualenv if any."
    (if (bound-and-true-p python-shell-virtualenv-root)
        (let ((exec-path (python-shell-calculate-exec-path)))
          (executable-find executable))
      (executable-find executable)))

  (defun flycheck-virtualenv-setup ()
    "Setup Flycheck for the current virtualenv."
    (setq-local flycheck-executable-find #'flycheck-virtualenv-executable-find))

  (add-hook 'python-mode-hook #'flycheck-virtualenv-setup)

  (setq flycheck-python-mypy-cache-dir "/home/daniel/.mypy-cache")
  (setq flycheck-flake8-maximum-line-length 110))

;; ipython5 uses prompt_toolkit which doesn't play nice with emacs
;; when setting interpreter to 'ipython', you need additional '--simple-prompt' arg
(setq python-shell-interpreter "python")
;;(setq python-shell-interpreter-args "-i")
;; FIXME: run new python interpreter on projectile-switch-project?
;; and only run pshell when it's a pyramid project.
;;(setq python-shell-interpreter "python"
;;      python-shell-interpreter-args "--simple-prompt -i /home/daniel/.virtualenvs/atomx/lib/python3.5/site-packages/pyramid/scripts/pshell.py /home/daniel/atomx/api/development.ini")

(use-package virtualenvwrapper
  ;; Automatically switch python venv
  :hook (projectile-after-switch-project . venv-projectile-auto-workon)
  :config
  (venv-initialize-interactive-shells) ;; if you want interactive shell support
  (venv-initialize-eshell) ;; if you want eshell support
  (setq venv-location "/home/daniel/.virtualenvs/")
  ;;(venv-workon '"atomx")  ; default venv after a starting emacs
  )


(defcustom python-autopep8-path (executable-find "autopep8")
  "autopep8 executable path."
  :group 'python
  :type 'string)

(defun python-autopep8 ()
  "Automatically formats Python code to conform to the PEP 8 style guide.
$ autopep8 --in-place --aggressive --aggressive <filename>"
  (interactive)
  (when (eq major-mode 'python-mode)
    (shell-command
     (format "%s --in-place --max-line-length %s --aggressive %s" python-autopep8-path
             whitespace-line-column
             (shell-quote-argument (buffer-file-name))))
    (revert-buffer t t t)))


;; importmagic
;; FIXME: very buggy yet 15.12.2016
;; importmagic itself buggy: https://github.com/alecthomas/importmagic
;; Always reorder imports; No way to put each import on a new line..
;; maybe always call py-isort after calling importmagic?
;;(require 'importmagic)
;;(add-hook 'python-mode-hook 'importmagic-mode)
;;(define-key importmagic-mode-map (kbd "C-c C-i") 'importmagic-fix-symbol-at-point)
;;(add-to-list 'helm-boring-buffer-regexp-list "\\*epc con")

;; Commint for redis
(use-package redis
  :defer t)

(use-package ruby-mode
  :defer t)

(use-package inf-ruby
  :hook (ruby-mode-hook . inf-ruby-minor-mode))

;; You may need installing the following packages on your system:
;; * rustc (Rust Compiler)
;; * cargo (Rust Package Manager)
;; * racer (Rust Completion Tool)
;; * rustfmt (Rust Tool for formatting code)
(use-package rust-mode
  :mode "\\.rs\\'"
  :config
  (use-package flycheck-rust
    :after flycheck
    :commands flycheck-rust-setup
    :init (add-hook 'flycheck-mode-hook #'flycheck-rust-setup))
  (use-package cargo
    :commands cargo-minor-mode
    :init (add-hook 'rust-mode-hook #'cargo-minor-mode))
  (use-package racer
    :commands racer-mode
    :hook (rust-mode . racer-mode)
    :config (define-key rust-mode-map (kbd "TAB") #'company-indent-or-complete-common)))

(use-package solidity-mode
  :mode "\\.sol\\'"
  :init
  (setq solidity-flycheck-solc-checker-active t)
  (setq solidity-flycheck-solium-checker-active t))

(use-package sql
  :mode (("\\.sql\\'" . sql-mode)
         ("\\.msql\\'" . sql-mode))  ; Mako template sql
  :hook (sql-interactive-mode . toggle-truncate-lines)
  :commands sql-init-passwords
  :bind (:map sql-interactive-mode-map
         ("M-p" . comint-previous-prompt)
         ("M-n" . comint-next-prompt)
         ([return] . dakra/add-semicolon-and-comint-send-input)
         ("DEL" . sql-delete-backward-char)
         ("C-d" . dakra/sql-quit-or-delete-char))
  :init
  ;; Persist sqli history accross multiple sessions
  (setq-default sql-input-ring-file-name
                (no-littering-expand-var-file-name "sql-input-ring"))
  :config
  ;; I never use multiline in the comint mode. So auto add ";" at the end
  (defun dakra/add-semicolon-and-comint-send-input ()
    "Adds semicolon at the end of the line and runs comint-send-input."
    (interactive)
    (beginning-of-line)
    (if (looking-at "\\\\")  ;; Don't append ";" if we use a postgres special command
        (comint-send-input)
      (move-end-of-line nil)
      ;;(delete-horizontal-space)  ; Remove all trailing whitespace
      (skip-syntax-backward " \n")
      (backward-char)
      ;; Only add semicolon if there is non already
      (unless (looking-at ";")
        (forward-char)
        (insert ";"))
      (comint-send-input)))

  (defun dakra/sql-quit-or-delete-char (arg)
    (interactive "p")
    (if (and (eolp) (looking-back sql-prompt-regexp nil))
        (progn
          (comint-quit-subjob)
          (sleep-for 0.4)  ; Wait 400ms for the process to quit
          (kill-buffer (current-buffer))
          (ignore-errors
            (when (= arg 4)  ; With prefix argument, also remove sql buffer frame/window
              (progn
                ;; Remove frame if sql buffer is only window (otherwise just close window)
                (if (one-window-p)
                    (delete-frame)
                  (delete-window))))))
      (delete-char arg)))

  (defun sql-delete-backward-char (n)
    "Only call (delete-backward-char N) when not at beginning of prompt."
    (interactive "p")
    (if (looking-back sql-prompt-regexp nil)
        (message "Beginning of prompt")
      (delete-char (- n))))

  (setq sql-product 'postgres)

  (defun dakra-sql-connect ()
    "Ensure that sql-connection-alist is populated including passwords."
    (interactive)
    (unless sql-connection-alist
      (sql-init-passwords))
    (call-interactively #'sql-connect))

  ;; FIXME: Use advice
  (defun sql-connect--ensure-passwords (&optional connection buf-name)
    "Ensure that sql-connection-alist is populated including passwords."
    (interactive
     (unless sql-connection-alist
       (sql-init-passwords))
     (list (sql-read-connection "Connection: ")
           current-prefix-arg)))
  ;;(advice-add 'sql-connect :before #'sql-connect--ensure-passwords)

  (defun sql-init-passwords ()
    "Fill sql-connection-alist with passwords from =~/.authinfo.gpg=."
    (interactive)
    (setq sql-connection-alist
          '((mysql-root (sql-product 'mariadb)
                        (sql-user "root")
                        (sql-database "atomx_api"))
            (atomx-local     (sql-product 'mariadb)
                             (sql-user "api")
                             (sql-database "atomx_api"))
            (atomx-remote    (sql-product 'mysql)
                             (sql-port 3307)
                             (sql-user "root")
                             (sql-database "api")
                             (sql-mysql-options '("-A")))
            (hogaso-remote   (sql-product 'mariadb)
                             (sql-port 3307)
                             (sql-user "root")
                             (sql-database "hogaso")
                             (sql-mysql-options '("-A")))
            (postgres-root (sql-product 'postgres)
                           (sql-user "postgres")
                           (sql-database "blif2"))
            (paessler-docker (sql-product 'mysql)
                             (sql-port 3308)
                             (sql-user "root")
                             (sql-database "paessler_com2"))
            (paessler-local (sql-product 'mariadb)
                            (sql-user "website")
                            (sql-database "paessler_com2"))
            (shop-local      (sql-product 'mariadb)
                             (sql-user "bis")
                             (sql-database "bis"))
            (blif-local      (sql-product 'postgres)
                             (sql-user "blif2")
                             (sql-database "blif2"))
            (blif-remote     (sql-product 'postgres)
                             (sql-port 5433)
                             (sql-user "blif2")
                             (sql-database "blif2"))
            (neorent-local   (sql-product 'postgres)
                             (sql-user "neoadmin")
                             (sql-database "neorent"))
            (neorent-remote  (sql-product 'postgres)
                             (sql-server "decisive-plate-71.db.databaselabs.io")
                             (sql-user "neouser")
                             (sql-database "neorent"))))
    (auth-source-forget-all-cached)  ;; FIXME
    (dolist (conn sql-connection-alist)
      (let* ((conn-name    (car conn))
             (conn-details (cdr conn))
             (host         (or (cadr (assoc 'sql-server conn-details)) "127.0.0.1"))
             (user         (symbol-name conn-name))
             (password     (auth-source-pick-first-password :host host :user user)))
        (unless password
          (message "No password set for sql connection %s in authinfo." conn-name))
        ;; Add password to each antry from .authinfo.gpg
        (nconc conn-details `((sql-password ,password)))
        ;; When there is no sql-server set, set it to "127.0.0.1"
        (unless (assoc 'sql-server conn-details)
          (nconc conn-details '((sql-server "127.0.0.1")))))))

  (setq sql-mysql-login-params (append sql-mysql-login-params '(port)))

  (setq sql-mysql-login-params
        '((user :default "daniel")
          (database :default "api")
          (server :default "localhost"))))

;; Smart indentation for SQL files
(use-package sql-indent
  :hook ((sql-mode sql-interactive-mode) . sqlind-minor-mode))
  ;;:config (setq-default sqlind-basic-offset 4)

;; Capitalize keywords in SQL mode
(use-package sqlup-mode
  :hook (sql-mode sql-interactive-mode redis-mode)
  :config
  ;; Don't capitalize `name` or 'type' keyword
  (add-to-list 'sqlup-blacklist "name")
  (add-to-list 'sqlup-blacklist "names")
  (add-to-list 'sqlup-blacklist "type"))

;; TypeScript
(use-package typescript-mode
  :init
  (put 'typescript-indent-level 'safe-local-variable 'integerp)
  :config
  (setq typescript-indent-level 2))

(use-package tide
  :hook ((typescript-mode js2-mode) . tide-setup)
  :config
  ;; Configure javascript-tide checker to run after your default javascript checker
  (flycheck-add-next-checker 'javascript-eslint 'javascript-tide 'append)

  ;; Format the buffer before saving
  ;; FIXME: auto indent doesn't respect editorconfig
  ;;(add-hook 'before-save-hook 'tide-format-before-save)
  (setq tide-format-options '(:insertSpaceAfterFunctionKeywordForAnonymousFunctions t
                              :placeOpenBraceOnNewLineForFunctions nil)))

(use-package emmet-mode
  :hook (web-mode sgml-mode css-mode)
  :bind (:map emmet-mode-keymap
         ("<backtab>" . emmet-expand-line)
         ("\C-c TAB" . emmet-expand-line)
         ("C-M-p" . emmet-prev-edit-point)
         ("C-M-n" . emmet-next-edit-point))
  :config
  (setq emmet-move-cursor-between-quotes t)
  (setq emmet-move-cursor-after-expanding t)

  (use-package helm-emmet :after helm :disabled t))

(use-package rainbow-mode
  :hook (css-mode scss-mode sass-mode emacs-lisp-mode hy-mode))

(use-package scss-mode
  :defer t
  :config
  ;;(setq css-indent-offset 2)
  ;; turn off annoying auto-compile on save
  (setq scss-compile-at-save nil))

;; Imenu support for css/scss/less
(use-package counsel-css
  :hook (css-mode . counsel-css-imenu-setup))

(use-package sass-mode
  :mode ("\\.sass\\'"))

;; FIXME: add flycheck support? Only for .vue files?
;; (flycheck-add-mode 'javascript-eslint 'web-mode)
(use-package web-mode
  :mode ("\\.phtml\\'" "\\.tpl\\.php\\'" "\\.tpl\\'" "\\.blade\\.php\\'" "\\.jsp\\'" "\\.as[cp]x\\'"
         "\\.erb\\'" "\\.html.?\\'" "/\\(views\\|html\\|theme\\|templates\\)/.*\\.php\\'"
         "\\.jinja2?\\'" "\\.mako\\'" "\\.vue\\'" "_template\\.txt")
  :init (add-to-list 'safe-local-eval-forms '(web-mode-set-engine "django"))
  :config
  ;;(setq web-mode-engines-alist '(("django"  . "/templates/.*\\.html\\'")))
  (setq web-mode-engines-alist '(("django" . "\\.jinja2?\\'")))

  ;; make web-mode play nice with smartparens
  (setq web-mode-enable-auto-pairing nil)

  (require 'smartparens)
  (sp-with-modes '(web-mode)
    (sp-local-pair "%" "%"
                   :unless '(sp-in-string-p)
                   :post-handlers '(((lambda (&rest _ignored)
                                       (just-one-space)
                                       (save-excursion (insert " ")))
                                     "SPC" "=" "#")))
    (sp-local-tag "%" "<% "  " %>")
    (sp-local-tag "=" "<%= " " %>")
    (sp-local-tag "#" "<%# " " %>"))

  ;; Flyspell setup
  ;;http://blog.binchen.org/posts/effective-spell-check-in-emacs.html

  ;; {{ flyspell setup for web-mode
  (defun web-mode-flyspell-verify ()
    (let* ((f (get-text-property (- (point) 1) 'face))
           rlt)
      (cond
       ;; Check the words with these font faces, possibly.
       ;; this *blacklist* will be tweaked in next condition
       ((not (memq f '(web-mode-html-attr-value-face
                       web-mode-html-tag-face
                       web-mode-html-attr-name-face
                       web-mode-constant-face
                       web-mode-doctype-face
                       web-mode-keyword-face
                       web-mode-comment-face ;; focus on get html label right
                       web-mode-function-name-face
                       web-mode-variable-name-face
                       web-mode-css-property-name-face
                       web-mode-css-selector-face
                       web-mode-css-color-face
                       web-mode-type-face
                       web-mode-block-control-face)))
        (setq rlt t))
       ;; check attribute value under certain conditions
       ((memq f '(web-mode-html-attr-value-face))
        (save-excursion
          (search-backward-regexp "=['\"]" (line-beginning-position) t)
          (backward-char)
          (setq rlt (string-match "^\\(value\\|class\\|ng[A-Za-z0-9-]*\\)$"
                                  (thing-at-point 'symbol)))))
       ;; finalize the blacklist
       (t
        (setq rlt nil)))
      rlt))
  (put 'web-mode 'flyspell-mode-predicate 'web-mode-flyspell-verify)

  ;; Don't display doublon (double word) as error
  (defvar flyspell-check-doublon t
    "Check doublon (double word) when calling `flyspell-highlight-incorrect-region'.")
  (make-variable-buffer-local 'flyspell-check-doublon)

  (defadvice flyspell-highlight-incorrect-region (around flyspell-highlight-incorrect-region-hack activate)
    (if (or flyspell-check-doublon (not (eq 'doublon (ad-get-arg 2))))
        ad-do-it))

  (defun web-mode-hook-setup ()
    ;;(flyspell-mode 1)
    (setq flyspell-check-doublon nil))

  (add-hook 'web-mode-hook 'web-mode-hook-setup)
  ;; } flyspell setup

  ;; Enable current element highlight
  (setq web-mode-enable-current-element-highlight t)
  ;; Show column for current element
  ;; Like highlight-indent-guide but only one line for current element
  (setq web-mode-enable-current-column-highlight t)

  ;; Don't indent directly after a <script> or <style> tag
  (setq web-mode-script-padding 0)
  (setq web-mode-style-padding 0)

  ;; Set default indent to 2 spaces
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2)
  ;; auto close tags in web-mode
  (setq web-mode-enable-auto-closing t))

;; Company-web is an alternative emacs plugin for autocompletion in html-mode, web-mode, jade-mode,
;; slim-mode and use data of ac-html. It uses company-mode.
(use-package company-web
  :disabled t  ;; Maybe no completion at all is best for web-mode? At least for the html part?!
  :after web-mode
  :commands company-web-html
  :config
  (require 'company-web-html)

  ;; Tide completion support in web-mode with company-mode
  (defun my-web-mode-hook ()
    "Hook for `web-mode'."
    (set (make-local-variable 'company-backends)
         '(company-tide company-web-html company-yasnippet company-files)))

  (add-hook 'web-mode-hook 'my-web-mode-hook)

  ;; Enable JavaScript completion between <script>...</script> etc.
  (defadvice company-tide (before web-mode-set-up-ac-sources activate)
    "Set `tide-mode' based on current language before running company-tide."
    (if (equal major-mode 'web-mode)
        (let ((web-mode-cur-language
               (web-mode-language-at-pos)))
          (if (or (string= web-mode-cur-language "javascript")
                  (string= web-mode-cur-language "jsx")
                  )
              (unless tide-mode (tide-mode))
            (if tide-mode (tide-mode -1)))))))

(use-package discover-my-major
  :bind (("C-h C-m" . discover-my-major)))

;; auto kill buffer when closing window
(defun maybe-delete-frame-buffer (frame)
  "When a dedicated FRAME is deleted, also kill its buffer.
A dedicated frame contains a single window whose buffer is not
displayed anywhere else."
  (let ((windows (window-list frame)))
    (when (eq 1 (length windows))
      (let ((buffer (window-buffer (car windows))))
        (when (eq 1 (length (get-buffer-window-list buffer nil t)))
          (kill-buffer buffer))))))
;;(add-to-list 'delete-frame-functions #'maybe-delete-frame-buffer)

(use-package restclient
  :mode ("\\.rest\\'" . restclient-mode)
  :hook (restclient-mode . restclient-outline-mode)
  :config
  (defun restclient-outline-mode ()
    (outline-minor-mode)
    (setq-local outline-regexp "##+")))

(use-package restclient-helm
  :disabled t
  :after (restclient helm))

(use-package company-restclient
  :after (restclient company)
  :config (add-to-list 'company-backends 'company-restclient))

(use-package symbol-overlay
  :hook ((prog-mode html-mode css-mode) . symbol-overlay-mode)
  :bind (("C-c s" . symbol-overlay-put)
         :map symbol-overlay-mode-map
         ("M-n" . symbol-overlay-jump-next)
         ("M-p" . symbol-overlay-jump-prev)
         :map symbol-overlay-map
         ("M-n" . symbol-overlay-jump-next)
         ("M-p" . symbol-overlay-jump-prev)
         ("C-c C-s r" . symbol-overlay-rename)
         ("C-c C-s k" . symbol-overlay-remove-all)
         ("C-c C-s q" . symbol-overlay-query-replace)
         ("C-c C-s t" . symbol-overlay-toggle-in-scope)
         ("C-c C-s n" . symbol-overlay-jump-next)
         ("C-c C-s p" . symbol-overlay-jump-prev))
  :init (setq symbol-overlay-temp-in-scope t)
  :config
  ;;(set-face-background 'symbol-overlay-temp-face "gray30")
  ;; Remove all default bindings
  (setq symbol-overlay-map (make-sparse-keymap)))


;; more useful frame title, that show either a file or a
;; buffer name (if the buffer isn't visiting a file)
(setq frame-title-format
      '("" invocation-name " " (:eval (if (buffer-file-name)
                                          (abbreviate-file-name (buffer-file-name))
                                        "%b"))))

(use-package dumb-jump
  :bind (("M-g o" . dumb-jump-go-other-window)
         ("M-g j" . dumb-jump-go)
         ("M-g p" . dumb-jump-back)
         ("M-g q" . dumb-jump-quick-look)
         ("M-g x" . dumb-jump-go-prefer-external)
         ("M-g z" . dumb-jump-go-prefer-external-other-window))
  :config (setq dumb-jump-selector 'helm))

;; change `find-file` so all files that belong to root are opened as root
;; too often unintentional changes. just use 'M-x crux-sudo-edit' when needed
;;(crux-reopen-as-root-mode)

(use-package aggressive-indent
  :hook ((emacs-lisp-mode lisp-mode hy-mode clojure-mode css js2-mode) . aggressive-indent-mode))

(use-package undo-tree
  :demand t
  :bind ("C-z" . undo-tree-undo)  ;; Don't (suspend-frame)
  :config
  (setq undo-tree-visualizer-timestamps t)  ; show timestamps in undo-tree
  ;;(setq undo-tree-visualizer-diff t)

  ;; autosave the undo-tree history
  (setq undo-tree-history-directory-alist
        `((".*" . ,temporary-file-directory)))
  (setq undo-tree-auto-save-history t)

  ;; Keep region when undoing in region
  (defadvice undo-tree-undo (around keep-region activate)
    (if (use-region-p)
        (let ((m (set-marker (make-marker) (mark)))
              (p (set-marker (make-marker) (point))))
          ad-do-it
          (goto-char p)
          (set-mark m)
          (set-marker p nil)
          (set-marker m nil))
      ad-do-it))

  (global-undo-tree-mode))


;; Smart region guesses what you want to select by one command:
;; - If you call this command multiple times at the same position, it
;;   expands the selected region (with `er/expand-region').
;; - Else, if you move from the mark and call this command, it selects
;;   the region rectangular (with `rectangle-mark-mode').
;; - Else, if you move from the mark and call this command at the same
;;   column as mark, it adds a cursor to each line (with `mc/edit-lines').
(use-package smart-region
  ;; C-SPC is smart-region
  :bind (([remap set-mark-command] . smart-region)))


;; "C-=" is not valid ascii sequence in terminals
;;(global-set-key (kbd "C-@") 'er/expand-region)

(use-package selected
  ;; Setting the hooks here manually instead of (selected-global-mode)
  ;; So use-package creates autoloads for us and only loads this package
  ;; if we really use it (i.e. mark anything)
  :hook ((activate-mark . selected--on)
         (deactivate-mark . selected-off))
  :init (defvar selected-org-mode-map (make-sparse-keymap))
  :bind (:map selected-keymap
         ("q" . selected-off)
         ("u" . upcase-region)
         ("d" . downcase-region)
         ("w" . count-words-region)
         ("m" . apply-macro-to-region-lines)
         ;; multiple cursors
         ("v" . mc/vertical-align-with-space)
         ("a" . mc/mark-all-dwim)
         ("A" . mc/mark-all-like-this)
         ("m" . mc/mark-more-like-this-extended)
         ("p" . mc/mark-previous-like-this)
         ("P" . mc/unmark-previous-like-this)
         ("S" . mc/skip-to-previous-like-this)
         ("n" . mc/mark-next-like-this)
         ("N" . mc/unmark-next-like-this)
         ("s" . mc/skip-to-next-like-this)
         ("r" . mc/edit-lines)
         :map selected-org-mode-map
         ("t" . org-table-convert-region)))

(use-package multiple-cursors
  :bind (("C-c m" . mc/mark-all-dwim)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         :map mc/keymap
         ("C-x v" . mc/vertical-align-with-space)
         ("C-x n" . mc-hide-unmatched-lines-mode))
  :config
  (global-unset-key (kbd "M-<down-mouse-1>"))
  (global-set-key (kbd "M-<mouse-1>") 'mc/add-cursor-on-click)

  (with-eval-after-load 'multiple-cursors-core
    (define-key mc/keymap (kbd "M-T") 'mc/reverse-regions)
    (define-key mc/keymap (kbd "C-,") 'mc/unmark-next-like-this)
    (define-key mc/keymap (kbd "C-.") 'mc/skip-to-next-like-this)))


(use-package god-mode
  :disabled t
  ;; Make god-mode a little bit more vi-like
  :bind (("<escape>" . god-local-mode)
         :map god-local-mode-map ("i" . god-local-mode))
  :config
  ;; change curser to bar when in god-mode
  (defun god-update-cursor ()
    "Toggle curser style to bar when in god-mode"
    (setq cursor-type (if (or god-local-mode buffer-read-only)
                          'bar
                        'box)))
  (add-hook 'god-mode-enabled-hook 'god-update-cursor)
  (add-hook 'god-mode-disabled-hook 'god-update-cursor))

;; Operate on system processes like dired
(use-package proced
  :bind ("C-x p" . proced)
  :config
  (setq-default proced-auto-update-flag t)
  (setq-default proced-auto-update-interval 1))

;; scroll 4 lines up/down w/o moving pointer
;;(global-set-key "\M-n"  (lambda () (interactive) (scroll-up   1)) )
;;(global-set-key "\M-p"  (lambda () (interactive) (scroll-down 1)) )

(use-package avy
  :bind ("C-;" . avy-goto-char-timer)
  :config
  (setq avy-background t)
  (setq avy-style 'at-full)
  (setq avy-timeout-seconds 0.3))

(use-package ace-link
  :bind (:map Info-mode-map ("o" . ace-link-info)
         :map help-mode-map ("o" . ace-link-help)
         :map compilation-mode-map ("o" . ace-link-compilation)
         :map org-mode-map ("M-o" . ace-link-org))
  :init
  (eval-after-load "woman"
    `(define-key woman-mode-map ,"o" 'ace-link-woman))
  (eval-after-load "eww"
    `(progn
       (define-key eww-link-keymap ,"o" 'ace-link-eww)
       (define-key eww-mode-map ,"o" 'ace-link-eww))))

;; Spellcheck setup

(use-package ispell
  :bind (("C-c I c" . ispell-comments-and-strings)
         ("C-c I d" . ispell-change-dictionary)
         ("C-c I k" . ispell-kill-ispell)
         ("C-c I m" . ispell-message)
         ("C-c I r" . ispell-region))
  :config
  ;; Spell check camel case strings
  (setq ispell-program-name "aspell"
        ;; force the English dictionary, support Camel Case spelling check (tested with aspell 0.6)
        ispell-extra-args '("--sug-mode=ultra"
                            "--run-together"
                            "--run-together-limit=5"
                            "--run-together-min=2"))

  ;; Javascript and ReactJS setup
  (defun js-flyspell-verify ()
    (let* ((f (get-text-property (- (point) 1) 'face)))
      ;; *whitelist*
      ;; only words with following font face will be checked
      (memq f '(js2-function-call
                js2-function-param
                js2-object-property
                font-lock-variable-name-face
                font-lock-string-face
                font-lock-function-name-face))))
  (put 'js2-mode 'flyspell-mode-predicate 'js-flyspell-verify)
  (put 'rjsx-mode 'flyspell-mode-predicate 'js-flyspell-verify)
  ;; }}

  ;; http://blog.binchen.org/posts/what-s-the-best-spell-check-set-up-in-emacs.html
  ;; Don't use Camel Case when correcting a word
  (defun flyspell-detect-ispell-args (&optional run-together)
    "if RUN-TOGETHER is true, spell check the CamelCase words."
    (let (args)
      (cond
       ((string-match  "aspell$" ispell-program-name)
        ;; Force the English dictionary for aspell
        ;; Support Camel Case spelling check (tested with aspell 0.6)
        (setq args (list "--sug-mode=ultra"))
        (if run-together
            (setq args (append args '("--run-together" "--run-together-limit=5" "--run-together-min=2")))))
       ((string-match "hunspell$" ispell-program-name)
        ;; Force the English dictionary for hunspell
        (setq args "")))
      args))

  (setq-default ispell-extra-args (flyspell-detect-ispell-args t))
  ;; (setq ispell-cmd-args (flyspell-detect-ispell-args))
  (defadvice ispell-word (around my-ispell-word activate)
    (let ((old-ispell-extra-args ispell-extra-args))
      (ispell-kill-ispell t)
      (setq ispell-extra-args (flyspell-detect-ispell-args))
      ad-do-it
      (setq ispell-extra-args old-ispell-extra-args)
      (ispell-kill-ispell t)))
  ;; flyspell-correct uses this function
  (defadvice flyspell-correct-word-generic (around my-ispell-word activate)
    (let ((old-ispell-extra-args ispell-extra-args))
      (ispell-kill-ispell t)
      (setq ispell-extra-args (flyspell-detect-ispell-args))
      ad-do-it
      (setq ispell-extra-args old-ispell-extra-args)
      (ispell-kill-ispell t)))
  ;; flyspell-correct uses this function
  (defadvice flyspell-correct-at-point (around my-ispell-word activate)
    (let ((old-ispell-extra-args ispell-extra-args))
      (ispell-kill-ispell t)
      (setq ispell-extra-args (flyspell-detect-ispell-args))
      ad-do-it
      (setq ispell-extra-args old-ispell-extra-args)
      (ispell-kill-ispell t)))

  (defadvice flyspell-auto-correct-word (around my-flyspell-auto-correct-word activate)
    (let ((old-ispell-extra-args ispell-extra-args))
      (ispell-kill-ispell t)
      ;; use emacs original arguments
      (setq ispell-extra-args (flyspell-detect-ispell-args))
      ad-do-it
      ;; restore our own ispell arguments
      (setq ispell-extra-args old-ispell-extra-args)
      (ispell-kill-ispell t)))

  (defun text-mode-hook-setup ()
    ;; Turn off RUN-TOGETHER option when spell check text-mode
    (setq-local ispell-extra-args (flyspell-detect-ispell-args)))
  (add-hook 'text-mode-hook 'text-mode-hook-setup)

  ;; end spell checking
  )

(use-package flyspell
  :hook ((prog-mode . flyspell-prog-mode)
         ((org-mode mu4e-compose-mode markdown-mode rst-mode) . flyspell-mode))
  :config
  ;; remove flyspess 'C-;' keybinding so we can use it for avy jump
  (unbind-key "C-;" flyspell-mode-map))

;; Show ivy-list of correct spelling suggesions
(use-package flyspell-correct-ivy
  :after flyspell
  :bind (:map flyspell-mode-map
         ("C-." . flyspell-correct-previous-word-generic)))

;; Automatically guess languages and switch ispell

(use-package guess-language
  ;; Only guess language for emails
  :hook (mu4e-compose-mode . guess-language-mode)
  :config
  (setq guess-language-langcodes '((en . ("en_GB" "English"))
                                   (de . ("de_DE" "German"))))
  (setq guess-language-languages '(en de))
  (setq guess-language-min-paragraph-length 35))


(use-package iedit
  :init (setq iedit-toggle-key-default nil)
  :bind ("C-c ;" . iedit-mode))


(use-package yasnippet
  :defer 10
  :mode (("\\.yasnippet\\'" . snippet-mode))
  :bind (:map yas-minor-mode-map
         ;; Complete yasnippets with company. No need for extra bindings
         ;;("TAB"     . nil)  ; Remove Yasnippet's default tab key binding
         ;;([tab]     . nil)
         ;; Set Yasnippet's key binding to C-tab
         ("\C-c TAB" . yas-expand))
  :config
  (yas-global-mode 1))

(use-package shrink-whitespace
  :bind ("M-SPC" . shrink-whitespace))

(use-package editorconfig
  :defer 1
  :config (editorconfig-mode 1))

;; backup

(setq create-lockfiles nil)  ; disable lock file symlinks

;;(setq backup-directory-alist `((".*" . "~/.emacs.d/.backups")))

(setq make-backup-files t               ; backup of a file the first time it is saved.
      backup-by-copying t               ; don't clobber symlinks
      version-control t                 ; version numbers for backup files
      delete-old-versions t             ; delete excess backup files silently
      kept-old-versions 6               ; oldest versions to keep when a new numbered backup is made (default: 2)
      kept-new-versions 9               ; newest versions to keep when a new numbered backup is made (default: 2)
      )

(use-package keychain-environment
  :disabled t
  :if (daemonp)
  ;; Load ssh/gpg agent environment after 2 minutes. If the agent isn't started yet (not entered password),
  ;; we have to call (keychain-refresh-environment) interactively later
  :defer 120
  :commands keychain-refresh-environment
  :config (keychain-refresh-environment))

(use-package org
  :mode ("\\.org\\'"  . org-mode)
  :bind (("C-c a"   . org-agenda)
         ("<f6>"    . org-agenda)
         ("<f7>"    . org-clock-goto)
         ("<f9> I"  . bh/punch-in)
         ("<f9> O"  . bh/punch-out)
         ("<f9> l"  . org-toggle-link-display)
         ("C-c l"   . org-store-link)
         ("C-c o c" . org-clock-goto)
         ("C-c o i" . org-clock-in-or-list)
         ("C-c C-x C-j" . org-clock-goto)
         ("C-c C-x C-i" . org-clock-in-or-list)
         ("C-c C-x C-o" . org-clock-out)
         ("C-c o O" . org-clock-out)
         ("C-c o l" . org-store-link)
         ("C-c o a" . org-agenda)
         ("C-c o b" . org-switchb)
         ("C-c o d" . org-hide-all-drawers)
         :map org-mode-map
         ([(shift return)] . crux-smart-open-line)
         ([(control shift return)] . crux-smart-open-line-above)
         ("<M-return>" . org-insert-todo-heading-respect-content)
         ("<M-S-return>" . org-meta-return)
         ("M-." . org-open-at-point)  ; So M-. behaves like in source code.
         ("M-," . org-mark-ring-goto)
         ("C-c C-x C-i" . org-clock-in-or-list)
         ;; Disable adding and removing org-agenda files via keybinding.
         ;; I explicitly specify agenda file directories in the config.
         ("C-c [" . nil)
         ("C-c ]" . nil)
         ("C-a" . org-beginning-of-line)  ; Overwrite crux-beginning-of-line
         ("M-o" . ace-link-org)
         ("M-p" . org-previous-visible-heading)
         ("M-n" . org-next-visible-heading)
         ("<M-up>" . org-metaup)
         ("<M-down>" . org-metadown)
         :map org-src-mode-map
         ("C-x n" . org-edit-src-exit))
  :init
  (add-hook 'org-mode-hook
            (lambda ()
              ;; Automatic line-wrapping in org-mode
              ;;(auto-fill-mode 1)

              (setq completion-at-point-functions
                    '(org-completion-symbols
                      ora-cap-filesystem))))
  :config
  ;; Insead of "..." show "…" when there's hidden folded content
  ;; Some characters to choose from: …, ⤵, ▼, ↴, ⬎, ⤷, and ⋱
  (setq org-ellipsis "⤵")

  (defun org-clock-in-or-list (&optional select start-time)
    "Like org-clock-in but show list of recent clocks when not in org buffer.
Show clock history when not in org buffer or when called with prefix argument."
    (interactive "P")
    (if (and (eq major-mode 'org-mode) (not (equal select '(4))))
        (org-clock-in select start-time)
      (counsel-org-clock-history)))

  ;; Show headings up to level 2 by default when opening an org files
  (setq org-startup-folded 'content)

  ;; Show inline images by default
  (setq org-startup-with-inline-images t)

  ;; Add more levels to headlines that get displayed with imenu
  (setq org-imenu-depth 5)

  ;; Enter key follows links (= C-c C-o)
  (setq org-return-follows-link t)

  ;; Don't remove links after inserting
  (setq org-keep-stored-link-after-insertion t)

  ;; Never show 'days' in clocksum (e.g. in report clocktable)
  ;; format string used when creating CLOCKSUM lines and when generating a
  ;; time duration (avoid showing days)
  (setq org-duration-format '((special . h:mm)))
  ;; Set to  (("d" . nil) (special . h:mm)) if you want to show days

  ;; Set default column view headings: Task Effort Clock_Summary
  ;;(setq org-columns-default-format "%80ITEM(Task) %10Effort(Effort){:} %10CLOCKSUM")

  ;; Set default column view headings: Task Total-Time Time-Stamp
  (setq org-columns-default-format "%75ITEM(Task) %10CLOCKSUM %16TIMESTAMP_IA")

  ;; global Effort estimate values
  ;; global STYLE property values for completion
  (setq org-global-properties (quote (("Effort_ALL" . "0:15 0:30 0:45 1:00 2:00 3:00 4:00 5:00 6:00 0:00")
                                      ("STYLE_ALL" . "habit"))))

  ;; Tags with fast selection keys
  (setq org-tag-alist (quote ((:startgroup)
                              ("WAITING" . ?w)
                              ("HOLD" . ?h)
                              ("CANCELLED" . ?c)
                              ("NOTE" . ?n)
                              (:endgroup)
                              ("PERSONAL" . ?P)
                              ("WORK" . ?W)
                              ("ATOMX" . ?A)
                              ("E5" . ?E)
                              ("HOGASO" . ?H)
                              ("ORG" . ?o)
                              ("crypt" . ?c)
                              ("FLAGGED" . ??))))

  ;; Allow setting single tags without the menu
  (setq org-fast-tag-selection-single-key (quote expert))

  (setq org-archive-mark-done nil)
  (setq org-archive-location "%s_archive::* Archived Tasks")

  ;; C-RET, C-S-RET insert new heading after current task content
  (setq org-insert-heading-respect-content nil)

  ;; Show a little bit more when using sparse-trees
  (setq org-show-following-heading t)
  (setq org-show-hierarchy-above t)
  (setq org-show-siblings (quote ((default))))

  ;; don't show * / = etc
  (setq org-hide-emphasis-markers t)

  ;; leave highlights in sparse tree after edit. C-c C-c removes highlights
  (setq org-remove-highlights-with-change nil)

  ;; M-RET should not split the lines
  (setq org-M-RET-may-split-line '((default . nil)))

  (setq org-special-ctrl-a/e t)
  (setq org-special-ctrl-k t)
  (setq org-yank-adjusted-subtrees t)

  ;; I have a few triggers that automatically assign tags to tasks based
  ;; on state changes. If a task moves to CANCELLED state then it gets a
  ;; CANCELLED tag. Moving a CANCELLED task back to TODO removes the
  ;; CANCELLED tag. These are used for filtering tasks in agenda views.
  (setq org-todo-state-tags-triggers
        (quote (("CANCELLED" ("CANCELLED" . t))
                ("WAITING" ("WAITING" . t))
                ("HOLD" ("WAITING") ("HOLD" . t))
                (done ("WAITING") ("HOLD"))
                ("TODO" ("WAITING") ("CANCELLED") ("HOLD"))
                ("NEXT" ("WAITING") ("CANCELLED") ("HOLD"))
                ("DONE" ("WAITING") ("CANCELLED") ("HOLD")))))

  (require 'smartparens-org)  ;; Additional org sp-local-pairs

  (setq org-directory "~/org/")

  ;; Log time when we re-schedule a task
  (setq org-log-reschedule 'time)
  ;; Always take note when marking task as done
  (setq org-log-done 'note)
  ;; and take note when re-scheduling a deadline
  (setq org-log-redeadline 'note)

  ;; Show org entities as UTF-8 characters (e.g. \sum as ∑)
  (setq org-pretty-entities t)
  ;; But Don't print "bar" as subscript in "foo_bar"
  (setq org-pretty-entities-include-sub-superscripts nil)
  ;; And also don't display ^ or _ as super/subscripts
  (setq org-use-sub-superscripts nil)
  ;; undone TODO entries will block switching the parent to DONE
  (setq org-enforce-todo-dependencies t)

  (setq org-use-fast-todo-selection t)

  ;; This allows changing todo states with S-left and S-right skipping all of the normal processing
  ;; when entering or leaving a todo state.
  ;; This cycles through the todo states but skips setting timestamps and entering notes which
  ;; is very convenient when all you want to do is fix up the status of an entry.
  (setq org-treat-S-cursor-todo-selection-as-state-change nil)

  (setq org-default-notes-file (concat org-directory "refile.org"))

  ;; From: https://stackoverflow.com/questions/17478260/completely-hide-the-properties-drawer-in-org-mode
  (defun org-cycle-hide-drawers (state)
    "Re-hide all drawers after a visibility state change."
    (when (and (derived-mode-p 'org-mode)
               (not (memq state '(overview folded contents))))
      (save-excursion
        (let* ((globalp (memq state '(contents all)))
               (beg (if globalp
                        (point-min)
                      (point)))
               (end (if globalp
                        (point-max)
                      (if (eq state 'children)
                          (save-excursion
                            (outline-next-heading)
                            (point))
                        (org-end-of-subtree t)))))
          (goto-char beg)
          (while (re-search-forward org-drawer-regexp end t)
            (save-excursion
              (beginning-of-line 1)
              (when (looking-at org-drawer-regexp)
                (let* ((start (1- (match-beginning 0)))
                       (limit
                        (save-excursion
                          (outline-next-heading)
                          (point)))
                       (msg (format
                             (concat
                              "org-cycle-hide-drawers:  "
                              "`:END:`"
                              " line missing at position %s")
                             (1+ start))))
                  (if (re-search-forward "^[ \t]*:END:" limit t)
                      (outline-flag-region start (point-at-eol) t)
                    (user-error msg))))))))))

  (defun org-hide-all-drawers ()
    "Hide all drawers"
    (interactive)
    (org-cycle-hide-drawers 'all))

  (defun prelude-org-mode-defaults ()
    (let ((oldmap (cdr (assoc 'prelude-mode minor-mode-map-alist)))
          (newmap (make-sparse-keymap)))
      (set-keymap-parent newmap oldmap)
      (define-key newmap (kbd "C-c +") nil)
      (define-key newmap (kbd "C-c -") nil)
      (define-key newmap (kbd "C-a") nil)  ; C-a is smarter in org-mode
      (define-key newmap [(control shift return)] nil)  ; C-S-return adds new TODO
      (make-local-variable 'minor-mode-overriding-map-alist)
      (push `(prelude-mode . ,newmap) minor-mode-overriding-map-alist)))
  (add-hook 'org-mode-hook 'prelude-org-mode-defaults)

  (require 'org-link-edit)
  (defun jk/unlinkify ()
    "Replace an org-link with the description, or if this is absent, the path."
    (interactive)
    (let ((eop (org-element-context)))
      (when (eq 'link (car eop))
        (message "%s" eop)
        (let* ((start (org-element-property :begin eop))
               (end (org-element-property :end eop))
               (contents-begin (org-element-property :contents-begin eop))
               (contents-end (org-element-property :contents-end eop))
               (path (org-element-property :path eop))
               (desc (and contents-begin
                          contents-end
                          (buffer-substring contents-begin contents-end))))
          (setf (buffer-substring start end)
                (concat (or desc path)
                        (make-string (org-element-property :post-blank eop) ?\s)))))))

  (define-key org-mode-map (kbd "C-c )")
    (defhydra hydra-org-link-edit (:color red)
      "Org Link Edit"
      (")" org-link-edit-forward-slurp "forward slurp")
      ("}" org-link-edit-forward-barf "forward barf")
      ("(" org-link-edit-backward-slurp "backward slurp")
      ("{" org-link-edit-backward-barf "backward barf")
      ("t" org-toggle-link-display "Toggle link display")
      ("r" jk/unlinkify "remove link")
      ("q" nil "cancel" :color blue)))

  ;; Targets include this file and any file contributing to the agenda - up to 9 levels deep
  (setq org-refile-targets '((nil :maxlevel . 9)
                             (org-agenda-files :maxlevel . 9)))

  ;; Allow refile to create parent tasks with confirmation
  (setq org-refile-allow-creating-parent-nodes (quote confirm))
  (setq org-refile-use-outline-path 'file)  ; Show filename for refiling
  (setq org-outline-path-complete-in-steps nil)  ; Refile in a single go

  ;; Exclude DONE state tasks from refile targets
  (defun org-refile-verify-refile-target ()
    "Exclude todo keywords with a done state from refile targets."
    (not (member (nth 2 (org-heading-components)) org-done-keywords)))

  (setq org-refile-target-verify-function #'org-refile-verify-refile-target)

  ;; automatically change the list bullets when you change list levels
  (setq org-list-demote-modify-bullet (quote (("+" . "-")
                                              ("*" . "-")
                                              ("1." . "-")
                                              ("1)" . "-")
                                              ("A)" . "-")
                                              ("B)" . "-")
                                              ("a)" . "-")
                                              ("b)" . "-")
                                              ("A." . "-")
                                              ("B." . "-")
                                              ("a." . "-")
                                              ("b." . "-"))))

  (setq org-todo-keywords
        (quote ((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
                (sequence "WAITING(w@/!)" "HOLD(h@/!)" "|" "CANCELLED(c@/!)" "PHONE" "MEETING"))))

  (setq org-todo-keyword-faces
        (quote (("TODO" :foreground "red" :weight bold)
                ("NEXT" :foreground "blue" :weight bold)
                ("DONE" :foreground "forest green" :weight bold)
                ("WAITING" :foreground "orange" :weight bold)
                ("HOLD" :foreground "magenta" :weight bold)
                ("CANCELLED" :foreground "forest green" :weight bold)
                ("MEETING" :foreground "forest green" :weight bold)
                ("PHONE" :foreground "forest green" :weight bold))))

  ;; Auto completion for symbols in org-mode
  ;; https://oremacs.com/2017/10/04/completion-at-point/
  (defun org-completion-symbols ()
    (when (looking-back "[`~=][a-zA-Z]+" nil)
      (let (cands)
        (save-match-data
          (save-excursion
            (goto-char (point-min))
            (while (re-search-forward "[`~=]\\([a-zA-Z.\\-_]+\\)[`~=]" nil t)
              (cl-pushnew
               (match-string-no-properties 0) cands :test 'equal))
            cands))
        (when cands
          (list (match-beginning 0) (match-end 0) cands)))))
  (defun ora-cap-filesystem ()
    (let (path)
      (when (setq path (ffap-string-at-point))
        (let ((compl
               (all-completions path #'read-file-name-internal)))
          (when compl
            (let ((offset (ivy-completion-common-length (car compl))))
              (list (- (point) offset) (point) compl)))))))

  ;; Custom org-sort to sort by TODO and then by priority
  ;; See: https://emacs.stackexchange.com/a/9588/12559
  (defun todo-to-int (todo)
    (first (-non-nil
            (mapcar (lambda (keywords)
                      (let ((todo-seq
                             (-map (lambda (x) (first (split-string  x "(")))
                                   (rest keywords))))
                        (cl-position-if (lambda (x) (string= x todo)) todo-seq)))
                    org-todo-keywords))))

  (defun my/org-sort-key ()
    (let* ((todo-max (apply #'max (mapcar #'length org-todo-keywords)))
           (todo (org-entry-get (point) "TODO"))
           (todo-int (if todo (todo-to-int todo) todo-max))
           (priority (org-entry-get (point) "PRIORITY"))
           (priority-int (if priority (string-to-char priority) org-default-priority)))
      (format "%03d %03d" todo-int priority-int)))

  (defun my/org-sort-entries ()
    (interactive)
    (org-sort-entries nil ?f #'my/org-sort-key))
  )

(use-package org-agenda
  :defer t
  :config
  (setq org-agenda-files '("~/org"))

  ;; Overwrite the current window with the agenda
  (setq org-agenda-window-setup 'current-window)

  ;; Do not dim blocked tasks
  (setq org-agenda-dim-blocked-tasks nil)

  ;; Compact the block agenda view
  (setq org-agenda-compact-blocks nil)

  ;; Agenda clock report parameters
  (setq org-agenda-clockreport-parameter-plist
        (quote (:link t :maxlevel 5 :fileskip0 t :compact nil :narrow 80)))

  ;; Agenda log mode items to display (closed and state changes by default)
  (setq org-agenda-log-mode-items (quote (closed state clock)))

  ;; Keep tasks with dates on the global todo lists
  (setq org-agenda-todo-ignore-with-date nil)

  ;; Keep tasks with deadlines on the global todo lists
  (setq org-agenda-todo-ignore-deadlines nil)

  ;; Keep tasks with scheduled dates on the global todo lists
  (setq org-agenda-todo-ignore-scheduled nil)

  ;; Keep tasks with timestamps on the global todo lists
  (setq org-agenda-todo-ignore-timestamp nil)

  ;; Remove completed deadline tasks from the agenda view
  (setq org-agenda-skip-deadline-if-done t)

  ;; Remove completed scheduled tasks from the agenda view
  (setq org-agenda-skip-scheduled-if-done t)

  ;; Remove completed items from search results
  (setq org-agenda-skip-timestamp-if-done t)

  ;; Include agenda archive files when searching for things
  (setq org-agenda-text-search-extra-files (quote (agenda-archives)))

  ;; Show all future entries for repeating tasks
  (setq org-agenda-repeating-timestamp-show-all t)

  ;; Show all agenda dates - even if they are empty
  (setq org-agenda-show-all-dates t)

  ;; Start the weekly agenda on Monday
  (setq org-agenda-start-on-weekday 1)

  ;; Use sticky agenda's so they persist
  ;;(setq org-agenda-sticky t)

  ;; Custom agenda command definitions
  (setq org-agenda-custom-commands
        (quote (("N" "Notes" tags "NOTE"
                 ((org-agenda-overriding-header "Notes")
                  (org-tags-match-list-sublevels t)))
                ("h" "Habits" tags-todo "STYLE=\"habit\""
                 ((org-agenda-overriding-header "Habits")
                  (org-agenda-sorting-strategy
                   '(todo-state-down effort-up category-keep))))
                (" " "Agenda"
                 ((agenda "" nil)
                  (tags "REFILE"
                        ((org-agenda-overriding-header "Tasks to Refile")
                         (org-tags-match-list-sublevels nil)))
                  (tags-todo "-CANCELLED/!"
                             ((org-agenda-overriding-header "Stuck Projects")
                              (org-agenda-skip-function 'bh/skip-non-stuck-projects)
                              (org-agenda-sorting-strategy
                               '(category-keep))))
                  (tags-todo "-HOLD-CANCELLED/!"
                             ((org-agenda-overriding-header "Projects")
                              (org-agenda-skip-function 'bh/skip-non-projects)
                              (org-tags-match-list-sublevels 'indented)
                              (org-agenda-sorting-strategy
                               '(category-keep))))
                  (tags-todo "-CANCELLED/!NEXT"
                             ((org-agenda-overriding-header (concat "Project Next Tasks"
                                                                    (if bh/hide-scheduled-and-waiting-next-tasks
                                                                        ""
                                                                      " (including WAITING and SCHEDULED tasks)")))
                              (org-agenda-skip-function 'bh/skip-projects-and-habits-and-single-tasks)
                              (org-tags-match-list-sublevels t)
                              (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                              (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
                              (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
                              (org-agenda-sorting-strategy
                               '(todo-state-down effort-up category-keep))))
                  (tags-todo "-REFILE-CANCELLED-WAITING-HOLD/!"
                             ((org-agenda-overriding-header (concat "Project Subtasks"
                                                                    (if bh/hide-scheduled-and-waiting-next-tasks
                                                                        ""
                                                                      " (including WAITING and SCHEDULED tasks)")))
                              (org-agenda-skip-function 'bh/skip-non-project-tasks)
                              (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                              (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
                              (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
                              (org-agenda-sorting-strategy
                               '(category-keep))))
                  (tags-todo "-REFILE-CANCELLED-WAITING-HOLD/!"
                             ((org-agenda-overriding-header (concat "Standalone Tasks"
                                                                    (if bh/hide-scheduled-and-waiting-next-tasks
                                                                        ""
                                                                      " (including WAITING and SCHEDULED tasks)")))
                              (org-agenda-skip-function 'bh/skip-project-tasks)
                              (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                              (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
                              (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
                              (org-agenda-sorting-strategy
                               '(category-keep))))
                  (tags-todo "-CANCELLED+WAITING|HOLD/!"
                             ((org-agenda-overriding-header (concat "Waiting and Postponed Tasks"
                                                                    (if bh/hide-scheduled-and-waiting-next-tasks
                                                                        ""
                                                                      " (including WAITING and SCHEDULED tasks)")))
                              (org-agenda-skip-function 'bh/skip-non-tasks)
                              (org-tags-match-list-sublevels nil)
                              (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                              (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)))
                  (tags "-REFILE/"
                        ((org-agenda-overriding-header "Tasks to Archive")
                         (org-agenda-skip-function 'bh/skip-non-archivable-tasks)
                         (org-tags-match-list-sublevels nil))))
                 nil))))
  ;; Limit restriction lock highlighting to the headline only
  (setq org-agenda-restriction-lock-highlight-subtree nil)

  ;; Sorting order for tasks on the agenda
  (setq org-agenda-sorting-strategy
        (quote ((agenda habit-down time-up user-defined-up effort-up category-keep)
                (todo category-up effort-up)
                (tags category-up effort-up)
                (search category-up))))

  ;; Enable display of the time grid so we can see the marker for the current time
  ;;(setq org-agenda-time-grid (quote ((daily today remove-match)
  ;;                                   #("----------------" 0 16 (org-heading t))
  ;;                                   (0900 1100 1300 1500 1700))))

  ;; Display tags farther right
  (setq org-agenda-tags-column -102)

  ;;
  ;; Agenda sorting functions
  ;;
  (setq org-agenda-cmp-user-defined 'bh/agenda-sort)

  (defmacro bh/agenda-sort-test (fn a b)
    "Test for agenda sort"
    `(cond
                                        ; if both match leave them unsorted
      ((and (apply ,fn (list ,a))
            (apply ,fn (list ,b)))
       (setq result nil))
                                        ; if a matches put a first
      ((apply ,fn (list ,a))
       (setq result -1))
                                        ; otherwise if b matches put b first
      ((apply ,fn (list ,b))
       (setq result 1))
                                        ; if none match leave them unsorted
      (t nil)))

  (defmacro bh/agenda-sort-test-num (fn compfn a b)
    `(cond
      ((apply ,fn (list ,a))
       (setq num-a (string-to-number (match-string 1 ,a)))
       (if (apply ,fn (list ,b))
           (progn
             (setq num-b (string-to-number (match-string 1 ,b)))
             (setq result (if (apply ,compfn (list num-a num-b))
                              -1
                            1)))
         (setq result -1)))
      ((apply ,fn (list ,b))
       (setq result 1))
      (t nil)))

  (defun bh/agenda-sort (a b)
    "Sorting strategy for agenda items.
Late deadlines first, then scheduled, then non-late deadlines"
    (let (result num-a num-b)
      (cond
       ;; time specific items are already sorted first by org-agenda-sorting-strategy

       ;; non-deadline and non-scheduled items next
       ((bh/agenda-sort-test 'bh/is-not-scheduled-or-deadline a b))

       ;; deadlines for today next
       ((bh/agenda-sort-test 'bh/is-due-deadline a b))

       ;; late deadlines next
       ((bh/agenda-sort-test-num 'bh/is-late-deadline '> a b))

       ;; scheduled items for today next
       ((bh/agenda-sort-test 'bh/is-scheduled-today a b))

       ;; late scheduled items next
       ((bh/agenda-sort-test-num 'bh/is-scheduled-late '> a b))

       ;; pending deadlines last
       ((bh/agenda-sort-test-num 'bh/is-pending-deadline '< a b))

       ;; finally default to unsorted
       (t (setq result nil)))
      result))
  )

(use-package ob
  :defer t
  :init
  ;; display/update images in the buffer after I evaluate
  (add-hook 'org-babel-after-execute-hook 'org-display-inline-images 'append)
  :config
  (setq org-confirm-babel-evaluate nil)  ; don't prompt me to confirm everytime I want to evaluate a block

  (defun org-babel-restart-session-to-point (&optional arg)
    "Restart session up to the src-block in the current point.
Goes to beginning of buffer and executes each code block with
`org-babel-execute-src-block' that has the same language and
session as the current block. ARG has same meaning as in
`org-babel-execute-src-block'."
    (interactive "P")
    (unless (org-in-src-block-p)
      (error "You must be in a src-block to run this command"))
    (let* ((current-point (point-marker))
           (info (org-babel-get-src-block-info))
           (lang (nth 0 info))
           (params (nth 2 info))
           (session (cdr (assoc :session params))))
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward org-babel-src-block-regexp nil t)
          ;; goto start of block
          (goto-char (match-beginning 0))
          (let* ((this-info (org-babel-get-src-block-info))
                 (this-lang (nth 0 this-info))
                 (this-params (nth 2 this-info))
                 (this-session (cdr (assoc :session this-params))))
            (when
                (and
                 (< (point) (marker-position current-point))
                 (string= lang this-lang)
                 (src-block-in-session-p session))
              (org-babel-execute-src-block arg)))
          ;; move forward so we can find the next block
          (forward-line)))))

  (defun org-babel-kill-session ()
    "Kill session for current code block."
    (interactive)
    (unless (org-in-src-block-p)
      (error "You must be in a src-block to run this command"))
    (save-window-excursion
      (org-babel-switch-to-session)
      (kill-buffer)))

  (defun org-babel-remove-result-buffer ()
    "Remove results from every code block in buffer."
    (interactive)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward org-babel-src-block-regexp nil t)
        (org-babel-remove-result))))


  ;; this adds a "new language" in babel that gets exported as js in html
  ;; https://www.reddit.com/r/orgmode/comments/5bi6ku/tip_for_exporting_javascript_source_block_to/
  (add-to-list 'org-src-lang-modes '("inline-js" . javascript))
  (defvar org-babel-default-header-args:inline-js
    '((:results . "html")
      (:exports . "results")))
  (defun org-babel-execute:inline-js (body _params)
    (format "<script type=\"text/javascript\">\n%s\n</script>" body))

  ;; Path when plantuml is installed from AUR (package `plantuml')
  (setq org-plantuml-jar-path "/opt/plantuml/plantuml.jar")

  ;; add all languages to org mode
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((C . t)
     ;;(R . t)
     (asymptote)
     (awk)
     (calc . t)
     (clojure)
     (comint)
     (css)
     (ditaa . t)
     (dot . t)
     (emacs-lisp . t)
     (fortran)
     (gnuplot . t)
     (haskell)
     (io)
     (java)
     (js . t)
     (latex)
     (ledger . t)
     (lilypond)
     (lisp)
     (lua)
     (matlab)
     (maxima)
     (mscgen)
     (ocaml)
     (octave . t)
     (org . t)
     (perl)
     (picolisp)
     (plantuml . t)
     (python . t)
     (ipython . t)
     (restclient . t)
     (ref)
     (ruby)
     (sass)
     (scala)
     (scheme)
     (screen)
     (shell . t)
     (shen)
     (snippet)
     (sql . t)
     (sqlite)))

  ;; Load personal library of babel
  (org-babel-lob-ingest (no-littering-expand-etc-file-name "library-of-babel.org")))

(use-package ob-restclient
  :after ob)

(use-package ob-ipython
  :after ob
  :config
  ;; Show multiple inline figures and results in one cell for ob-ipython.
  ;; http://kitchingroup.cheme.cmu.edu/blog/2017/01/29/ob-ipython-and-inline-figures-in-org-mode/
  ;; results must be in a drawer. So set a header like:
  ;; #+BEGIN_SRC ipython :session :results output drawer
  (defun ob-ipython-inline-image (b64-string)
    "Write the b64-string to a temporary file.
Returns an org-link to the file."
    (let* ((tfile (make-temp-file "ob-ipython-" nil ".png"))
           (link (format "[[file:%s]]" tfile)))
      (ob-ipython--write-base64-string tfile b64-string)
      link))

  (defun org-babel-execute:ipython (body params)
    "Execute a block of IPython code with Babel.
This function is called by `org-babel-execute-src-block'."
    (let* ((file (cdr (assoc :file params)))
           (session (cdr (assoc :session params)))
           (result-type (cdr (assoc :result-type params))))
      (org-babel-ipython-initiate-session session params)
      (-when-let (ret (ob-ipython--eval
                       (ob-ipython--execute-request
                        (org-babel-expand-body:generic (encode-coding-string body 'utf-8)
                                                       params (org-babel-variable-assignments:python params))
                        (ob-ipython--normalize-session session))))
        (let ((result (cdr (assoc :result ret)))
              (output (cdr (assoc :output ret))))
          (if (eq result-type 'output)
              (concat
               output
               (format "%s"
                       (mapconcat 'identity
                                  (loop for res in result
                                        if (eq 'image/png (car res))
                                        collect (ob-ipython-inline-image (cdr res)))
                                  "\n")))
            (ob-ipython--create-stdout-buffer output)
            (cond ((and file (string= (f-ext file) "png"))
                   (->> result (assoc 'image/png) cdr (ob-ipython--write-base64-string file)))
                  ((and file (string= (f-ext file) "svg"))
                   (->> result (assoc 'image/svg+xml) cdr (ob-ipython--write-string-to-file file)))
                  (file (error "%s is currently an unsupported file extension." (f-ext file)))
                  (t (->> result (assoc 'text/plain) cdr)))))))))

(use-package org-src
  :defer t
  :init
  (put 'org-src-preserve-indentation 'safe-local-variable 'booleanp)
  :config
  ;; Always split babel source window below.
  ;; Alternative is `current-window' to don't mess with window layout at all
  (setq org-src-window-setup 'split-window-below)

  (setq org-src-fontify-natively t)  ; syntax highlighting for source code blocks

  ;; Tab should do indent in code blocks
  (setq org-src-tab-acts-natively t)

  ;; Don't remove (or add) any extra whitespace
  (setq org-src-preserve-indentation nil)
  (setq org-edit-src-content-indentation 0)

;;; Some helper function to manage org-babel sessions

  (defun src-block-in-session-p (&optional name)
    "Return if src-block is in a session of NAME.
NAME may be nil for unnamed sessions."
    (let* ((info (org-babel-get-src-block-info))
           ;;(lang (nth 0 info))
           ;;(body (nth 1 info))
           (params (nth 2 info))
           (session (cdr (assoc :session params))))

      (cond
       ;; unnamed session, both name and session are nil
       ((and (null session)
             (null name))
        t)
       ;; Matching name and session
       ((and
         (stringp name)
         (stringp session)
         (string= name session))
        t)
       ;; no match
       (t nil))))

  ;; dot == graphviz-dot
  (add-to-list 'org-src-lang-modes '("dot" . graphviz-dot))

  ;; Add 'conf-mode' to org-babel
  (add-to-list 'org-src-lang-modes '("ini" . conf))
  (add-to-list 'org-src-lang-modes '("conf" . conf))

  (add-to-list 'org-src-lang-modes '("web" . web))
  (define-derived-mode web-django-mode web-mode "WebDjango"
    "Major mode for editing web-mode django templates."
    (web-mode)
    (web-mode-set-engine "django")))

(use-package org-indent
  :hook (org-mode . org-indent-mode))

(use-package org-bullets
  :hook (org-mode . org-bullets-mode))

(use-package org-protocol :after org)
;; org-capture chrome plugin: https://chrome.google.com/webstore/detail/org-capture/kkkjlfejijcjgjllecmnejhogpbcigdc?hl=en

(use-package org-capture
  :bind ("C-c c" . org-capture)
  :config
  ;; Capture/refile new items to the top of the list
  (setq org-reverse-note-order t)
  ;; Capture templates for: TODO tasks, Notes, appointments, phone calls, meetings, and org-protocol
  (setq org-capture-templates
        `(("t" "todo" entry (file ,(concat org-directory "refile.org"))
           "* TODO %?\n%U\n" :clock-in t :clock-resume t)
          ("T" "todo with link" entry (file ,(concat org-directory "refile.org"))
           "* TODO %?\n%U\n%a\n" :clock-in t :clock-resume t)
          ("e" "email" entry (file ,(concat org-directory "refile.org"))
           "* TODO %? Email: %:from on %:subject\nSCHEDULED: %t\n%U\n%a\n"
           :clock-in t :clock-resume t :immediate-finish nil)
          ("j" "Journal entry" entry (file+datetree ,(concat org-directory "journal.org"))
           "* %?\n%U\n" :clock-in t :clock-resume t)
          ("J" "Journal with link" entry (file+datetree ,(concat org-directory "journal.org"))
           "* %?\n%U\n%a\n" :clock-in t :clock-resume t)
          ("r" "respond" entry (file ,(concat org-directory "refile.org"))
           "* TODO Respond to %:from on %:subject\nSCHEDULED: %t\n%U\n%a\n" :clock-in t :clock-resume t :immediate-finish t)
          ("n" "note" entry (file ,(concat org-directory "refile.org"))
           "* %? :NOTE:\n%U\n%a\n" :clock-in t :clock-resume t)
          ("w" "org-protocol" entry (file ,(concat org-directory "refile.org"))
           "* TODO Review %c\n%U\n" :immediate-finish t)
          ("m" "Meeting" entry (file ,(concat org-directory "refile.org"))
           "* MEETING with %? :MEETING:\n%U" :clock-in t :clock-resume t)
          ("c" "Code Review" entry (file+headline ,(concat org-directory "refile.org") "Code Review")
           "* TODO %?\n  %i")
          ("P" "Phone call" entry (file ,(concat org-directory "refile.org"))
           "* PHONE %? :PHONE:\n%U" :clock-in t :clock-resume t)
          ("p" "Protocol" entry (file ,(concat org-directory "refile.org"))
           "* %^{Title}\nSource: %u, %c\n #+BEGIN_QUOTE\n%i\n#+END_QUOTE\n\n\n%?")
          ("L" "Protocol Link" entry (file ,(concat org-directory "refile.org"))
           "* %?\n[[%:link][%:description]]\n")
          ("w" "Web site" entry (file "")
           "* %a :website:\n\n%U %?\n\n%:initial")
          ("h" "Habit" entry (file ,(concat org-directory "refile.org"))
           "* NEXT %?\n%U\n%a\nSCHEDULED: %(format-time-string \"%<<%Y-%m-%d %a .+1d/3d>>\")\n:PROPERTIES:\n:STYLE: habit\n:REPEAT_TO_STATE: NEXT\n:END:\n")))
  )

(use-package noflet :defer t)  ; let you locally overwrite functions

(use-package orca
  :disabled t
  :after org-capture
  :config
  (setq orca-handler-list
        `((orca-handler-match-url
           "https://www.reddit.com/r/emacs"
           ,(concat org-directory "refile.org") "\\* Reddit")
          (orca-handler-match-url
           "https://emacs.stackexchange.com/"
           ,org-default-notes-file "\\* Questions")
          (orca-handler-file
           ,org-default-notes-file "\\* Refile")))
  ;; To capture in current open org buffer:
  ;;(push '(orca-handler-current-buffer "\\* Tasks") orca-handler-list)
  )

;; FIXME: install bookmarklet and shell script (integrate with org-capture plugin?!)
(use-package org-protocol-capture-html
  :disabled t  ; Usefule but never used since bookmarklet not configured yet
  :after org-capture)

;;; Clock Setup
(use-package org-clock
  :after org
  :init
  ;; FIXME: remove unused bh functions?
  (setq bh/keep-clock-running nil)

  (defun bh/clock-in-last-task (arg)
    "Clock in the interrupted task if there is one
Skip the default task and get the next one.
A prefix arg forces clock in of the default task."
    (interactive "p")
    (let ((clock-in-to-task
           (cond
            ((eq arg 4) org-clock-default-task)
            ((and (org-clock-is-active)
                  (equal org-clock-default-task (cadr org-clock-history)))
             (caddr org-clock-history))
            ((org-clock-is-active) (cadr org-clock-history))
            ((equal org-clock-default-task (car org-clock-history)) (cadr org-clock-history))
            (t (car org-clock-history)))))
      (widen)
      (org-with-point-at clock-in-to-task
        (org-clock-in nil))))

  (defun bh/clock-in-to-next (kw)
    "Switch a task from TODO to NEXT when clocking in.
Skips capture tasks, projects, and subprojects.
Switch projects and subprojects from NEXT back to TODO"
    (when (not (and (boundp 'org-capture-mode) org-capture-mode))
      (cond
       ((and (member (org-get-todo-state) (list "TODO"))
             (bh/is-task-p))
        "NEXT")
       ((and (member (org-get-todo-state) (list "NEXT"))
             (bh/is-project-p))
        "TODO"))))

  (defun bh/find-project-task ()
    "Move point to the parent (project) task if any"
    (save-restriction
      (widen)
      (let ((parent-task (save-excursion (org-back-to-heading 'invisible-ok) (point))))
        (while (org-up-heading-safe)
          (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
            (setq parent-task (point))))
        (goto-char parent-task)
        parent-task)))

  (defun bh/punch-in (arg)
    "Start continuous clocking and set the default task to the
selected task.  If no task is selected set the Organization task
as the default task."
    (interactive "p")
    (setq bh/keep-clock-running t)
    (if (equal major-mode 'org-agenda-mode)
        ;;
        ;; We're in the agenda
        ;;
        (let* ((marker (org-get-at-bol 'org-hd-marker))
               (tags (org-with-point-at marker (org-get-tags))))
          (if (and (eq arg 4) tags)
              (org-agenda-clock-in '(16))
            (bh/clock-in-organization-task-as-default)))
      ;;
      ;; We are not in the agenda
      ;;
      (save-restriction
        (widen)
                                        ; Find the tags on the current task
        (if (and (equal major-mode 'org-mode) (not (org-before-first-heading-p)) (eq arg 4))
            (org-clock-in '(16))
          (bh/clock-in-organization-task-as-default)))))

  (defun bh/punch-out ()
    (interactive)
    (setq bh/keep-clock-running nil)
    (when (org-clock-is-active)
      (org-clock-out))
    (org-agenda-remove-restriction-lock))

  (defun bh/clock-in-default-task ()
    (save-excursion
      (org-with-point-at org-clock-default-task
        (org-clock-in))))

  (defun bh/clock-in-parent-task ()
    "Move point to the parent (project) task if any and clock in"
    (let ((parent-task))
      (save-excursion
        (save-restriction
          (widen)
          (while (and (not parent-task) (org-up-heading-safe))
            (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
              (setq parent-task (point))))
          (if parent-task
              (org-with-point-at parent-task
                (org-clock-in))
            (when bh/keep-clock-running
              (bh/clock-in-default-task)))))))

  (defvar bh/organization-task-id "f2088c3f-8452-4221-b63e-fbd9fb83089f")

  (defun bh/clock-in-organization-task-as-default ()
    (interactive)
    (org-with-point-at (org-id-find bh/organization-task-id 'marker)
      (org-clock-in '(16))))

  (defun bh/clock-out-maybe ()
    (when (and bh/keep-clock-running
               (not org-clock-clocking-in)
               (marker-buffer org-clock-default-task)
               (not org-clock-resolving-clocks-due-to-idleness))
      (bh/clock-in-parent-task)))

  (add-hook 'org-clock-out-hook 'bh/clock-out-maybe 'append)

  :config
  ;; Install `xprintidle' to get idle time over all X11. Otherwise it's only Emacs idle time.
  (setq org-clock-idle-time 15)  ; idle after 15 minutes

  ;;(setq org-clock-continuously t)  ; Start clocking from the last clock-out time, if any.

  ;; Show lot of clocking history so it's easy to pick items off the C-F11 list
  (setq org-clock-history-length 23)

  ;; Save the running clock and all clock history when exiting Emacs, load it on startup
  (setq org-clock-persist t)
  (org-clock-persistence-insinuate)

  ;; org-clock-display (C-c C-x C-d) shows times for this month by default
  (setq org-clock-display-default-range 'thismonth)

  ;; Only show the current clocked time in mode line (not all)
  (setq org-clock-mode-line-total 'current)

  ;; Clocktable (C-c C-x C-r) defaults
  ;; Use fixed month instead of (current-month) because I want to keep a table for each month
  (setq org-clock-clocktable-default-properties
        `(:block ,(format-time-string "%Y-%m") :scope file-with-archives))

  ;; Clocktable (reporting: r) in the agenda
  (setq org-clocktable-defaults
        '(:maxlevel 3 :lang "en" :scope file-with-archives
          :wstart 1 :mstart 1 :tstart nil :tend nil :step nil :stepskip0 nil :fileskip0 nil
          :tags nil :emphasize nil :link t :narrow 70! :indent t :formula nil :timestamp nil
          :level nil :tcolumns nil :formatter nil))

  ;; Resume clocking task on clock-in if the clock is open
  (setq org-clock-in-resume t)
  ;; Change tasks to NEXT when clocking in
  (setq org-clock-in-switch-to-state 'bh/clock-in-to-next)
  ;; Separate drawers for clocking and logs
  (setq org-drawers (quote ("PROPERTIES" "LOGBOOK")))
  ;; Save clock data and state changes and notes in the LOGBOOK drawer
  (setq org-clock-into-drawer t)
  ;; Log all State changes to drawer
  (setq org-log-into-drawer t)
  ;; make time editing use discrete minute intervals (no rounding) increments
  (setq org-time-stamp-rounding-minutes (quote (1 1)))
  ;; Sometimes I change tasks I'm clocking quickly - this removes clocked tasks with 0:00 duration
  (setq org-clock-out-remove-zero-time-clocks t)
  ;; Don't clock out when moving task to a done state
  (setq org-clock-out-when-done nil)

  ;; Enable auto clock resolution for finding open clocks
  (setq org-clock-auto-clock-resolution (quote when-no-clock-is-running))
  ;; Include current clocking task in clock reports
  (setq org-clock-report-include-clocking-task t))

(use-package org-crypt
  :defer t
  :config
  ;; Encrypt all entries before saving
  (org-crypt-use-before-save-magic)
  (setq org-tags-exclude-from-inheritance (quote ("crypt")))
  ;; GPG key to use for encryption
  (setq org-crypt-key "C1C8D63F884EF9C9")
  ;; don't ask to disable auto-save
  (setq org-crypt-disable-auto-save nil))

(use-package ox
  :commands org-formatted-copy
  ;;:bind ("C-c e" . org-formatted-copy)
  :config
  ;; copy org text as rich text
  (defun org-formatted-copy ()
    "Export region to HTML, and copy it to the clipboard."
    (interactive)
    (save-window-excursion
      (let* ((buf (org-export-to-buffer 'html "*Formatted Copy*" nil nil t t))
             (_html (with-current-buffer buf (buffer-string))))
        (with-current-buffer buf
          (shell-command-on-region
           (point-min)
           (point-max)
           "xclip -selection clipboard -t 'text/html' -i"))
        (kill-buffer buf))))

  ;; FIXME: This is only a hack as I do NOT want the tags INSIDE the h3 title tag
  (defun my-hack-org-html-format-headline-function
      (todo _todo-type priority text tags info)
    "Default format function for a headline.
See `org-html-format-headline-function' for details."
    (let ((todo (org-html--todo todo info))
	  (priority (org-html--priority priority info))
	  (tags (org-html--tags tags info)))
      (concat todo (and todo " ")
	      priority (and priority " ")
	      text
	      (and tags "&#xa0;&#xa0;&#xa0;</h3><p>") tags (and tags "</p><h3>"))))
  (setq org-html-format-headline-function #'my-hack-org-html-format-headline-function)

  ;; Use html5 as org export and use new tags (I don't care about browsers <=IE8)
  (setq org-html-doctype "html5")
  (setq org-html-html5-fancy t)
  ;; Don't add html footer to export
  (setq org-html-postamble nil)
  ;; Don't export ^ or _ as super/subscripts
  (setq org-export-with-sub-superscripts nil))

;; Export blog posts to hugo
(use-package ox-hugo
  :after ox)

;; Jira export (then copy&paste to ticket)
(use-package ox-jira
  :after ox)

;; Github markdown
(use-package ox-gfm
  :after ox)

;; reStructuredText
(use-package ox-rst
  :after ox)

(use-package org-habit
  :after org)

(use-package org-man
  :after org
  :config
  (setq org-man-command 'woman))  ; open org-link man pages with woman

(use-package org-expiry
  :after org
  :config
  (setq org-expiry-inactive-timestamps t)
  (org-expiry-insinuate))

(use-package org-id
  :after org
  :config (setq org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id))

(use-package org-table
  :after org
  :config
  ;; FIXME: Maybe just bind key to mark cell and M-f M-b to cell forward/backwards.
  ;; no hydra needed

  ;; Nice org table navigation (and easy copy etc from cells)
  ;; https://github.com/kaushalmodi/.emacs.d/blob/ea60f986d58b27f45d510cde1148bf6d52e10dda/setup-files/setup-org.el#L1041-L1080
  ;;;; Table Field Marking
  (defun org-table-mark-field ()
    "Mark the current table field."
    (interactive)
    ;; Do not try to jump to the beginning of field if the point is already there
    (when (not (looking-back "|[[:blank:]]?" nil))
      (org-table-beginning-of-field 1))
    (set-mark-command nil)
    (org-table-end-of-field 1))

  (defhydra hydra-org-table-mark-field
    (:body-pre (org-table-mark-field)
     :color red
     :hint nil)
    "
   ^^      ^🠙^     ^^
   ^^      _p_     ^^
🠘 _b_  selection  _f_ 🠚          | Org table mark ▯field▮ |
   ^^      _n_     ^^
   ^^      ^🠛^     ^^
"
    ("x" exchange-point-and-mark "exchange point/mark")
    ("f" (lambda (arg)
           (interactive "p")
           (when (eq 1 arg)
             (setq arg 2))
           (org-table-end-of-field arg)))
    ("b" (lambda (arg)
           (interactive "p")
           (when (eq 1 arg)
             (setq arg 2))
           (org-table-beginning-of-field arg)))
    ("n" next-line)
    ("p" previous-line)
    ("q" nil "cancel" :color blue))

  (bind-keys
   :map org-mode-map
   :filter (org-at-table-p)
   ("S-SPC" . hydra-org-table-mark-field/body)))

(use-package org-pomodoro
  :defer t
  :init
  ;; called with i3status-rs in ~/.config/i3/status.toml with
  ;; command = "emacsclient --eval '(dakra/org-pomodoro-i3-bar-time)' || echo 'Emacs daemon not started'"
  (defun dakra/org-pomodoro-i3-bar-time ()
    "Display remaining pomodoro time in i3 status bar."
    (if (org-pomodoro-active-p)
        (format "Pomodoro: %d minutes - %s" (/ org-pomodoro-countdown 60) org-clock-heading)
      (if (org-clock-is-active)
          (org-no-properties (org-clock-get-clock-string))
        "No active pomodoro or task")))

  :config
  ;; Don't delete already clocked time when killing a running pomodoro
  (setq org-pomodoro-keep-killed-pomodoro-time t)
  ;; Never clock-out automatically
  (setq org-pomodoro-clock-always t))

(use-package org-jira
  :defer t
  :config
  (setq jiralib-url "https://jira.paesslergmbh.de")
  ;; Don't sync anything back to jira
  (setq org-jira-deadline-duedate-sync-p nil)
  (setq org-jira-worklog-sync-p nil))

(use-package org-github
  :defer t
  :config
  (setq org-github-default-owner "atomx")
  (setq org-github-default-name "api"))

(use-package orgit
  ;; Automatically copy orgit link to last commit after commit
  :hook (git-commit-setup . orgit-store-after-commit)
  :config
  (defun orgit-store-after-commit ()
    "Store orgit-link for latest commit after commit message editor is finished."
    (add-hook 'with-editor-post-finish-hook
              (lambda ()
                (sleep-for 0.5)  ;; See https://github.com/magit/orgit/issues/19
                (let* ((repo (abbreviate-file-name default-directory))
                       (rev (magit-git-string "rev-parse" "HEAD"))
                       (link (format "orgit-rev:%s::%s" repo rev))
                       (summary (substring-no-properties (magit-format-rev-summary rev)))
                       (desc (format "%s (%s)" summary repo)))
                  (push (list link desc) org-stored-links)))
              t t)))

(use-package counsel-org-clock
  :defer t)

(defun bh/is-project-p ()
  "Any task with a todo keyword subtask"
  (save-restriction
    (widen)
    (let ((has-subtask)
          (subtree-end (save-excursion (org-end-of-subtree t)))
          (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
      (save-excursion
        (forward-line 1)
        (while (and (not has-subtask)
                    (< (point) subtree-end)
                    (re-search-forward "^\*+ " subtree-end t))
          (when (member (org-get-todo-state) org-todo-keywords-1)
            (setq has-subtask t))))
      (and is-a-task has-subtask))))

(defun bh/is-project-subtree-p ()
  "Any task with a todo keyword that is in a project subtree.
Callers of this function already widen the buffer view."
  (let ((task (save-excursion (org-back-to-heading 'invisible-ok)
                              (point))))
    (save-excursion
      (bh/find-project-task)
      (if (equal (point) task)
          nil
        t))))

(defun bh/is-task-p ()
  "Any task with a todo keyword and no subtask"
  (save-restriction
    (widen)
    (let ((has-subtask)
          (subtree-end (save-excursion (org-end-of-subtree t)))
          (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
      (save-excursion
        (forward-line 1)
        (while (and (not has-subtask)
                    (< (point) subtree-end)
                    (re-search-forward "^\*+ " subtree-end t))
          (when (member (org-get-todo-state) org-todo-keywords-1)
            (setq has-subtask t))))
      (and is-a-task (not has-subtask)))))

(defun bh/is-subproject-p ()
  "Any task which is a subtask of another project"
  (let ((is-subproject)
        (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
    (save-excursion
      (while (and (not is-subproject) (org-up-heading-safe))
        (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
          (setq is-subproject t))))
    (and is-a-task is-subproject)))

(defun bh/list-sublevels-for-projects-indented ()
  "Set org-tags-match-list-sublevels so when restricted to a subtree we list all subtasks.
  This is normally used by skipping functions where this variable is already local to the agenda."
  (if (marker-buffer org-agenda-restrict-begin)
      (setq org-tags-match-list-sublevels 'indented)
    (setq org-tags-match-list-sublevels nil))
  nil)

(defun bh/list-sublevels-for-projects ()
  "Set org-tags-match-list-sublevels so when restricted to a subtree we list all subtasks.
  This is normally used by skipping functions where this variable is already local to the agenda."
  (if (marker-buffer org-agenda-restrict-begin)
      (setq org-tags-match-list-sublevels t)
    (setq org-tags-match-list-sublevels nil))
  nil)

(defvar bh/hide-scheduled-and-waiting-next-tasks t)

(defun bh/toggle-next-task-display ()
  (interactive)
  (setq bh/hide-scheduled-and-waiting-next-tasks (not bh/hide-scheduled-and-waiting-next-tasks))
  (when  (equal major-mode 'org-agenda-mode)
    (org-agenda-redo))
  (message "%s WAITING and SCHEDULED NEXT Tasks" (if bh/hide-scheduled-and-waiting-next-tasks "Hide" "Show")))

(defun bh/skip-stuck-projects ()
  "Skip trees that are not stuck projects"
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (if (bh/is-project-p)
          (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
                 (has-next ))
            (save-excursion
              (forward-line 1)
              (while (and (not has-next) (< (point) subtree-end) (re-search-forward "^\\*+ NEXT " subtree-end t))
                (unless (member "WAITING" (org-get-tags))
                  (setq has-next t))))
            (if has-next
                nil
              next-headline)) ; a stuck project, has subtasks but no next task
        nil))))

(defun bh/skip-non-stuck-projects ()
  "Skip trees that are not stuck projects"
  ;; (bh/list-sublevels-for-projects-indented)
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (if (bh/is-project-p)
          (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
                 (has-next ))
            (save-excursion
              (forward-line 1)
              (while (and (not has-next) (< (point) subtree-end) (re-search-forward "^\\*+ NEXT " subtree-end t))
                (unless (member "WAITING" (org-get-tags))
                  (setq has-next t))))
            (if has-next
                next-headline
              nil)) ; a stuck project, has subtasks but no next task
        next-headline))))

(defun bh/skip-non-projects ()
  "Skip trees that are not projects"
  ;; (bh/list-sublevels-for-projects-indented)
  (if (save-excursion (bh/skip-non-stuck-projects))
      (save-restriction
        (widen)
        (let ((subtree-end (save-excursion (org-end-of-subtree t))))
          (cond
           ((bh/is-project-p)
            nil)
           ((and (bh/is-project-subtree-p) (not (bh/is-task-p)))
            nil)
           (t
            subtree-end))))
    (save-excursion (org-end-of-subtree t))))

(defun bh/skip-non-tasks ()
  "Show non-project tasks.
Skip project and sub-project tasks, habits, and project related tasks."
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
       ((bh/is-task-p)
        nil)
       (t
        next-headline)))))

(defun bh/skip-project-trees-and-habits ()
  "Skip trees that are projects"
  (save-restriction
    (widen)
    (let ((subtree-end (save-excursion (org-end-of-subtree t))))
      (cond
       ((bh/is-project-p)
        subtree-end)
       ((org-is-habit-p)
        subtree-end)
       (t
        nil)))))

(defun bh/skip-projects-and-habits-and-single-tasks ()
  "Skip trees that are projects, tasks that are habits, single non-project tasks"
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
       ((org-is-habit-p)
        next-headline)
       ((and bh/hide-scheduled-and-waiting-next-tasks
             (member "WAITING" (org-get-tags)))
        next-headline)
       ((bh/is-project-p)
        next-headline)
       ((and (bh/is-task-p) (not (bh/is-project-subtree-p)))
        next-headline)
       (t
        nil)))))

(defun bh/skip-project-tasks-maybe ()
  "Show tasks related to the current restriction.
When restricted to a project, skip project and sub project tasks, habits, NEXT tasks, and loose tasks.
When not restricted, skip project and sub-project tasks, habits, and project related tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
           (next-headline (save-excursion (or (outline-next-heading) (point-max))))
           (limit-to-project (marker-buffer org-agenda-restrict-begin)))
      (cond
       ((bh/is-project-p)
        next-headline)
       ((org-is-habit-p)
        subtree-end)
       ((and (not limit-to-project)
             (bh/is-project-subtree-p))
        subtree-end)
       ((and limit-to-project
             (bh/is-project-subtree-p)
             (member (org-get-todo-state) (list "NEXT")))
        subtree-end)
       (t
        nil)))))

(defun bh/skip-project-tasks ()
  "Show non-project tasks.
Skip project and sub-project tasks, habits, and project related tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t))))
      (cond
       ((bh/is-project-p)
        subtree-end)
       ((org-is-habit-p)
        subtree-end)
       ((bh/is-project-subtree-p)
        subtree-end)
       (t
        nil)))))

(defun bh/skip-non-project-tasks ()
  "Show project tasks.
Skip project and sub-project tasks, habits, and loose non-project tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
           (next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
       ((bh/is-project-p)
        next-headline)
       ((org-is-habit-p)
        subtree-end)
       ((and (bh/is-project-subtree-p)
             (member (org-get-todo-state) (list "NEXT")))
        subtree-end)
       ((not (bh/is-project-subtree-p))
        subtree-end)
       (t
        nil)))))

(defun bh/skip-projects-and-habits ()
  "Skip trees that are projects and tasks that are habits"
  (save-restriction
    (widen)
    (let ((subtree-end (save-excursion (org-end-of-subtree t))))
      (cond
       ((bh/is-project-p)
        subtree-end)
       ((org-is-habit-p)
        subtree-end)
       (t
        nil)))))

(defun bh/skip-non-subprojects ()
  "Skip trees that are not projects"
  (let ((next-headline (save-excursion (outline-next-heading))))
    (if (bh/is-subproject-p)
        nil
      next-headline)))

;; Show 20 minute clocking gaps. Hit "v c" in the agenda view
(setq org-agenda-clock-consistency-checks
      '(:max-duration "4:00"
        :min-duration 0
        :max-gap 30
        :gap-ok-around ("4:00" "11:00" "19:00" "20:00" "21:00")))

(defun bh/widen ()
  (interactive)
  (if (equal major-mode 'org-agenda-mode)
      (progn
        (org-agenda-remove-restriction-lock)
        (when org-agenda-sticky
          (org-agenda-redo)))
    (widen)))

(add-hook 'org-agenda-mode-hook
          '(lambda () (org-defkey org-agenda-mode-map "W" (lambda () (interactive) (setq bh/hide-scheduled-and-waiting-next-tasks t) (bh/widen))))
          'append)

(defun bh/skip-non-archivable-tasks ()
  "Skip trees that are not available for archiving."
  (save-restriction
    (widen)
    ;; Consider only tasks with done todo headings as archivable candidates
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max))))
          (subtree-end (save-excursion (org-end-of-subtree t))))
      (if (member (org-get-todo-state) org-todo-keywords-1)
          (if (member (org-get-todo-state) org-done-keywords)
              (let* ((daynr (string-to-number (format-time-string "%d" (current-time))))
                     (a-month-ago (* 60 60 24 (+ daynr 1)))
                     (last-month (format-time-string "%Y-%m-" (time-subtract (current-time) (seconds-to-time a-month-ago))))
                     (this-month (format-time-string "%Y-%m-" (current-time)))
                     (subtree-is-current (save-excursion
                                           (forward-line 1)
                                           (and (< (point) subtree-end)
                                                (re-search-forward (concat last-month "\\|" this-month) subtree-end t)))))
                (if subtree-is-current
                    subtree-end ; Has a date in this month or last month, skip it
                  nil))  ; available to archive
            (or subtree-end (point-max)))
        next-headline))))

(defun bh/is-not-scheduled-or-deadline (date-str)
  (and (not (bh/is-deadline date-str))
       (not (bh/is-scheduled date-str))))

(defun bh/is-due-deadline (date-str)
  (string-match "Deadline:" date-str))

(defun bh/is-late-deadline (date-str)
  (string-match "\\([0-9]*\\) d\. ago:" date-str))

(defun bh/is-pending-deadline (date-str)
  (string-match "In \\([^-]*\\)d\.:" date-str))

(defun bh/is-deadline (date-str)
  (or (bh/is-due-deadline date-str)
      (bh/is-late-deadline date-str)
      (bh/is-pending-deadline date-str)))

(defun bh/is-scheduled (date-str)
  (or (bh/is-scheduled-today date-str)
      (bh/is-scheduled-late date-str)))

(defun bh/is-scheduled-today (date-str)
  (string-match "Scheduled:" date-str))

(defun bh/is-scheduled-late (date-str)
  (string-match "Sched\.\\(.*\\)x:" date-str))

(use-package erc
  :config
  (setq erc-hide-list '("PART" "QUIT" "JOIN"))
  (setq erc-autojoin-channels-alist '(("freenode.net"
                                       "#emacs"
                                       "#pyramid")))
  (setq erc-server "irc.freenode.net")
  (setq erc-nick "dakra")
  (setq erc-user-full-name user-full-name)
  (setq erc-prompt-for-password nil)

  (add-to-list 'erc-modules 'notifications)
  (add-to-list 'erc-modules 'spelling)
  (erc-update-modules)
  (erc-track-minor-mode 1)
  (erc-track-mode 1))

(use-package erc-hl-nicks
  :after erc)

(use-package erc-services
  :after erc
  :config
  (setq erc-prompt-for-nickserv-password nil)
  (setq erc-nickserv-passwords
        `((freenode(("dakra" . ,(auth-source-pick-first-password :host erc-server :login erc-nick)))))))

;; mu package (includes mu4e) must be installed in the system
(use-package mu4e
  ;; Open mu4e with the 'Mail' key (if your keyboard has one)
  :bind (("<XF86Mail>" . mu4e)
         :map mu4e-headers-mode-map
         ("TAB" . mu4e-headers-next-unread)
         ("d" . my-move-to-trash)
         ("D" . my-move-to-trash)
         ("M" . mu4e-headers-mark-all-unread-read) ; Mark all as read
         :map mu4e-view-mode-map
         ("n" . mu4e-scroll-up)
         ("p" . mu4e-scroll-down)
         ("N" . mu4e-view-headers-next)
         ("P" . mu4e-view-headers-prev)
         ("d" . my-move-to-trash)
         ("D" . my-move-to-trash))
  :init
  ;; Use completing-read (which is ivy) instead of ido
  (setq mu4e-completing-read-function 'completing-read)

  ;; set mu4e as default mail client
  (setq mail-user-agent 'mu4e-user-agent)

  ;; Always use local smtp server (msmtp in my case) to send mails
  (setq send-mail-function 'sendmail-send-it
        sendmail-program "~/bin/msmtp-enqueue.sh"
        mail-specify-envelope-from t
        message-sendmail-f-is-evil nil
        mail-envelope-from 'header
        message-sendmail-envelope-from 'header)
  :config
  ;; gmail delete == move mail to trash folder
  (fset 'my-move-to-trash "mt")

  ;; Fix mu4e highlighting in moe-dark theme
  (set-face-attribute 'mu4e-header-highlight-face nil :background "#626262" :foreground "#eeeeee")

  ;;; Save attachment (this can also be a function)
  (setq-default mu4e-attachment-dir "~/Downloads")

  ;; When saving multiple attachments (C-u prefix) save all in same directory
  ;; without asking for the location of every attachment
  (setq-default mu4e-save-multiple-attachments-without-asking t)

  ;; Always display plain text messages.
  (setq mu4e-view-html-plaintext-ratio-heuristic most-positive-fixnum)

  (setq mu4e-msg2pdf "/usr/bin/msg2pdf")  ; to display html messages as pdf

  ;; Show additional user-agent header
  (setq-default mu4e-view-fields
                '(:from :to :cc :subject :flags :date :maildir :user-agent :mailing-list
                  :tags :attachments :signature :decryption))

  ;; Attach file with helm-locate
  ;;(helm-add-action-to-source "Attach to Email" #'mml-attach-file helm-source-locate)

  ;; default
  (setq-default mu4e-maildir "~/Maildir")
  (setq-default mu4e-drafts-folder "/private/Drafts")
  (setq-default mu4e-sent-folder   "/private/Sent")
  (setq-default mu4e-trash-folder  "/private/Trash")

  ;; Setup some handy shortcuts
  ;; you can quickly switch to your Inbox -- press ``ji''
  ;; then, when you want archive some messages, move them to
  ;; the 'All Mail' folder by pressing ``ma''.

  (setq mu4e-maildir-shortcuts
        '(("/private/Inbox"      . ?i)
          ("/private/Sent"       . ?s)
          ("/private/Trash"      . ?t)
          ("/private/Drafts"     . ?d)
          ("/private/Archive"   . ?a)))

  ;; Dynamically refile
  ;; See: https://www.djcbsoftware.nl/code/mu/mu4e/Smart-refiling.html#Smart-refiling
  (defun dakra-mu4e-private-refile (msg)
    (cond
     ;; refile all messages from Uber to the 'uber' folder
     ((mu4e-message-contact-field-matches msg :from "@uber\\.com")
      "/private/uber")
     ;; important to have a catch-all at the end!
     (t  "/private/Archive")))

  (setq-default mu4e-refile-folder 'dakra-mu4e-private-refile)

  ;; Don't show duplicate mails when searching
  (setq-default mu4e-headers-skip-duplicates t)

  ;; Show email address as well and not only the name
  (setq-default mu4e-view-show-addresses t)

  ;; Don't show related messages by default.
  ;; Activate with 'W' on demand
  (setq-default mu4e-headers-include-related nil)

  ;; Don't ask to quit
  (setq-default mu4e-confirm-quit nil)

  ;; Don't spam the minibuffer with 'Indexing...' messages
  (setq-default mu4e-hide-index-messages t)

  ;; Always update in background otherwise mu4e manipulates the window layout
  ;; when the update is finished but this breaks when we switch exwm workspaces
  ;; and the current focused window just gets hidden.
  (setq-default mu4e-index-update-in-background t)

  ;; Add some mailing lists
  (dolist (mailing-list '(("intern.lists.entropia.de" . "Entropia")
                          ("intern.lists.ccc.de" . "CCC")
                          ("pylons-discuss.googlegroups.com" . "PyrUsr")
                          ("pylons-devel.googlegroups.com" . "PyrDev")
                          ("sqlalchemy.googlegroups.com" . "SQLA")))
    (add-to-list 'mu4e~mailing-lists mailing-list))

  (setq mu4e-bookmarks `((,(concat "maildir:/private/Inbox OR "
                                   "maildir:/paessler/Inbox OR "
                                   "maildir:/gmail/inbox OR "
                                   "maildir:/atomx/inbox OR "
                                   "maildir:/hogaso/inbox OR "
                                   "maildir:/e5/Inbox")
                          "All inboxes" ?i)
                         ("flag:flagged" "Flagged messages" ?f)
                         (,(concat "flag:unread AND "
                                   "NOT flag:trashed AND "
                                   "NOT flag:seen AND "
                                   "NOT list:emacs-devel.gnu.org AND "
                                   "NOT list:emacs-orgmode.gnu.org AND "
                                   "NOT maildir:/private/Junk AND "
                                   "NOT maildir:/atomx/spam AND "
                                   "NOT maildir:/atomx/trash AND "
                                   "NOT maildir:/gmail/spam AND "
                                   "NOT maildir:/gmail/trash")
                          "Unread messages" ?a)
                         (,(concat "flag:unread AND "
                                   "NOT flag:trashed AND "
                                   "NOT flag:seen AND "
                                   "NOT maildir:/private/Junk AND "
                                   "NOT maildir:/atomx/spam AND "
                                   "NOT maildir:/atomx/trash AND "
                                   "NOT maildir:/gmail/spam AND "
                                   "NOT maildir:/gmail/trash")
                          "All Unread messages" ?A)
                         ("list:emacs-devel.gnu.org" "Emacs dev" ?d)
                         ("list:emacs-orgmode.gnu.org" "Emacs orgmode" ?o)
                         ("list:magit.googlegroups.com OR list:mu-discuss.googlegroups.com" "Elisp" ?e)
                         ("list:pylons-discuss.googlegroups.com OR list:pylons-devel.googlegroups.com OR list:sqlalchemy.googlegroups.com" "Python" ?p)
                         ("list:intern.lists.ccc.de" "CCC Intern" ?c)
                         ("list:intern.lists.entropia.de" "Entropia Intern" ?k)
                         ("list:uwsgi.lists.unbit.it" "uwsgi" ?u)))

  ;; (add-hook 'mu4e-mark-execute-pre-hook
  ;;           (lambda (mark msg)
  ;;             (cond ((member mark '(refile trash)) (mu4e-action-retag-message msg "-\\Inbox"))
  ;;                   ((equal mark 'flag) (mu4e-action-retag-message msg "\\Starred"))
  ;;                   ((equal mark 'unflag) (mu4e-action-retag-message msg "-\\Starred")))))

  ;; allow for updating mail using 'U' in the main view:
  ;; (only update inboxes)
  (setq mu4e-get-mail-command "mbsync private paessler e5 gmail-inbox atomx-inbox hogaso-inbox")
  ;; for update all:
  ;;(setq mu4e-get-mail-command "mbsync -a")

  ;; update database every ten minutes
  (setq  mu4e-update-interval (* 60 10))

  ;; We do a full index (that verify integrity) with a systemd job
  ;; Go fast inside emacs
  (setq mu4e-index-cleanup nil      ;; don't do a full cleanup check
        mu4e-index-lazy-check t)    ;; don't consider up-to-date dirs

  ;;; Use 'fancy' non-ascii characters in various places in mu4e
  (setq mu4e-use-fancy-chars t)

  ;; I want my format=flowed thank you very much
  ;; mu4e sets up visual-line-mode and also fill (M-q) to do the right thing
  ;; each paragraph is a single long line; at sending, emacs will add the
  ;; special line continuation characters.
  (setq mu4e-compose-format-flowed nil)

  ;; Dont open new frame for composing mails
  (setq mu4e-compose-in-new-frame nil)

  ;; Don't reply to self
  (setq mu4e-user-mail-address-list
        '("daniel@kraus.my" "daniel.kraus@gmail.com" "dakra@tr0ll.net" "daniel@tr0ll.net" "d@niel-kraus.de"
          "arlo@kraus.my"
          "dakra-cepheus@tr0ll.net"
          "daniel@skor.buzz"
          "daniel@atomx.com"
          "daniel@hogaso.com"
          "daniel.kraus@paessler.com"
          "daniel.kraus@ebenefuenf.de"))
  (setq mu4e-compose-dont-reply-to-self t)

  ;; Extract name from email for yasnippet template
  ;; http://pragmaticemacs.com/emacs/email-templates-in-mu4e-with-yasnippet/
  (defun bjm/mu4e-get-names-for-yasnippet ()
    "Return comma separated string of names for an email"
    (interactive)
    (let ((email-name "") str email-string email-list email-name2 tmpname)
      (save-excursion
        (goto-char (point-min))
        ;; first line in email could be some hidden line containing NO to field
        (setq str (buffer-substring-no-properties (point-min) (point-max))))
      ;; take name from TO field - match series of names
      (when (string-match "^To: \"?\\(.+\\)" str)
        (setq email-string (match-string 1 str)))
      ;;split to list by comma
      (setq email-list (split-string email-string " *, *"))
      ;;loop over emails
      (dolist (tmpstr email-list)
        ;;get first word of email string
        (setq tmpname (car (split-string tmpstr " ")))
        ;;remove whitespace or ""
        (setq tmpname (replace-regexp-in-string "[ \"]" "" tmpname))
        ;;join to string
        (setq email-name
              (concat email-name ", " tmpname)))
      ;;remove initial comma
      (setq email-name (replace-regexp-in-string "^, " "" email-name))

      ;;see if we want to use the name in the FROM field
      ;;get name in FROM field if available, but only if there is only
      ;;one name in TO field
      (if (< (length email-list) 2)
          (when (string-match "^\\([^ ,\n]+\\).+writes:$" str)
            (progn (setq email-name2 (match-string 1 str))
                   ;;prefer name in FROM field if TO field has "@"
                   (when (string-match "@" email-name)
                     (setq email-name email-name2))
                   )))
      email-name))

  ;; Always store contacts as first last <email>
  ;; https://martinralbrecht.wordpress.com/2016/05/30/handling-email-with-emacs/
  (defun malb/canonicalise-contact-name (name)
    (let ((case-fold-search nil))
      (setq name (or name ""))
      (if (string-match-p "^[^ ]+@[^ ]+\.[^ ]" name)
          ""
        (progn
          ;; drop email address
          (setq name (replace-regexp-in-string "^\\(.*\\) [^ ]+@[^ ]+\.[^ ]" "\\1" name))
          ;; strip quotes
          (setq name (replace-regexp-in-string "^\"\\(.*\\)\"" "\\1" name))
          ;; deal with YELL’d last names
          (setq name (replace-regexp-in-string "^\\(\\<[[:upper:]]+\\>\\) \\(.*\\)" "\\2 \\1" name))
          ;; Foo, Bar becomes Bar Foo
          (setq name (replace-regexp-in-string "^\\(.*\\), \\([^ ]+\\).*" "\\2 \\1" name))))))

  (defun malb/mu4e-contact-rewrite-function (contact)
    (let* ((name (or (plist-get contact :name) ""))
           (mail (plist-get contact :mail))
           (case-fold-search nil))
      (plist-put contact :name (malb/canonicalise-contact-name name))
      contact))

  (setq mu4e-contact-rewrite-function #'malb/mu4e-contact-rewrite-function)


  (defun dakra-mu4e-action-attachment-import-gcalcli (msg attachnum)
    "Import ical attachments with gcalcli"
    (mu4e-view-open-attachment-with msg attachnum "~/bin/icalimport.sh"))

  (add-to-list 'mu4e-view-attachment-actions '("iImport ical" . dakra-mu4e-action-attachment-import-gcalcli) t)

  (defun mu4e-action-view-in-firefox (msg)
    "View the body of the message in a new Firefox window."
    (let ((browse-url-browser-function 'browse-url-firefox)
          (browse-url-new-window-flag t))
      (browse-url (concat "file://" (mu4e~write-body-to-html msg)))))

  ;; View mail in browser with "a V"
  (add-to-list 'mu4e-view-actions
               '("ViewInBrowser" . mu4e-action-view-in-browser) t)
  (add-to-list 'mu4e-view-actions
               '("fViewInFirefox" . mu4e-action-view-in-firefox) t)
  (add-to-list 'mu4e-view-actions
               '("xViewXWidget" . mu4e-action-view-with-xwidget) t)
  ;; enable inline images
  (setq mu4e-view-show-images t)
  ;; use imagemagick, if available
  (when (fboundp 'imagemagick-register-types)
    (imagemagick-register-types))

  ;;rename files when moving
  ;;NEEDED FOR MBSYNC
  (setq mu4e-change-filenames-when-moving t)

  (defun mu4e-message-maildir-matches (msg rx)
    "Match message MSG with regex RX based on maildir."
    (when rx
      (if (listp rx)
          ;; if rx is a list, try each one for a match
          (or (mu4e-message-maildir-matches msg (car rx))
              (mu4e-message-maildir-matches msg (cdr rx)))
        ;; not a list, check rx
        (string-match rx (mu4e-message-field msg :maildir)))))

  (defmacro mu4e-context-match-fun (maildir)
    "Return lambda for context switching which checks if a message is in MAILDIR."
    `(lambda (msg)
       (when msg
         (mu4e-message-maildir-matches msg ,maildir))))

  (setq mu4e-contexts
        `( ,(make-mu4e-context
             :name "private"
             :enter-func (lambda () (mu4e-message "Switch to the Private context"))
             :match-func (mu4e-context-match-fun "^/private")
             :vars '(( user-mail-address  . "daniel@kraus.my" )
                     ( mu4e-maildir-shortcuts . (("/private/Inbox"      . ?i)
                                                 ("/private/Sent"       . ?s)
                                                 ("/private/Trash"      . ?t)
                                                 ("/private/Drafts"     . ?d)
                                                 ("/private/Archive"   . ?a)))
                     ( mu4e-drafts-folder . "/private/Drafts" )
                     ( mu4e-sent-folder   . "/private/Sent" )
                     ( mu4e-trash-folder  . "/private/Trash" )
                     ( mu4e-refile-folder . dakra-mu4e-private-refile)))
           ,(make-mu4e-context
             :name "gmail"
             :enter-func (lambda () (mu4e-message "Switch to the gmail context"))
             :match-func (mu4e-context-match-fun "^/gmail")
             :vars '(( user-mail-address  . "daniel.kraus@gmail.com"  )
                     ( mu4e-maildir-shortcuts . (("/gmail/inbox"      . ?i)
                                                 ("/gmail/sent_mail"  . ?s)
                                                 ("/gmail/trash"      . ?t)
                                                 ("/gmail/drafts"     . ?d)
                                                 ("/gmail/all_mail"   . ?a)))
                     ( mu4e-drafts-folder . "/gmail/drafts" )
                     ( mu4e-sent-folder   . "/gmail/sent_mail" )
                     ( mu4e-trash-folder  . "/gmail/trash" )
                     ( mu4e-refile-folder . "/gmail/all_mail" )
                     ;; don't save message to Sent Messages, Gmail/IMAP takes care of this
                     ( mu4e-sent-messages-behavior  . delete)))
           ,(make-mu4e-context
             :name "atomx"
             :enter-func (lambda () (mu4e-message "Switch to the Atomx context"))
             :match-func (mu4e-context-match-fun "^/atomx")
             :vars '(( user-mail-address  . "daniel@atomx.com" )
                     ( mu4e-maildir-shortcuts . (("/atomx/inbox"      . ?i)
                                                 ("/atomx/sent_mail"  . ?s)
                                                 ("/atomx/trash"      . ?t)
                                                 ("/atomx/drafts"     . ?d)
                                                 ("/atomx/all_mail"   . ?a)))
                     ( mu4e-drafts-folder . "/atomx/drafts" )
                     ( mu4e-sent-folder   . "/atomx/sent_mail" )
                     ( mu4e-trash-folder  . "/atomx/trash" )
                     ( mu4e-refile-folder . "/atomx/all_mail" )
                     ;; don't save message to Sent Messages, Gmail/IMAP takes care of this
                     ( mu4e-sent-messages-behavior  . delete)))
           ,(make-mu4e-context
             :name "e5"
             :enter-func (lambda () (mu4e-message "Switch to the e5 context"))
             :match-func (mu4e-context-match-fun "^/e5")
             :vars '(( user-mail-address  . "daniel.kraus@ebenefuenf.de" )
                     ( mu4e-maildir-shortcuts . (("/e5/Inbox"      . ?i)
                                                 ("/e5/Sent"  . ?s)
                                                 ("/e5/Trash"      . ?t)
                                                 ("/e5/Drafts"     . ?d)
                                                 ("/e5/Archive"    . ?a)))
                     ( mu4e-drafts-folder . "/e5/Drafts" )
                     ( mu4e-sent-folder   . "/e5/Sent" )
                     ( mu4e-trash-folder  . "/e5/Trash" )
                     ( mu4e-refile-folder . "/e5/Archive" )))
           ,(make-mu4e-context
             :name "Paessler"
             :enter-func (lambda () (mu4e-message "Switch to the paessler context"))
             :match-func (mu4e-context-match-fun "^/paessler")
             :vars '(  ( user-mail-address  . "daniel.kraus@paessler.com" )
                       ( mu4e-maildir-shortcuts . (("/paessler/Inbox"         . ?i)
                                                   ("/paessler/Outbox"        . ?s)
                                                   ("/paessler/Deleted Items" . ?t)
                                                   ("/paessler/Drafts"        . ?d)
                                                   ("/paessler/Archive"       . ?a)))
                       ( mu4e-drafts-folder . "/paessler/Drafts" )
                       ( mu4e-sent-folder   . "/paessler/Sent" )
                       ( mu4e-trash-folder  . "/paessler/Deleted Items" )
                       ( mu4e-refile-folder . "/paessler/Archive" )))
           ,(make-mu4e-context
             :name "hogaso"
             :enter-func (lambda () (mu4e-message "Switch to the Hogaso context"))
             :match-func (mu4e-context-match-fun "^/hogaso")
             :vars '(( user-mail-address  . "daniel@hogaso.com" )
                     ( mu4e-maildir-shortcuts . (("/hogaso/inbox"      . ?i)
                                                 ("/hogaso/sent_mail"  . ?s)
                                                 ("/hogaso/trash"      . ?t)
                                                 ("/hogaso/drafts"     . ?d)
                                                 ("/hogaso/all_mail"   . ?a)))
                     ( mu4e-drafts-folder . "/hogaso/drafts" )
                     ( mu4e-sent-folder   . "/hogaso/sent_mail" )
                     ( mu4e-trash-folder  . "/hogaso/trash" )
                     ( mu4e-refile-folder . "/hogaso/all_mail" )
                     ;; don't save message to Sent Messages, Gmail/IMAP takes care of this
                     ( mu4e-sent-messages-behavior  . delete)
                     ( mu4e-compose-signature . (concat
                                                 "Daniel Kraus\n"
                                                 "Hogaso | https://hogaso.com\n"))))))

  ;; start with the first (default) context;
  ;; default is to ask-if-none (ask when there's no context yet, and none match)
  (setq mu4e-context-policy 'pick-first)

  ;; compose with the current context is no context matches;
  ;; default is to ask
  '(setq mu4e-compose-context-policy nil)

  ;; don't keep message buffers around
  (setq message-kill-buffer-on-exit t)

  ;; something about ourselves
  ;; (setq
  ;;  user-mail-address "daniel@kraus.my"
  ;;  user-full-name  "Daniel Kraus"
  ;;  mu4e-compose-signature
  ;;  (concat
  ;;   "regards,\n"
  ;;   "  Daniel\n"))

  ;; If there's 'attach' 'file' 'pdf' in the message warn when sending w/o attachment
  (defun mbork/message-attachment-present-p ()
    "Return t if an attachment is found in the current message."
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-min))
        (when (search-forward "<#part" nil t) t))))

  (defcustom mbork/message-attachment-intent-re
    (regexp-opt '("attach"
                  "anhang"
                  "angehängt"
                  "angehaengt"
                  "datei"
		  "file"
                  "pdf"))
    "A regex which - if found in the message, and if there is no
attachment - should launch the no-attachment warning."
    :type '(sexp)
    :group 'mu4e)

  (defcustom mbork/message-attachment-reminder
    "Are you sure you want to send this message without any attachment? "
    "The default question asked when trying to send a message
containing `mbork/message-attachment-intent-re' without an
actual attachment."
    :type '(string)
    :group 'mu4e)

  (defun mbork/message-warn-if-no-attachments ()
    "Ask the user if s?he wants to send the message even though
there are no attachments."
    (when (and (save-excursion
	         (save-restriction
		   (widen)
		   (goto-char (point-min))
		   (re-search-forward mbork/message-attachment-intent-re nil t)))
	       (not (mbork/message-attachment-present-p)))
      (unless (y-or-n-p mbork/message-attachment-reminder)
        (keyboard-quit))))

  (add-hook 'message-send-hook #'mbork/message-warn-if-no-attachments))


;; for org capture
(use-package org-mu4e
  :after (:any org mu4e)
  :config
  ;; when mail is sent, automatically convert org body to HTML
  (setq-default org-mu4e-convert-to-html t)

  (defalias 'org-mail 'org-mu4e-compose-org-mode)

  ;; FIXME: only set this during mu4e usage
  (setq-default org-export-with-toc nil)  ; turn off table of contents

  ;; Store link to message if in header view, not to header query
  (setq-default org-mu4e-link-query-in-headers-mode nil))

;; Show overview of unread/all mails for each maildir/bookmarks in mu4e main window
(use-package mu4e-maildirs-extension
  :disabled t
  :commands mu4e-maildirs-extension-force-update
  :config
  (setq-default mu4e-maildirs-extension-use-bookmarks t)
  (setq-default mu4e-maildirs-extension-use-maildirs nil)
  (mu4e-maildirs-extension))


;; XXX: Play more with org-mime instead of mu4e-compose-org-mode
;; Look at: http://kitchingroup.cheme.cmu.edu/blog/2016/10/29/Sending-html-emails-from-org-mode-with-org-mime/
(use-package org-mime
  :commands (org-mime-htmlize org-mime-org-buffer-htmlize org-mime-org-subtree-htmlize)
  :bind (:map message-mode-map ("C-c M-o" . org-mime-htmlize)
         :map org-mode-map ("C-c M-o" . org-mime-org-subtree-htmlize))
  :config
  (setq org-mime-export-options '(:section-numbers nil
                                  :with-author nil
                                  :with-toc nil)))

;; Auto sign mails
(use-package mml-sec
  :hook (mu4e-compose-mode . mml-secure-message-sign-pgpmime))
;; Encrypt mails by calling (mml-secure-message-encrypt-pgpmime)

;; use helm-mu for search
(use-package helm-mu
  :disabled t
  :commands helm-mu
  :after mu4e
  :bind (:map mu4e-main-mode-map ("s" . dakra-helm-mu)
         :map mu4e-headers-mode-map ("s" . dakra-helm-mu)
         :map mu4e-view-mode-map ("s" . dakra-helm-mu))
  :init
  ;; helm-mu expects a bash compatible shell (which fish isn't)
  ;; and doesn't play nice with helms autofollow mode
  (defun dakra-helm-mu ()
    (interactive)
    (let ((shell-file-name "/usr/bin/bash")
          (helm-follow-mode-persistent nil))
      (helm-mu)))
  :config
  ;; Only show contacts who sent you emails directly
  (setq helm-mu-contacts-personal t)
  ;; default search only inbox, archive or sent mail
  ;; (setq helm-mu-default-search-string (concat "(maildir:/private/Inbox OR "
  ;;                                             "maildir:/private/Archive OR "
  ;;                                             "maildir:/private/Sent)"))
  )


;; (define-key mu4e-headers-mode-map (kbd "d") 'my-move-to-trash)
;; (define-key mu4e-view-mode-map (kbd "d") 'my-move-to-trash)
;; ;; Overwrite normal 'D' keybinding
;; (define-key mu4e-headers-mode-map (kbd "D") 'my-move-to-trash)
;; (define-key mu4e-view-mode-map (kbd "D") 'my-move-to-trash)

;; ;; Mark all as read with 'M'
;; (define-key mu4e-headers-mode-map (kbd "M") 'mu4e-headers-mark-all-unread-read)


;; Attach files from dired (C-c RET C-a)
(use-package gnus-dired
  :after mu4e
  :config
  ;; make the `gnus-dired-mail-buffers' function also work on
  ;; message-mode derived modes, such as mu4e-compose-mode
  (defun gnus-dired-mail-buffers ()
    "Return a list of active message buffers."
    (let (buffers)
      (save-current-buffer
        (dolist (buffer (buffer-list t))
          (set-buffer buffer)
          (when (and (derived-mode-p 'message-mode)
                     (null message-sent-message-via))
            (push (buffer-name buffer) buffers))))
      (nreverse buffers)))

  (setq gnus-dired-mail-mode 'mu4e-user-agent)
  (add-hook 'dired-mode-hook 'turn-on-gnus-dired-mode))

;; display html messages
(use-package mu4e-contrib
  :after mu4e
  :config
  ;;(require 'mu4e-message)
  ;;(setq mu4e-html2text-command 'mu4e-shr2text)
  (add-hook 'mu4e-view-mode-hook
            (lambda()
              ;; try to emulate some of the eww key-bindings
              (local-set-key (kbd "<tab>") 'shr-next-link)
              (local-set-key (kbd "<backtab>") 'shr-previous-link))))

(use-package xelb
  :if (daemonp))

(use-package exwm
  :if (daemonp)
  :demand t
  :hook (exwm-init . exwm-startup-apps)
  :bind (:map exwm-mode-map
         ;; The following can only apply to EXWM buffers, else it could have unexpected effects.
         ("s-SPC" . exwm-floating-toggle-floating)
         ("s-q" . exwm-input-send-next-key)  ; Shorter than the default C-c C-q
         ("s-t" . exwm-input-toggle-keyboard)
         ("s-F" . exwm-layout-toggle-fullscreen)
         ("M-y" . exwm-counsel-yank-pop))
  :config
  (defun exwm-counsel-yank-pop ()
    "Same as `counsel-yank-pop' and paste into exwm buffer."
    (interactive)
    (let ((inhibit-read-only t)
          ;; Make sure we send selected yank-pop candidate to
          ;; clipboard:
          (yank-pop-change-selection t))
      (call-interactively #'counsel-yank-pop))
    (when (derived-mode-p 'exwm-mode)
      (exwm-input--set-focus (exwm--buffer->id (window-buffer (selected-window))))
      (exwm-input--fake-key ?\C-v)))

  ;; Set the initial workspace number.
  (setq exwm-workspace-number 4)
  ;; Make class name the buffer name
  (add-hook 'exwm-update-class-hook
            (lambda ()
              (exwm-workspace-rename-buffer exwm-class-name)))

  (add-hook 'exwm-floating-setup-hook 'exwm-layout-hide-mode-line)
  (add-hook 'exwm-floating-exit-hook 'exwm-layout-show-mode-line)

  ;; XXX: Make macro
  (defun exwm-bind-keys (&rest bindings)
    "Like exwm-input-set-key but syntax similar to bind-keys.
Define keybindings that work in exwm and non-exwm buffers.
Only works *before* exwm in initialized."
    (pcase-dolist (`(,key . ,fun) bindings)
      (add-to-list 'exwm-input-global-keys `(,(kbd key) . ,fun))))

  (exwm-bind-keys
   ;; General exwm commands
   '("s-R"       . exwm-reset)
   '("s-w"       . exwm-workspace-switch)
   ;; Moving/editing windows
   '("s-j"       . exwm-windmove-left)
   '("s-k"       . exwm-windmove-down)
   '("s-i"       . exwm-windmove-up)
   '("s-l"       . exwm-windmove-right)
   '("<s-left>"  . exwm-windmove-left)
   '("<s-down>"  . exwm-windmove-down)
   '("<s-up>"    . exwm-windmove-up)
   '("<s-right>" . exwm-windmove-right)
   '("s-\\"       . toggle-window-split)
   '("s-J"       . swap-windows-left)
   '("s-K"       . swap-windows-below)
   '("s-I"       . swap-windows-above)
   '("s-L"       . swap-windows-right)
   ;; XXX: switch to winner-mode (C-X 1 and the C-c <left>)
   '("s-f"       . toggle-single-window)
   ;; Workspaces
   '("s-u"       . exwm-workspace-switch-previous)
   '("s-o"       . exwm-workspace-switch-next)
   ;; Launch apps
   '("s-b"       . ivy-switch-buffer)
   '("s-d"       . counsel-linux-app)
   '("s-D"       . exwm-launch-shell-command))

  ;; We start workspaces at 1 instead of 0
  (defun exwm-workspace-number-to-string (number)
    (number-to-string (1+ number)))
  (setq exwm-workspace-index-map #'exwm-workspace-number-to-string)

  ;; Switching workspaces
  (defun exwm-workspace-switch-previous (p)
    "Switch to previous workspace"
    (interactive "p")
    (if (< (- exwm-workspace-current-index p) 0)
        (exwm-workspace-switch (1- (length exwm-workspace--list)))
      (exwm-workspace-switch (- exwm-workspace-current-index p))))

  (defun exwm-workspace-switch-next (p)
    "Switch to next workspace"
    (interactive "p")
    (if (> (+ exwm-workspace-current-index p) (1- (length exwm-workspace--list)))
        (exwm-workspace-switch 0)
      (exwm-workspace-switch (+ exwm-workspace-current-index p))))

  (require 'windmove)
  (defun exwm-windmove-left (&optional arg)
    "Like windmove-left but go to previous workspace if there is
no window on the left."
    (interactive "P")
    (if (or (<= exwm-connected-displays 1) (windmove-find-other-window 'left arg))
        (windmove-do-window-select 'left arg)
      ;; No window to the left
      ;; Switch to previous workspace and select rightmost window
      (exwm-workspace-switch-previous 1)
      (while (windmove-find-other-window 'right arg)
        (windmove-do-window-select 'right arg))))

  (defun exwm-windmove-right (&optional arg)
    "Like windmove-right but go to previous workspace if there is
no window on the right."
    (interactive "P")
    (if (or (<= exwm-connected-displays 1) (windmove-find-other-window 'right arg))
        (windmove-do-window-select 'right arg)
      ;; No window to the left
      ;; Switch to previous workspace and select rightmost window
      (exwm-workspace-switch-next 1)
      (while (windmove-find-other-window 'left arg)
        (windmove-do-window-select 'left arg))))

  (setq exwm-windmove-workspace-1-below-p t)
  ;; FIXME: Automatically get displayed workspace on top monitor
  (setq exwm-windmove-last-workspace-top 1)

  (defun exwm-windmove-down (&optional arg)
    "Like windmove-down but go to workspace 1 if there is no window
or active minibuffer below and `exwm-windmove-workspace-1-below-p' is non-NIL."
    (interactive "P")
    (let ((active-minibuffer-below-p
           (and (minibuffer-window-active-p (minibuffer-window))
                (eq (minibuffer-window) (windmove-find-other-window 'down arg)))))
      (if (or (<= exwm-connected-displays 1)
              active-minibuffer-below-p
              (= exwm-workspace-current-index 0)
              (not (eq (minibuffer-window) (windmove-find-other-window 'down arg))))
          (windmove-do-window-select 'down arg)
        ;; No window below
        (when exwm-windmove-workspace-1-below-p
          ;; Switch to workspace 0 and select top window
          (setq exwm-windmove-last-workspace-top exwm-workspace-current-index)
          (exwm-workspace-switch 0)
          (while (windmove-find-other-window 'up arg)
            (windmove-do-window-select 'up arg))))))

  (defun exwm-windmove-up (&optional arg)
    "Like windmove-up but go to workspace 1 if there is
no window below and `exwm-windmove-workspace-1-below-p' is non-NIL."
    (interactive "P")
    (if (or (<= exwm-connected-displays 1) (windmove-find-other-window 'up arg))
        (windmove-do-window-select 'up arg)
      ;; No window below
      (when exwm-windmove-workspace-1-below-p
        ;; Switch to workspace 1 and select bottom window
        (exwm-workspace-switch exwm-windmove-last-workspace-top)
        (while (windmove-find-other-window 'down arg)
          (windmove-do-window-select 'down arg)))))

  ;; 's-N': Switch to certain workspace
  (dotimes (i 4)
    (exwm-input-set-key (kbd (format "s-%d" (+ 1 i)))
                        `(lambda ()
                           (interactive)
                           (exwm-workspace-switch-create ,i))))
  ;; 's-D': Launch application
  (defun exwm-launch-shell-command (command)
    (interactive (list (read-shell-command "$ ")))
    (start-process-shell-command command nil command))

  ;; Line-editing shortcuts
  (setq exwm-input-simulation-keys
        '(([?\C-b] . [left])
          ([?\C-f] . [right])
          ([?\C-p] . [up])
          ([?\C-n] . [down])
          ([?\C-a] . [home])
          ([?\C-e] . [end])
          ([?\M-v] . [prior])
          ([?\C-v] . [next])
          ([?\C-y] . [?\C-v])
          ;;([?\C-k] . [S-end delete])
          ([?\C-d] . [delete])))

  (setq exwm-workspace-show-all-buffers t)
  (setq exwm-layout-show-all-buffers t)

  ;; This setup needs `autorandr' installed.
  ;; AUR package `autorandr' and enable with `systemctl enable autorandr`
  ;; Autorandr uses udev rules to pick and choose the correct xrandr layout so here
  ;; in exwm we only need to set dynamically which workspaces map to which output.
  (require 'exwm-randr)
  ;; Dynamic xrandr config ideas from https://github.com/ch11ng/exwm/issues/202

  (defvar exwm-connected-displays 1
    "Number of connected displays.")

  ;; Update exwm-randr-workspace-output-plist with 2 or 3 outputs named
  ;; 'primary' and 'other-1'/'other-2'.
  ;; With 3 outputs connected the first workspace will be primary,
  ;; second workspace goes to 'other-2' and all others to 'other-1'.
  ;; With 2 outputs, first workspace is 'primary' display and rest 'other-1'.
  ;; And with only one connected output, primary has all workspaces.
  (defun dakra-exwm-randr-screen-change ()
    (let* ((connected-cmd "xrandr -q|awk '/ connected/ {print $1}'")
           (connected (process-lines "bash" "-lc" connected-cmd))
           (primary (car connected))  ; Primary display is always first in list
           (other-1 (cadr connected))
           (other-2 (caddr connected)))
      (setq exwm-connected-displays (length connected))
      (setq exwm-randr-workspace-output-plist
            (append (list 0 primary)
                    (list 1 (or other-2 other-1 primary))
                    (mapcan (lambda (i) (list i (or other-1 other-2 primary)))
                            (number-sequence 2 exwm-workspace-number))))
      (exwm-randr--refresh)
      (message "Display: %s refreshed." (string-join connected ", "))))

  (add-hook 'exwm-randr-screen-change-hook #'dakra-exwm-randr-screen-change)
  (exwm-randr-enable)

  ;; Warp cursor automatically after workspace switch
  (setq exwm-workspace-warp-cursor t)

  (require 'exwm-systemtray)
  ;; Pick some height for the system tray. Some applet icons don't appear otherwise.
  (setq exwm-systemtray-height 18)
  (exwm-systemtray-enable)

  (setq exwm-manage-configurations
        '(((string= exwm-instance-name "emacs")
           ;; Emacs is better off being started in char-mode.
           char-mode t)
          ((equal exwm-class-name "keepassxc")
           floating t
           floating-mode-line nil
           width 0.6
           height 0.8)
          ((equal exwm-class-name "Firefox Developer Edition")
           simulation-keys (([?\C-q] . [?\C-w])  ; close tab instead of quitting Firefox
                            ([?\C-b] . [left])
                            ([?\C-f] . [right])
                            ([?\C-p] . [up])
                            ([?\C-n] . [down])
                            ([?\C-a] . [home])
                            ([?\C-e] . [end])
                            ([?\M-v] . [prior])
                            ([?\C-v] . [next])
                            ([?\C-d] . [delete])))
          ((equal exwm-class-name "Termite")
           simulation-keys (([?\C-c ?\C-c] . [?\C-c])  ;; Send C-c with C-c C-c
                            ([?\C-f] . [right])
                            ([?\C-p] . [up])
                            ([?\C-n] . [down])
                            ([?\C-a] . [home])
                            ([?\C-e] . [end])
                            ([?\M-v] . [prior])
                            ([?\C-v] . [next])))))

  (defun dakra/poweroff ()
    "Clock out, save all Emacs buffers and shut computer down."
    (interactive)
    (when (y-or-n-p "Really want to shut down?")
      (when (org-clock-is-active)
        (org-clock-out))
      (save-some-buffers t)
      (start-process-shell-command "poweroff" nil "poweroff")))
  (defun dakra/reboot ()
    "Save all Emacs buffers and reboot."
    (interactive)
    (when (y-or-n-p "Really want to reboot?")
      (save-some-buffers t)
      (start-process-shell-command "reboot" nil "reboot")))

  ;; Start some apps
  (defun exwm-startup-apps ()
    "Start some applications after exwm init."
    (start-process-shell-command "pidgin" nil "pidgin")
    ;; Start some always used Emacs apps
    (org-agenda nil " ")
    ;; (pop-to-buffer (eshell))
    ;; (pop-to-buffer (mu4e))
    ;; (pop-to-buffer (elfeed))
    (pop-to-buffer (find-file "~/.emacs.d/init.org"))
    ;; Start some external apps
    (start-process-shell-command "firefox-developer-edition" nil "env GTK_THEME=Arc firefox-developer-edition")

    (start-process-shell-command "syncthing-gtk" nil "syncthing-gtk --minimized")
    (start-process-shell-command "kdeconnect-indicator" nil "kdeconnect-indicator")
    (start-process-shell-command "keepassxc" nil "keepassxc"))

  ;; Enable EXWM
  (exwm-enable))

(use-package gpastel
  :hook (exwm-init . gpastel-start-listening))

(use-package pulseaudio-control
  :bind (("<XF86AudioRaiseVolume>" . pulseaudio-control-increase-volume)
         ("<XF86AudioLowerVolume>" . pulseaudio-control-decrease-volume)
         ("<XF86AudioMute>" . pulseaudio-control-toggle-current-sink-mute)
         ("C-c v" . hydra-pulseaudio-control/body)
         :map exwm-mode-map
         ("<XF86AudioRaiseVolume>" . pulseaudio-control-increase-volume)
         ("<XF86AudioLowerVolume>" . pulseaudio-control-decrease-volume)
         ("<XF86AudioMute>" . pulseaudio-control-toggle-current-sink-mute))
  ;;:bind-keymap ("C-c v" . pulseaudio-control-map)
  :config
  ;; XXX: Maybe -set-volume (1-9 keys sets 10%, 20% etc)?
  ;;      Maybe show selected sink and volume
  (defhydra hydra-pulseaudio-control (:hint nil)
    "Pulseaudio Control"
    ("+" pulseaudio-control-increase-volume "Increase Volume")
    ("i" pulseaudio-control-increase-volume "Increase Volume")
    ("-" pulseaudio-control-decrease-volume "Decrease Volume")
    ("d" pulseaudio-control-decrease-volume "Decrease Volume")
    ("m" pulseaudio-control-toggle-current-sink-mute "Toggle Mute")
    ("s" pulseaudio-control-select-sink-by-name "Select Sink")
    ("q" nil "quit"))
  (setq pulseaudio-control-volume-step "5%"))

(use-package xbacklight
  :bind (("<XF86MonBrightnessUp>" . xbacklight-increase)
         ("<XF86MonBrightnessDown>" . xbacklight-decrease)
         :map exwm-mode-map
         ("<XF86MonBrightnessUp>" . xbacklight-increase)
         ("<XF86MonBrightnessDown>" . xbacklight-decrease)))

(defvar counsel-network-manager-history nil
  "Network manager history.")

(defun counsel-network-manager (&optional initial-input)
  "Connect to wifi network."
  (interactive)
  (shell-command "nmcli device wifi rescan")
  (let ((networks-list (s-split "\n" (shell-command-to-string "nmcli device wifi list"))))
    (ivy-read "Select network" networks-list
              :initial-input initial-input
              :require-match t
              :history counsel-network-manager-history
              :sort nil
              :caller 'counsel-network-manager
              :action (lambda (line)
                        (let ((network (car (s-split " " (s-trim (s-chop-prefix "*" line)) t))))
                          (message "Connecting to \"%s\".." network)
                          (async-shell-command
                           (format "nmcli device wifi connect %s" (shell-quote-argument network))))))))

;; Focus follows mouse for Emacs windows and frames
(setq mouse-autoselect-window t)
(setq focus-follows-mouse t)

;; swap-window functions from
;; https://github.com/Ambrevar/dotfiles/blob/master/.emacs.d/lisp/functions.el
(defun swap-windows (&optional w1 w2)
  "If 2 windows are up, swap them.
Else if W1 is a window, swap it with current window.
If W2 is a window too, swap both."
  (interactive)
  (unless (or (= 2 (count-windows))
              (windowp w1)
              (windowp w2))
    (error "Ambiguous window selection"))
  (let* ((w1 (or w1 (car (window-list))))
         (w2 (or w2
                 (if (eq w1 (car (window-list)))
                     (nth 1 (window-list))
                   (car (window-list)))))
         (b1 (window-buffer w1))
         (b2 (window-buffer w2))
         (s1 (window-start w1))
         (s2 (window-start w2)))
    (with-temp-buffer
      ;; Some buffers like EXWM buffers can only be in one live buffer at once.
      ;; Switch to a dummy buffer in w2 so that we don't display any buffer twice.
      (set-window-buffer w2 (current-buffer))
      (set-window-buffer w1 b2)
      (set-window-buffer w2 b1))
    (set-window-start w1 s2)
    (set-window-start w2 s1))
  (select-window w1))
(global-set-key (kbd "C-x \\") 'swap-windows)

(defun swap-windows-left ()
  "Swap current window with the window to the left."
  (interactive)
  (swap-windows (window-in-direction 'left)))
(defun swap-windows-below ()
  "Swap current window with the window below."
  (interactive)
  (swap-windows (window-in-direction 'below)))
(defun swap-windows-above ()
  "Swap current window with the window above."
  (interactive)
  (swap-windows (window-in-direction 'above)))
(defun swap-windows-right ()
  "Swap current window with the window to the right."
  (interactive)
  (swap-windows (window-in-direction 'right)))

(defvar single-window--last-configuration nil "Last window configuration before calling `delete-other-windows'.")
(defun toggle-single-window ()
  "Un-maximize current window.
If multiple windows are active, save window configuration and
delete other windows.  If only one window is active and a window
configuration was previously save, restore that configuration."
  (interactive)
  (if (= (count-windows) 1)
      (when single-window--last-configuration
        (set-window-configuration single-window--last-configuration))
    (setq single-window--last-configuration (current-window-configuration))
    (delete-other-windows)))

(defun toggle-window-split ()
  "Switch between vertical and horizontal split.
It only works for frames with exactly two windows."
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  'split-window-horizontally
                'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))
(global-set-key (kbd "C-x C-\\") 'toggle-window-split)

(use-package switch-window
  :disabled t
  :commands switch-window
  :config (setq switch-window-input-style 'minibuffer))

(use-package winner
  :defer 3
  :config (winner-mode 1))

(use-package transmission
  :defer t
  :config
  ;; Auto refresh for all transmission buffers
  (setq transmission-refresh-modes '(transmission-mode
                                     transmission-files-mode
                                     transmission-info-mode
                                     transmission-peers-mode)))

(use-package brain-fm
  :defer t
  :config
  ;; Station 35 is "Focus"
  (setq brain-fm-station-id 35))

(use-package emms
  :defer t)

(use-package emms-player-mpv
  :after emms
  :config
  (setq emms-player-list '(emms-player-mpv))
  (setq emms-player-mpv-parameters '("--no-terminal" "--force-window=no" "--audio-display=no")))

(use-package youtube-dl
  :defer t
  :init
  (setq youtube-dl-directory "~/videos/youtube")
  :config
  (setq youtube-dl-arguments
        '("--no-mtime" "--restrict-filenames" "--format" "best" "--mark-watched")))

(use-package image :defer t
  :config
  ;; always loop GIF images
  (setq image-animate-loop t))

(use-package eimp
  :hook (image-mode . eimp-mode))

(use-package blimp
  :hook (image-mode . blimp-mode))

(use-package atomx
  :defer t)

(use-package gif-screencast
  :bind (:map gif-screencast-mode-map
         ("<f11>" . gif-screencast-toggle-pause)
         ("<f12>" . gif-screencast-stop)
         ("<escape>" . gif-screencast-stop))
  :config (setq gif-screencast-output-directory (expand-file-name "videos/emacs/" "~")))

(use-package systemctl
  :commands hydra-systemctl/body
  :config
  (defun systemctl-hydra-status (unit)
    "Return a checkbox indicating the status of UNIT."
    (if (equal (type-of unit) 'string)
        (if (systemctl-is-active-p unit)
            "[x]" "[ ]")
      (if (-all-p 'systemctl-is-active-p unit)
          "[x]" "[ ]")))

  (defhydra hydra-systemctl (:hint none)
    "
Presets                    Services
-------                    --------
_1_: ?1? postgres/redis      ?p? _p_ostgres
_2_: ?2? mysql/redis         ?r? _r_edis
_3_: ?3? mysql/rdb/redis     ?m? _m_ysql
                           ?t? re_t_hinkdb
                           ?d? _d_ocker
_o_: offline (stop all)      ?c? _c_ups
_g_: Refresh Hydra  _q_: quit"
    ;; Environments
    ("1" (mapc #'systemctl-start '("postgresql" "redis"))
     (systemctl-hydra-status '("postgresql" "redis")))
    ("2" (mapc #'systemctl-start '("mysqld" "redis"))
     (systemctl-hydra-status '("mysqld" "redis")))
    ("3" (mapc #'systemctl-start '("mysqld" "redis" "rethinkdb@default.service"))
     (systemctl-hydra-status '("mysqld" "redis" "rethinkdb@default.service")))
    ;; Stop all
    ("o" (mapc #'systemctl-stop'("postgresql" "mysqld" "redis" "rethinkdb@default.service"
                                 "docker" "org.cups.cupsd")))
    ;; Services
    ("p" (systemctl-toggle "postgresql") (systemctl-hydra-status "postgresql"))
    ("r" (systemctl-toggle "redis") (systemctl-hydra-status "redis"))
    ("m" (systemctl-toggle "mysqld") (systemctl-hydra-status "mysqld"))
    ("t" (systemctl-toggle "rethinkdb@default.service") (systemctl-hydra-status "rethinkdb@default.service"))
    ("d" (systemctl-toggle "docker") (systemctl-hydra-status "docker"))
    ("c" (mapc #'systemctl-toggle '("org.cups.cupsd" "cups-browsed" "avahi-daemon"))
     (systemctl-hydra-status "org.cups.cupsd"))

    ("g" (message "Hydra refreshed"))
    ("q" (message "Abort") :exit t)))

(use-package ovpn-mode
  :defer t
  :config
  (setq ovpn-mode-ipv6-auto-toggle t)  ; Always turn off ipv6 when starting vpn
  (setq ovpn-mode-base-directory "~/vpn"))

;; ledger-mode for bookkeeping
(defun ledger-mode-outline-hook ()
  (outline-minor-mode)
  (setq-local outline-regexp "[#;]+"))

(use-package hledger-mode
  :disabled t  ;; Think ledger-mode is better.. needs more experimenting
  ;;:mode "\\.ledger\\'"
  :commands (hledger-mode hledger-jentry hledger-run-command)
  :bind (:map hledger-mode-map
         ("C-c e" . hledger-jentry)
         ("C-c j" . hledger-run-command)
         ("M-p" . hledger/prev-entry)
         ("M-n" . hledger/next-entry))
  :init (add-hook 'hledger-mode-hook 'ledger-mode-outline-hook)
  :config
  (setq hledger-jfile "/home/daniel/cepheus/finances.ledger")
  ;; Auto-completion for account names
  (add-to-list 'company-backends 'hledger-company)

  (defun hledger/next-entry ()
    "Move to next entry and pulse."
    (interactive)
    (hledger-next-or-new-entry)
    (hledger-pulse-momentary-current-entry))

  (defun hledger/prev-entry ()
    "Move to last entry and pulse."
    (interactive)
    (hledger-backward-entry)
    (hledger-pulse-momentary-current-entry)))

(use-package ledger-mode
  ;;:disabled t  ;; try hledger
  :mode "\\.ledger\\'"
  :init
  ;; http://unconj.ca/blog/using-hledger-with-ledger-mode.html
  ;; Required to use hledger instead of ledger itself.
  ;;(setq ledger-mode-should-check-version nil
  ;;      ledger-report-links-in-register nil
  ;;      ledger-binary-path "hledger")

  (add-hook 'ledger-mode-hook 'ledger-mode-outline-hook)
  :config
  (setq ledger-reports
        '(("Balance (this year)" "%(binary) -f %(ledger-file) bal -p 'this year'")
          ("Balance (last year)" "%(binary) -f %(ledger-file) bal -p 'last year'")
          ("Balance (all time)" "%(binary) -f %(ledger-file) bal")
          ("Register (this year)" "%(binary) -f %(ledger-file) reg -p 'this year'")
          ("Register (last year)" "%(binary) -f %(ledger-file) reg -p 'last year'")
          ("Account (this year)" "%(binary) -f %(ledger-file) reg %(account) -p 'this year'")
          ("Account (last year)" "%(binary) -f %(ledger-file) reg %(account) -p 'last year'")
          ("Account (all time)" "%(binary) -f %(ledger-file) reg %(account)")
          ("Payee" "%(binary) -f %(ledger-file) reg @%(payee)")))

  (setq ledger-use-iso-dates t)  ; Use YYYY-MM-DD format

  ;;(add-to-list 'ledger-reports
  ;;             (list "monthly expenses"
  ;;                   (concat "%(binary) -f %(ledger-file) balance expenses "
  ;;                           "--tree --no-total --row-total --average --monthly")))
  ;; disable whitespace-mode in ledger reports
  (add-hook 'ledger-report-mode-hook (lambda () (whitespace-mode -1)))
  (setq ledger-post-amount-alignment-column 60))

(use-package flycheck-ledger
  :after (flycheck ledger-mode))

(use-package elfeed
  :defer t
  :bind (:map elfeed-show-mode-map
         ("d" . elfeed-search-youtube-dl)
         ;; Make n/p scroll and N/P switch articles
         ("N" . elfeed-show-next)
         ("P" . elfeed-show-prev)
         ("n" . scroll-up-line)
         ("p" . scroll-down-line)
         :map elfeed-search-mode-map
         ("RET" . elfeed-readability-show-entry)
         ;; M for unread like in mu4e where R is for reply
         ("m" . elfeed-search-untag-all-unread)
         ("M" . elfeed-mark-all-as-read)
         ("N" . elfeed-mark-all-read-and-next-tag)
         ("U" . elfeed-search-fetch)
         ("R" . elfeed-mark-all-as-read)
         ("x" . elfeed-reset-filter)
         ("t" . elfeed-toggle-tags)
         ("y" . elfeed-toggle-youtube)
         ("l" . elfeed-show-log)
         ("d" . elfeed-search-youtube-dl)
         ("D" . elfeed-search-youtube-dl-slow)
         ("L" . youtube-dl-list))
  :config
  ;; Config from https://github.com/skeeto/.emacs.d/blob/master/etc/feed-setup.el
  (setq-default elfeed-search-filter "@1-week-ago -youtube +unread")

  (defun elfeed-mark-all-as-read ()
    "Mark all as read."
    (interactive)
    (call-interactively 'mark-whole-buffer)
    (elfeed-search-untag-all-unread))

  (defun elfeed-reset-filter ()
    "Reset filter."
    (interactive)
    (elfeed-search-set-filter (default-value 'elfeed-search-filter)))

  (defun elfeed-show-log ()
    "Show elfeed log buffer."
    (interactive)
    (switch-to-buffer (elfeed-log-buffer)))

  ;; Download the readable part of the original website
  ;; like in Firefox's article view
  ;; XXX: Instead of external python script use `eww-readable'
  (setq elfeed-readability-script "~/bin/read_url.py")
  (setq elfeed-readability-url-regex "www\\.\\(heise\\|tagesschau\\)\\.de")

  (defun elfeed-readability-content (entry)
    "Replace entry content with readability article.
Some feeds (like heise.de) only provide a summary and not the full article.
This uses a python script to fetch the readable part of the original
article content.  Like in Firefox article view."
    (unless (elfeed-meta entry :readability)
      (let ((url (elfeed-entry-link entry)))
        (message "Downloading article content for: %s" url)
        (setf (elfeed-entry-content entry)
              (elfeed-ref (shell-command-to-string (format "%s %s" elfeed-readability-script url))))
        (setf (elfeed-meta entry :readability) t))))

  ;; Uncomment this if you always want to fetch the readability article content.
  ;; As the python script runs synchronously it makes Emacs "hang" while downloading content.
  ;; (add-hook 'elfeed-new-entry-hook
  ;;           (elfeed-make-tagger :feed-url elfeed-readability-url-regex
  ;;                               :callback #'elfeed-readability-content))

  (defun elfeed-readability-show-entry (entry)
    "Download readable content from website and show entry in a buffer.
This command is like `elfeed-search-show-entry' but it first downloads the
readable website content if the entry url matches `elfeed-readability-url-regex'."
    (interactive (list (elfeed-search-selected :ignore-region)))
    (when (string-match-p elfeed-readability-url-regex (elfeed-entry-link entry))
      (elfeed-readability-content entry))
    (elfeed-search-show-entry entry))

  (defun elfeed-mark-all-read-and-next-tag ()
    "Marks all as read and filters by another tag."
    (interactive)
    ;; Only toggle all as read if we're not in the overview
    (unless (eq elfeed-search-filter (default-value 'elfeed-search-filter))
      (elfeed-mark-all-as-read))
    (elfeed-toggle-tags))

  (defun elfeed-toggle-tags ()
    "Iterate over taglist and set filter for each tag."
    (interactive)
    ;; FIXME: simplify list
    (cl-macrolet ((re (re rep str) `(replace-regexp-in-string ,re ,rep ,str)))
      (elfeed-search-set-filter
       (cond
        ((string-match-p "-youtube" elfeed-search-filter)
         (re " *-youtube" " +emacs" elfeed-search-filter))
        ((string-match-p "\\+emacs" elfeed-search-filter)
         (re " *\\+emacs" " +python" elfeed-search-filter))
        ((string-match-p "\\+python" elfeed-search-filter)
         (re " *\\+python" " +dev" elfeed-search-filter))
        ((string-match-p "\\+dev" elfeed-search-filter)
         (re " *\\+dev" " +fefe" elfeed-search-filter))
        ((string-match-p "\\+fefe" elfeed-search-filter)
         (re " *\\+fefe" " +mma" elfeed-search-filter))
        ((string-match-p "\\+mma" elfeed-search-filter)
         (re " *\\+mma" " +chess" elfeed-search-filter))
        ((string-match-p "\\+chess" elfeed-search-filter)
         (re " *\\+chess" " +poker" elfeed-search-filter))
        ((string-match-p "\\+poker" elfeed-search-filter)
         (re " *\\+poker" " +health" elfeed-search-filter))
        ((string-match-p "\\+health" elfeed-search-filter)
         (re " *\\+health" " +news" elfeed-search-filter))
        ((string-match-p "\\+news" elfeed-search-filter)
         (re " *\\+news" " -youtube" elfeed-search-filter))
        ((concat elfeed-search-filter " -youtube")))))
    ;; Skip tags when there's no result
    (unless (or (string-match-p "-youtube" elfeed-search-filter) (elfeed-search-selected t))
      (elfeed-toggle-tags)))

  (defun elfeed-toggle-unread ()
    "Toggle unread filter"
    (interactive)
    (cl-macrolet ((re (re rep str) `(replace-regexp-in-string ,re ,rep ,str)))
      (elfeed-search-set-filter
       (cond
        ((string-match-p "-unread" elfeed-search-filter)
         (re " *-unread" " +unread" elfeed-search-filter))
        ((string-match-p "\\+unread" elfeed-search-filter)
         (re " *\\+unread" " -unread" elfeed-search-filter))
        ((concat elfeed-search-filter " -unread"))))))

  ;; Some youtube helpers
  (defun elfeed-toggle-youtube ()
    "Toggle youtube filter"
    (interactive)
    (cl-macrolet ((re (re rep str) `(replace-regexp-in-string ,re ,rep ,str)))
      (elfeed-search-set-filter
       (cond
        ((string-match-p "-youtube" elfeed-search-filter)
         (re " *-youtube" " +youtube" elfeed-search-filter))
        ((string-match-p "\\+youtube" elfeed-search-filter)
         (re " *\\+youtube" " -youtube" elfeed-search-filter))
        ((concat elfeed-search-filter " -youtube"))))))

  (defun elfeed-show-youtube-dl ()
    "Download the current entry with youtube-dl."
    (interactive)
    (pop-to-buffer (youtube-dl (elfeed-entry-link elfeed-show-entry))))

  (cl-defun elfeed-search-youtube-dl (&key slow)
    "Download the current entry with youtube-dl."
    (interactive)
    (let ((entries (elfeed-search-selected)))
      (dolist (entry entries)
        (if (null (youtube-dl (elfeed-entry-link entry)
                              :title (elfeed-entry-title entry)
                              :slow slow))
            (message "Entry is not a YouTube link!")
          (message "Downloading %s" (elfeed-entry-title entry)))
        (elfeed-untag entry 'unread)
        (elfeed-search-update-entry entry)
        (unless (use-region-p) (forward-line)))))

  (defalias 'elfeed-search-youtube-dl-slow
    (elfeed-expose #'elfeed-search-youtube-dl :slow t)
    "Slowly download the current entry with youtube-dl.")

  ;; Custom faces

  (defface elfeed-comic
    '((t :foreground "#BFF"))
    "Marks comics in Elfeed."
    :group 'elfeed)

  (push '(comic elfeed-comic)
        elfeed-search-face-alist)

  (defface elfeed-youtube
    '((t :foreground "#f9f"))
    "Marks YouTube videos in Elfeed."
    :group 'elfeed)

  (push '(youtube elfeed-youtube)
        elfeed-search-face-alist)

  (defface elfeed-important
    '((t :foreground "#E33"))
    "Marks important entries in Elfeed."
    :group 'elfeed)

  (push '(important elfeed-important)
        elfeed-search-face-alist)

  ;; Special filters

  (add-hook 'elfeed-new-entry-hook
            (elfeed-make-tagger :before "7 days ago"
                                :remove 'unread))

  ;; The actual feeds listing

  (defvar youtube-feed-format
    '(("^UC" . "https://www.youtube.com/feeds/videos.xml?channel_id=%s")
      ("^PL" . "https://www.youtube.com/feeds/videos.xml?playlist_id=%s")
      (""    . "https://www.youtube.com/feeds/videos.xml?user=%s")))

  (defun elfeed--expand (listing)
    "Expand feed URLs depending on their tags."
    (cl-destructuring-bind (url . tags) listing
      (cond
       ((member 'youtube tags)
        (let* ((case-fold-search nil)
               (test (lambda (s r) (string-match-p r s)))
               (format (cl-assoc url youtube-feed-format :test test)))
          (cons (format (cdr format) url) tags)))
       (listing))))

  (defmacro elfeed-config (&rest feeds)
    "Minimizes feed listing indentation without being weird about it."
    (declare (indent 0))
    `(setf elfeed-feeds (mapcar #'elfeed--expand ',feeds)))

  (elfeed-config
    ("http://blog.atomx.com/rss" atomx)

    ("http://www.bildblog.de/wp-rss2.php" news german)
    ("http://blog.fefe.de/rss.xml?html" news german fefe)
    ("http://www.gruenderszene.de/feed" news german)
    ("http://www.tagesschau.de/xml/rss2" news german)

    ("http://blog.chromium.org/feeds/posts/default" dev web)
    ("http://blog.angularjs.org/feeds/posts/default" dev web js)

    ("http://www.archlinux.org/feeds/news/" dev important)
    ("http://www.heise.de/newsticker/heise-atom.xml" dev)
    ("http://feeds.feedburner.com/codinghorror/" dev)
    ("http://googledevelopers.blogspot.com/atom.xml" dev google)
    ("https://cloudblog.withgoogle.com/rss/" dev google)
    ("https://blogs.msdn.microsoft.com/oldnewthing/feed" dev)
    ("http://blog.dubbelboer.com/atom.xml" dev friends)

    ("https://blog.golang.org/feeds/posts/default" dev go)

    ("http://codelike.com/blog/feed" dev friends python)
    ("http://planet.python.org/rss20.xml" dev python)
    ("http://planet.scipy.org/rss20.xml" dev python)
    ("http://feeds.doughellmann.com/PyMOTW" dev python)
    ("https://blogs.msdn.microsoft.com/pythonengineering/feed/" dev python)

    ("https://scripter.co/posts/index.xml" dev emacs)
    ("http://www.holgerschurig.de/topics/emacs/index.xml" dev emacs)
    ("http://planet.emacsen.org/atom.xml" dev emacs)
    ("http://feeds.feedburner.com/XahsEmacsBlog" dev emacs)
    ("https://oremacs.com/atom.xml" dev emacs)
    ("http://sachachua.com/blog/category/emacs/feed/" dev emacs)
    ("http://emacsredux.com/atom.xml" dev emacs)
    ("http://kitchingroup.cheme.cmu.edu/blog/feed" dev emacs)
    ("http://lisperator.net/atom" dev emacs)
    ("http://planet.lisp.org/rss20.xml" dev lisp)
    ("https://emacs.stackexchange.com/feeds" dev stackexchange emacs)

    ("http://nutrientjournal.com/feed/" health)
    ("http://suppversity.blogspot.com/feeds/posts/default" health)
    ("http://mountaindogdiet.com/feed/" health)
    ("https://examine.com/nutrition/rss/" health)

    ;; "https://en.chessbase.com/feed" is broken: elfeed says "Unknown feed type"
    ("http://feeds.feedburner.com/chessbase/mNmu" chess)

    ("http://www.twoplustwo.com/two-plus-two-magazine-rss.xml" poker)
    ("http://www.highstakesdb.com/rss.aspx" poker)

    ("http://www.mmafighting.com/rss.xml" mma)
    ("http://www.terrencechanpoker.com/feeds/posts/default" mma)

    ("http://xkcd.com/rss.xml" comic)

    ("http://googleblog.blogspot.com/atom.xml" news google)

    ("1veritasium" youtube education)
    ("UCsXVk37bltHxD1rDPwtNM8Q" youtube education) ; Kurzgesagt – In a Nutshell
    ("Wendoverproductions" youtube education)
    ("minutephysics" youtube education)
    ("SciShow" youtube education)
    ("AsapSCIENCE" youtube education)
    ("UCAuUUnT6oDeKwE6v1NGQxug" youtube education)  ; TED
    ("UCsooa4yRKGN_zEE8iknghZA" youtube education)  ; TED-Ed
    ("Vsauce" youtube education)
    ("PowerPlayChess" youtube chess)
    ("UC2TXq_t06Hjdr2g_KdKpHQg" youtube dev)  ; media.ccc.de
    ("BroScienceLife" youtube comedy)
    ("cgpgrey" youtube education)
    ("ufc" youtube mma)
    ("MMAFightingonSBN" youtube mma)))

(use-package info-beamer
  :hook (lua-mode . info-beamer-mode))

(use-package nov
  :mode ("\\.epub\\'" . nov-mode))

;; Read and manage your pocket (getpocket.com) list
(use-package pocket-reader
  :defer t)

;; Tag articles with 'capture' in pocket and then call
;; org-pocket-capture-items to save all tagged articles in an org file
(use-package org-pocket
  :after (pocket-reader org)
  :config (setq org-pocket-capture-file "org/pocket.org"))

;; Use 'C-c S' or 'M-s M-w' for 'eww-search-words' current region
;;(define-key prelude-mode-map (kbd "C-c S") nil)  ; remove default crux find-shell-init keybinding
(global-set-key (kbd "C-c S") 'eww-search-words)

(use-package browse-url
  :bind (("C-c u" . browse-url-at-point))
  :init
  (defun dakra-toggle-browser ()
    "Toggle browser function between eww and Firefox."
    (interactive)
    (if (eq browse-url-browser-function 'eww-browse-url)
        (progn
          (setq browse-url-browser-function 'browse-url-firefox)
          (message "Setting browser to Firefox"))
      (setq browse-url-browser-function 'eww-browse-url)
      (message "Setting browser to eww")))
  :config
  (setq browse-url-firefox-program "firefox-developer-edition")
  (setq browse-url-browser-function 'browse-url-firefox))

(use-package eww
  :defer t
  :config (setq eww-search-prefix "https://google.com/search?q="))

;; wolfram alpha queries (M-x wolfram-alpha)
(use-package wolfram
  :defer t
  :config
  (setq wolfram-alpha-app-id "KTKV36-2LRW2LELV8"))

(use-package tea-timer
  :defer t)

(use-package web-server
  :config
  (defvar web-server-file-server nil
    "Is the file server running? Holds an instance if so.")
  (defvar web-server-file-server-default-port 8888
    "Default port the file web server listens to when not calles with prefix argument.")
  (defvar web-server-old-global-mode-string nil)  ; XXX: Make nicer solution to display in mode line

  (defun web-server-file-server-toggle ()
    "Toggle file-server start/stop."
    (interactive)
    (if web-server-file-server
        (web-server-file-server-stop)
      (web-server-file-server-start web-server-file-server-default-port)))

  (defun web-server-file-server-start (&optional port)
    "Start a file server on a `PORT', serving the content of directory
associated with the current buffer's file."
    (interactive "p")
    (if web-server-file-server
        (message "File server is already running!")
      (when (= port 1)
        (setq port web-server-file-server-default-port))
      (lexical-let ((docroot (if (buffer-file-name)
                                 (file-name-directory (buffer-file-name))
                               (expand-file-name default-directory))))
        (setf web-server-file-server
              (ws-start
               (lambda (request)
                 (with-slots (process headers) request
                   (let ((path (substring (cdr (assoc :GET headers)) 1)))
                     (if (ws-in-directory-p docroot path)
                         (if (file-directory-p path)
                             (ws-send-directory-list process
                                                     (expand-file-name path docroot)
                                                     "^[^\.]")
                           (ws-send-file process (expand-file-name path docroot)))
                       (ws-send-404 process)))))
               port
               nil  ; no log buffer
               :host "0.0.0.0"))
        (setq web-server-old-global-mode-string global-mode-string)
        (add-to-list 'global-mode-string (format " fs:%d" port) t)
        (message "Serving files from %s on port %d" docroot port))))

  (defun web-server-file-server-stop ()
    "Stop the file server if running."
    (interactive)
    (if web-server-file-server
        (progn
          (ws-stop web-server-file-server)
          (setf web-server-file-server nil)
          (setq global-mode-string web-server-old-global-mode-string)
          (message "File server stopped."))
      (message "No file server is running."))))

(use-package esup
  :defer t
  :config (setq esup-user-init-file "~/.emacs.d/emacs.el"))

(defun borg-sync-drone-urls ()
  "Offer to update outdated upstream urls of all drones."
  (interactive)
  (let (moved)
    (dolist (drone (borg-clones))
      (let ((a (borg-get drone "url"))
            (b (ignore-errors (oref (epkg drone) url))))
        (when (and a b (not (magit--github-url-equal a b)))  ;; when (and b (not (magit--forge-url-equal a b)))
          (push (list drone a b) moved))))
    (when (and moved
               (yes-or-no-p
                (concat (mapconcat (pcase-lambda (`(,drone ,a ,b))
                                     (format "%s: %s => %s" drone a b))
                                   moved "\n")
                        "\n\nThese upstream repositories appear to have moved."
                        "\s\sUpdate local configuration accordingly? ")))
      (let ((default-directory borg-user-emacs-directory))
        (pcase-dolist (`(,drone ,_ ,b) moved)
          (process-file "git" nil nil nil "config" "-f" ".gitmodules"
                        (format "submodule.%s.url" drone) b))
        (process-file "git" nil nil nil "submodule" "sync")))))

(message "Loading %s...done (%.3fs)" user-init-file
         (float-time (time-subtract (current-time)
                                    before-user-init-time)))
(add-hook 'after-init-hook
          (lambda ()
            (message
             "Loading %s...done (%.3fs) [after-init]" user-init-file
             (float-time (time-subtract (current-time)
                                        before-user-init-time)))
            ;; Restore original file name handlers
            (setq file-name-handler-alist file-name-handler-alist-old)
            ;; Let's lower our GC thresholds back down to a sane level.
            (setq gc-cons-threshold (* 20 1024 1024)))
          t)
