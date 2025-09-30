(defun my/setup-clojure-mode ()
  "Configure Clojure mode with paredit and rainbow modes."
  (when (fboundp 'paredit-mode) (paredit-mode 1))
  (when (fboundp 'turn-on-pretty-mode) (turn-on-pretty-mode))
  (when (fboundp 'rainbow-delimiters-mode) (rainbow-delimiters-mode 1))
  (when (fboundp 'rainbow-identifiers-mode) (rainbow-identifiers-mode 1)))

(defun my/setup-nrepl-mode ()
  "Configure nREPL mode with paredit."
  (when (fboundp 'paredit-mode) (paredit-mode 1)))

(defun my/setup-go-mode ()
  "Configure Go mode with 2-space indentation."
  (setq-local tab-width 2)
  (setq-local standard-indent 2)
  (setq-local indent-tabs-mode nil))

(defun my/setup-rust-mode ()
  "Configure Rust mode with spaces and prettify symbols."
  (setq-local indent-tabs-mode nil)
  (when (fboundp 'prettify-symbols-mode) (prettify-symbols-mode)))

(defun my/disable-yasnippet-in-term ()
  "Disable yasnippet in terminal mode to avoid keybinding conflicts."
  (yas-minor-mode -1))

(defun my/setup-ibuffer ()
  "Configure ibuffer with VC groups and filename sorting."
  (when (fboundp 'ibuffer-vc-set-filter-groups-by-vc-root)
    (ibuffer-vc-set-filter-groups-by-vc-root))
  (unless (eq ibuffer-sorting-mode 'filename/process)
    (ibuffer-do-sort-by-filename/process)))

;; Hook assignments
(when (fboundp 'clojure-mode-hook)
  (add-hook 'clojure-mode-hook 'my/setup-clojure-mode))

(when (fboundp 'nrepl-mode-hook)
  (add-hook 'nrepl-mode-hook 'my/setup-nrepl-mode))

(when (fboundp 'go-mode-hook)
  (add-hook 'go-mode-hook 'my/setup-go-mode))

(add-hook 'before-save-hook 'gofmt-before-save)

(when (fboundp 'rust-mode-hook)
  (add-hook 'rust-mode-hook 'my/setup-rust-mode))

(setq rust-format-on-save t)

(when (fboundp 'term-mode-hook)
  (add-hook 'term-mode-hook 'my/disable-yasnippet-in-term))

(when (fboundp 'ibuffer-hook)
  (add-hook 'ibuffer-hook 'my/setup-ibuffer))

(when (fboundp 'after-init-hook)
  (add-hook 'after-init-hook #'projectile-mode))
