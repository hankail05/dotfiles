;;; cmake-ide and its deps.

(require 'cl)
(require 'company)
(require 'flycheck)


(unless (fboundp 'levenshtein-distance)
  (use-package levenshtein
    :ensure t))


(use-package cmake-mode
  :ensure t
  :mode ("CMakeLists.txt" . cmake-mode)
  :init (setq cmake-tab-width 4))


;;; keymap

;(evil-define-key 'normal 'rtags-)


;;; C common style

(add-hook 'c-mode-common-hook '(lambda ()
				 (setq c-default-style "bsd"
				       indent-tabs-mode nil
				       c-basic-offset 4)))

(add-hook 'c-mode-common-hook 'highlight-numbers-mode)


;;; ivy-rtags

(use-package ivy-rtags
  :ensure t
  :config (setq rtags-display-result-backend 'ivy))


;;; flycheck-clang-tidy

(use-package flycheck-clang-tidy
  :ensure t
  :config (add-hook 'flycheck-mode-hook #'flycheck-clang-tidy-setup))


;;; company

(use-package company-rtags
  :ensure t
  :config (add-hook 'c-mode-common-hook (lambda ()
					  (add-to-list 'company-backends 'company-c-headers))))


;;; rtags
;; Completion, Navigation.

(use-package rtags
  :ensure t
  :config (progn (setq rtags-autostart-diagnostics t)
                 (setq rtags-completions-enabled t)
                 (setq rtags-path "~/.emacs.d/elpa/rtags-20190410.1615/rtags-2.22/bin")
                 (add-hook 'c-mode-common-hook 'rtags-start-process-unless-running)))


;;; eldoc

(use-package eldoc
  :ensure t
  :diminish eldoc-mode)

;;; Rtags + Eldoc:
;; https://github.com/Andersbakken/rtags/issues/987

(defun fontify-string (str mode)
  "Return STR fontified according to MODE."
  (with-temp-buffer
    (insert str)
    (delay-mode-hooks (funcall mode))
    (font-lock-default-function mode)
    (font-lock-default-fontify-region
     (point-min) (point-max) nil)
    (buffer-string)))

(defun rtags-eldoc-function ()
  (let ((summary (rtags-get-summary-text)))
    (and summary
         (fontify-string
          (replace-regexp-in-string
           "{[^}]*$" ""
           (mapconcat
            (lambda (str) (if (= 0 (length str)) "//" (string-trim str)))
            (split-string summary "\r?\n")
            " "))
          major-mode))))

(defun rtags-eldoc-mode ()
  (interactive)
  (setq-local eldoc-documentation-function #'rtags-eldoc-function)
  (eldoc-mode 1))

(add-hook 'c-mode-common-hook 'rtags-eldoc-mode)


;;; cmake-ide

(use-package cmake-ide
  :ensure t
  :config (progn (require 'rtags) ;; optional, must have rtags installed
		 (cmake-ide-setup)
		 ;;
		 (defun cmake-ide-compile* ()
		   (interactive)
		   (let ((old-pw default-directory))
		     (cd (cide--build-dir))
		     (call-interactively 'compile)
		     (cd old-pw)))
		 (define-key c-mode-base-map (kbd "C-c b") (function cmake-ide-compile*))))

(defun cmake-ide-delete-build-dir ()
  (interactive)
  (let ((dir-name (cide--build-dir)))
    (when (yes-or-no-p (format "Delete directory %s ?" dir-name))
      (delete-directory dir-name t)
      (message (format "DELETED %s" dir-name)))))


;;; cmake-ide + gdb/exec.

(defun run-process-in-comint (cmd)
  (let* ((name (format "Process: %s" cmd))
         (buf (set-buffer (generate-new-buffer name)))
         (proc nil)
         (line-- (make-string 80 ?-))
         (proc-sentinal-fn (lambda (proc evt)
                             (insert (format "%s\n%s -- %s\n%s\n" line-- evt (current-time-string) line--))))
         (comint-mode-result (comint-mode)))
    ;;
    (switch-to-buffer-other-window buf)
    ;;
    (insert (format "Starting: %s\n%s\n" (current-time-string) line--))
    (setq proc (start-process-shell-command name buf cmd))
    (set-process-sentinel proc (lambda (proc evt)
                                 (insert (format "==========\n%s -- (%s) %s\n"
                                                 evt
                                                 (process-exit-status proc)
                                                 evt (current-time-string)))))
    ;;
    proc))

(defun cmake-ide-find-exe-file ()
  (interactive)
  (let* ((exec-files (seq-filter 'file-executable-p
                                 (directory-files-recursively
                                  (cide--build-dir)
                                  ".*")))
         (base-buffer-name (file-name-base (buffer-name)))
         (calc-dist (lambda (fn) (cons fn
                                       (levenshtein-distance
                                        base-buffer-name
                                        (file-name-base fn)))))
         (cdr-< (lambda (a b) (< (cdr a) (cdr b))))
         (distances (sort (mapcar calc-dist exec-files) cdr-<))
         ;;(---- (message distances))
         (nearest (car (first distances))))
    (cons nearest exec-files)))

(defun cmake-ide-gdb-files-source ()
  "http://kitchingroup.cheme.cmu.edu/blog/2015/01/24/Anatomy-of-a-helm-source/"
  (interactive)
  (require 'seq)
  `((name . "Executable file to debug")
    (candidates . ,(cmake-ide-find-exe-file))
    (action . (lambda (sel)
                (gdb (read-from-minibuffer
                      "Cmd: " (format "%s %s" gud-gdb-command-name sel)))))))

(defun cmake-ide-helm-run-gdb ()
  (interactive)
  (helm :sources (cmake-ide-gdb-files-source)))

(define-key c-mode-base-map (kbd "C-c d")
  (function cmake-ide-helm-run-gdb))

(defun cmake-ide-run-files-source ()
  (interactive)
  (require 'seq)
  `((name . "Executable file")
    (candidates . ,(cmake-ide-find-exe-file))
    (action . (lambda (sel)
                (run-process-in-comint (read-from-minibuffer "Cmd: " sel))))))

(defun cmake-ide-helm-run-exe ()
  (interactive)
  (helm :sources (cmake-ide-run-files-source)))

(define-key c-mode-base-map (kbd "C-c x")
  (function cmake-ide-helm-run-exe))


;;; clang-format

(use-package clang-format
  :ensure t
  :config (defun clang-format-auto ()
            (interactive)
            (if mark-active
                (call-interactively 'clang-format-region)
              (clang-format-buffer)))
  (define-key c-mode-base-map (kbd "C-c C-f") (function clang-format))
  (define-key c-mode-base-map (kbd "C-c f") (function clang-format-auto)))


;;; disaster

(use-package disaster
  :ensure t)

(defun cmake-ide-objdump-disaster (file-name)
  (let* ((objdump-cmd (format "%s %s" disaster-objdump (shell-quote-argument file-name)))
         (buf (set-buffer (generate-new-buffer objdump-cmd))))
    (shell-command objdump-cmd buf)
    (read-only-mode)
    (asm-mode)
    (disaster--shadow-non-assembly-code)
    (switch-to-buffer-other-window buf)))

(defun cmake-ide-find-obj-files ()
  (interactive)
  (let* ((exec-files (seq-filter 'file-readable-p
                                 (directory-files-recursively
                                  (cide--build-dir) ".+\.o[bj]?$")))
         (base-buffer-name (file-name-base (buffer-name)))
         (calc-dist (lambda (fn) (cons fn
                                       (levenshtein-distance
                                        base-buffer-name
                                        (file-name-base fn)))))
         (cdr-< (lambda (a b) (< (cdr a) (cdr b))))
         (distances (sort (mapcar calc-dist exec-files) cdr-<)))
    (mapcar 'car distances)))

(defun cmake-ide-obj-files-source ()
  (interactive)
  (require 'seq)
  `((name . "Object file to objdump")
    (candidates . ,(cmake-ide-find-obj-files))
    (action . (lambda (sel) (cmake-ide-objdump-disaster sel)))))

(defun cmake-ide-objdump ()
  (interactive)
  (helm :sources (cmake-ide-obj-files-source)))

;;;
(when (fboundp 'general-create-definer)
  (my-local-leader-def :keymaps 'c-mode-base-map
    ;; Compile, CMake
    "b" '(:ignore t :which-key "cmake+build")
    "b c" 'cmake-ide-run-cmake
    "b b" 'cmake-ide-compile
    "b B" 'cmake-ide-compile*
    "b D" 'cmake-ide-delete-build-dir
    ;; RTags
    "?" 'rtags-print-symbol-info
    "." 'rtags-find-symbol-at-point
    "," 'rtags-location-stack-back
    ">" 'rtags-find-references-at-point
    ";" 'rtags-find-file
    "v" 'rtags-find-virtuals-at-point
    "[" 'rtags-previous-match
    "]" 'rtags-next-match
    "!" 'rtags-fix-fixit-at-point
    "r" '(:ignore t :which-key "more-rtags")
    "r s" 'rtags-find-symbol
    "r r" 'rtags-find-references
    "r i" 'rtags-imenu
    "r d" 'rtags-diagnostics
    "r D" 'rtags-dependency-tree
    "r R" 'rtags-references-tree
    ;; Debugger
    "d" 'cmake-ide-helm-run-gdb
    "x" 'cmake-ide-helm-run-exe
    ;; Formatting
    "f" 'clang-format-auto
    ;; Disassemble
    "`" '(:ignore t :which-key "misc")
    "` d" 'cmake-ide-objdump
    ))


;; FILE ".dir-locals.el"
;; ((nil . ((cmake-ide-build-dir . "./_build")
;;	 (flycheck-clang-tidy-build-path . "_build")
;; 	 (cmake-ide-cmake-opts . "-DCMAKE_BUILD_TYPE=Debug -GNinja"))))

;; FILE ".clang-tidy"
;; Checks: '-*,clang-diagnostic-*,llvm-*,misc-*'

(defconst agelmacs/layer/cmake-ide t)

;;; EOF
