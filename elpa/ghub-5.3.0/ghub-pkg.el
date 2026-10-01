;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "ghub" "5.3.0"
  "Client libraries for Git forge APIs."
  '((emacs    "29.1")
    (compat   "31.0")
    (cond-let "1.1")
    (llama    "1.0")
    (treepy   "0.1.3"))
  :url "https://github.com/magit/ghub"
  :commit "cba5666d8b999e2733aefac369a4e0def3be7fc9"
  :revdesc "v5.3.0-0-gcba5666d8b99"
  :keywords '("tools")
  :authors '(("Jonas Bernoulli" . "emacs.ghub@jonas.bernoulli.dev"))
  :maintainers '(("Jonas Bernoulli" . "emacs.ghub@jonas.bernoulli.dev")))
