    import os
    import time
    import random
    import json
    import paho.mqtt.client as mqtt
    from datetime import datetime

    MQTT_BROKER = os.getenv('MQTT_BROKER', 'mosquitto')
    MQTT_PORT = int(os.getenv('MQTT_PORT', 1883))
    MQTT_USER = os.getenv('MQTT_USER', 'sensor_user')
    MQTT_PASS = os.getenv('MQTT_PASS', '')
    SENSOR_ID = os.getenv('SENSOR_ID', 'temp_sensor_01')

    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print(f'[{SENSOR_ID}] Conectado ao broker!')
        else:
            print(f'[{SENSOR_ID}] Falha na conexao: {rc}')

    def on_publish(client, userdata, mid):
        pass

    client = mqtt.Client(client_id=SENSOR_ID)
    client.username_pw_set(MQTT_USER, MQTT_PASS)
    client.on_connect = on_connect
    client.on_publish = on_publish

    try:
        print(f'[{SENSOR_ID}] Conectando a {MQTT_BROKER}:{MQTT_PORT}...')
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        
        while True:
            temp = round(random.uniform(20.0, 30.0), 2)
            payload = {
                'sensor_id': SENSOR_ID,
                'timestamp': datetime.now().isoformat(),
                'temperature': temp,
                'unit': 'celsius'
            }
            
            topic = f'factory/sensors/{SENSOR_ID}/telemetry'
            client.publish(topic, json.dumps(payload), qos=1)
            print(f'[{SENSOR_ID}] Temp: {temp}C')
            
            time.sleep(5)
            
    except KeyboardInterrupt:
        print(f'\n[{SENSOR_ID}] Encerrando...')
        client.loop_stop()
        client.disconnect()