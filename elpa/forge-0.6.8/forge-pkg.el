;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "forge" "0.6.8"
  "Access Git forges from Magit."
  '((emacs         "29.1")
    (compat        "31.0")
    (closql        "2.4")
    (cond-let      "1.1")
    (emacsql       "4.4")
    (ghub          "5.3")
    (llama         "1.0")
    (magit         "4.7")
    (markdown-mode "2.8")
    (transient     "0.13")
    (yaml          "1.2"))
  :url "https://github.com/magit/forge"
  :commit "29f45d8f247079a1d8d2247efdacb5b50a3b1e51"
  :revdesc "v0.6.8-0-g29f45d8f2470"
  :keywords '("git" "tools" "vc")
  :authors '(("Jonas Bernoulli" . "emacs.forge@jonas.bernoulli.dev"))
  :maintainers '(("Jonas Bernoulli" . "emacs.forge@jonas.bernoulli.dev")))
