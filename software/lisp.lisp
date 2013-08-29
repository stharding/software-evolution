;;; lisp.lisp --- software representation of lisp code

;; Copyright (C) 2013  Eric Schulte

;; Licensed under the Gnu Public License Version 3 or later

;;; Code:
(in-package :software-evolution)


;;; Tree actions
(defun tree-size (tree)
  "Return the number of cons cells in TREE."
  (if (and tree (consp tree))
      (+ 1 (tree-size (car tree)) (tree-size (cdr tree)))
      0))

(defun subtree (tree index)
  "Return the INDEX cons cell in TREE in depth first order."
  (if (zerop index)
      (values tree index)
      (flet ((descend (branch)
               (when (consp branch)
                 (multiple-value-bind (new-tree new-index)
                     (subtree branch (1- index))
                   (if (= new-index 0)
                       (return-from subtree (values new-tree new-index))
                       (setf index new-index))))))
        (descend (car tree))
        (descend (cdr tree))
        (values nil index))))

(defun (setf subtree) (new tree index)
  (rplaca (subtree tree index) new))


;;; Lisp software object
(defclass lisp (software)
  ((genome :initarg :genome :accessor genome :initform nil)))

(defmethod from-file ((lisp lisp) file)
  (with-open-file (in file)
    (setf (genome lisp)
          (loop :for form = (read in nil :eof)
             :until (eq form :eof)
             :collect form)))
  lisp)

;; TODO: should take an optional stream
(declaim (inline genome-string))
(defmethod genome-string ((lisp lisp))
  (with-output-to-string (out)
    (dolist (form (genome lisp))
      (format out "~&~S~%" form))))

(defmethod to-file ((software lisp) path)
  (with-open-file (out path :direction :output :if-exists :supersede)
    (string-to-file (genome-string lisp))))

(defmethod copy ((lisp lisp))
  (make-instance (type-of lisp)
    :fitness (fitness lisp)
    :genome (copy-tree (genome lisp))))
