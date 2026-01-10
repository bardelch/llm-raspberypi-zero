# =============================================================================
# Stage 1: Builder (heavy dependencies & compilation)
# Use a compatible 32-bit ARM base - raspbian/bullseye is one of few that works
# =============================================================================
FROM arm32v7/debian:bullseye-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    ca-certificates \
    wget \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Clone optimized llama.zero fork (ARMv6 friendly)
RUN git clone https://github.com/pham-tuan-binh/llama.zero.git \
    && cd llama.zero \
    && make clean \
    && make -j1 GGML_NO_NEON=1 GGML_NO_LLAMAFILE=1  # very important: no neon!

# Download small coding model (Gemma-2-2B Q2_K ~800MB)
RUN mkdir -p /models \
    && wget -q --show-progress \
       https://huggingface.co/second-state/Gemma-2-2B-It-GGUF/resolve/main/Gemma-2-2B-It-Q2_K.gguf \
       -O /models/gemma-2-2b-it-q2_k.gguf

# Prepare python environment
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
       smolagents[toolkit] \
       huggingface_hub  # just in case you want more models later

# Copy your agent script (create this file in the same folder as Dockerfile)
COPY agent.py /app/agent.py

# =============================================================================
# Stage 2: Final runtime image - as small as reasonably possible
# =============================================================================
FROM arm32v7/debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PATH="/venv/bin:$PATH"

# Runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    libgomp1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean autoclean \
    && rm -rf /var/lib/{apt,dpkg,cache,log}

WORKDIR /app

# Copy compiled binary + model + python environment + script
COPY --from=builder /build/llama.zero/main          /app/llama-main
COPY --from=builder /models/gemma-2-2b-it-q2_k.gguf  /app/models/
COPY --from=builder /venv                            /venv
COPY agent.py                                        /app/agent.py

# Optional: make binary executable & reduce size a bit
RUN chmod +x /app/llama-main

# You can use different CMD / ENTRYPOINT styles:
# 1. Run interactive python shell
# CMD ["python3"]

# 2. Run your agent script directly
CMD ["python3", "agent.py"]

# 3. Or run llama.cpp server (recommended for agent integration)
# EXPOSE 8080
# CMD ["/app/llama-main", "--server", "--model", "/app/models/gemma-2-2b-it-q2_k.gguf", "--host", "0.0.0.0", "--port", "8080"]

