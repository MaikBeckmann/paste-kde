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
(require 'cl)

(defgroup paste-kde nil
  "Paste text to paste.kde.org"
  :tag "Paste KDE"
  :group 'applications
  :version "23.2.1")

(defvar *paste-kde-langs*
  (list
   (list '4cs-mode '4cs "GADV 4CS")
   (list '6502acme-mode '6502acme "ACME Cross Asm")
   (list '6502kickass-mode '6502kickass "Kick Asm")
   (list '6502tasm-mode '6502tasm "TASM/64TASS 1.46 Asm")
   (list '68000devpac-mode '68000devpac "HiSoft Devpac ST 2 Asm")
   (list 'abap-mode 'abap "ABAP")
   (list 'actionscript-mode 'actionscript "ActionScript")
   (list 'actionscript3-mode 'actionscript3 "ActionScript 3")
   (list 'ada-mode 'ada "Ada")
   (list 'algol68-mode 'algol68 "ALGOL 68")
   (list 'apache-mode 'apache "Apache configuration")
   (list 'applescript-mode 'applescript "AppleScript")
   (list 'apt-mode 'apt "sources - Apt sources")
   (list 'asm-mode 'asm "ASM")
   (list 'asp-mode 'asp "ASP")
   (list 'autoconf-mode 'autoconf "Autoconf")
   (list 'autohotkey-mode 'autohotkey "Autohotkey")
   (list 'autoit-mode 'autoit "AutoIt")
   (list 'avisynth-mode 'avisynth "AviSynth")
   (list 'awk-mode 'awk "awk")
   (list 'bash-mode 'bash "Bash")
   (list 'basic4gl-mode 'basic4gl "Basic4GL")
   (list 'bf-mode 'bf "Brainfuck")
   (list 'bibtex-mode 'bibtex "BibTeX")
   (list 'blitzbasic-mode 'blitzbasic "BlitzBasic")
   (list 'bnf-mode 'bnf "bnf")
   (list 'boo-mode 'boo "Boo")
   (list 'c-mode 'c "C")
   (list 'c-mode 'c "loadrunner - C (LoadRunner)")
   (list 'c-mode 'c "mac - C (Mac)")
   (list 'caddcl-mode 'caddcl "CAD DCL")
   (list 'cadlisp-mode 'cadlisp "CAD Lisp")
   (list 'cfdg-mode 'cfdg "CFDG")
   (list 'cfm-mode 'cfm "ColdFusion")
   (list 'chaiscript-mode 'chaiscript "ChaiScript")
   (list 'cil-mode 'cil "CIL")
   (list 'clojure-mode 'clojure "Clojure")
   (list 'cmake-mode 'cmake "CMake")
   (list 'cobol-mode 'cobol "COBOL")
   (list 'cpp-mode 'cpp "C++")
   (list 'cpp-mode 'cpp "qt -   C++ (Qt)")
   (list 'c++-mode 'cpp "C++")
   (list 'c++-mode 'cpp "qt -   C++ (Qt)")
   (list 'csharp-mode 'csharp "C#")
   (list 'css-mode 'css "CSS")
   (list 'cuesheet-mode 'cuesheet "Cuesheet")
   (list 'd-mode 'd "D")
   (list 'dcs-mode 'dcs "DCS")
   (list 'delphi-mode 'delphi "Delphi")
   (list 'diff-mode 'diff "Diff")
   (list 'div-mode 'div "DIV")
   (list 'dos-mode 'dos "DOS")
   (list 'dot-mode 'dot "dot")
   (list 'e-mode 'e "E")
   (list 'ecmascript-mode 'ecmascript "ECMAScript")
   (list 'eiffel-mode 'eiffel "Eiffel")
   (list 'email-mode 'email "eMail (mbox)")
   (list 'emacs-lisp-mode 'lisp "Emacs Lisp")
   (list 'epc-mode 'epc "EPC")
   (list 'erlang-mode 'erlang "Erlang")
   (list 'f1-mode 'f1 "Formula One")
   (list 'falcon-mode 'falcon "Falcon")
   (list 'fo-mode 'fo "FO (abas-ERP)")
   (list 'fortran-mode 'fortran "Fortran")
   (list 'freebasic-mode 'freebasic "FreeBasic")
   (list 'fsharp-mode 'fsharp "F#")
   (list 'fundamental-mode 'text "Fundamental Mode")
   (list 'gambas-mode 'gambas "GAMBAS")
   (list 'gdb-mode 'gdb "GDB")
   (list 'genero-mode 'genero "genero")
   (list 'genie-mode 'genie "Genie")
   (list 'gettext-mode 'gettext "GNU Gettext")
   (list 'glsl-mode 'glsl "glSlang")
   (list 'gml-mode 'gml "GML")
   (list 'gnuplot-mode 'gnuplot "Gnuplot")
   (list 'go-mode 'go "Go")
   (list 'groovy-mode 'groovy "Groovy")
   (list 'gwbasic-mode 'gwbasic "GwBasic")
   (list 'haskell-mode 'haskell "Haskell")
   (list 'hicest-mode 'hicest "HicEst")
   (list 'hq9plus-mode 'hq9plus "HQ9+")
   (list 'html4strict-mode 'html4strict "HTML")
   (list 'icon-mode 'icon "Icon")
   (list 'idl-mode 'idl "Uno Idl")
   (list 'ini-mode 'ini "INI")
   (list 'conf-unix-mode 'ini "INI")
   (list 'inno-mode 'inno "Inno")
   (list 'intercal-mode 'intercal "INTERCAL")
   (list 'io-mode 'io "Io")
   (list 'j-mode 'j "J")
   (list 'java-mode 'java "Java")
   (list 'java5-mode 'java5 "J2SE")
   (list 'javascript-mode 'javascript "Javascript")
   (list 'js-mode 'javascript "Javascript")
   (list 'jquery-mode 'jquery "jQuery")
   (list 'kixtart-mode 'kixtart "KiXtart")
   (list 'klonec-mode 'klonec "KLone C")
   (list 'klonecpp-mode 'klonecpp "KLone C++")
   (list 'latex-mode 'latex "LaTeX")
   (list 'lb-mode 'lb "Liberty BASIC")
   (list 'lisp-mode 'lisp "Lisp")
   (list 'lisp-interaction-mode 'lisp "Lisp Interaction")
   (list 'locobasic-mode 'locobasic "Locomotive Basic")
   (list 'logtalk-mode 'logtalk "Logtalk")
   (list 'lolcode-mode 'lolcode "LOLcode")
   (list 'lotusformulas-mode 'lotusformulas "Lotus Notes")
   (list 'lotusscript-mode 'lotusscript "LotusScript")
   (list 'lscript-mode 'lscript "LScript")
   (list 'lsl2-mode 'lsl2 "LSL2")
   (list 'lua-mode 'lua "Lua")
   (list 'm68k-mode 'm68k "Motorola 68000 Asm")
   (list 'magiksf-mode 'magiksf "MagikSF")
   (list 'make-mode 'make "GNU make")
   (list 'mapbasic-mode 'mapbasic "MapBasic")
   (list 'matlab-mode 'matlab "Matlab M")
   (list 'mirc-mode 'mirc "mIRC Scripting")
   (list 'mmix-mode 'mmix "MMIX")
   (list 'modula2-mode 'modula2 "Modula-2")
   (list 'modula3-mode 'modula3 "Modula-3")
   (list 'mpasm-mode 'mpasm "Microchip Asm")
   (list 'mxml-mode 'mxml "MXML")
   (list 'mysql-mode 'mysql "MySQL")
   (list 'newlisp-mode 'newlisp "newlisp")
   (list 'nsis-mode 'nsis "NSIS")
   (list 'oberon2-mode 'oberon2 "Oberon-2")
   (list 'objc-mode 'objc "Objective-C")
   (list 'objeck-mode 'objeck "Objeck")
   (list 'ocaml-mode 'ocaml "OCaml")
   (list 'ocaml-mode 'ocaml "brief -   OCaml (brief)")
   (list 'oobas-mode 'oobas "OpenOffice.org Basic")
   (list 'oracle11-mode 'oracle11 "Oracle 11 SQL")
   (list 'oracle8-mode 'oracle8 "Oracle 8 SQL")
   (list 'oxygene-mode 'oxygene "Oxygene (Delphi Prism)")
   (list 'oz-mode 'oz "OZ")
   (list 'pascal-mode 'pascal "Pascal")
   (list 'pcre-mode 'pcre "PCRE")
   (list 'per-mode 'per "per")
   (list 'perl-mode 'perl "Perl")
   (list 'perl6-mode 'perl6 "Perl 6")
   (list 'pf-mode 'pf "OpenBSD Packet Filter")
   (list 'php-mode 'php "PHP")
   (list 'php-mode 'php "brief -   PHP (brief)")
   (list 'pic16-mode 'pic16 "PIC16")
   (list 'pike-mode 'pike "Pike")
   (list 'pixelbender-mode 'pixelbender "Pixel Bender 1.0")
   (list 'plsql-mode 'plsql "PL/SQL")
   (list 'postgresql-mode 'postgresql "PostgreSQL")
   (list 'povray-mode 'povray "POVRAY")
   (list 'powerbuilder-mode 'powerbuilder "PowerBuilder")
   (list 'powershell-mode 'powershell "PowerShell")
   (list 'progress-mode 'progress "Progress")
   (list 'prolog-mode 'prolog "Prolog")
   (list 'properties-mode 'properties "PROPERTIES")
   (list 'providex-mode 'providex "ProvideX")
   (list 'purebasic-mode 'purebasic "PureBasic")
   (list 'python-mode 'python "Python")
   (list 'q-mode 'q "q/kdb+")
   (list 'qbasic-mode 'qbasic "QBasic/QuickBASIC")
   (list 'rails-mode 'rails "Rails")
   (list 'rebol-mode 'rebol "REBOL")
   (list 'reg-mode 'reg "Microsoft Registry")
   (list 'robots-mode 'robots "robots.txt")
   (list 'rpmspec-mode 'rpmspec "RPM Specification File")
   (list 'rsplus-mode 'rsplus "R / S+")
   (list 'ruby-mode 'ruby "Ruby")
   (list 'sas-mode 'sas "SAS")
   (list 'scala-mode 'scala "Scala")
   (list 'scheme-mode 'scheme "Scheme")
   (list 'scilab-mode 'scilab "SciLab")
   (list 'sdlbasic-mode 'sdlbasic "sdlBasic")
   (list 'smalltalk-mode 'smalltalk "Smalltalk")
   (list 'smarty-mode 'smarty "Smarty")
   (list 'sql-mode 'sql "SQL")
   (list 'systemverilog-mode 'systemverilog "SystemVerilog")
   (list 'tcl-mode 'tcl "TCL")
   (list 'teraterm-mode 'teraterm "Tera Term Macro")
   (list 'thinbasic-mode 'thinbasic "thinBasic")
   (list 'tsql-mode 'tsql "T-SQL")
   (list 'typoscript-mode 'typoscript "TypoScript")
   (list 'unicon-mode 'unicon "Unicon")
   (list 'vala-mode 'vala "Vala")
   (list 'vb-mode 'vb "Visual Basic")
   (list 'vbnet-mode 'vbnet "VB.NET")
   (list 'verilog-mode 'verilog "Verilog")
   (list 'vhdl-mode 'vhdl "VHDL")
   (list 'vim-mode 'vim "Vim Script")
   (list 'visualfoxpro-mode 'visualfoxpro "Visual Fox Pro")
   (list 'visualprolog-mode 'visualprolog "Visual Prolog")
   (list 'whitespace-mode 'whitespace "Whitespace")
   (list 'whois-mode 'whois "Whois (RPSL format)")
   (list 'winbatch-mode 'winbatch "Winbatch")
   (list 'xbasic-mode 'xbasic "XBasic")
   (list 'xml-mode 'xml "XML")
   (list 'xorg-mode 'xorg "conf - Xorg configuration")
   (list 'xpp-mode 'xpp "X++")
   (list 'z80-mode 'z80 "ZiLOG Z80 Asm")
   (list 'zxbasic-mode 'zxbasic "ZXBasic")))

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

(defun paste-kde-list-of-possible-langs ()
  (mapcar #'third *paste-kde-langs*))

(defun paste-kde-lang-name (item)
  (third item))

(defun paste-kde-lang-symbol (item)
  (second item))

(defun paste-kde-lang-mode (item)
  (first item))

(defun paste-kde-langs-name (name)
  (find name *paste-kde-langs*
        :key #'paste-kde-lang-name
        :test #'string-equal))

(defun paste-kde-langs-mode (mode)
  (find mode *paste-kde-langs*
        :key #'paste-kde-lang-mode))

(defun paste-kde-pick-lang ()
  (let ((item (paste-kde-langs-mode major-mode)))
    (if (null item)
        "text"
      (symbol-name (paste-kde-lang-symbol item)))))

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

(defun paste-kde-user-pick-lang (prefix)
  (if prefix
      (completing-read "Choose the language: "
                       (paste-kde-list-of-possible-langs)
                       nil t)
    (paste-kde-pick-lang)))

(defun paste-kde-buffer (lang)
  "Paste the current buffer

If called with a prefix, LANG will be filled by you. Without a prefix, LANG will be choosen automatically."
  (interactive
   (list (paste-kde-user-pick-lang current-prefix-arg)))
  (paste-kde-region (point-min) (point-max) lang))

(defun paste-kde-region (start end lang)
  "Paste the current region

If called with a prefix, LANG will be filled by you. Without a prefix, LANG will be choosen automatically."
  (interactive
   (let ((string (paste-kde-user-pick-lang current-prefix-arg)))
     (list (region-beginning) (region-end) string)))
  (let ((data (buffer-substring-no-properties start end)))
    (let ((url (paste-kde-post data lang)))
      (when paste-kde-open-browser (browse-url url))
      (message "%s" url))))

(provide 'paste-kde)

;;; paste-kde.el ends here
