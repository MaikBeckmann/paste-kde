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

(defun paste-kde-retrieve-json ()
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "{\\(.*\n?\\)*}")
    (match-string 0)))

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
   (cons 'mode "json")))

(defun paste-kde-post (data lang)
  (let ((url-request-method "POST")
        (url-request-data
         (concat "paste_data=" data "&"
                 "paste_lang=" lang "&"
                 "api_submit=true&mode=json")))
    (paste-kde-parse-post-url (http-post-simple
                               *paste-kde-url*
                               (paste-kde-make-post-alist data lang)))))

(defun paste-kde-buffer ()
  (interactive)
  (let ((lang (paste-kde-pick-lang))
        (data (buffer-substring-no-properties (point-min) (point-max))))
    (browse-url (paste-kde-post data lang))))
