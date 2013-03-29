;; Use cmd as meta
(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'option)

(global-set-key [f5] 'indent-all)

;; Change font size
(global-set-key [(meta -)] 'font-smaller)
(global-set-key [(meta \+)] 'font-larger)

;; Go Full Screen
(global-set-key [(meta n)] 'toggle-frame-fullscreen)

;; Use regexp instead
(global-set-key "\C-s" 'isearch-forward-regexp)
(global-set-key "\C-r" 'isearch-backward-regexp)
