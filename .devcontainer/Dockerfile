FROM mcr.microsoft.com/devcontainers/universal:2-linux

ARG ZIG_VERSION="0.13.0"
WORKDIR /home/codespace
ADD --chown=codespace:codespace install-zig.sh install-zig.sh
RUN chmod +x install-zig.sh && ./install-zig.sh ${ZIG_VERSION}
