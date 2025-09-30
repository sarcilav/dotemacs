(add-to-list 'load-path "~/.emacs.d/personal/")

(load "misc.el")
;;(server-start)

;; Start ido
(require 'ido)
(ido-mode t)
(setq ido-enable-prefix nil
      ido-enable-flex-matching t
      ido-create-new-buffer 'always
      ido-use-filename-at-point 'guess
      ido-max-prospects 10)

(when (and (equal emacs-version "27.2")
           (eql system-type 'darwin))
  (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))

(require 'package)
;; add melpa-stable
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/"))

;; add cider to the pinned packages
(add-to-list 'package-pinned-packages '(cider . "melpa-stable") t)
(package-initialize)

;; Requiring elpa packages
(require 'yasnippet)
(yas-global-mode 1)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(coffee-tab-width 2)
 '(custom-safe-themes
   '("41d60687e37fb8441f3ebfbefddb2cd1ff480432abe1d3848b28e356d12241ab"
     "986cfa891116be38a60d1e82d820965249ea44e0d6348634a40ef6827f27bbb0"
     "5f128efd37c6a87cd4ad8e8b7f2afaba425425524a68133ac0efd87291d05874"
     "130b47ad4ea2bc61b79e13ecb4a6e6b30351de0fea02e757f074477aa744128b"
     "c1de07961a3b5b49bfd50080e7811eea9c949526084df8d64ce1b4e0fdc076ff"
     "b97a01622103266c1a26a032567e02d920b2c697ff69d40b7d9956821ab666cc"
     "06f0b439b62164c6f8f84fdda32b62fb50b6d00e8b01c2208e55543a6337433a"
     "bb08c73af94ee74453c90422485b29e5643b73b05e8de029a6909af6a3fb3f58"
     default))
 '(magit-log-arguments '("--graph" "--color" "--decorate" "-n256"))
 '(magit-notes-arguments nil)
 '(magit-push-arguments '("--set-upstream"))
 '(package-selected-packages
   '(ag cider circe clojurescript-mode coffee-mode
        color-theme-sanityinc-tomorrow creamsody-theme csharp-mode
        doom-themes elm-mode forge fzf go-mode haml-mode
        handlebars-mode handlebars-sgml-mode ibuffer-vc lua-mode magit
        markdown-mode org-present paredit pretty-lambdada pretty-mode
        quelpa quelpa-use-package rainbow-delimiters
        rainbow-identifiers rust-mode slime ssh-agency terraform-mode
        typescript-mode visual-fill-column web-mode yaml-mode))
 '(safe-local-variable-values '((encoding . utf-8)))
 '(typescript-indent-level 2))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(setq magit-last-seen-setup-instructions "1.4.0")

;; Custom 'files'
(require 'multi-term)
(setq multi-term-program "/usr/bin/bash")
(setq multi-term-program-switches "--login")

(load "personal.el")
(load "face.el")
(load "org-presentations.el")
(load "bindings.el")
(load "modes.el")
(load "hooks.el")
(setq projectile-completion-system 'ido)
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
