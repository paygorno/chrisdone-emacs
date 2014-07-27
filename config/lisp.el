
;; Fundamental functions

(defun emacs-lisp-expand-clever (arg)
  "Cleverly expand symbols with normal dabbrev-expand, but also
  if the symbol is -foo, then expand to module-name-foo."
  (interactive "*P")
  (let ((sym (dabbrev--abbrev-at-point)))
    (cond
     ((string-prefix-p "-" sym)
      (let ((namespace (emacs-lisp-module-name)))
        (when namespace
          (save-excursion
            (backward-sexp 1)
            (insert namespace))))
      (dabbrev-expand arg))
     (t (dabbrev-expand arg)))))

(defun emacs-lisp-module-name ()
  "Search the buffer for `provide' declaration."
  (save-excursion
    (goto-char (point-min))
    (when (search-forward-regexp "^(provide '" nil t 1)
      (symbol-name (symbol-at-point)))))

(defun emacs-lisp-module-template ()
  (interactive)
  (when (and (buffer-file-name)
             (= (point-min)
                (point-max)))
    (let ((module-name
           (replace-regexp-in-string
            "\\.el$" ""
            (file-name-nondirectory (buffer-file-name)))))
      (insert (format ";;; %s.el --- $DESC$

;; Copyright (c) 2014 Chris Done. All rights reserved.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

%s

\(provide '%s)" module-name (if (string-match "^shm-" module-name)
                                "(require 'shm-core)\n\n" "") module-name))
      (search-backward "$DESC$")
      (delete-region (point)
                     (line-end-position)))))

(defun emacs-lisp-return-or-backslash ()
  "Return to previous point in god-mode."
  (interactive)
  (if god-local-mode
      (call-interactively 'god-mode-self-insert)
    (call-interactively 'paredit-backslash)))

(defun paredit-kill-sexp ()
  "Kill the sexp at point."
  (interactive)
  (if (eq last-command 'kill-region)
      (call-interactively 'kill-sexp)
      (cond
       ((paredit-in-string-p)
        (paredit-backward-up)
        (call-interactively 'kill-sexp))
       ((paredit-inside-sexp-p)
        (paredit-backward)
        (call-interactively 'kill-sexp))
       ((paredit-start-of-sexp-p)
        (call-interactively 'kill-sexp))
       (t
        (paredit-backward)
        (call-interactively 'kill-sexp)))))

(defun paredit-delete-sexp ()
  "Delete the sexp at point."
  (interactive)
  (cond
   ((paredit-in-comment-p)
    (call-interactively 'delete-char))
   ;; Strings don't behave the same as normal sexps in paredit.
   ((paredit-in-string-p)
    (delete-region (save-excursion (paredit-backward-up)
                                   (point))
                   (save-excursion (paredit-backward-up)
                                   (paredit-forward)
                                   (point))))
   ((paredit-inside-sexp-p)
    (delete-region (save-excursion (paredit-backward)
                                   (point))
                   (save-excursion (paredit-forward)
                                   (point))))
   ((paredit-start-of-sexp-p)
    (delete-region (point)
                   (save-excursion (paredit-forward)
                                   (point))))
   ;; Otherwise we're at the end of a sexp.
   (t
    (delete-region (save-excursion (paredit-backward)
                                   (point))
                   (save-excursion (paredit-backward)
                                   (paredit-forward)
                                   (point))))))

(defun paredit-inside-sexp-p ()
  "Are we inside the bounds of a sexp?"
  (= (save-excursion (paredit-forward)
                     (point))
     (save-excursion (paredit-backward)
                     (paredit-forward)
                     (point))))

(defun paredit-start-of-sexp-p ()
  "Are we at the start of a sexp?"
  (= (save-excursion (paredit-forward)
                     (paredit-backward)
                     (point))
     (point)))


;; Keybindings

(define-key emacs-lisp-mode-map (kbd "M-/") 'emacs-lisp-expand-clever)
(define-key paredit-mode-map (kbd "\\") 'emacs-lisp-return-or-backslash)
(define-key paredit-mode-map (kbd "<delete>") 'paredit-delete-sexp)
(define-key paredit-mode-map (kbd "C-M-k") 'paredit-kill-sexp)
(define-key paredit-mode-map (kbd "M-k") 'paredit-kill-sexp)


;; Hooks

(add-hook 'emacs-lisp-mode-hook 'emacs-lisp-module-template)
