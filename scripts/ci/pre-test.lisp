;;; OpenLDK src/floating.lisp registers each SBCL defknown while compiling
;;; and again when the fasl loads. The cerror is continuable. CI runs with
;;; the debugger disabled, so continue that one condition and keep the GHCR
;;; system load going.
(labels ((continue-fun-info (condition)
           (let ((restart (find-restart 'continue condition)))
             (when (and restart
                        (search "FUN-INFO" (princ-to-string condition)))
               (invoke-restart restart))))
         (wrap (current)
           (lambda (condition hook)
             (declare (ignore hook))
             (continue-fun-info condition)
             (when current
               (funcall current condition current)))))
  (setf *debugger-hook* (wrap *debugger-hook*))
  #+sbcl
  (setf sb-ext:*invoke-debugger-hook*
        (wrap sb-ext:*invoke-debugger-hook*)))
