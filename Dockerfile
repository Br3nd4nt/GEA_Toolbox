# syntax=docker/dockerfile:1
#
# Build a license-free demo image for end-users by running a compiled MATLAB
# application with MATLAB Runtime (MCR).
#
# Prereq (you, the developer): compile first using MATLAB Compiler:
#   ./deploy/compile_demo.sh
#
# Then build:
#   docker build -t gea-demo:local .
#
# Run:
#   docker run --rm gea-demo:local minimal
#   docker run --rm gea-demo:local gqap_t1
#
# Multi-arch note:
#   MathWorks MCR images are typically linux/amd64. On Apple Silicon/ARM hosts
#   you can run with emulation:
#     docker run --platform=linux/amd64 --rm gea-demo:local minimal

ARG MCR_IMAGE=containers.mathworks.com/matlab-runtime:r2025a
FROM ${MCR_IMAGE} AS runtime

WORKDIR /opt/gea_demo

# compiler.build.standaloneApplication writes a folder tree; copy everything.
# The default output path from deploy/compile_demo.m is dist/GEA_Demo.
COPY dist/GEA_Demo/ ./app/

COPY deploy/docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["minimal"]
