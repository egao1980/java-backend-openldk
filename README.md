# java-backend-openldk

SBCL loader for Java libraries on [OpenLDK](https://github.com/atgreen/openldk) 1.0.2.

OpenLDK is GPL-3.0-or-later with the Classpath exception. This system is MIT. It calls `openldk.interop` only. Jar bytes go through `cl-stack-http`. SHA-256 goes through `crypto-protocol`. Paths go through `cl-stack-pathlib`.

```lisp
(asdf:load-system "crypto-backend-ironclad")
(asdf:load-system "http-backend-async") ; or another stack-http backend
(asdf:load-system "java-backend-openldk")

(ldk-java:add-maven-jar "commons-codec:commons-codec:1.17.1"
                        :sha256 "...")
(ldk-java:jstatic "java.lang.Math" "max(II)" 3 4)
```

`JAVA_HOME` should be a JDK 25. If it is unset, OpenLDK fetches Temurin.

A system can pull a jar at load time:

```lisp
(defsystem "my-app"
  :defsystem-depends-on ("java-backend-openldk")
  :components ((:ldk-maven-jar "commons-codec"
                :coordinates "commons-codec:commons-codec:1.17.1"
                :sha256 "...")))
```

`RETRY` fetches a jar or starts the runtime again. `USE-VALUE` replaces bad Maven coordinates, or accepts a jar whose checksum does not match.
