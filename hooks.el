(add-hook 'text-mode-hook 'turn-on-auto-fill)
(add-hook 'text-mode-hook (lambda () pretty-lambdas))

(provide 'hooks)
