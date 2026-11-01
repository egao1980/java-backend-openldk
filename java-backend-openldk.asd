(defsystem "java-backend-openldk"
  :version "0.1.0"
  :description "Load Java libraries on SBCL through OpenLDK. Downloads use cl-stack-http; checksums use crypto-protocol."
  :author "egao1980"
  :license "MIT"
  :depends-on ("cl-stack-http"
               "crypto-protocol"
               ;; OpenLDK src/jrt.lisp reads sb-posix:mmap. Windows SBCL
               ;; does not export that. The GHCR system stays the runtime
               ;; on SBCL outside Windows.
               (:feature (:and :sbcl (:not :windows)) "openldk/interop"))
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "conditions")
               (:file "maven")
               (:file "runtime" :if-feature (:and :sbcl (:not :windows)))
               (:file "asdf" :if-feature (:and :sbcl (:not :windows))))
  :in-order-to ((test-op (test-op "java-backend-openldk/tests")))
  :properties
  ;; serapeum depends on iterate. Client 0.23 leaves a non-registry copy in
  ;; place. :with force-installs the GHCR package before the walk.
  (:cl-repo (:ci (:with ("crypto-backend-ironclad" "iterate")))))

(defsystem "java-backend-openldk/tests"
  :depends-on ("java-backend-openldk" "crypto-backend-ironclad" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "maven-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
