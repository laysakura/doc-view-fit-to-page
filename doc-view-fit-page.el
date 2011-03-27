;;; Fit-to-page extension for DocViewMode

(require 'doc-view)

(defconst doc-view-tmp-png-path "/tmp/doc-view-tmp.png")
(defconst doc-view-tmp-pdf/ps-path "/tmp/doc-view-tmp-img")

(defun doc-view-get-dpi ()
  "Returns resolution of your display in Dpi.
If you don't use X Window System, this function asks you Dpi."
  (let ((resolution-info (shell-command-to-string
                          "xdpyinfo |grep 'resolution'")))
    (if (string-match "\\([0-9]+\\)x" resolution-info)
        (string-to-number (match-string 1 resolution-info))
      (read-number "Input your display resolution (Dpi): "))))
;; (doc-view-get-dpi)

(defun doc-view-pdf/ps-size-in-px (pdf/ps-path)
  "Returns (width . height) of PDF/PS file with 'pdf/ps-path`"
  (call-process "gs" nil nil t
                "-dSAFER" "-dNOPAUSE" "-sDEVICE=png16m" "-dTextAlphaBits=4"
                "-dBATCH" "-dGraphicsAlphaBits=4" "-dQUIET"
                "-dFirstPage=1" "-dLastPage=1" (concat "-sOutputFile=" doc-view-tmp-png-path)
                pdf/ps-path)
  (cons (string-to-number
         (shell-command-to-string
          (concat "echo -n `identify -format \"%w\" " doc-view-tmp-png-path "`")))
        (string-to-number
         (shell-command-to-string
          (concat "echo -n `identify -format \"%h\" " doc-view-tmp-png-path "`")))))
;; (doc-view-pdf/ps-size-in-px "sample.ps")
;; (doc-view-pdf/ps-size-in-px "sample.pdf")

(defun doc-view-window-size-in-px ()
  "Returns current window size in pixel like (width . height) ."
  (cons (* (window-width) (frame-char-width))
        (* (window-height) (frame-char-height))))
;; (doc-view-window-size-in-px)

(defun doc-view-px-to-natural (px dpi)
  "Convert pixel to \"Natural size\", which is about the same size with one printed on paper.
Emacs displays images with \"Natural size\", so this conversion is necessary."
  (* px 1.3871979865e-2 dpi))
;; (doc-view-px-to-natural 596 96)

(defun doc-view-percentage-to-fit (pdf/ps-path dpi)
  "Returns percentage you can set to fit image onto a window.
For example, (88 . 74) means if you set 88 to 'doc-view-resolution',
the width of the image fits the window."
  (let* ((pdf/ps-size (doc-view-pdf/ps-size-in-px pdf/ps-path))
         (pdf/ps-width (car pdf/ps-size))
         (pdf/ps-height (cdr pdf/ps-size))
         (window-size (doc-view-window-size-in-px))
         (window-width (car window-size))
         (window-height (cdr window-size)))
    (cons (* 100.0 (/ window-width (doc-view-px-to-natural (float pdf/ps-width) dpi)))
          (* 100.0 (/ window-height (doc-view-px-to-natural (float pdf/ps-height) dpi))))))
;; (doc-view-percentage-to-fit "sample.ps" (doc-view-get-dpi))
;; (doc-view-percentage-to-fit "sample.pdf" (doc-view-get-dpi))

(defun doc-view-change-size (size)
  "Changes the size of the image viewed in DocViewMode into 'size'."
  (set (make-local-variable 'doc-view-resolution) size)
  (doc-view-reconvert-doc))

(defun doc-view-fit-height ()
  "Makes the height of image fit with window."
  (interactive)
  (doc-view-change-size
   (round (cdr (doc-view-percentage-to-fit (buffer-file-name) (doc-view-get-dpi))))))
(defun doc-view-fit-width ()
  "Makes the height of image fit with window."
  (interactive)
  (doc-view-change-size
   (round (car (doc-view-percentage-to-fit (buffer-file-name) (doc-view-get-dpi))))))
(defun doc-view-fit-page ()
  "Makes image fit with window."
  (interactive)
  (let ((percentage (doc-view-percentage-to-fit (buffer-file-name) (doc-view-get-dpi))))
    (doc-view-change-size (round (min (car percentage)
                             (cdr percentage))))))

(provide 'doc-view-fit-page)
