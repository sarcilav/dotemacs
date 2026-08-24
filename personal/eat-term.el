(require 'eat)
(require 'seq)

(setq eat-kill-buffer-on-exit t
      ;; Eat implements terminal-requested cursor blink by toggling a buffer-local
      ;; timer that calls `redraw-frame', which can make GUI frames flicker.
      eat-enable-blinking-text nil
      eat-very-visible-cursor-type (list (car eat-default-cursor-type) nil nil)
      eat-very-visible-vertical-bar-cursor-type '(bar nil nil)
      eat-very-visible-horizontal-bar-cursor-type '(hbar nil nil))

(defvar my/eat-shell "/opt/homebrew/bin/bash --login"
  "Shell command for eat terminals. Multi-word is fine: eat wraps it in `sh -c'.")

(defvar my/eat-buffer-list nil
  "Ordered list of live eat terminal buffers, mirroring multi-term-buffer-list.")

(defcustom my/eat-resize-debounce-delay 0.2
  "Seconds to wait before applying the latest Eat terminal size.
Set this to zero to resize synchronously after every window change."
  :type 'number
  :group 'eat)

(defvar my/eat--resizing nil
  "Non-nil while applying a resize-only Eat update.")

(defvar my/eat--force-resize nil
  "Non-nil while a pending Eat resize is being applied.")

(defvar-local my/eat--resize-timer nil
  "Timer waiting to apply this Eat buffer's latest window size.")

(defvar-local my/eat--base-window-size-function nil
  "Window-size function wrapped by `my/eat--debounced-window-size'.")

(defun my/eat--cancel-resize-timer ()
  "Cancel the pending resize timer in the current buffer."
  (when (timerp my/eat--resize-timer)
    (cancel-timer my/eat--resize-timer))
  (setq my/eat--resize-timer nil))

(defun my/eat--apply-pending-resize (buffer)
  "Apply the settled terminal size for Eat BUFFER."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (setq my/eat--resize-timer nil)
      (let ((proc (get-buffer-process buffer))
            (windows (get-buffer-window-list buffer nil 'visible)))
        (when (and (process-live-p proc) windows eat-terminal)
          (let (size)
            (let ((my/eat--force-resize t)
                  (my/eat--resizing t))
              (setq size (eat--adjust-process-window-size proc windows)))
            (when size
              (set-process-window-size proc (cdr size) (car size)))))))))

(defun my/eat--schedule-resize (buffer)
  "Schedule a settled terminal resize for Eat BUFFER."
  (my/eat--cancel-resize-timer)
  (setq my/eat--resize-timer
        (run-at-time my/eat-resize-debounce-delay nil
                     #'my/eat--apply-pending-resize buffer)))

(defun my/eat--debounced-window-size (process windows)
  "Return a settled size for PROCESS displayed in WINDOWS.
Ordinary resize requests are coalesced.  A forced request delegates to the
window-size function that was active when the Eat buffer was configured."
  (let ((size-function (or my/eat--base-window-size-function
                           #'window-adjust-process-window-size-smallest)))
    (cond
     ((<= my/eat-resize-debounce-delay 0)
      (funcall size-function process windows))
     (my/eat--force-resize
      (let ((size (funcall size-function process windows)))
        (unless (and size eat-terminal
                     (equal size (eat-term-size eat-terminal)))
          size)))
     (t
      (my/eat--schedule-resize (current-buffer))
      nil))))

(defun my/eat--configure-resizing ()
  "Configure debounced process resizing in the current Eat buffer."
  (unless (eq window-adjust-process-window-size-function
              #'my/eat--debounced-window-size)
    (setq-local my/eat--base-window-size-function
                window-adjust-process-window-size-function))
  (setq-local window-adjust-process-window-size-function
              #'my/eat--debounced-window-size)
  (add-hook 'kill-buffer-hook #'my/eat--cancel-resize-timer nil t))

(add-hook 'eat-mode-hook #'my/eat--configure-resizing)

(defun my/eat-prune-buffer-list ()
  "Remove dead buffers from `my/eat-buffer-list'."
  (setq my/eat-buffer-list (seq-filter #'buffer-live-p my/eat-buffer-list)))

(defun my/eat-forget-current-buffer ()
  "Remove the current buffer from `my/eat-buffer-list'."
  (setq my/eat-buffer-list
        (delq (current-buffer) (my/eat-prune-buffer-list))))

(defun my/eat-switch-to-buffer-if-live (buf)
  "Switch to BUF if it is still live."
  (when (buffer-live-p buf)
    (switch-to-buffer buf)))

(defun my/eat-on-exec (proc)
  "Register a new eat terminal buffer in `my/eat-buffer-list'."
  (let ((buf (process-buffer proc)))
    (when (buffer-live-p buf)
      (my/eat-prune-buffer-list)
      (unless (memq buf my/eat-buffer-list)
        (setq my/eat-buffer-list (nconc my/eat-buffer-list (list buf))))
      (with-current-buffer buf
        (my/eat--cancel-resize-timer)
        (add-hook 'kill-buffer-hook #'my/eat-forget-current-buffer nil t)))))

(defun my/eat-on-exit (proc)
  "Remove the closed eat buffer and switch to another one after cleanup."
  (let* ((closed (process-buffer proc))
         (other  (car (delq closed (my/eat-prune-buffer-list)))))
    (setq my/eat-buffer-list (delq closed my/eat-buffer-list))
    (when (buffer-live-p closed)
      (with-current-buffer closed
        (my/eat--cancel-resize-timer)))
    (when (buffer-live-p other)
      (run-at-time 0 nil #'my/eat-switch-to-buffer-if-live other))))

(add-hook 'eat-exec-hook #'my/eat-on-exec)
(add-hook 'eat-exit-hook #'my/eat-on-exit)

(defun my/eat (&optional arg)
  "Create a new eat terminal (login bash).
With a numeric prefix ARG, switch to terminal number ARG instead."
  (interactive "P")
  (eat my/eat-shell (if (numberp arg) arg t)))

(defun my/eat-switch (direction)
  "Cycle eat buffers; DIRECTION is `next or `previous."
  (let* ((bufs (my/eat-prune-buffer-list))
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
