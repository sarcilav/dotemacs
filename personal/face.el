;; Clean interface
(setq inhibit-startup-message t)
(menu-bar-mode 1)
(tool-bar-mode -1)
(scroll-bar-mode nil)
(mouse-wheel-mode t)
(line-number-mode 1)
(column-number-mode 1)
(global-font-lock-mode t)
(show-paren-mode 1)
(prefer-coding-system 'utf-8)
(blink-cursor-mode t)

;; nice fonts in OS X
(setq mac-allow-anti-aliasing t)
(set-default-font "-apple-inconsolata-medium-r-normal--0-0-0-0-m-0-iso10646-1")
(set-face-attribute 'default nil :height 180)

;; interpret and use ansi color codes in shell output windows
(autoload 'ansi-color-for-comint-mode-on "ansi-color" nil t)

;; Theme
(load-theme 'leuven) ;; only works on emacs 24

;; no tabs
(setq-default indent-tabs-mode nil)

;; Electric mode
(electric-indent-mode)
(electric-pair-mode)

;; Enable auto-fill
;; (setq-default auto-fill-function 'do-auto-fill)

;; default window size
(set-frame-height (selected-frame) 50)
(set-frame-width (selected-frame) 140)
(set-frame-position (selected-frame) 0 0)

;; Change c indent to linux style
(setq c-default-style "linux"
      c-basic-offset 2)

;; Change coffee tabs to 2 spaces
(custom-set-variables '(coffee-tab-width 2))

