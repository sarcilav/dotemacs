;;; ssh-agency-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ssh-agency" "ssh-agency.el" (0 0 0 0))
;;; Generated autoloads from ssh-agency.el

(autoload 'ssh-agency-ensure "ssh-agency" "\
Start ssh-agent and add keys, as needed.

Intended to be added to `magit-credential-hook'." nil nil)

(add-hook 'magit-credential-hook 'ssh-agency-ensure)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "ssh-agency" '("ssh-agency-")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ssh-agency-autoloads.el ends here
