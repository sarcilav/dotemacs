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
