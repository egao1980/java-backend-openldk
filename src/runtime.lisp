(in-package #:java-backend-openldk)

(defun ensure-runtime (&key classpath)
  "Start OpenLDK, or add CLASSPATH (list or colon-separated string) if it is already up.
RETRY runs the start again. JDK 25 comes from JAVA_HOME, or from OpenLDK's Temurin fetch."
  (tagbody
   again
     (return-from ensure-runtime
       (restart-case
           (handler-bind ((error
                           (lambda (c)
                             (unless (typep c 'jdk-not-found)
                               (error 'jdk-not-found
                                      :java-home (uiop:getenv "JAVA_HOME")
                                      :cause c
                                      :message "OpenLDK did not start.")))))
             (openldk.interop:start-runtime :classpath classpath))
         (retry ()
           :report "Retry starting OpenLDK"
           (go again))))))

(defun add-jar (jar)
  "Put JAR on the OpenLDK classpath, starting the runtime if needed."
  (let ((file (probe-file jar)))
    (unless file
      (error 'java-library-error :path jar :message "jar not found"))
    (ensure-runtime)
    (openldk.interop:add-to-classpath (namestring (truename file)))
    file))

(defun add-maven-jar (coordinates &key sha256 (repository *maven-repository*))
  "Download COORDINATES if needed and put the jar on the OpenLDK classpath."
  (add-jar (path:as-namestring
            (ensure-maven-jar coordinates :sha256 sha256 :repository repository))))

(defun load-class (name)
  (openldk.interop:java-load name))

(defun jcall (method object &rest args)
  (apply #'openldk.interop:java-call method object args))

(defun jstatic (class method &rest args)
  (apply #'openldk.interop:java-static class method args))

(defun jnew (class constructor &rest args)
  (apply #'openldk.interop:java-new class constructor args))

(defun jstatic-field (class field)
  (openldk.interop:java-static-field class field))

(defun jstring (string)
  (openldk.interop:jstring string))

(defun lstring (java-string)
  (openldk.interop:lstring java-string))
