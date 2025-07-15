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
  (setq path (concat "/usr/local/bin:"
                     "/usr/local/sbin:"
                     "/usr/bin:"
                     "/bin:"
                     "/usr/sbin:"
                     "/sbin:"
                     "/usr/texbin:"
                     "~/.rvm/bin:"))
  (setenv "PATH" path))
(setq-default shell-file-name "/usr/bin/bash")


(setq dotfiles-dir (file-name-directory
                    (or (buffer-file-name) load-file-name)))

;; Don't add backup files everywhere
(setq backup-directory-alist `(("." . ,(expand-file-name
                                        (concat dotfiles-dir "backups")))))

;; Avoid to write all the time yes/no
(defalias 'yes-or-no-p 'y-or-n-p)

;; SLIME
;; (load (expand-file-name "~/quicklisp/slime-helper.el"))
;; Replace "sbcl" with the path to your implementation
;; (setq inferior-lisp-program "/usr/local/bin/sbcl")
;; (slime-setup '(slime-fancy))

;; Fold toggling
(defun toggle-fold ()
  "Toggle code folding according to indentation of current line."
  (interactive)
  (set-selective-display
   (if selective-display
       nil
     (save-excursion
       (back-to-indentation)
       (1+ (current-column))))))


(require 'tramp)
(add-to-list 'tramp-methods
  '("gcssh"
    (tramp-login-program        "gcloud compute ssh")
    (tramp-login-args           (("%h")))
    (tramp-async-args           (("-q")))
    (tramp-remote-shell         "/bin/bash")
    (tramp-remote-shell-args    ("-c"))
    (tramp-gw-args              (("-o" "GlobalKnownHostsFile=/dev/null")
                                 ("-o" "UserKnownHostsFile=/dev/null")
                                 ("-o" "StrictHostKeyChecking=no")))
    (tramp-default-port         22)))

(use-package copilot
  :vc (:url "https://github.com/copilot-emacs/copilot.el"
            :rev :newest
            :branch "main"))
