;;; package --- summary:
;;; Commentary:
;;; Code:


;;; python language server

(setq lsp-pyls-plugins-pylint-enabled nil)


;;; python debug adapter

(require 'dap-python)


;;; additional linters

(leaf flycheck-pycheckers
  :ensure t
  :after flycheck
  :hook (python-mode-hook . flycheck-pycheckers-setup)
  :setq ((flycheck-pycheckers-checkers . '(bandit))))


;;; virtual environment

(leaf virtualenvwrapper
  :ensure t
  :setq ((venv-location . (directory-file-name buffer-file-name)))
  :config (progn (venv-initialize-interactive-shells)
                 (venv-initialize-eshell)))

(leaf auto-virtualenvwrapper
  :ensure t
  :after virtualenvwrapper
  :hook (python-mode-hook . auto-virtualenvwrapper-activate))


;;; pip in emacs

(leaf pippel
  :ensure t
  :config (progn ()))

(leaf pip-requirements
  :ensure t)


;;; code style

(setq python-indent-offset 4
      python-indent-guess-indent-offset nil)


;; keymaps

(defvar custom-python-repl-keymap
  (let ((map(make-sparse-keymap)))
    ;; repl
    (define-key map "p" 'run-python)
    (define-key map "r" 'python-shell-send-region)
    (define-key map "c" 'python-shell-send-buffer)
    map))
(defalias 'custom-python-repl-prefix custom-python-repl-keymap)

(defvar custom-python-keymap
  (let ((map(make-sparse-keymap)))
    (define-key map "c" 'custom-python-repl-prefix)
    map))
(defalias 'custom-python-prefix custom-python-keymap)

(evil-leader/set-key-for-mode 'python-mode
  "<SPC>" 'custom-python-prefix)


;;; init-python.el ends here
