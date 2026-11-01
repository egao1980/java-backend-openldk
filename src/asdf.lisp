(in-package #:java-backend-openldk)

(defclass asdf::ldk-maven-jar (asdf:component)
  ((coordinates :initarg :coordinates :reader ldk-maven-jar-coordinates)
   (sha256 :initarg :sha256 :initform nil :reader ldk-maven-jar-sha256)
   (repository :initarg :repository :initform nil :reader ldk-maven-jar-repository))
  (:documentation "Maven jar placed on the OpenLDK classpath at load-op.
The consuming system must :defsystem-depends-on (\"java-backend-openldk\")."))

(defmethod asdf:component-pathname ((component asdf::ldk-maven-jar))
  nil)

(defmethod asdf:input-files ((op asdf:compile-op) (component asdf::ldk-maven-jar))
  nil)

(defmethod asdf:output-files ((op asdf:compile-op) (component asdf::ldk-maven-jar))
  (values nil t))

(defmethod asdf:perform ((op asdf:compile-op) (component asdf::ldk-maven-jar))
  nil)

(defmethod asdf:perform ((op asdf:load-op) (component asdf::ldk-maven-jar))
  (apply #'add-maven-jar
         (ldk-maven-jar-coordinates component)
         (append (when (ldk-maven-jar-sha256 component)
                   (list :sha256 (ldk-maven-jar-sha256 component)))
                 (when (ldk-maven-jar-repository component)
                   (list :repository (ldk-maven-jar-repository component))))))
