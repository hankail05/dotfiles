;;; package --- summary:
;;; Commentary:
;;; Code:


(leaf flycheck
  :ensure t
  :hook (prog-mode-hook . flycheck-mode)
  :setq ((flycheck-errors-function . nil)
         (flycheck-idle-change-delay . 0.5)
         (flycheck-display-errors-delay . 0.5))
  :config (progn (evil-leader/set-key
                   "f" flycheck-command-map))
  :bind ((:flycheck-command-map
          ("j" . flycheck-next-error)
          ("k" . flycheck-previous-error))))


(leaf flycheck-inline
  :ensure t
  :after flycheck quick-peek
  :setq ((flycheck-inline-display-function . (lambda (msg pos)
                                               (let* ((ov (quick-peek-overlay-ensure-at pos))
                                                      (contents (quick-peek-overlay-contents ov)))
                                                 (setf (quick-peek-overlay-contents ov)
                                                       (concat contents (when contents "\n") msg))
                                                 (quick-peek-update ov))))
         (flycheck-inline-clear-function 'quick-peek-hide))
  :config ())
(global-flycheck-inline-mode)


(leaf flycheck-indicator
  :ensure t
  :after flycheck
  :hook (flycheck-mode-hook . flycheck-indicator-mode))


;;; init-flycheck.el ends here