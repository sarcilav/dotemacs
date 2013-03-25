;; Use cmd as meta
(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'option)

(global-set-key [f5] 'indent-all)

;; Change font size
(global-set-key [(meta -)] 'font-smaller)
(global-set-key [(meta \+)] 'font-larger)

;; Go Full Screen
(global-set-key [(meta n)] 'toggle-frame-fullscreen)

;; Use tab for dabbrev-expand aka completation
(global-set-key [tab] 'dabbrev-expand)
(provide 'bindings)
