(defun indent-all()
  "indent whole buffer"
  (interactive)
  (delete-trailing-whitespace)
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max)))(interactive)


;;;;;;;;;;;;;; tc-TopCoder fast compile and run
(defun tc () (interactive)
  (compile (concat "g++ " (buffer-name)" -g -o "(substring (buffer-name) 0 -4)" && ./"(substring (buffer-name) 0 -4)))
  )
;;;;;;;;;;;;;; tc-TopCoder


(defun increase-font-size ()
  (set-face-attribute 'default (selected-frame) :height (+ (face-attribute 'default :height) 10)))

(defun decrease-font-size ()
  (set-face-attribute 'default (selected-frame) :height (- (face-attribute 'default :height) 10)))

(defun font-larger ()
  "Increases font size."
  (interactive)
  (increase-font-size))

(defun font-smaller ()
  "Decreases font size."
  (interactive)
  (decrease-font-size))

(provide 'personal)
