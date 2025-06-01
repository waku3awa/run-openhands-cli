# FROM python:3
FROM docker.all-hands.dev/all-hands-ai/runtime:0.39-nikolaik
RUN apt-get update \
    && apt-get install -y \
    x11-utils \
 && apt-get autoremove -y \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*
 ENV DISPLAY=:0