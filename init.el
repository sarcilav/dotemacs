
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
(require 'yasnippet)
(yas-global-mode 1)

(require 'pretty-lambdada)
(pretty-lambda-for-modes)


;; Custom 'files'
(load "personal.el")
(load "face.el")
(load "bindings.el")
(load "modes.el")
