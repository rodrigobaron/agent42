FROM nvidia/cuda:10.1-base-ubuntu18.04

ENV DEBIAN_FRONTEND=noninteractive

# Install some basic utilities
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    ca-certificates \
    sudo \
    git \
    bzip2 \
    libx11-6 \
    wget \
    tar \
    build-essential \
    apt-utils \
    cmake \
    g++ \
    openssh-client \
    openssh-server \
    qt5-default \
    openssl \
    libboost-dev \
    libboost-thread-dev \
    libboost-filesystem-dev \
    libopenmpi-dev \
    openmpi-bin \
    openmpi-doc \
    libglib2.0-0 \
    libglew2.0 \
    libglfw3 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libxrender1 \
    libgl1-mesa-dev \
    libgl1-mesa-glx \
    libglew-dev \
    libosmesa6-dev \
    libevent-dev \
    locales \
    net-tools \
    qt5-default \
    xpra \
    xserver-xorg-dev \
    tzdata \
    patchelf \
 && rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/patchelf https://s3-us-west-2.amazonaws.com/openai-sci-artifacts/manual-builds/patchelf_0.9_amd64.elf \
    && chmod +x /usr/local/bin/patchelf

# Create a working directory
RUN mkdir /app
WORKDIR /app
ADD . /app


# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
 && chown -R user:user /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory
ENV HOME=/home/user
RUN chmod 777 /home/user

# Install Miniconda and Python 3.7
ENV CONDA_AUTO_UPDATE_CONDA=false
ENV PATH=/home/user/miniconda/bin:$PATH
RUN curl -sLo ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-4.7.12.1-Linux-x86_64.sh \
 && chmod +x ~/miniconda.sh \
 && ~/miniconda.sh -b -p ~/miniconda \
 && rm ~/miniconda.sh \
 && conda install -y python==3.7.0 \
 && conda clean -ya

# CUDA 10.1-specific steps
RUN conda install -y -c pytorch \
    cudatoolkit=10.1 \
    "pytorch=1.4.0=py3.7_cuda10.1.243_cudnn7.6.3_0" \
    "torchvision=0.5.0=py37_cu101" \
 && conda clean -ya

# RUN cd /home/user && \
#     wget -c https://mujoco.org/download/mujoco210-linux-x86_64.tar.gz && \
#     tar -vzxf mujoco210-linux-x86_64.tar.gz && \
#     mkdir -p .mujoco && \
#     mv mujoco210 .mujoco/mujoco210 && \
#     rm -rf mujoco210-linux-x86_64.tar.gz 

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/user/.mujoco/mujoco210/bin

ENV LANG C.UTF-8

RUN mkdir -p /home/user/.mujoco \
    && wget https://mujoco.org/download/mujoco210-linux-x86_64.tar.gz -O mujoco.tar.gz \
    && tar -xf mujoco.tar.gz -C /home/user/.mujoco \
    && rm mujoco.tar.gz

# ENV LD_LIBRARY_PATH /root/.mujoco/mujoco210/bin:${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib64:${LD_LIBRARY_PATH}

RUN python3 -m pip install -r requirements.txt 

# Set the default command to python3
CMD ["python3"]
