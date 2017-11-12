;;; flx-test.el --- flx ert unit tests

;; Copyright © 2013 Le Wang

;; Author: Le Wang
;; Maintainer: Le Wang
;; Description: fuzzy matching with good sorting
;; Created: Tue Apr 16 23:32:32 2013 (+0800)
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

;;; Code:

(eval-when-compile (require 'cl))

(require 'ert)
(add-to-list 'load-path "~/Development/elisp/emacs-module-test")
(add-to-list 'load-path "~/Development/elisp/flx")
(require 'flx)

(ert-deftest flx-test-sanity ()
  "sanity check."
  (should (= 1 1)))

;; all test here are not relevant because command t does not use heatmaps
;; the most important thing is score which is will be returned as float
;; so we modify all tests to account for that instead of (car and heatmap)
(ert-deftest flx-score-basic ()
  "basic scoring -- matches get number, non-matches get nil"
  ;; matches
  (mapc (lambda (str)
          (should (flx-score str "a" (flx-make-filename-cache))))
        '("a"
          "ba"
          "ab"
          ".a"
          "aaaa"
          "foo.bra"
          "a/foo"
          "b/a/foo"
          "b/.a/foo"
          "b/.a./foo"))
  ;; empty string should not match anything
  ;; but in command t case that is 1.0
  (mapc (lambda (str)
          (should (= (flx-score str "" (flx-make-filename-cache)) 1.0 )))
        '(""
          "zz"
          "."))
  ;; non-matches
  ;; this will be 0.0
  (mapc (lambda (str)
          (should (= (flx-score str "a" (flx-make-filename-cache)) 0.0 )))
        '(""
          "zz"
          ".")))


(ert-deftest flx-score-capital ()
  "QUERY should not be downcased."
  ;; in commandt case should not be scored
  (should (= (flx-score "abc" "A" (flx-make-filename-cache)) 0.0)))

(ert-deftest flx-score-string ()
  "score as string"
  (let ((string-as-path-score (flx-score "a/b" "a" ))
        (string-score (flx-score "a_b" "a" )))
    (should (= string-as-path-score string-score))))


(ert-deftest flx-basename-order ()
  "index of match matters"
  (let* ((query "a")
         (higher (flx-score "a_b_c" query (flx-make-filename-cache)))
         (lower (flx-score "b_a_c" query (flx-make-filename-cache))))
    (should (> higher lower))))

(ert-deftest flx-basename-lead-separators ()
  "leading word separators should be penalized"
  (let* ((query "a")
         (higher (flx-score "ab" query (flx-make-filename-cache)))
         (lower (flx-score "_ab" query (flx-make-filename-cache))))
    (should (> higher lower))))


(ert-deftest flx-entire-match-1 ()
  "whole match is preferred"
  (let* ((query "a")
         (higher (flx-score "a" query (flx-make-filename-cache)))
         (lower (flx-score "ab" query (flx-make-filename-cache))))
    (should (> higher lower))))

;;;;;;;;;;;;;;
;; advanced ;;
;;;;;;;;;;;;;;

(ert-deftest flx-filename-non-anchored-substring-yields-better ()
  "Preferring to match beginning-of-word can lead to wrong answers.

In this case, the match with more contiguous characters is better."
  (let* ((query "abcd")
         (lower (flx-score "f a fbcd/fabcd/z" query (flx-make-filename-cache)))
         (higher (flx-score "f a fbcd/z" query (flx-make-filename-cache))))
    (should (> higher lower))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; imported from Command-t tests ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(ert-deftest flx-imported-prioritizes-matches-with-more-matching-characters ()
  (let* ((str "foobar")
         (higher (flx-score str "fbar" (flx-make-filename-cache)))
         (lower (flx-score str "fb" (flx-make-filename-cache))))
    (should (> higher lower))))

(ert-deftest flx-imported-prioritizes-shorter-paths-over-longer-ones ()
  (let* ((query "art")
         (higher (flx-score "articles.rb" query (flx-make-filename-cache)))
         (lower (flx-score "articles_controller_spec.rb" query (flx-make-filename-cache))))
    (should (> higher lower))))


;;; I've had to modify these test heavily, every assertion Command-t
;;; makes, we've gone the opposite way.  :)
;;;
;;; We strongly prefer basename matches, where as they do not.

(ert-deftest flx-imported-prioritizes-matches-after-/ ()
  (let ((query "b"))
    (let ((higher (flx-score "foo/bar" query (flx-make-filename-cache)))
          (lower (flx-score "foobar" query (flx-make-filename-cache))))
    (should (> higher lower)))
    (let ((higher (flx-score "foo/bar" query (flx-make-filename-cache)))
          (lower (flx-score "foo9bar" query (flx-make-filename-cache))))
    (should (> higher lower)))
    (let ((higher (flx-score "foo/bar" query (flx-make-filename-cache)))
          (lower (flx-score "foo.bar" query (flx-make-filename-cache))))
    (should (> higher lower)))))



(ert-deftest flx-imported-prioritizes-matches-after-- ()
  (let ((query "b"))
    (let ((higher (flx-score "foo-bar" query (flx-make-filename-cache)))
          (lower (flx-score "foobar" query (flx-make-filename-cache))))
    (should (> higher lower)))
    (let ((higher (flx-score "foo-bar" query (flx-make-filename-cache)))
          (lower (flx-score "foo.bar" query (flx-make-filename-cache))))
    (should (> higher lower)))))

(ert-deftest flx-imported-prioritizes-matches-after-_ ()
  (let ((query "b"))
    (let ((higher (flx-score "foo_bar" query (flx-make-filename-cache)))
          (lower (flx-score "foobar" query (flx-make-filename-cache))))
      (should (> higher lower)))
    (let ((higher (flx-score "foo_bar" query (flx-make-filename-cache)))
          (lower (flx-score "foo.bar" query (flx-make-filename-cache))))
    (should (> higher lower)))))

(ert-deftest flx-imported-prioritizes-matches-after-space ()
  (let ((query "b"))
    (let ((higher (flx-score "foo bar" query (flx-make-filename-cache)))
          (lower (flx-score "foobar" query (flx-make-filename-cache))))
      (should (> higher lower)))
    (let ((higher (flx-score "foo bar" query (flx-make-filename-cache)))
          (lower (flx-score "foo.bar" query (flx-make-filename-cache))))
      (should (> higher lower)))))

(ert-deftest flx-imported-prioritizes-matches-after-periods ()
  (let ((query "b"))
    (let ((higher (flx-score "foo.bar" query (flx-make-filename-cache)))
          (lower (flx-score "foobar" query (flx-make-filename-cache))))
      (should (> higher lower)))))

(ert-deftest flx-imported-prioritizes-matching-capitals-following-lowercase ()
  (let ((query "b"))
    (let ((higher (flx-score "fooBar" query (flx-make-filename-cache)))
          (lower (flx-score "foobar" query (flx-make-filename-cache))))
      (should (> higher lower)))))

(ert-deftest prioritizes-matches-earlier-in-the-string ()
  (let ((query "b"))
    (let ((higher (flx-score "**b*****" query (flx-make-filename-cache)))
          (lower (flx-score "******b*" query (flx-make-filename-cache))))
      (should (> higher lower)))))


(ert-deftest flx-imported-prioritizes-matches-closer-to-previous-matches ()
  (let ((query "bc"))
    (let ((higher (flx-score "**bc****" query (flx-make-filename-cache)))
          (lower (flx-score "**b***c*" query (flx-make-filename-cache))))
      (should (> higher lower)))))


(ert-deftest flx-imported-scores-alternative-matches-of-same-path-differently ()
  (let ((query "artcon"))
    (let ((higher (flx-score "***/***********/art*****_con*******.**" query (flx-make-filename-cache)))
          (lower (flx-score "a**/****r******/**t*c***_*on*******.**" query (flx-make-filename-cache))))
      (should (> higher lower)))))

(ert-deftest flx-imported-provides-intuitive-results-for-artcon-and-articles_controller ()
  (let ((query "artcon"))
    (let ((higher (flx-score "app/controllers/articles_controller.rb" query (flx-make-filename-cache)))
          (lower (flx-score "app/controllers/heartbeat_controller.rb" query (flx-make-filename-cache))))
      (should (> higher lower)))))

(ert-deftest flx-imported-provides-intuitive-results-for-aca-and-a/c/articles_controller ()
  (let ((query "aca"))
    (let ((lower (flx-score "app/controllers/heartbeat_controller.rb" query (flx-make-filename-cache)))
          (higher (flx-score "app/controllers/articles_controller.rb" query (flx-make-filename-cache)))
          (best   (flx-score "a**/c**********/a*****************.**" query (flx-make-filename-cache))))
      (should (> higher lower))
      ;; our best is a higher score than higher because we penalize higher for
      ;; having one more word.
      (should (> best higher)))))


(ert-deftest flx-imported-provides-intuitive-results-for-d-and-doc/command-t.txt ()
  (let ((query "d"))
    (let ((lower (flx-score "TODO" query (flx-make-filename-cache)))
          (higher (flx-score "doc/command-t.txt" query (flx-make-filename-cache))))
      (should (> higher lower)))))

(ert-deftest flx-imported-provides-intuitive-results-for-do-and-doc/command-t.txt ()
  (let ((query "do"))
    ;; This test is flipped around, because we consider capitals to always be
    ;; word starters, and we very heavily favor basepath matches.
    (let ((higher (flx-score "doc/command-t.txt" query (flx-make-filename-cache)))
          (lower (flx-score "TODO" query (flx-make-filename-cache))))
      (should (> higher lower)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; new features (not in ST2) ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(ert-deftest flx-entire-match-3 ()
  "when entire string is match, it shoud overpower acronym matches"
  (let* ((query "rss")
         (higher (flx-score "rss" query (flx-make-filename-cache)))
         (lower (flx-score "rff-sff-sff" query (flx-make-filename-cache))))
    (should (> higher lower))))

(ert-deftest flx-entire-match-5 ()
  "when entire string is match, 4 letters is the cutoff when
substring can overpower abbreviation."
  (let* ((query "rssss")
         (higher (flx-score "rssss" query (flx-make-filename-cache)))
         (lower (flx-score "rff-sff-sff-sff-sff" query (flx-make-filename-cache))))
    (should (> higher lower))))

(ert-deftest flx-capital-runs ()
  "Runs of capital letters should be considered one word."
  (let* ((query "ab")
         (score1 (flx-score "AFFB" query (flx-make-filename-cache)))
         (score2 (flx-score "affb" query (flx-make-filename-cache))))
    (should (= score1 score2))))


(ert-deftest flx-basepath-is-last-segment ()
  "For a path like \"bar/foo/\" the basename should be foo"
  (let* ((query "def")
         (higher (flx-score "defuns/" query (flx-make-filename-cache)))
         (lower (flx-score "sane-defaults.el" query (flx-make-filename-cache))))
    (should (> higher lower))))

(ert-deftest flx-case-fold ()
  "Lower case can match lower or upper case, but upper case can only match upper case."
  (let* ((query "def")
         (lower-folds (flx-score "Defuns/" query (flx-make-filename-cache))))
    (should lower-folds))
  (let* ((query "Def")
         (upper-no-folds (flx-score "defuns/" query (flx-make-filename-cache))))
    (should (not upper-no-folds))))


;;; perf

;; (ert-deftest flx-prune-search-space-optimizations ()
;;   "Make sure optimizations that prune bad paths early are working."
;;   (let ((future (async-start
;;                  `(lambda ()
;;                     ,(async-inject-variables "\\`load-path\\'")
;;                     (require 'flx)
;;                     (flx-score "~/foo/bar/blah.elllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll" "lllllllllllllllllllllllllllllllll" (flx-make-filename-cache)))
;;                  nil))
;;         result)
;;     (with-timeout (1 (kill-process future) )
;;       (while (not result) ;; while process is running
;;         (sit-for .2)
;;         (when (async-ready future)
;;           (setq result (async-get future)))))
;;     (should result)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; flx-test.el ends here
