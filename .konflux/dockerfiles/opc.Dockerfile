ARG GO_BUILDER=registry.access.redhat.com/ubi10/go-toolset:latest@sha256:5d2ab83e88506afee6bcc909fdab425ab979725ab30d6ad43a02aaa77e2258ff
ARG UBI_RUNTIME=registry.access.redhat.com/ubi10/ubi-minimal:latest@sha256:ab67cd02caf8706e34a695a1432ebe965934f6128ec352a6c3f4048b43a4fb5e


FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/openshift-pipelines/opc
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
ENV GOEXPERIMENT="strictfipsruntime"
RUN go build -buildvcs=false -mod=vendor -tags disable_gcp,strictfipsruntime  -o /tmp/opc main.go

FROM $UBI_RUNTIME
ARG VERSION=nightly
COPY --from=builder /tmp/opc /usr/bin

# ubi10/ubi-minimal does not ship shadow-utils, which provides groupadd/useradd
RUN microdnf install -y shadow-utils && \
    groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

LABEL \
    com.redhat.component="openshift-pipelines-opc-rhel10-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:nightly::el10" \
    description="Red Hat OpenShift Pipelines opc opc" \
    io.k8s.description="Red Hat OpenShift Pipelines opc opc" \
    io.k8s.display-name="Red Hat OpenShift Pipelines opc opc" \
    io.openshift.tags="tekton,openshift,opc,opc" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-opc-rhel10" \
    summary="Red Hat OpenShift Pipelines opc opc" \
    version="nightly"
