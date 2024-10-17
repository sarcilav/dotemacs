;;; copilot-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "copilot" "copilot.el" (0 0 0 0))
;;; Generated autoloads from copilot.el

(autoload 'copilot-complete "copilot" "\
Complete at the current point." t nil)

(autoload 'copilot-mode "copilot" "\
Minor mode for Copilot.

This is a minor mode.  If called interactively, toggle the
`Copilot mode' mode.  If the prefix argument is positive, enable
the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `copilot-mode'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(put 'global-copilot-mode 'globalized-minor-mode t)

(defvar global-copilot-mode nil "\
Non-nil if Global Copilot mode is enabled.
See the `global-copilot-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-copilot-mode'.")

(custom-autoload 'global-copilot-mode "copilot" nil)

(autoload 'global-copilot-mode "copilot" "\
Toggle Copilot mode in all buffers.
With prefix ARG, enable Global Copilot mode if ARG is positive;
otherwise, disable it.

If called from Lisp, toggle the mode if ARG is `toggle'.
Enable the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

Copilot mode is enabled in all buffers where `copilot-mode' would do
it.

See `copilot-mode' for more information on Copilot mode.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "copilot" '("copilot-"))

;;;***

;;;### (autoloads nil nil ("copilot-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; copilot-autoloads.el ends here
