import os, time, random, json, ssl
import paho.mqtt.client as mqtt
from datetime import datetime

MQTT_BROKER = os.getenv('MQTT_BROKER', 'mosquitto')
MQTT_PORT = int(os.getenv('MQTT_PORT', 8883))
MQTT_USER = os.getenv('MQTT_USER', 'sensor_user')
MQTT_PASS = os.getenv('MQTT_PASS', '')
SENSOR_ID = os.getenv('SENSOR_ID', 'temp_sensor_01')
USE_TLS = os.getenv('MQTT_USE_TLS', 'true').lower() == 'true'

def on_connect(client, userdata, flags, rc):
    print(f'[{SENSOR_ID}] {"Conectado!" if rc == 0 else f"Erro: {rc}"}')

client = mqtt.Client(client_id=SENSOR_ID, protocol=mqtt.MQTTv311)
client.username_pw_set(MQTT_USER, MQTT_PASS)
client.on_connect = on_connect

if USE_TLS:
    client.tls_set(cert_reqs=ssl.CERT_NONE)
    client.tls_insecure_set(True)

try:
    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    client.loop_start()
    
    while True:
        temp = round(random.uniform(18.0, 32.0), 2)
        payload = {'sensor_id': SENSOR_ID, 'timestamp': datetime.now().isoformat(), 'temperature': temp, 'unit': 'celsius'}
        client.publish(f'factory/sensors/{SENSOR_ID}/telemetry', json.dumps(payload), qos=1)
        print(f'[{SENSOR_ID}] Temp: {temp}C')
        time.sleep(5)
except KeyboardInterrupt:
    client.loop_stop()
    client.disconnect()
