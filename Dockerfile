FROM ubuntu:24.04

RUN  apt update && \
     apt upgrade -y
     
RUN  apt install -y curl git

RUN  sh -c "$(curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh)"

RUN  apt install -y curl git

ENV PATH="/root/.local/share/ponyup/bin:/root/.local/share/ponyup/pony-stable/bin:${PATH}"

RUN echo PATH

RUN  ponyup update ponyc release
     
RUN  git clone https://github.com/alexanderwebber/AgentPony

WORKDIR /AgentPony

RUN ponyc

CMD ["./AgentPony"]