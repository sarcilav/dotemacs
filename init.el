(add-to-list 'load-path "~/.emacs.d")

(load "misc.el")
(server-start)

;; Start ido
(require 'ido)
(ido-mode t)



;; add marmalade
(require 'package)
(add-to-list 'package-archives
             '("marmalade" .
               "http://marmalade-repo.org/packages/"))
(package-initialize)

;; Requiring elpa packages
;; yasnisppet
(require 'yasnippet)
(yas-global-mode 1)

;; Custom 'packages'
(require 'personal)
(require 'face)
(require 'hooks)
(require 'bindings)
(require 'modes)
