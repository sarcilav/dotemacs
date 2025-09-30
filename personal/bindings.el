;; Platform-specific configuration
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta)
  (setq mac-option-modifier 'option))

(defun my/setup-global-keybindings ()
  "Set up all global keybindings with proper error handling."
  (interactive)

  ;; Navigation and project bindings
  (when (fboundp 'projectile-toggle-between-implementation-and-test)
    (global-set-key [f2] 'projectile-toggle-between-implementation-and-test))

  (when (fboundp 'toggle-fold)
    (global-set-key [f3] 'toggle-fold))

  (when (fboundp 'magit-status)
    (global-set-key [f4] 'magit-status))

  (when (fboundp 'indent-all)
    (global-set-key [f5] 'indent-all))

  ;; Font size adjustments
  (global-set-key [(meta -)] 'font-smaller)
  (global-set-key [(meta \+)] 'font-larger)

  ;; Full screen toggle
  (global-set-key [(meta n)] 'toggle-frame-fullscreen)

  ;; Search bindings
  (global-set-key "\C-s" 'isearch-forward-regexp)
  (global-set-key "\C-r" 'isearch-backward-regexp)

  ;; Project search
  (when (fboundp 'ag-project-regexp)
    (global-set-key "\M-s\M-s" 'ag-project-regexp))

  ;; Terminal
  (when (fboundp 'multi-term)
    (global-set-key "\C-c\C-\M-t" 'multi-term))

  ;; Buffer management
  (global-set-key (kbd "C-x C-b") 'ibuffer))

;; Initialize keybindings
(my/setup-global-keybindings)
