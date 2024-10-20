;; Use cmd as meta
(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'option)

;; swap between test and implementation
(global-set-key [f2] 'projectile-toggle-between-implementation-and-test)
;; toggle at point
(global-set-key [f3] 'toggle-fold)
;; magit-status
(global-set-key [f4] 'magit-status)
;; indent all
(global-set-key [f5] 'indent-all)

;; Change font size
(global-set-key [(meta -)] 'font-smaller)
(global-set-key [(meta \+)] 'font-larger)

;; Go Full Screen
(global-set-key [(meta n)] 'toggle-frame-fullscreen)

;; Use regexp instead
(global-set-key "\C-s" 'isearch-forward-regexp)
(global-set-key "\C-r" 'isearch-backward-regexp)

;; Use ag-project-regexp for searching in files
(global-set-key "\M-s\M-s" 'ag-project-regexp)

;; multi term bindings
(global-set-key "\C-c\C-\M-t" 'multi-term)

;; replace ibuffer
(global-set-key (kbd "C-x C-b") 'ibuffer)

;; accept completion
(define-key copilot-completion-map (kbd "<tab>") 'copilot-accept-completion)

;; list all solutions
(define-key copilot-completion-map (kbd "<backtab>") 'copilot-panel-complete)


