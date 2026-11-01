(in-package #:java-backend-openldk/tests)

(deftest parse-coordinates
  (multiple-value-bind (group artifact version)
      (parse-maven-coordinates "com.google.guava:guava:33.0.0-jre")
    (ok (equal "com.google.guava" group))
    (ok (equal "guava" artifact))
    (ok (equal "33.0.0-jre" version))))

(deftest parse-coordinates-rejects-short-form
  (ok (signals (parse-maven-coordinates "guava:33") 'java-library-error)))

(deftest parse-coordinates-use-value
  (multiple-value-bind (group artifact version)
      (handler-bind ((java-library-error
                      (lambda (c)
                        (declare (ignore c))
                        (invoke-restart 'use-value "commons-codec:commons-codec:1.17.1"))))
        (parse-maven-coordinates "nope"))
    (ok (equal "commons-codec" group))
    (ok (equal "commons-codec" artifact))
    (ok (equal "1.17.1" version))))

(deftest maven-url-rewrites-group-dots
  (ok (equal "https://repo1.maven.org/maven2/com/google/guava/guava/33.0.0-jre/guava-33.0.0-jre.jar"
             (maven-jar-url "com.google.guava:guava:33.0.0-jre"))))

(defun %with-bytes (bytes fn)
  (let ((path (merge-pathnames (format nil "ldk-java-~A" (random 1000000))
                               (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (with-open-file (out path :direction :output :if-exists :supersede
                                :element-type '(unsigned-byte 8))
             (write-sequence bytes out))
           (funcall fn path))
      (when (uiop:file-exists-p path)
        (delete-file path)))))

(deftest sha256-of-abc
  (%with-bytes #(97 98 99)
               (lambda (path)
                 (ok (string-equal
                      "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
                      (file-sha256 path))))))

(deftest checksum-mismatch-use-value
  (%with-bytes #(97 98 99)
               (lambda (path)
                 (ok (signals (java-backend-openldk::%check-sha256 path "00")
                              'checksum-mismatch))
                 (ok (equal (namestring path)
                            (namestring
                             (handler-bind ((checksum-mismatch
                                             (lambda (c)
                                               (declare (ignore c))
                                               (invoke-restart 'use-value))))
                               (java-backend-openldk::%check-sha256 path "00"))))))))

(deftest ldk-maven-jar-component-class
  (if (find-class 'asdf::ldk-maven-jar nil)
      (ok t)
      (skip "asdf component is loaded with the system")))
