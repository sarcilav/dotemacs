;;; eat-supervisor.el --- Supervisor view for eat agent terminals -*- lexical-binding: t -*-

(require 'eat)
(require 'tabulated-list)
(require 'cl-lib)
(require 'subr-x)
;; alert is loaded lazily; assume the user installs it before enabling the mode.
(declare-function alert "alert" (info &rest params))

;; my/eat-buffer-list lives in eat-term.el; declare to silence the byte-compiler
;; if eat-supervisor is loaded before eat-term has registered it.
(defvar my/eat-buffer-list)

;;; Customization

(defgroup my/eat-sup nil
  "Supervisor for eat coding-agent terminals."
  :group 'eat
  :prefix "my/eat-sup-")

(defcustom my/eat-sup-scan-interval 2.0
  "Seconds between supervisor scans of all eat buffers."
  :type 'number :group 'my/eat-sup)

(defcustom my/eat-sup-idle-debounce 5.0
  "Seconds a buffer must remain :idle before the idle alert fires."
  :type 'number :group 'my/eat-sup)

(defcustom my/eat-sup-working-window 15
  "Number of trailing lines scanned for :working markers."
  :type 'integer :group 'my/eat-sup)

(defcustom my/eat-sup-approval-window 10
  "Number of trailing lines scanned for :awaiting-approval markers."
  :type 'integer :group 'my/eat-sup)

(defcustom my/eat-sup-detect-window 50
  "Number of trailing lines scanned for agent detection."
  :type 'integer :group 'my/eat-sup)

(defcustom my/eat-sup-working-grace 30.0
  "If output was seen within this many seconds, allow :working state."
  :type 'number :group 'my/eat-sup)

(defcustom my/eat-sup-working-hold 6.0
  "Seconds to keep working after the last working title or output marker."
  :type 'number :group 'my/eat-sup)

(defvar my/eat-sup-working-re "esc to interrupt\\|✽ "
  "Regex matching any coding-agent working indicator (global fallback for agents
without a per-agent :working list in `my/eat-sup-patterns').")

(defvar my/eat-sup-patterns
  '((claude
     :detect ("Claude Code\\|claude\\.ai\\|anthropic")
     :title-working ("✻\\|✽"
                     "\\(?:^\\|[[:space:]]\\)[-+*][[:space:]]+[[:alpha:]][[:alpha:]-]*…")
     :title-awaiting-approval ("Do you want to proceed\\|Esc to cancel.*Tab to amend")
     :working ("[Ee]sc to interrupt"
               "[Ww]orking[.…]")
     :awaiting-approval ("Esc to cancel.*Tab to amend"
                         "Do you want to proceed"
                         "❯\\s-*1\\."))
    (codex
     :detect ("codex\\|OpenAI Codex")
     :title-working ("\\(?:^\\|[[:space:][:punct:]]\\)\\(?:[Tt]hinking\\|[Ww]orking\\|[Rr]unning\\)\\(?:[[:space:][:punct:]]\\|$\\)"
                     "⠋\\|⠙\\|⠹\\|⠸\\|⠼\\|⠴\\|⠦\\|⠧\\|⠇\\|⠏")
     :title-awaiting-approval ("[Aa]ction [Rr]equired"
                               "Allow .*\\?"
                               "\\[\\s-*!\\s-*\\]")
     :awaiting-approval ("enter to submit.*esc to cancel"
                         "Press enter to confirm or esc*"
                         "tab to add notes | enter to submit answer | esc to *"
                         "[Aa]ction [Rr]equired"
                         "›\\s-*1\\.\\s-*Allow"))
    (shell
     :idle ("[$#%❯>] *\\'")))
  "Per-agent regex patterns.
Each entry is (AGENT . PLIST).  PLIST may contain :detect, :title-working,
:title-awaiting-approval, :working, :awaiting-approval, and :idle, each with a
list of regexes.  Agent identity is set by shell-integration advice; :detect is
a cold-start fallback.  Agents without :working fall back to
`my/eat-sup-working-re'.")

;;; Buffer-local state

(defvar-local my/eat-sup--agent 'unknown)
(defvar-local my/eat-sup--state :unknown)
(defvar-local my/eat-sup--last-output 0.0)
(defvar-local my/eat-sup--last-working-marker 0.0)
(defvar-local my/eat-sup--last-state :unknown)
(defvar-local my/eat-sup--state-since 0.0)
(defvar-local my/eat-sup--idle-alerted nil)
(defvar-local my/eat-sup--session-active nil
  "Non-nil while a coding-agent command is running per shell-integration.
Set by `my/eat-sup--on-set-cmd'; cleared by `my/eat-sup--on-new-prompt'.
Guards idle alerts so text-detection flicker cannot fire spurious done alerts.")
(defvar-local my/eat-sup--pending-idle-agent nil
  "Agent whose completion should be reported when the prompt returns.")

;;; Shell-integration advice — agent identity

(defun my/eat-sup--on-set-cmd (cmd)
  "Detect agent from shell-integration preexec CMD (base64-encoded)."
  (when-let ((command (ignore-errors
                        (decode-coding-string
                         (base64-decode-string cmd)
                         locale-coding-system))))
    (let ((agent (cond
                  ((string-match-p "claude" command) 'claude)
                  ((string-match-p "codex"  command) 'codex)
                  (t 'shell))))
      (setq-local my/eat-sup--agent          agent
                  my/eat-sup--pending-idle-agent nil
                  my/eat-sup--session-active (memq agent '(claude codex))
                  my/eat-sup--last-working-marker 0.0))))

(defun my/eat-sup--on-new-prompt ()
  "Record agent completion before the shell prompt owns the buffer again.
Sets `my/eat-sup--pending-idle-agent' whenever a coding-agent session ends so
the done alert fires reliably regardless of whether working state was detected."
  (when (memq my/eat-sup--agent '(claude codex))
    (setq-local my/eat-sup--pending-idle-agent my/eat-sup--agent))
  (setq-local my/eat-sup--agent          'shell
              my/eat-sup--session-active nil
              my/eat-sup--last-working-marker 0.0))

;;; Faces

(defface my/eat-sup-awaiting '((t :foreground "red" :weight bold))
  "Face for :awaiting-approval rows.")
(defface my/eat-sup-working '((t :foreground "goldenrod"))
  "Face for :working rows.")
(defface my/eat-sup-idle '((t :foreground "green4"))
  "Face for :idle rows.")
(defface my/eat-sup-exited '((t :inherit shadow))
  "Face for :exited rows.")

;;; Helpers

(defun my/eat-sup--tail (n-lines)
  "Return the last N-LINES of current buffer, eat-filtered."
  (save-excursion
    (goto-char (point-max))
    (forward-line (- n-lines))
    (eat-term-filter-string
     (buffer-substring-no-properties (point) (point-max)))))

(defun my/eat-sup--title ()
  "Return the current Eat terminal title for this buffer, or nil."
  (when (and (boundp 'eat-terminal) eat-terminal)
    (ignore-errors
      (let ((title (eat-term-title eat-terminal)))
        (unless (string-empty-p title)
          title)))))

(defun my/eat-sup--match-any (regexes text)
  "Non-nil if any regex in REGEXES matches TEXT."
  (and regexes text
       (cl-some (lambda (re) (string-match-p re text)) regexes)))

(defun my/eat-sup--detect-agent ()
  "Return the agent symbol for the current buffer.
Prefers the buffer-local value set by shell-integration advice; falls back to
:detect text patterns for cold-start (e.g. supervisor enabled mid-session)."
  (if (not (eq my/eat-sup--agent 'unknown))
      my/eat-sup--agent
    (let ((detect-text (concat (or (my/eat-sup--title) "")
                               "\n"
                               (my/eat-sup--tail my/eat-sup-detect-window))))
      (or
       (cl-loop for (agent . plist) in my/eat-sup-patterns
                when (my/eat-sup--match-any (plist-get plist :detect) detect-text)
                return agent)
       (when (my/eat-sup--match-any
              (plist-get (alist-get 'shell my/eat-sup-patterns) :idle)
              (my/eat-sup--tail 1))
         'shell)
       'unknown))))

(defun my/eat-sup--awaiting-approval-p (plist title text)
  "Return non-nil when PLIST, TITLE, or TEXT indicate an approval prompt."
  (or (my/eat-sup--match-any (plist-get plist :title-awaiting-approval) title)
      (my/eat-sup--match-any (plist-get plist :awaiting-approval) text)))

(defun my/eat-sup--working-marker-p (plist title text)
  "Return non-nil when PLIST, TITLE, or TEXT indicate active agent work."
  (let ((agent-working (plist-get plist :working)))
    (or (my/eat-sup--match-any (plist-get plist :title-working) title)
        (if agent-working
            (my/eat-sup--match-any agent-working text)
          (and text (string-match-p my/eat-sup-working-re text))))))

(defun my/eat-sup--working-held-p (now)
  "Return non-nil when recent working evidence should still count at NOW."
  (and (memq my/eat-sup--agent '(claude codex))
       (> my/eat-sup--last-working-marker 0)
       (< (- now my/eat-sup--last-working-marker) my/eat-sup-working-hold)
       (< (- now my/eat-sup--last-output) my/eat-sup-working-grace)))

(defun my/eat-sup--detect-state (agent)
  "Return the state keyword for the current buffer given AGENT."
  (let* ((plist         (alist-get agent my/eat-sup-patterns))
         (proc          (get-buffer-process (current-buffer)))
         (title         (my/eat-sup--title))
         (working-text  (my/eat-sup--tail my/eat-sup-working-window))
         (now           (float-time))
         (working-p     (my/eat-sup--working-marker-p plist title working-text)))
    (when (and working-p
               (< (- now my/eat-sup--last-output) my/eat-sup-working-grace))
      (setq-local my/eat-sup--last-working-marker now))
    (cond
     ((not (process-live-p proc)) :exited)
     ((my/eat-sup--awaiting-approval-p
       plist title (my/eat-sup--tail my/eat-sup-approval-window))
      :awaiting-approval)
     ((and (or working-p (my/eat-sup--working-held-p now))
           (< (- now my/eat-sup--last-output) my/eat-sup-working-grace))
      :working)
     (t :idle))))

;;; Buffer init / output tracking

(defun my/eat-sup--note-output ()
  "Record the timestamp of the latest terminal output."
  (let ((now (float-time)))
    (setq-local my/eat-sup--last-output now)
    (when (eq my/eat-sup--agent 'unknown)
      (setq-local my/eat-sup--agent (my/eat-sup--detect-agent)))
    (let ((plist (alist-get my/eat-sup--agent my/eat-sup-patterns)))
      (when (and plist
                 (my/eat-sup--working-marker-p
                  plist
                  (my/eat-sup--title)
                  (my/eat-sup--tail my/eat-sup-working-window)))
        (setq-local my/eat-sup--last-working-marker now)))))

(defun my/eat-sup--init-buffer (proc)
  "Initialise supervisor state in PROC's buffer."
  (when-let ((buf (process-buffer proc)))
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (setq-local my/eat-sup--agent          'unknown
                    my/eat-sup--state          :unknown
                    my/eat-sup--last-output    (float-time)
                    my/eat-sup--last-working-marker 0.0
                    my/eat-sup--last-state     :unknown
                    my/eat-sup--state-since    (float-time)
                    my/eat-sup--idle-alerted   nil
                    my/eat-sup--session-active nil
                    my/eat-sup--pending-idle-agent nil)
        (add-hook 'eat-update-hook #'my/eat-sup--note-output nil t)))))

(defun my/eat-sup--on-exit (proc)
  "Fire the :exited alert for known agents when PROC dies."
  (when-let ((buf (process-buffer proc)))
    (when (buffer-live-p buf)
      (let ((agent (buffer-local-value 'my/eat-sup--agent buf)))
        (when (memq agent '(claude codex))
          (alert (format "%s in %s — exited"
                         (capitalize (symbol-name agent)) (buffer-name buf))
                 :category 'eat-agent :severity 'low :buffer buf))))))

;;; Scan & transitions

(defvar my/eat-sup--timer nil "Repeating scan timer.")

(defun my/eat-sup--alive-buffers ()
  "Live eat buffers from `my/eat-buffer-list'."
  (and (boundp 'my/eat-buffer-list)
       (seq-filter #'buffer-live-p my/eat-buffer-list)))

(defun my/eat-sup--scan ()
  "Recompute agent and state for every live eat buffer; fire transitions."
  (dolist (buf (my/eat-sup--alive-buffers))
    (with-current-buffer buf
      (when (eq my/eat-sup--agent 'unknown)
        (setq my/eat-sup--agent (my/eat-sup--detect-agent)))
      (let ((new-state (my/eat-sup--detect-state my/eat-sup--agent)))
        (unless (eq new-state my/eat-sup--state)
          (setq my/eat-sup--last-state  my/eat-sup--state
                my/eat-sup--state       new-state
                my/eat-sup--state-since (float-time)
                my/eat-sup--idle-alerted nil)
          (my/eat-sup--on-transition buf my/eat-sup--last-state new-state))
        (when (and (eq new-state :idle)
                   (not my/eat-sup--idle-alerted)
                   (not my/eat-sup--session-active)
                   (or my/eat-sup--pending-idle-agent
                       (memq my/eat-sup--last-state '(:working :awaiting-approval)))
                   (>= (- (float-time) my/eat-sup--state-since)
                       my/eat-sup-idle-debounce))
          (my/eat-sup--alert-idle buf)
          (setq my/eat-sup--idle-alerted t)))))
  (my/eat-sup--update-display))

(defun my/eat-sup--on-transition (buf _old new)
  "Fire alerts for the transition into NEW state in BUF."
  (let ((agent (buffer-local-value 'my/eat-sup--agent buf)))
    (when (memq agent '(claude codex))
      (cond
       ((eq new :awaiting-approval)
        (alert (format "%s in %s — awaiting approval"
                       (capitalize (symbol-name agent)) (buffer-name buf))
               :category 'eat-agent :severity 'high :buffer buf))))))

(defun my/eat-sup--alert-idle (buf)
  "Fire the debounced active-to-idle alert for BUF."
  (with-current-buffer buf
    (let ((agent (or my/eat-sup--pending-idle-agent my/eat-sup--agent)))
      (when (memq agent '(claude codex))
        (alert (format "%s in %s — done"
                       (capitalize (symbol-name agent)) (buffer-name buf))
               :category 'eat-agent :severity 'normal :buffer buf)
        (when my/eat-sup--pending-idle-agent
          (setq-local my/eat-sup--agent 'shell
                      my/eat-sup--pending-idle-agent nil))))))

;;; Supervisor list buffer

(defvar my/eat-supervisor-buffer-name "*Eat Supervisor*")

(defun my/eat-sup--state-face (state)
  (pcase state
    (:awaiting-approval 'my/eat-sup-awaiting)
    (:working           'my/eat-sup-working)
    (:idle              'my/eat-sup-idle)
    (:exited            'my/eat-sup-exited)
    (_                  'default)))

(defun my/eat-sup--format-state (state)
  (propertize (substring (symbol-name state) 1)
              'face (my/eat-sup--state-face state)))

(defun my/eat-sup--format-idle (since)
  (let ((s (truncate (- (float-time) since))))
    (cond ((< s 60)   (format "%ds" s))
          ((< s 3600) (format "%dm%02ds" (/ s 60) (mod s 60)))
          (t          (format "%dh%02dm" (/ s 3600) (/ (mod s 3600) 60))))))

(defun my/eat-sup--list-entries ()
  (cl-loop for buf in (my/eat-sup--alive-buffers)
           collect
           (with-current-buffer buf
             (list buf
                   (vector (symbol-name my/eat-sup--agent)
                           (my/eat-sup--format-state my/eat-sup--state)
                           (my/eat-sup--format-idle my/eat-sup--state-since)
                           (buffer-name buf)
                           (abbreviate-file-name default-directory))))))

(defun my/eat-sup--visit ()
  (interactive)
  (when-let ((buf (tabulated-list-get-id)))
    (when (buffer-live-p buf) (switch-to-buffer buf))))

(defun my/eat-sup--visit-other-window ()
  (interactive)
  (when-let ((buf (tabulated-list-get-id)))
    (when (buffer-live-p buf) (switch-to-buffer-other-window buf))))

(defun my/eat-sup--kill-buffer ()
  (interactive)
  (when-let ((buf (tabulated-list-get-id)))
    (when (and (buffer-live-p buf)
               (yes-or-no-p (format "Kill %s? " (buffer-name buf))))
      (kill-buffer buf)
      (tabulated-list-revert))))

(defvar my/eat-supervisor-list-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m (kbd "RET") #'my/eat-sup--visit)
    (define-key m (kbd "o")   #'my/eat-sup--visit-other-window)
    (define-key m (kbd "k")   #'my/eat-sup--kill-buffer)
    m)
  "Keymap for `my/eat-supervisor-list-mode'.")

(define-derived-mode my/eat-supervisor-list-mode tabulated-list-mode
  "EatSupervisor"
  "Tabulated view of live eat agent terminals."
  (setq tabulated-list-format
        [("Agent"  10 t)
         ("State"  18 t)
         ("Idle"    8 t)
         ("Buffer" 24 t)
         ("CWD"     0 t)])
  (setq tabulated-list-entries #'my/eat-sup--list-entries)
  (tabulated-list-init-header))

(defun my/eat-sup-debug-title ()
  "Show the current Eat terminal title for the selected buffer."
  (interactive)
  (message "eat title: %s" (or (my/eat-sup--title) "")))

;;;###autoload
(defun my/eat-supervisor ()
  "Open the eat supervisor buffer."
  (interactive)
  (let ((buf (get-buffer-create my/eat-supervisor-buffer-name)))
    (with-current-buffer buf
      (my/eat-supervisor-list-mode)
      (tabulated-list-revert))
    (pop-to-buffer buf)))

;;; Mode-line indicator

(defvar my/eat-sup--mode-line-string ""
  "Cached mode-line segment, refreshed on every scan.")
;;;###autoload
(put 'my/eat-sup--mode-line-string 'risky-local-variable t)

(defun my/eat-sup--counts ()
  (let ((aw 0) (wk 0))
    (dolist (buf (my/eat-sup--alive-buffers))
      (pcase (buffer-local-value 'my/eat-sup--state buf)
        (:awaiting-approval (cl-incf aw))
        (:working           (cl-incf wk))))
    (list :awaiting aw :working wk)))

(defun my/eat-sup--build-mode-line ()
  (let* ((c  (my/eat-sup--counts))
         (aw (plist-get c :awaiting))
         (wk (plist-get c :working)))
    (if (and (zerop aw) (zerop wk))
        ""
      (let ((map (make-sparse-keymap)))
        (define-key map [mode-line mouse-1] #'my/eat-supervisor)
        (concat " "
                (propertize
                 (concat "["
                         (when (> aw 0) (format "⚠%d" aw))
                         (when (and (> aw 0) (> wk 0)) " ")
                         (when (> wk 0) (format "▶%d" wk))
                         "]")
                 'face       (if (> aw 0) 'my/eat-sup-awaiting 'my/eat-sup-working)
                 'help-echo  "eat agents — click to open supervisor"
                 'mouse-face 'mode-line-highlight
                 'local-map  map))))))

(defun my/eat-sup--update-display ()
  "Refresh visible supervisor buffer (if any) and the mode-line indicator."
  (let ((mode-line-string (my/eat-sup--build-mode-line)))
    (unless (equal mode-line-string my/eat-sup--mode-line-string)
      (setq my/eat-sup--mode-line-string mode-line-string)
      (force-mode-line-update t)))
  (when-let ((buf (get-buffer my/eat-supervisor-buffer-name)))
    (when (get-buffer-window buf 'visible)
      (with-current-buffer buf
        (let ((point (point)))
          (tabulated-list-revert)
          (goto-char (min point (point-max))))))))

;;; Global minor mode

;;;###autoload
(define-minor-mode my/eat-supervisor-mode
  "Scan live eat buffers and surface coding-agent state."
  :global t :group 'my/eat-sup
  (cond
   (my/eat-supervisor-mode
    (require 'alert)
    (add-hook 'eat-exec-hook #'my/eat-sup--init-buffer)
    (add-hook 'eat-exit-hook #'my/eat-sup--on-exit)
    (advice-add 'eat--set-cmd           :after #'my/eat-sup--on-set-cmd)
    (advice-add 'eat--before-new-prompt :after #'my/eat-sup--on-new-prompt)
    (dolist (buf (my/eat-sup--alive-buffers))
      (when-let ((proc (get-buffer-process buf)))
        (my/eat-sup--init-buffer proc)))
    (unless (and (consp global-mode-string)
                 (memq 'my/eat-sup--mode-line-string global-mode-string))
      (setq global-mode-string
            (append (cond ((null global-mode-string) '(""))
                          ((stringp global-mode-string) (list global-mode-string))
                          (t global-mode-string))
                    '(my/eat-sup--mode-line-string))))
    (setq my/eat-sup--timer
          (run-with-timer 0 my/eat-sup-scan-interval #'my/eat-sup--scan)))
   (t
    (remove-hook 'eat-exec-hook #'my/eat-sup--init-buffer)
    (remove-hook 'eat-exit-hook #'my/eat-sup--on-exit)
    (advice-remove 'eat--set-cmd           #'my/eat-sup--on-set-cmd)
    (advice-remove 'eat--before-new-prompt #'my/eat-sup--on-new-prompt)
    (when (timerp my/eat-sup--timer)
      (cancel-timer my/eat-sup--timer)
      (setq my/eat-sup--timer nil))
    (setq my/eat-sup--mode-line-string "")
    (force-mode-line-update t))))

(provide 'eat-supervisor)
;;; eat-supervisor.el ends here
