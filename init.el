(setq user-mail-address "sebastianarcila@gmail.com")
(setq user-full-name "Sebastian Arcila-Valenzuela")

(add-to-list 'load-path "~/.emacs24.d")

(server-start)

(require 'personal)
(require 'face)
(require 'bindings)

;; Start ido
(require 'ido)
(ido-mode t)

;; add marmalade
(require 'package)
(add-to-list 'package-archives
             '("marmalade" .
               "http://marmalade-repo.org/packages/"))
(package-initialize)
