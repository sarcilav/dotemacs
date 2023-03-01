;; Clean interface
(setq inhibit-startup-message t)
(menu-bar-mode 1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(mouse-wheel-mode t)
(line-number-mode 1)
(column-number-mode 1)
(global-font-lock-mode t)
(show-paren-mode 1)
(prefer-coding-system 'utf-8)
(blink-cursor-mode t)

;; nice fonts in OS X
(setq mac-allow-anti-aliasing t)
(set-frame-font "-PfEd-Monoid HalfLoose-normal-normal-semicondensed-*-*-*-*-*-*-0-iso10646-1")
(set-face-attribute 'default nil :height 180)

;; interpret and use ansi color codes in shell output windows
(autoload 'ansi-color-for-comint-mode-on "ansi-color" nil t)

;; Theme
(load-theme 'creamsody)
(creamsody-modeline-one)

(set-cursor-color "#e47133")
;; no tabs
(setq-default indent-tabs-mode nil)

;; Electric mode
(electric-indent-mode)
(electric-pair-mode)

;; Enable auto-fill
;; (setq-default auto-fill-function 'do-auto-fill)

;; default window size
(set-frame-height (selected-frame) 50)
(set-frame-width (selected-frame) 127)
(set-frame-position (selected-frame) 0 0)

;; Change c indent to linux style
(setq c-default-style "linux"
      c-basic-offset 2)

;; Change coffee tabs to 2 spaces
(custom-set-variables '(coffee-tab-width 2))

;; change js indent
(setq js-indent-level 2)

;; Ibuffer
;; Use human readable Size column instead of original one
(require 'ibuffer)
(define-ibuffer-column size-h
  (:name "Size" :inline t)
  (cond
   ((> (buffer-size) 1000000) (format "%7.1fM" (/ (buffer-size) 1000000.0)))
   ((> (buffer-size) 100000) (format "%7.0fk" (/ (buffer-size) 1000.0)))
   ((> (buffer-size) 1000) (format "%7.1fk" (/ (buffer-size) 1000.0)))
   (t (format "%8d" (buffer-size)))))

;; Modify the default ibuffer-formats
(setq ibuffer-formats
      '((mark modified read-only " "
              (name 20 20 :left :elide)
              " "
              (size-h 9 -1 :right)
              " "
              (mode 10 10 :left :elide)
              " "
              filename-and-process)))


;; Transparency
 (defun transparency (value)
   "Sets the transparency of the frame window. 0=transparent/100=opaque"
   (interactive "nTransparency Value 0 - 100 opaque:")
   (set-frame-parameter (selected-frame) 'alpha value))

;; Subtle ring bell
(setq ring-bell-function
      (lambda ()
        (let ((orig-fg (face-foreground 'mode-line)))
          (set-face-foreground 'mode-line "#F2804F")
          (run-with-idle-timer 0.1 nil
                               (lambda (fg) (set-face-foreground 'mode-line fg))
                               orig-fg))))
