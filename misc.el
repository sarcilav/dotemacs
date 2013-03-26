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
