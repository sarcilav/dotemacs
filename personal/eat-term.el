(require 'eat)

(setq eat-kill-buffer-on-exit t)

(defvar my/eat-shell "/opt/homebrew/bin/bash --login"
  "Shell command for eat terminals. Multi-word is fine: eat wraps it in `sh -c'.")

(defvar my/eat-buffer-list nil
  "Ordered list of live eat terminal buffers, mirroring multi-term-buffer-list.")

(defun my/eat-on-exec (proc)
  "Register a new eat terminal buffer in `my/eat-buffer-list'."
  (let ((buf (process-buffer proc)))
    (unless (memq buf my/eat-buffer-list)
      (setq my/eat-buffer-list (nconc my/eat-buffer-list (list buf))))))

(defun my/eat-on-exit (proc)
  "Switch to the next eat buffer and remove the closed one from the list."
  (let* ((closed (process-buffer proc))
         (other  (seq-find (lambda (b) (not (eq b closed)))
                           my/eat-buffer-list)))
    (when other (switch-to-buffer other))
    (setq my/eat-buffer-list (delq closed my/eat-buffer-list))))

(add-hook 'eat-exec-hook #'my/eat-on-exec)
(add-hook 'eat-exit-hook #'my/eat-on-exit)

(defun my/eat (&optional arg)
  "Create a new eat terminal (login bash).
With a numeric prefix ARG, switch to terminal number ARG instead."
  (interactive "P")
  (eat my/eat-shell (if (numberp arg) arg t)))

(defun my/eat-switch (direction)
  "Cycle eat buffers; DIRECTION is `next or `previous."
  (let* ((bufs (seq-filter #'buffer-live-p my/eat-buffer-list))
         (idx  (seq-position bufs (current-buffer))))
    (cond
     ((null bufs) (my/eat))
     ((null idx)  (switch-to-buffer (car bufs)))
     (t (switch-to-buffer
         (nth (mod (+ idx (if (eq direction 'next) 1 -1)) (length bufs))
              bufs))))))

(defun my/eat-next ()
  "Switch to the next eat terminal buffer."
  (interactive)
  (my/eat-switch 'next))

(defun my/eat-prev ()
  "Switch to the previous eat terminal buffer."
  (interactive)
  (my/eat-switch 'previous))

(defun my/eat-project (&optional arg)
  "Switch to or create an eat terminal at the project root (login bash).
With a non-numeric prefix ARG, create a new project terminal."
  (interactive "P")
  (require 'project)
  (let* ((default-directory (project-root (project-current t)))
         (eat-buffer-name (project-prefixed-buffer-name "eat")))
    (eat my/eat-shell arg)))

(define-key eat-semi-char-mode-map (kbd "M-]") #'my/eat-next)
(define-key eat-semi-char-mode-map (kbd "M-[") #'my/eat-prev)

(defun my/eat-alert-default-style ()
  "Return the preferred alert style for eat supervisor notifications."
  (cond ((and (eq system-type 'darwin)
              (executable-find "terminal-notifier"))
         'notifier)
        ((eq system-type 'darwin)    'osx-notifier)
        ((eq system-type 'gnu/linux) 'libnotify)
        (t                           'message)))

(require 'eat-supervisor)
(if (require 'alert nil t)
    (progn
      (setq alert-default-style (my/eat-alert-default-style))
      (my/eat-supervisor-mode 1))
  (message "eat-supervisor: alert.el not installed; supervisor mode left off."))

(provide 'eat-term)
