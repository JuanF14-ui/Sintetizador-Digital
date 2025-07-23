import time
import network
from machine import Pin, ADC, UART
from client import Client

# NETWORK
SSID = "Redmi Note 13"
PASSWORD = "123456789"
# MQTT DEFINITIONS
OSC_SERVER = "192.168.112.203"
OSC_PORT = 9001
CLIENT_ID = "/dev2"
TOPIC_FLUTE = CLIENT_ID + "/flauta"
# PERIPHERALS DEFINITIONS ESP32C3 mini see PinOUT
LED_PIN = 8
BUTTON_PIN = 9
ADC_PIN = 0
ADC_MAX = 4095.0  # 1023.0, 4095.0, etc
TX_PIN = 20
RX_PIN = 21
BAUDRATE = 57600  # 9600 57600 115200
DELAY = 0.1

# Make objects for peripherals
led = Pin(LED_PIN, Pin.OUT)
adc = ADC(ADC_PIN)
user_button = Pin(BUTTON_PIN, Pin.IN, Pin.PULL_UP)
uart_fpga = UART(1, baudrate=BAUDRATE, tx=TX_PIN, rx=RX_PIN)


def connectSTA(ssid, pwd):
    sta_if = network.WLAN(network.STA_IF)
    if not sta_if.isconnected():
        print("connecting to network...")
        sta_if.active(True)
        sta_if.connect(ssid, pwd)
        while not sta_if.isconnected():
            pass
    print("network config:", sta_if.ifconfig())


def get_osc_format(array):
    if array[0] == "i":  # si formato integer
        try:
            return int(array[1])
        except ValueError:
            return ""
    elif array[0] == "f":  # si formato flotante
        try:
            return float(array[1])
        except ValueError:
            return ""
    else:  # "s" es string
        return array[1]


def midi_adc():
    adc_value = adc.read()
    print(adc_value)
    return int(adc_value / ADC_MAX * 128)


# Función principal
def main():
    # 1. Conectarse a una RED WIFI
    connectSTA(SSID, PASSWORD)
    # 2. Configurar el cliente OSC
    osc_client = Client(OSC_SERVER, OSC_PORT)
    print("Configurando cliente OSC")

    while True:
        print("waiting")
        # 4. Verificar si se ha pulsado el botón
        if user_button.value() == 0:
            osc_client.send(TOPIC_FLUTE, midi_adc())
        # 5. Verificar si se ha recibido datos por UART
        if uart_fpga.any():
            # buffer = uart_fpga.read().decode("utf-8")  # Para leer cualquier valor
            buffer = uart_fpga.readline().decode("utf-8")[
                :-2
            ]  # Leer la linea y borrar los últimos dos caracteres \n\r
            #               0       1       2       3           4           5 ...
            # decoder = ["osc", "topic", "format", "value1", "format", "value2", ... ]
            decoder = buffer.split(" ")
            print(decoder)
            if decoder[0] == "osc":
                size = len(decoder)
                if size == 4:  # topic más un valor con formato
                    osc_client.send(decoder[1], get_osc_format(decoder[2:4]))
                if size == 6:  # topic más dos valores con formato
                    osc_client.send(
                        decoder[1],
                        get_osc_format(decoder[2:4]),
                        get_osc_format(decoder[4:6]),
                    )
                if size == 8:  # topic más tres valores con formato
                    osc_client.send(
                        decoder[1],
                        get_osc_format(decoder[2:4]),
                        get_osc_format(decoder[4:6]),
                        get_osc_format(decoder[6:8]),
                    )
                if size == 10:  # topic más cuatro valores con formato
                    osc_client.send(
                        decoder[1],
                        get_osc_format(decoder[2:4]),
                        get_osc_format(decoder[4:6]),
                        get_osc_format(decoder[6:8]),
                        get_osc_format(decoder[8:10]),
                    )
        # 6. Esperar un tiempo antes de hacer el loop
        time.sleep(DELAY)


if __name__ == "__main__":
    main()
