(defsystem "java-backend-openldk"
  :version "0.1.0"
  :description "Load Java libraries on SBCL through OpenLDK. Downloads use cl-stack-http; checksums use crypto-protocol."
  :author "egao1980"
  :license "MIT"
  :depends-on ("openldk/interop" "cl-stack-http" "crypto-protocol")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "conditions")
               (:file "maven")
               (:file "runtime")
               (:file "asdf"))
  :in-order-to ((test-op (test-op "java-backend-openldk/tests")))
  :properties
  (:cl-repo (:ci (:with ("crypto-backend-ironclad")))))

(defsystem "java-backend-openldk/tests"
  :depends-on ("java-backend-openldk" "crypto-backend-ironclad" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "maven-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
