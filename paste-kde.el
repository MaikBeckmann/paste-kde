(require 'http-post-simple)

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

(defvar *paste-kde-url* "http://paste.kde.org/")
(defvar paste-kde-user user-login-name
  "*Defines the alias to be used in the post")
(defvar paste-kde-expire 604800
  "*Number of seconds after which the paste will be deleted from the server.
Set this value to 0 to disable this feature. The default is set to 7 days.")

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
  (let ((lang (paste-kde-pick-lang))
        (data (buffer-substring-no-properties (point-min) (point-max))))
    (browse-url (paste-kde-post data lang))))

(provide 'paste-kde)
