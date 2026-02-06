;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "forge" "0.6.3"
  "Access Git forges from Magit."
  '((emacs         "29.1")
    (compat        "30.1")
    (closql        "2.4")
    (cond-let      "0.2")
    (emacsql       "4.3")
    (ghub          "5.0")
    (llama         "1.0")
    (magit         "4.5")
    (markdown-mode "2.7")
    (seq           "2.24")
    (transient     "0.12")
    (yaml          "1.2"))
  :url "https://github.com/magit/forge"
  :commit "315e8e9a2b45d050ca7fc717595cc698e175b140"
  :revdesc "v0.6.3-0-g315e8e9a2b45"
  :keywords '("git" "tools" "vc")
  :authors '(("Jonas Bernoulli" . "emacs.forge@jonas.bernoulli.dev"))
  :maintainers '(("Jonas Bernoulli" . "emacs.forge@jonas.bernoulli.dev")))
