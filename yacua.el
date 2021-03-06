(require 'calc)

(defun yacua-check-indentation ()
  (let ((co (current-column)))
    (beginning-of-line)
    (skip-chars-forward " \t")
    (move-to-column (max co (current-column)))))

(defun yacua-split (txt)
  (let* ((i (length txt))
	 (char (substring txt (1- i) i))
	 p num)
    (when (string-match-p "[0-9]" char)
      (while (and (not (eq p 1)) (> i 0) (string-match-p "[0-9.]" char))
	(and (string= char ".") (setq p (if p 1 0)))
	(setq i (1- i))
	(and (> i 0) (setq char (substring txt (1- i) i))))
      (setq num (substring txt i)
	    txt (substring txt 0 i))
      (and (> (length num) 0)
	   (string= (substring num 0 1) ".")
	   (setq txt (concat txt ".")
		 num (substring num 1))))
    (cons txt num)))

;;;###autoload
(defun yacua-insert ()
  (interactive)
  (unless (minibufferp)
    (when (use-region-p)
      (let ((beg (region-beginning))
	    (end (region-end))
	    co-beg co txt num inc prc fmt co ins)
	(save-excursion
	  (goto-char beg)
	  (setq co-beg (current-column))
	  (goto-char end)
	  (setq co (current-column)))
	(setq txt (if (= co-beg co) (read-string "Insert: ") ""))
	(when (> (length txt) 0)
	  (setq txt (yacua-split txt)
		num (cdr txt)
		txt (car txt))
	  (when num
	    (setq inc (read-string "Increment: "))
	    (and (= (string-to-number inc) 0) (setq inc "0"))
	    (setq prc (max (length (cadr (split-string num "\\.")))
			   (length (cadr (split-string inc "\\."))))
		  fmt (concat "%." (number-to-string prc) "f")))
	  (save-excursion
	    (goto-char beg)
	    (push-mark nil t)
	    (while (and (not (eobp))
			(or (= (current-column) co)
			    (and (> (current-column) co)
				 (forward-line)
				 nil)
			    (move-to-column co))
			(<= (point) end))
	      (setq co_ (yacua-check-indentation))
	      (when (= co co_)
		(and num (setq num (format fmt (string-to-number num))))
		(setq ins (concat txt num))
		(insert ins)
		(setq end (+ end (length ins)))
		(and num (setq num (calc-eval (concat num "+" inc)))))
	      (forward-line)))
	  (goto-char end))))))

;;;###autoload
(defun yacua-delete ()
  (interactive)
  (unless (minibufferp)
    (when (use-region-p)
      (let ((beg (region-beginning))
	    (end (region-end))
	    co-beg co-end diff p co)
	(save-excursion
	  (goto-char beg)
	  (setq co-beg (current-column))
	  (goto-char end)
	  (setq co-end (current-column)
		diff (- co-end co-beg))
	  (when (> diff 0)
	    (while (and (not (eq p 1))
			(move-to-column co-beg)
			(>= (point) beg))
	      (setq co (yacua-check-indentation))
	      (delete-char (min diff (if (<= co co-beg)
					 (- (line-end-position) (point))
				       (max (- co-end co) 0))))
	      (forward-line -1)
	      (and (bobp) (setq p (if p 1 0))))))))))

(provide 'yacua)
