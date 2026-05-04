;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "alert" "1.3"
  "Growl-style notification system for Emacs."
  '((gntp   "0.1")
    (log4e  "0.3.0")
    (cl-lib "0.5"))
  :url "https://github.com/jwiegley/alert"
  :commit "9f329be87820474925f29b52a1131084c8ea95b9"
  :revdesc "v1.3-0-g9f329be87820"
  :keywords '("notification" "emacs" "message")
  :authors '(("John Wiegley" . "jwiegley@gmail.com"))
  :maintainers '(("John Wiegley" . "jwiegley@gmail.com")))
