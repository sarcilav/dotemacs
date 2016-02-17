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
                     "/Applications/Emacs.app/Contents/MacOS/bin:"
                     "~/.rvm/bin"))
  (setenv "PATH" path)
  (add-to-list 'exec-path "/usr/local/bin"))

(setq dotfiles-dir (file-name-directory
                    (or (buffer-file-name) load-file-name)))

;; Don't add backup files everywhere
(setq backup-directory-alist `(("." . ,(expand-file-name
                                        (concat dotfiles-dir "backups")))))

;; Avoid to write all the time yes/no
(defalias 'yes-or-no-p 'y-or-n-p)

;; SLIME
(load (expand-file-name "~/quicklisp/slime-helper.el"))
;; Replace "sbcl" with the path to your implementation
(setq inferior-lisp-program "/usr/local/bin/sbcl")
(slime-setup '(slime-fancy))

;; Ask to save *scratch*
(defun try-to-save-*scratch*-and-exit ()
  "Ask to savewhether or not to save *scratch*, and then close if y was pressed"
  (interactive)
  (when (y-or-n-p (format "Do you want to save *scratch*? "))
    (switch-to-buffer "*scratch*")
    (interactive)
    (save-buffer))
  (save-buffers-kill-emacs))

(when window-system
  (global-set-key (kbd "C-x C-c") 'try-to-save-*scratch*-and-exit))
