;; Use cmd as meta
(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'option)

(global-set-key [f5] 'indent-all)

;; Change font size
(global-set-key [(meta -)] 'font-smaller)
(global-set-key [(meta \+)] 'font-larger)

(provide 'bindings)
