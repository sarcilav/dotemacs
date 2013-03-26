;; hippie-exp from topfunky dotemacs, trying to have a nice tab
;; Remove scrollbars and make hippie expand
;; work nicely with yasnippet
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(require 'hippie-exp)
(setq hippie-expand-try-functions-list
      '(yas-hippie-try-expand
        try-expand-dabbrev
        try-expand-dabbrev-visible
        try-expand-dabbrev-all-buffers))

(setq user-mail-address "sebastianarcila@gmail.com")
(setq user-full-name "Sebastian Arcila-Valenzuela")

;; set path

(let ((path))
  (setq path (concat "/usr/local/heroku/bin:"
                     "/usr/bin:"
                     "/bin:"
                     "/usr/sbin:"
                     "/sbin:"
                     "/usr/local/bin:"
                     "/opt/X11/bin:"
                     "/usr/texbin:"
                     "~/.rvm/bin"))
  (setenv "PATH" path))
