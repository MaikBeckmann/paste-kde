;;; paste-kde.el --- paste text to KDE's pastebin service

;; Copyright (C) 2012 Diogo F. S. Ramos

;; Author: Diogo F. S. Ramos <diogofsr@gmail.com>
;; Version: 0
;; Keywords: comm, convenience, tools

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To post the current buffer to KDE's pastebin service, use the
;; procedure `paste-kde-buffer'. To post a region, `paste-kde-region'.

;; paste-kde will try to figure out the language of the code using the
;; buffer's major mode and an internal hash table. If there isn't a
;; match, paste-kde will post the code as Text.

;; After posting the code, the post's url will be open using
;; `browser-url'.

;; This library uses `http-simple-post.el' to post the text.

;;; Code:

(require 'http-post-simple)
(require 'json)

(defgroup paste-kde nil
  "Paste text to paste.kde.org"
  :tag "Paste KDE"
  :group 'applications
  :version "23.2.1")

(defvar *paste-kde-langs*
  #s(hash-table size 42 data
                (emacs-lisp-mode
                 "lisp"
                 scheme-mode
                 "scheme"
                 lisp-mode
                 "lisp"
                 c-mode
                 "c")))

(defconst *paste-kde-url* "http://paste.kde.org/"
  "KDE's pastebin service url to post text")

(defcustom paste-kde-user user-login-name
  "Defines the alias to be used in the post"
  :group 'paste-kde
  :type '(string))
(defcustom paste-kde-expire 604800
  "Number of seconds after which the paste will be deleted from the server.
Set this value to 0 to disable this feature. The default is set to 7 days."
  :group 'paste-kde
  :type '(integer))
(defcustom paste-kde-open-browser t
  "Whenever the posted text should be opened using a browser."
  :group 'paste-kde
  :type '(boolean))

(defun paste-kde-pick-lang ()
  (let ((lang (gethash major-mode *paste-kde-langs*)))
    (if (null lang) "text" lang)))

(defun paste-kde-post-id (alist)
  (cdr (assoc 'id (assoc 'result alist))))

(defun paste-kde-parse-post-url (response-list)
  (concat *paste-kde-url* (paste-kde-post-id (json-read-from-string (first response-list)))))

(defun paste-kde-make-post-alist (data lang)
  (list
   (cons 'paste_data data)
   (cons 'paste_lang lang)
   (cons 'api_submit "true")
   (cons 'mode "json")
   (cons 'paste_user paste-kde-user)
   (cons 'paste_expire (int-to-string paste-kde-expire))))

(defun paste-kde-post (data lang)
  (paste-kde-parse-post-url (http-post-simple
                             *paste-kde-url*
                             (paste-kde-make-post-alist data lang))))

(defun paste-kde-buffer ()
  (interactive)
  (paste-kde-region (point-min) (point-max)))

(defun paste-kde-region (start end)
  (interactive "r")
  (let ((lang (paste-kde-pick-lang))
        (data (buffer-substring-no-properties start end)))
    (let ((url (paste-kde-post data lang)))
      (when paste-kde-open-browser (browse-url url))
      (message "%s" url))))

(provide 'paste-kde)

;;; paste-kde.el ends here
