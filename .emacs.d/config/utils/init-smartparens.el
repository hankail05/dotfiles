;;; package --- summary:
;;; Commentary:
;;; Code:


(leaf smartparens
  :ensure t
  :init (require 'smartparens-config)
  :setq ((sp-ignore-modes-list . (delete 'minibuffer-inactive-mode sp-ignore-modes-list))
         (sp-escape-quotes-after-insert . nil))
  :config (progn (smartparens-global-strict-mode)
                 (when (version<= "27" emacs-version)
                   (dolist (parens '(c-electric-paren c-electric-brace))
                     (add-to-list 'sp--special-self-insert-commands parens)))
                 (sp-local-pair 'minibuffer-inactive-mode "'" nil :actions nil)
                 (sp-local-pair 'snippet-mode "'" nil :actions nil)
                 (sp-local-pair 'emacs-lisp-mode "'" nil :actions nil)
                 (sp-local-pair 'emacs-lisp-mode "`" nil :actions nil)))


;;; init-smartparens.el ends here
