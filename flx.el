;;; flx.el --- fuzzy matching with good sorting

;; Copyright © 2013, 2015 Le Wang

;; Author: Le Wang
;; Maintainer: Le Wang
;; Description: fuzzy matching with good sorting
;; Created: Wed Apr 17 01:01:41 2013 (+0800)
;; Version: 0.6.1
;; Package-Requires: ((cl-lib "0.3"))
;; URL: https://github.com/lewang/flx

;; This file is NOT part of GNU Emacs.

;;; License

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;; Implementation notes
;; --------------------
;;
;; Use defsubst instead of defun
;;
;; * Using bitmaps to check for matches worked out to be SLOWER than just
;;   scanning the string and using `flx-get-matches'.
;;
;; * Consing causes GC, which can often slowdown Emacs more than the benefits
;;   of an optimization.

;;; Acknowledgments

;; Scott Frazer's blog entry http://scottfrazersblog.blogspot.com.au/2009/12/emacs-better-ido-flex-matching.html
;; provided a lot of inspiration.
;; ido-hacks was helpful for ido optimization

;;; Code:

(require 'cl)
(add-to-list 'load-path "~/Development/elisp/emacs-module-test")
(require 'module-test)

(defgroup flx nil
  "Fuzzy matching with good sorting"
  :group 'convenience
  :prefix "flx-")

(defcustom flx-word-separators '(?\  ?- ?_ ?: ?. ?/ ?\\)
  "List of characters that act as word separators in flx"
  :type '(repeat character)
  :group 'flx)

(defface flx-highlight-face  '((t (:inherit font-lock-variable-name-face :bold t :underline t)))
  "Face used by flx for highlighting flx match characters."
  :group 'flx)

;;; Do we need more word separators than ST?


(defun flx-make-filename-cache ()
  '(t))

(defun flx-score (str query &optional case)
  "Return best score matching QUERY against STR"
  (calc-score query str))


(defvar flx-file-cache nil
  "Cached heatmap info about strings.")

;;; reset value on every file load.
(setq flx-file-cache (flx-make-filename-cache))

(defvar flx-strings-cache nil
  "Cached heatmap info about filenames.")

;;; reset value on every file load.
(setq flx-strings-cache nil)

(provide 'flx)

;;; flx.el ends here
