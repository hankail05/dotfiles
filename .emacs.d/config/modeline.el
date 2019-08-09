;;; package --- summary:
;;; Commentary:
;;; Code:


;;; attributes

;;; https://emacs.stackexchange.com/a/16658

(defun mode-line-fill-right (face reserve)
  "Return empty space using FACE and leaving RESERVE space on the right."
  (unless reserve
    (setq reserve 20))
  (when (and window-system (eq 'right (get-scroll-bar-mode)))
    (setq reserve (- reserve 3)))
  (propertize " "
              'display `((space :align-to (- (+ right right-fringe right-margin) ,reserve)))))

(defun mode-line-fill-center (face reserve)
  "Return empty space using FACE to the center of remaining space leaving RESERVE space on the right."
  (unless reserve
    (setq reserve 20))
  (when (and window-system (eq 'right (get-scroll-bar-mode)))
    (setq reserve (- reserve 3)))
  (propertize " "
              'display `((space :align-to (- (+ center (.5 . right-margin)) ,reserve
                                             (.5 . left-margin))))))

(defun reserve-left/middle (line)
  (/ (length (format-mode-line line)) 2))

(defun reserve-middle/right (line)
  (length (format-mode-line line)))

(defvar mode-line-align-left ;; file status
  '((:properlize " %* ") ;; buffer R/W state - modified / read only / saved
    (:properlize (:eval (if (bound-and-true-p vc-mode)
                            (concat " " (substring vc-mode 5) " ")
                          ""))) ;; version control system; need to show more information.
    (:properlize " %b ") ;; file name
    ))

(defvar mode-line-align-middle ;; volatile states
  '((:properlize evil-mode-line-tag) ;; evil state
    (:properlize (:eval (if (bound-and-true-p flycheck-mode)
                            (concat " F " (pcase flycheck-last-status-change
                                            (`not-checked " / / ")
                                            (`no-checker "-/-/-")
                                            (`running "*/*/*")
                                            (`errored "!/!/!")
                                            (`finished (let-alist (flycheck-count-errors flycheck-current-errors)
                                                         (if (or .error .warning .info)
                                                             (format "%s/%s/%s" (or .error 0) (or .warning 0) (or .info 0))
                                                           "0/0/0")))
                                            (`interrupted "././.")
                                            (`suspicious "?/?/?")))
                          ""))) ;; flycheck errors - error / warning / info
    (:properlize (:eval (if (bound-and-true-p iedit-mode)
                            (concat "  I"
                                    (format " %s/%s "
                                            iedit-occurrence-index
                                            (iedit-counter)))
                          ""))) ;; iedit candidates
    ))

(defvar mode-line-align-right ;; positions, file systems
  '((:properlize (:eval (cond ((eq major-mode 'pdf-view-mode) (format " %s p " (pdf-view-current-page))) ;; pdfview mode current page
                              (t (concat " %4l : %3c " ;; cursor position - row / column
                                         " %6p " ;; percentage of the buffer text above the top of the window
                                         (pcase (coding-system-eol-type buffer-file-coding-system)
                                           (0 " LF ")
                                           (1 " CRLF ")
                                           (2 " CR ")) ;; EoL type
                                         "" ;; Encoding; TODO
                                         ) ;; code writing modes
                                 ))))
    (:properlize " %m ") ;; major mode
    ))

(setq-default mode-line-format
              (list mode-line-align-left
                    '(:eval (mode-line-fill-center 'mode-line (reserve-left/middle mode-line-align-middle)))
                    mode-line-align-middle
                    '(:eval (mode-line-fill-right 'mode-line (reserve-middle/right mode-line-align-right)))
                    mode-line-align-right))


;;; clean major/minor mode

(defvar mode-line-cleaner-alist
  '(;; major-mode
    (c-mode . "C")
    (c++-mode . "C++")
    (eshell-mode . "[Eshell]")
    (python-mode . "Python")
    (inferior-python-mode . "[Python]")
    (ein:notebook-multilang-mode . "iPython")
    (ein:notebooklist-mode . "iPython-notebooklist")
    (ess-julia-mode . "Julia")
    (inferior-ess-julia-mode . "[Julia]")
    (pdf-view-mode . "PDF")
    (emacs-lisp-mode . "ELisp")
    (lisp-interaction-mode . "[Lisp]")
    (inferiror-emacs-lisp-mode . "[ELisp]")
    (cider-repl-mode . "[Clojure]")))

(defun clean-mode-line ()
  (interactive)
  (cl-loop for (mode . mode-str) in mode-line-cleaner-alist
           do
           (let ((old-mode-str (cdr (assq mode minor-mode-alist))))
             (when old-mode-str
               (setcar old-mode-str mode-str))
             ;; major mode
             (when (eq mode major-mode)
               (setq mode-name mode-str)))))

(add-hook 'after-change-major-mode-hook  'clean-mode-line)


;;; modeline.el ends here
