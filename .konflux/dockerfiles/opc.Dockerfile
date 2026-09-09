ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:latest@sha256:5e68f09a652ac6627a83c57655e42e24575efb278b54336039c9308607fc6b21
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal@sha256:d235f607e1d6d833f031db107dc42206e4dd4d5aa9142c43d3771fb7f9bea76a


FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/openshift-pipelines/opc
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
ENV GOEXPERIMENT="strictfipsruntime"
RUN go build -buildvcs=false -mod=vendor -tags disable_gcp,strictfipsruntime  -o /tmp/opc main.go

FROM $RUNTIME
ARG VERSION=1.24
COPY --from=builder /tmp/opc /usr/bin

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

LABEL \
    com.redhat.component="openshift-pipelines-opc-rhel9-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:1.24::el9" \
    description="Red Hat OpenShift Pipelines opc opc" \
    io.k8s.description="Red Hat OpenShift Pipelines opc opc" \
    io.k8s.display-name="Red Hat OpenShift Pipelines opc opc" \
    io.openshift.tags="tekton,openshift,opc,opc" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-opc-rhel9" \
    summary="Red Hat OpenShift Pipelines opc opc" \
    version="v1.24.0-RC-1"
