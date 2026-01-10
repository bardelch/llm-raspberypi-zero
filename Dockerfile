# =============================================================================
# Stage 1: Builder - compile llama.zero + install deps + download model
# =============================================================================
FROM arm32v6/alpine:3.21 AS builder

# Set non-interactive mode for apk
ENV ALPINE_NO_INTERACTIVE=true

# Install build dependencies (git, make, gcc, etc.) + wget/curl for downloads
RUN apk add --no-cache \
    git \
    build-base \
    cmake \
    linux-headers \
    wget \
    ca-certificates \
    python3 \
    py3-pip \
    py3-virtualenv \
    && update-ca-certificates

WORKDIR /build

# Clone optimized llama.zero fork (ARMv6 friendly - no NEON/SIMD)
RUN git clone https://github.com/pham-tuan-binh/llama.zero.git \
    && cd llama.zero \
    && echo "===== STARTING LLAMA.ZERO COMPILATION (expect 2-6+ hours on Pi Zero) =====" \
    && cmake -B build
    && cmake --build build --config Release
    && echo "===== Compilation finished! ====="

# Download small coding model (~800 MB quantized GGUF)
RUN mkdir -p /models \
    && wget -q --show-progress \
       https://huggingface.co/second-state/Gemma-2-2B-It-GGUF/resolve/main/Gemma-2-2B-It-Q2_K.gguf \
       -O /models/gemma-2-2b-it-q2_k.gguf

# Prepare minimal Python venv for smolagents
RUN python3 -m venv /venv \
    && /venv/bin/pip install --no-cache-dir --upgrade pip \
    && /venv/bin/pip install --no-cache-dir \
       smolagents[toolkit] \
       # Add any other tiny deps if needed; avoid heavy ones

# Copy your agent script (place this file next to Dockerfile)
COPY agent.py /app/agent.py

# =============================================================================
# Stage 2: Final ultra-light runtime image
# =============================================================================
FROM arm32v6/alpine:3.21

# Minimal runtime deps: python runtime + shared libs for llama.cpp
RUN apk add --no-cache \
    python3 \
    py3-pip \
    libstdc++ \
    ca-certificates \
    && rm -rf /var/cache/apk/* \
    && update-ca-certificates

ENV PYTHONUNBUFFERED=1 \
    PATH="/venv/bin:$PATH"

WORKDIR /app

# Copy only what's needed from builder
COPY --from=builder /build/llama.zero/main          /app/llama-main
COPY --from=builder /models/gemma-2-2b-it-q2_k.gguf  /app/models/gemma-2-2b-it-q2_k.gguf
COPY --from=builder /venv                            /venv
COPY agent.py                                        /app/agent.py

# Make binary executable
RUN chmod +x /app/llama-main

# Optional: tiny healthcheck or just run the agent
# HEALTHCHECK --interval=30s CMD ["python3", "-c", "print('alive')"] || exit 1

# Default: run your agent script
CMD ["python3", "/app/agent.py"]

# Alternative: run llama.cpp in server mode (OpenAI-compatible API)
# CMD ["/app/llama-main", "--server", "--model", "/app/models/gemma-2-2b-it-q2_k.gguf", "--host", "0.0.0.0", "--port", "8080"]
# EXPOSE 8080


