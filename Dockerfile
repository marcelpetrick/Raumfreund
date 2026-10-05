# syntax=docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# Raumfreund – reproducible Android build and APK download server.
#
# Stages:
#   toolchain  pinned JDK 21, Android SDK (cmdline-tools 23.0, platform 36,
#              build-tools 36.0.0, NDK 28.2) and Flutter (.flutter-version)
#   build      runs the Dart quality gates (format, analyze, tests, coverage)
#              and builds the release APK via tool/build_apk.sh
#   runtime    unprivileged nginx serving a download page + APK on port 8080
#
# Build:  docker build -t raumfreund .
# Run:    docker run --rm -p 8080:8080 raumfreund   → http://localhost:8080
# Signing material is passed as BuildKit secret "keystore_properties" plus
# "keystore" (see docs/releasing.md); without it the APK is debug-signed and
# named *-debugsigned.apk.

FROM eclipse-temurin:21-jdk-noble@sha256:b468c3fc688b14450571494f588bd939378e7fd542ed5a73f8efc13f17872a87 AS toolchain

ARG ANDROID_CMDLINE_TOOLS_BUILD=16111833
ARG ANDROID_CMDLINE_TOOLS_SHA256=0877a1d048fe4a24efe2eff536ca4223f7adeb58648bb81909d33c446918cfa8
ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    PUB_CACHE=/opt/pub-cache \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    LANG=C.UTF-8
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSfL -o /tmp/tools.zip \
        "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_BUILD}_latest.zip" \
    && echo "${ANDROID_CMDLINE_TOOLS_SHA256}  /tmp/tools.zip" | sha256sum --check \
    && mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && unzip -q /tmp/tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
    && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm /tmp/tools.zip \
    && yes | sdkmanager --licenses >/dev/null \
    && sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0" \
        "ndk;28.2.13676358" >/dev/null

WORKDIR /src
COPY .flutter-version .flutter-sha256 ./
COPY tool/flutter.sh tool/flutter.sh
RUN git config --global --add safe.directory '*' \
    && tool/flutter.sh --ensure \
    && tool/flutter.sh precache --android

FROM toolchain AS build
COPY pubspec.yaml pubspec.lock ./
RUN tool/flutter.sh pub get --enforce-lockfile
COPY . .
ARG GIT_COMMIT=unknown
# Same gates as ./localPipeline.sh for the Dart side; shell and Kotlin linters
# run in the regular pipeline/CI because they need extra tools.
RUN ./localPipeline.sh --only toolchain,deps,format,analyze,test,coverage
RUN --mount=type=cache,target=/root/.gradle \
    --mount=type=secret,id=keystore_properties,required=false \
    --mount=type=secret,id=keystore,required=false \
    if [ -f /run/secrets/keystore_properties ]; then \
        cp /run/secrets/keystore_properties android/key.properties \
        && cp /run/secrets/keystore android/upload-keystore.jks; \
    fi \
    && tool/build_apk.sh --commit "${GIT_COMMIT}" \
    && rm -f android/key.properties android/upload-keystore.jks \
    && docker/render_index.sh dist docker/index.html.template dist/index.html

FROM nginxinc/nginx-unprivileged:1-alpine@sha256:b9241c6e7b8e9a862f129d8d4199ab64b10390949a78bdd5603379b32c844083 AS runtime
ARG GIT_COMMIT=unknown
LABEL org.opencontainers.image.title="Raumfreund" \
      org.opencontainers.image.description="Raumfreund Android APK download server (friendly noise traffic light)" \
      org.opencontainers.image.source="https://github.com/marcelpetrick/Raumfreund" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.revision="${GIT_COMMIT}"
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/dist/ /usr/share/nginx/html/
COPY LICENSE /usr/share/nginx/html/LICENSE.txt
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1
