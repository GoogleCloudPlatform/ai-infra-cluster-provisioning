FROM nvcr.io/nvidia/pytorch:23.09-py3

WORKDIR /workspace/

ADD pingpong.py .
ADD start_ping_pong.sh .

ENTRYPOINT ["bash", "start_pingpong.sh"]