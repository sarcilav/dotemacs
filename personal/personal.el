(defun indent-all ()
  "Indent entire buffer and clean up whitespace."
  (interactive)
  (save-excursion
    (delete-trailing-whitespace)
    (indent-region (point-min) (point-max) nil)
    (untabify (point-min) (point-max))))

(defun tc-compile-and-run ()
  "Compile and run current C++ file.
Assumes file has .cpp extension and creates executable with same base name."
  (interactive)
  (unless (string-suffix-p ".cpp" (buffer-name))
    (error "Current buffer is not a C++ file"))

  (let* ((filename (buffer-name))
         (basename (file-name-sans-extension filename))
         (compile-cmd (format "g++ %s -g -o %s" filename basename))
         (run-cmd (format "./%s" basename)))
    (compile (concat compile-cmd " && " run-cmd))))

(defun font-larger ()
  "Increase font size by 10 units."
  (interactive)
  (set-face-attribute 'default (selected-frame)
                      :height (+ (face-attribute 'default :height) 10)))

(defun font-smaller ()
  "Decrease font size by 10 units."
  (interactive)
  (set-face-attribute 'default (selected-frame)
                      :height (- (face-attribute 'default :height) 10)))

(defun indent-or-complete ()
  "Indent line or trigger completion based on context."
  (interactive)
  (cond
   ((and (looking-at "$") (not (looking-back "^\\s-*" (line-beginning-position))))
    (hippie-expand nil))
   (t
    (indent-for-tab-command))))

(defun setup-indent-or-complete ()
  "Set up TAB key to use indent-or-complete in current buffer."
  (local-set-key (kbd "TAB") 'indent-or-complete))

;; Update the hook
(add-hook 'find-file-hook 'setup-indent-or-complete)
