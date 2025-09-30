(add-hook 'clojure-mode-hook 'paredit-mode)
(add-hook 'clojure-mode-hook 'turn-on-pretty-mode)
(add-hook 'clojure-mode-hook 'rainbow-delimiters-mode)
(add-hook 'clojure-mode-hook 'rainbow-identifiers-mode)

(add-hook 'nrepl-mode-hook 'paredit-mode)

;; Display spaces on go-mode as using 2 width spaces
(add-hook 'go-mode-hook
  (lambda ()
    (setq-default)
    (setq tab-width 2)
    (setq standard-indent 2)
    (setq indent-tabs-mode nil)))

;; Use fmt automagically
(add-hook 'before-save-hook 'gofmt-before-save)

;; rust hook and fmt
(add-hook 'rust-mode-hook
          (lambda () (setq indent-tabs-mode nil)))
(add-hook 'rust-mode-hook
          (lambda () (prettify-symbols-mode)))
(setq rust-format-on-save t)

;; remove yas from term, to avoid keybinding problems
(add-hook 'term-mode-hook (lambda()
                            (yas-minor-mode -1)))

;; filter by version control or by mode name
(add-hook 'ibuffer-hook
          (lambda ()
            (ibuffer-vc-set-filter-groups-by-vc-root)
            (unless (eq ibuffer-sorting-mode 'filename/process)
              (ibuffer-do-sort-by-filename/process))))
;; init projectile
(add-hook 'after-init-hook #'projectile-mode)


;;(add-hook 'prog-mode-hook 'copilot-mode)
