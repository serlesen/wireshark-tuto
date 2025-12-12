FROM kalilinux/kali-rolling

WORKDIR /app

COPY . /app/w4sp-lab

RUN apt-get update && \
    apt-get install -y sudo vim python3 python3-all python3-pip python3-netifaces python3-flask python3-docker

RUN groupadd -f wireshark && \
    useradd -m w4sp-lab -s /bin/bash -G sudo,wireshark -U && \
    echo "w4sp-lab:w4sp-lab" | chpasswd

# usermod -aG sudo w4sp-lab
# su - w4sp-lab

#CMD python3 /app/w4sp-lab/w4sp_webapp.py && echo "hello"
