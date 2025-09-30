;;; aidermacs-output.el --- Output manipulation for Aidermacs -*- lexical-binding: t; -*-
;; Author: Mingde (Matthew) Zeng <matthewzmd@posteo.net>
;; Keywords: ai emacs llm aider ai-pair-programming tools
;; URL: https://github.com/MatthewZMD/aidermacs
;; SPDX-License-Identifier: Apache-2.0

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This file contains the output and diff functionality for Aidermacs.

;;; Code:

(require 'ediff)
(require 'cl-lib)

(declare-function aidermacs-get-buffer-name "aidermacs")
(declare-function aidermacs-project-root "aidermacs")
(declare-function aidermacs--is-aidermacs-buffer-p "aidermacs")
(declare-function aidermacs--prepare-file-paths-for-command "aidermacs")
(declare-function aidermacs--send-command-backend "aidermacs-backends")

(defgroup aidermacs-output nil
  "Output manipulation for Aidermacs."
  :group 'aidermacs)

(defvar-local aidermacs--tracked-files nil
  "List of files that have been mentioned in the aidermacs output.
This is used to avoid having to run /ls repeatedly.")

(defun aidermacs--find-tracked-file (path)
  "Check if PATH (absolute or relative) is in `aidermacs--tracked-files'.
Returns the matching tracked file entry or nil if not found."
  (let* ((project-root (aidermacs-project-root))
         ;; Convert to relative path if it's absolute
         (relative-path (if (file-name-absolute-p path)
                            (file-relative-name path project-root)
                          path))
         ;; Get basename and directory for matching
         (basename (file-name-nondirectory path))
         (path-directory (file-name-directory relative-path)))

    ;; Try strategies in order of specificity
    (or
     ;; 1. Exact match (with or without read-only suffix)
     (cl-find-if (lambda (tracked)
                   (or (string= tracked relative-path)
                       (string= tracked (concat relative-path " (read-only)"))))
                 aidermacs--tracked-files)

     ;; 2. Path suffix match (handles different path representations)
     (cl-find-if (lambda (tracked)
                   (let ((clean-tracked (replace-regexp-in-string " (read-only)$" "" tracked)))
                     (and (string= (file-name-nondirectory clean-tracked) basename)
                          (or (and path-directory
                                  (file-name-directory clean-tracked)
                                  (string-match-p
                                   (regexp-quote (directory-file-name path-directory))
                                   (directory-file-name (file-name-directory clean-tracked))))
                              (string-suffix-p clean-tracked relative-path)
                              (string-suffix-p relative-path clean-tracked)))))
                 aidermacs--tracked-files)

     ;; 3. Basename match (only if unambiguous)
     (let ((basename-matches
            (cl-remove-if-not
             (lambda (tracked)
               (string= basename
                        (file-name-nondirectory
                         (replace-regexp-in-string " (read-only)$" "" tracked))))
             aidermacs--tracked-files)))
       (when (= 1 (length basename-matches))
         (car basename-matches))))))

(defvar-local aidermacs--output-history nil
  "List to store aidermacs output history.
Each entry is a cons cell (timestamp . output-text).")

(defvar-local aidermacs--last-command nil
  "Store the last command sent to aidermacs.")

(defvar-local aidermacs--current-output ""
  "Accumulator for current output being captured as a string.")

(defcustom aidermacs-output-limit 10
  "Maximum number of output entries to keep in history."
  :type 'integer)

(defcustom aidermacs-show-diff-after-change t
  "When non-nil, enable ediff for reviewing AI-generated changes.
When nil, skip preparing temp buffers and showing ediff comparisons."
  :type 'boolean
  :group 'aidermacs)

(defvar-local aidermacs--pre-edit-file-buffers nil
  "Alist of (filename . temp-buffer) storing file state before Aider edits.
These contain the original content of files that might be modified by Aider.")

(defvar aidermacs--pre-ediff-window-config nil
  "Window configuration before starting ediff sessions.")

(defun aidermacs--ensure-current-file-tracked ()
  "Ensure current file is tracked in the aidermacs session."
  (when buffer-file-name
    (let* ((session-buffer (get-buffer (aidermacs-get-buffer-name)))
           (filename buffer-file-name)
           (relative-path (file-relative-name filename (aidermacs-project-root))))
      (when session-buffer
        (with-current-buffer session-buffer
          (unless (member relative-path aidermacs--tracked-files)
            (push relative-path aidermacs--tracked-files)
            (let ((command (aidermacs--prepare-file-paths-for-command "/add" (list relative-path))))
              (aidermacs--send-command-backend session-buffer command nil))))))))

(defun aidermacs--capture-file-state (filename)
  "Store the current state of FILENAME in a temporary buffer.
Creates a read-only buffer with the file's content, appropriate major mode,
and syntax highlighting to match the original file."
  (when (and filename (file-exists-p filename))
    (condition-case err
        (let ((temp-buffer (generate-new-buffer
                            (format " *aidermacs-pre-edit:%s*"
                                    (file-name-nondirectory filename)))))
          (with-current-buffer temp-buffer
            (insert-file-contents filename)
            (set-buffer-modified-p nil)
            ;; Use same major mode as the original file
            (with-demoted-errors "%S"
              (let ((buffer-file-name filename)
                    (delay-mode-hooks t))
                (set-auto-mode)
                (font-lock-ensure))
              ;; Make buffer read-only
              (setq buffer-read-only t)))
          (cons filename temp-buffer))
      (error
       (message "Error capturing file state for %s: %s"
                filename (error-message-string err))
       nil))))

(defun aidermacs--cleanup-temp-buffers ()
  "Clean up all temporary buffers created for ediff sessions.
This is called when all ediff sessions are complete.
Kills all pre-edit buffers that were created to store original file content."
  (interactive)
  (with-current-buffer (get-buffer (aidermacs-get-buffer-name))
    ;; Clean up buffers in the tracking list
    (dolist (file-pair aidermacs--pre-edit-file-buffers)
      (let ((temp-buffer (cdr file-pair)))
        (when (and temp-buffer (buffer-live-p temp-buffer))
          (kill-buffer temp-buffer))))
    ;; Clear the list after cleanup
    (setq aidermacs--pre-edit-file-buffers nil)))

(defun aidermacs--prepare-for-code-edit ()
  "Prepare for code edits by capturing current file states in memory buffers.
Creates temporary buffers containing the original content of all tracked files.
This is skipped if `aidermacs-show-diff-after-change' is nil."
  (when aidermacs-show-diff-after-change
    (aidermacs--cleanup-temp-buffers)
    (when-let* ((files aidermacs--tracked-files))
      (let ((attempts 0)
            (max-attempts 3))
        ;; Use iteration rather than recursion with a limit on attempts
        (while (and (zerop (length aidermacs--pre-edit-file-buffers))
                    (< attempts max-attempts))
          (setq aidermacs--pre-edit-file-buffers
                (cl-remove-duplicates
                 (delq nil
                       (mapcar (lambda (file)
                                 (let* ((clean-file (replace-regexp-in-string " (read-only)$" "" file))
                                        (full-path (expand-file-name clean-file (aidermacs-project-root))))
                                   ;; Only capture state if we don't already have it
                                   (or (assoc full-path aidermacs--pre-edit-file-buffers)
                                       (aidermacs--capture-file-state full-path))))
                               files))
                 :test (lambda (a b) (equal (car a) (car b)))))
          (setq attempts (1+ attempts))
          ;; Add a small delay before retry to allow for file system operations
          (when (and (zerop (length aidermacs--pre-edit-file-buffers))
                     (< attempts max-attempts))
            (sit-for 0.1)))

        (if (zerop (length aidermacs--pre-edit-file-buffers))
            (message "Warning: Failed to capture file states after %d attempts" max-attempts)
          (message "Prepared code edit for %d files" (length aidermacs--pre-edit-file-buffers)))))))

(defun aidermacs--ediff-quit-handler ()
  "Handle ediff session cleanup.
This function is called when an ediff session is quit."
  (when (and (boundp 'ediff-buffer-A)
             (buffer-live-p ediff-buffer-A)
             (string-match " \\*aidermacs-pre-edit:"
                           (buffer-name ediff-buffer-A)))

    (when (and (buffer-live-p ediff-buffer-B) (buffer-modified-p ediff-buffer-B))
      (save-some-buffers ediff-buffer-B))

    ;; Cleanup ediff buffers
    (aidermacs--ediff-cleanup-auxiliary-buffers)
    ;; Restore original window configuration
    (when aidermacs--pre-ediff-window-config
      (set-window-configuration aidermacs--pre-ediff-window-config))))

(defun aidermacs--ediff-cleanup-auxiliary-buffers ()
  (let* ((ctl-buf ediff-control-buffer)
         (ctl-win (ediff-get-visible-buffer-window ctl-buf))
         (ctl-frm ediff-control-frame)
         (main-frame (cond ((window-live-p ediff-window-A)
                            (window-frame ediff-window-A))
                           ((window-live-p ediff-window-B)
                            (window-frame ediff-window-B)))))
    (ediff-kill-buffer-carefully ediff-diff-buffer)
    (ediff-kill-buffer-carefully ediff-custom-diff-buffer)
    (ediff-kill-buffer-carefully ediff-fine-diff-buffer)
    (ediff-kill-buffer-carefully ediff-tmp-buffer)
    (ediff-kill-buffer-carefully ediff-error-buffer)
    (ediff-kill-buffer-carefully ediff-msg-buffer)
    (ediff-kill-buffer-carefully ediff-debug-buffer)
    (when (boundp 'ediff-patch-diagnostics)
      (ediff-kill-buffer-carefully ediff-patch-diagnostics))
    (cond ((and (display-graphic-p)
                (frame-live-p ctl-frm))
           (delete-frame ctl-frm))
          ((window-live-p ctl-win)
           (delete-window ctl-win)))
    (ediff-kill-buffer-carefully ctl-buf)
    (when (frame-live-p main-frame)
      (select-frame main-frame))))

(defun aidermacs--setup-ediff-cleanup-hooks ()
  "Set up hooks to ensure proper cleanup of temporary buffers after ediff.
Only adds the hook if it's not already present."
  (unless (member #'aidermacs--ediff-quit-handler ediff-quit-hook)
    (add-hook 'ediff-quit-hook #'aidermacs--ediff-quit-handler)))

(defun aidermacs--parse-output-for-files (output)
  "Parse OUTPUT for files and add them to `aidermacs--tracked-files'."
  (when output
    (let ((lines (split-string output "\n"))
          (last-line "")
          (in-udiff nil)
          (current-udiff-file nil))
      (dolist (line lines)
        (cond
         ;; Applied edit to <filename>
         ((string-match "Applied edit to \\(\\./\\)?\\(.+\\)" line)
          (when-let* ((file (match-string 2 line)))
            (add-to-list 'aidermacs--tracked-files file)))

         ;; Added <filename> to the chat.
         ((string-match "Added \\(\\./\\)?\\(.+\\) to the chat" line)
          (when-let* ((file (match-string 2 line)))
            (add-to-list 'aidermacs--tracked-files file)))

         ;; Removed <filename> from the chat (handling read-only, relative and full paths)
         ((string-match "Removed \\(?:read-only file \\)?\\(\\./\\)?\\(.+\\) from the chat" line)
          (when-let* ((raw-path (match-string 2 line))
                      (tracked-file (aidermacs--find-tracked-file raw-path)))
            (setq aidermacs--tracked-files (delete tracked-file aidermacs--tracked-files))
            (message "Removed %s from tracked files" tracked-file)))

         ;; Added <filename> to read-only files.
         ((string-match "Added \\(\\./\\)?\\(.+\\) to read-only files" line)
          (when-let* ((file (match-string 2 line)))
            (add-to-list 'aidermacs--tracked-files (concat file " (read-only)"))))

         ;; Moved <file> from editable to read-only files in the chat
         ((string-match "Moved \\(\\./\\)?\\(.+\\) from editable to read-only files in the chat" line)
          (when-let* ((file (match-string 2 line)))
            (let ((editable-file (replace-regexp-in-string " (read-only)$" "" file)))
              (setq aidermacs--tracked-files (delete editable-file aidermacs--tracked-files))
              (add-to-list 'aidermacs--tracked-files (concat file " (read-only)")))))

         ;; Moved <file> from read-only to editable files in the chat
         ((string-match "Moved \\(\\./\\)?\\(.+\\) from read-only to editable files in the chat" line)
          (when-let* ((file (match-string 2 line)))
            (let ((read-only-file (concat file " (read-only)")))
              (setq aidermacs--tracked-files (delete read-only-file aidermacs--tracked-files))
              (add-to-list 'aidermacs--tracked-files file))))

         ;; <file>\nAdd file to the chat?
         ((string-match "Add file to the chat?" line)
          (add-to-list 'aidermacs--tracked-files last-line)
          (aidermacs--prepare-for-code-edit))

         ;; <file> is already in the chat as an editable file
         ((string-match "\\(\\./\\)?\\(.+\\) is already in the chat as an editable file" line)
          (when-let* ((file (match-string 2 line)))
            (add-to-list 'aidermacs--tracked-files file)))

         ;; Handle udiff format
         ;; Detect start of udiff with "--- filename"
         ((string-match "^--- \\(\\./\\)?\\(.+\\)" line)
          (setq in-udiff t
                current-udiff-file (match-string 2 line)))

         ;; Confirm udiff file with "+++ filename" line
         ((and in-udiff
               current-udiff-file
               (string-match "^\\+\\+\\+ \\(\\./\\)?\\(.+\\)" line))
          (let ((plus-file (match-string 2 line)))
            ;; Only add if the filenames match (ignoring ./ prefix)
            (when (string= (file-name-nondirectory current-udiff-file)
                           (file-name-nondirectory plus-file))
              (add-to-list 'aidermacs--tracked-files current-udiff-file)
              (setq in-udiff nil
                    current-udiff-file nil)))))

        (setq last-line line))

      ;; Verify all tracked files exist
      (let* ((project-root (aidermacs-project-root))
             (is-remote (file-remote-p project-root))
             (valid-files nil))
        (dolist (file aidermacs--tracked-files)
          (let* ((is-readonly (string-match-p " (read-only)$" file))
                 (actual-file (if is-readonly
                                  (substring file 0 (- (length file) 12))
                                file))
                 (full-path (expand-file-name actual-file project-root)))
            (when (or (file-exists-p full-path) is-remote)
              (push file valid-files))))
        (setq aidermacs--tracked-files valid-files)))))

(defun aidermacs--store-output (output)
  "Store output string in the history with timestamp.
OUTPUT is the string to store.
If there's a callback function, call it with the output."
  (when (stringp output)
    ;; Store the output
    (setq aidermacs--current-output (substring-no-properties output))
    (push (cons (current-time) (substring-no-properties output)) aidermacs--output-history)
    ;; Trim history if needed
    (when (> (length aidermacs--output-history) aidermacs-output-limit)
      (setq aidermacs--output-history
            (seq-take aidermacs--output-history aidermacs-output-limit)))
    ;; Parse files from output
    (aidermacs--parse-output-for-files output)
    ;; Handle callback if present
    (unless aidermacs--in-callback
      (when (functionp aidermacs--current-callback)
        (let ((aidermacs--in-callback t))
          (funcall aidermacs--current-callback)
          (setq aidermacs--current-callback nil))))))

(defun aidermacs-show-output-history ()
  "Display the AI output history in a new buffer."
  (interactive)
  (let ((buf (get-buffer-create "*aidermacs-history*"))
        (history aidermacs--output-history))
    (with-current-buffer buf
      (org-mode)
      (setq buffer-read-only nil)
      (erase-buffer)
      (display-line-numbers-mode 1)
      (dolist (entry history)
        (let ((timestamp (format-time-string "%F %T" (car entry)))
              (output (cdr entry)))
          (insert (format "* %s\n#+BEGIN_SRC\n%s\n#+END_SRC\n" timestamp output))))
      (goto-char (point-min))
      (setq buffer-read-only t)
      (local-set-key (kbd "q") #'kill-this-buffer)
      (switch-to-buffer-other-window buf))))

(defun aidermacs-clear-output-history ()
  "Clear the output history."
  (interactive)
  (setq aidermacs--output-history nil))

(defun aidermacs--detect-edited-files ()
  "Parse current output to find files edited by Aider.
Returns a list of files that have been modified according to the output."
  (let ((project-root (aidermacs-project-root))
        (output aidermacs--current-output)
        (edited-files)
        (unique-files)
        (valid-files))
    (when output
      (with-temp-buffer
        (insert output)
        (goto-char (point-min))

        ;; Case 1: Find "Applied edit to" lines
        (while (search-forward "Applied edit to" nil t)
          (beginning-of-line)
          (when-let* ((file (and (looking-at ".*Applied edit to \\(\\./\\)?\\([^[:space:]]+\\)")
                                (match-string-no-properties 2))))
            (push file edited-files))
          (forward-line 1))

        ;; Case 2: Find triple backtick blocks with filenames
        (goto-char (point-min))
        (while (search-forward "```" nil t)
          (save-excursion
            (forward-line -1)
            (let ((potential-file (string-trim (buffer-substring (line-beginning-position) (line-end-position)))))
              (when (and (not (string-empty-p potential-file))
                         (not (string-match-p "\\`[[:space:]]*\\'" potential-file))
                         (not (string-match-p "^```" potential-file)))
                (push potential-file edited-files))))
          (forward-line 1))

        ;; Case 3: Handle udiff format
        (goto-char (point-min))
        (while (search-forward "--- " nil t)
          (let* ((line-end (line-end-position))
                 (current-udiff-file (buffer-substring (point) line-end)))
            (forward-line 1)
            (when (looking-at "\\+\\+\\+ ")
              (let ((plus-file (buffer-substring (+ (point) 4) (line-end-position))))
                (when (string= (file-name-nondirectory current-udiff-file)
                               (file-name-nondirectory plus-file))
                  (push current-udiff-file edited-files)))))))

      ;; Filter the list to only include valid files
      (setq unique-files (delete-dups edited-files))
      (setq valid-files (nreverse (cl-remove-if-not
                                   (lambda (file)
                                     (file-exists-p (expand-file-name file project-root)))
                                   unique-files)))
      valid-files)))

(defun aidermacs--show-ediff-for-edited-files (edited-files)
  "Show a list of edited files in EDITED-FILES for selection.
This is skipped if `aidermacs-show-diff-after-change' is nil."
  (when (and aidermacs-show-diff-after-change edited-files)
    (aidermacs--show-file-selection-buffer edited-files)))

(define-derived-mode aidermacs-file-diff-selection-mode special-mode "Aider Diff Files"
  "Major mode for selecting files edited by Aider."
  :group 'aidermacs
  (font-lock-mode 1)
  (setq buffer-read-only t))

(defun aidermacs--file-diff-selection-quit ()
  "Quit file selection"
  (interactive)
  (kill-buffer)
  (aidermacs--cleanup-temp-buffers))

(define-key aidermacs-file-diff-selection-mode-map (kbd "q") 'aidermacs--file-diff-selection-quit)

(defun aidermacs--show-file-selection-buffer (files)
  "Display a buffer with a list of FILES that were edited.
User can select a file to view its diff."
  (when-let (buf (get-buffer "*aidermacs-edited-files*"))
    (kill-buffer buf))

  (let ((buf (get-buffer-create "*aidermacs-edited-files*"))
        (pre-edit-file-buffers aidermacs--pre-edit-file-buffers))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (aidermacs-file-diff-selection-mode)
        (setq-local default-directory (aidermacs-project-root))
        (setq-local aidermacs--pre-edit-file-buffers pre-edit-file-buffers)

        (insert "Files modified by Aider:\n")
        (insert "=======================\n\n")
        (insert "Press RET on a file to view diff, q to quit\n\n")

        (dolist (file files)
          (insert-text-button file
                             'action (lambda (_)
                                      (aidermacs--show-ediff-for-file file))
                             'follow-link t
                             'help-echo "Click to view diff for this file")
          (insert "\n"))

        (goto-char (point-min))
        (forward-line 5)))

    ;; Display the buffer after the hooks are completed
    (run-with-timer 0 nil (lambda () (interactive)
                          (switch-to-buffer-other-window buf)))))


(defun aidermacs--show-ediff-for-file (file)
  "Uses the pre-edit buffer stored to compare with the current FILE state."
  (setq aidermacs--pre-ediff-window-config (current-window-configuration))

  (let* ((full-path (expand-file-name file (aidermacs-project-root)))
         (pre-edit-pair (assoc full-path aidermacs--pre-edit-file-buffers))
         (pre-edit-buffer (and pre-edit-pair (cdr pre-edit-pair))))
    (if (and pre-edit-buffer (buffer-live-p pre-edit-buffer))
        (progn
          (let ((current-buffer (or (get-file-buffer full-path)
                                    (find-file-noselect full-path))))
            (with-current-buffer current-buffer
              (revert-buffer t t t))
            ;; Start ediff session
            (ediff-buffers pre-edit-buffer current-buffer)))
      ;; If no pre-edit buffer found, simply show buffer
      (find-file file))))

(provide 'aidermacs-output)
;;; aidermacs-output.el ends here
