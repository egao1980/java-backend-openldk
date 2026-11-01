;;; cl-repo against GHCR only. A missing system stays missing.
(setf cl-repository-client/source-policy:*default-source* :oci)
