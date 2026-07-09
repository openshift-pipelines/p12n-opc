ARG GO_BUILDER=registry.access.redhat.com/ubi8/go-toolset@sha256:2cf375705f1930a4e248f17d2ec288be909e9b303bdc7192323dc138cc9dbee8
ARG RUNTIME=registry.access.redhat.com/ubi8/ubi-minimal@sha256:61e4f7716c700562f8e8882913a99677748918aa5a534929990d02c1bae10ca4


FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/openshift-pipelines/opc
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
ENV GOEXPERIMENT="strictfipsruntime"
RUN go build -buildvcs=false -mod=vendor -tags disable_gcp,strictfipsruntime  -o /tmp/opc main.go

FROM $RUNTIME
ARG VERSION=1.15
COPY --from=builder /tmp/opc /usr/bin

RUN microdnf install -y shadow-utils && \
    groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

LABEL \
    com.redhat.component="openshift-pipelines-opc-rhel8-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:1.15::el8" \
    description="Red Hat OpenShift Pipelines opc opc" \
    io.k8s.description="Red Hat OpenShift Pipelines opc opc" \
    io.k8s.display-name="Red Hat OpenShift Pipelines opc opc" \
    io.openshift.tags="tekton,openshift,opc,opc" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-opc-rhel8" \
    summary="Red Hat OpenShift Pipelines opc opc" \
    version="v1.15.5"
