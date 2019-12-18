;;; package --- summary:
;;; Commentary:
;;; Code:


;;; fancy start page

(leaf dashboard
  :straight t
  :defun (all-the-icons-icon-for-file . ext:all-the-icons.el)
  :setq ((dashboard-banner-logo-title . "Welcome back to Emacs!")
         (dashboard-startup-banner . 'logo)
         (dashboard-items . '((recents  . 10)
                              (bookmarks . 5)
                              (projects . 10)
                              (agenda . 5)))
         (dashboard-center-content . t))
  :config (progn (setq dashboard-footer-icon (if (and (display-graphic-p)
                                                      (or (fboundp 'all-the-icons-fileicon)
                                                          (require 'all-the-icons nil 'noerror)))
                                                 (all-the-icons-fileicon "emacs"
                                                                         :height 1.1
                                                                         :v-adjust 0
                                                                         :face 'font-lock-constant-face)
                                               (propertize ">" 'face 'dashboard-footer)))
                 (dashboard-setup-startup-hook)
                 (evil-set-initial-state 'dashboard-mode 'insert)
                 (define-key dashboard-mode-map "\C-w" evil-window-map)))

(leaf dashboard-hackernews
  :straight t)


;;; init-dashboard.el ends here