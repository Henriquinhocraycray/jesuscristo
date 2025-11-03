FROM python:3.11-slim
WORKDIR /app
RUN pip install paho-mqtt
COPY sensor.py .
CMD ["python", "-u", "sensor.py"]
