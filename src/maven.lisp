(in-package #:java-backend-openldk)

(defparameter *maven-repository* "https://repo1.maven.org/maven2")

(defun %hex (octets)
  (with-output-to-string (out)
    (loop for byte across octets
          do (format out "~(~2,'0x~)" byte))))

(defun file-sha256 (path)
  "SHA-256 hex of PATH via crypto-protocol. Load a crypto-backend-* first."
  (%hex (crypto:digest (path:read-bytes path) :algorithm :sha256)))

(defun %coordinates-parts (coordinates)
  (let ((parts (uiop:split-string coordinates :separator ":")))
    (if (and (= 3 (length parts))
             (every (lambda (part) (and part (plusp (length part)))) parts))
        parts
        nil)))

(defun parse-maven-coordinates (coordinates)
  "COORDINATES as (values group artifact version). USE-VALUE supplies a replacement."
  (check-type coordinates string)
  (loop
    (let ((parts (%coordinates-parts coordinates)))
      (when parts
        (return (values-list parts)))
      (restart-case
          (error 'java-library-error
                 :coordinates coordinates
                 :message "Maven coordinates are group:artifact:version")
        (use-value (new)
          :report "Supply group:artifact:version"
          :interactive (lambda ()
                         (format *query-io* "Coordinates: ")
                         (finish-output *query-io*)
                         (list (read-line *query-io*)))
          (setf coordinates new))))))

(defun maven-jar-url (coordinates &key (repository *maven-repository*))
  (multiple-value-bind (group artifact version) (parse-maven-coordinates coordinates)
    (format nil "~A/~A/~A/~A/~A-~A.jar"
            (string-right-trim "/" repository)
            (substitute #\/ #\. group)
            artifact version artifact version)))

(defun %cache-file (coordinates)
  (multiple-value-bind (group artifact version) (parse-maven-coordinates coordinates)
    (merge-pathnames
     (format nil "java-backend-openldk/maven/~A/~A/~A/~A-~A.jar"
             (substitute #\/ #\. group)
             artifact version artifact version)
     (uiop:xdg-cache-home))))

(defun %check-sha256 (path expected)
  (let ((actual (file-sha256 path)))
    (when (string-equal expected actual)
      (return-from %check-sha256 path))
    (restart-case
        (error 'checksum-mismatch :path path :expected expected :actual actual
               :message "SHA-256 mismatch")
      (use-value ()
        :report "Accept the jar despite the checksum"
        path))))

(defun %download-jar (url dest)
  (handler-bind ((error (lambda (c)
                          (declare (ignore c))
                          (when (uiop:file-exists-p dest)
                            (ignore-errors (delete-file dest))))))
    (http:download url (path:ensure-path dest)
                   :overwrite t
                   :create-parents t)))

(defun ensure-maven-jar (coordinates &key sha256 (repository *maven-repository*))
  "Local path of the Maven jar. Downloads with stack-http. RETRY fetches again.
An HTTP backend must already be loaded (stack-http:ensure-http-backend)."
  (let ((dest (%cache-file coordinates))
        (url (maven-jar-url coordinates :repository repository)))
    (tagbody
     fetch
       (return-from ensure-maven-jar
         (restart-case
             (progn
               (unless (uiop:file-exists-p dest)
                 (%download-jar url dest))
               (when (and sha256 (plusp (length sha256)))
                 (%check-sha256 dest sha256))
               (path:ensure-path dest))
           (retry ()
             :report "Delete the cached jar and download it again"
             (when (uiop:file-exists-p dest)
               (delete-file dest))
             (go fetch)))))))
