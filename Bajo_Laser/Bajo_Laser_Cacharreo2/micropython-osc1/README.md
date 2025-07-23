<!-- LTeX: enabled=true language=es -->
<!-- :set spell! -->
<!-- :MarkdownPreview -->
<!-- :GenTocMarked -->

# Preparación del esp32 para la prueba de funcionamiento

Para poder realizar este proceso deberá instalar micropython en el esp32 y luego guardar los scripts de Python que permiten la comunicación OSC desde el ESP32 con chuck.

## Identificación del puerto serial

Tiene diferentes mecanismos para realizar esta operación, por ejemplo:

* Conecte el esp32 al puerto usb y ejecute el comando:
```bash
ls /dev/tty*
```
Del resultado, busque en la lista el nombre del archivo que representa el ESP32, el cual puede tener
la secuencia `/dev/ttyUSBx` o `/dev/ttyACMx` donde **x** es el número del puerto.

> El nombre del puerto debe ser **sustituido** en los siguientes comandos para que pueda realizar las
> tareas satisfactoriamente.

## Instalación de micropython en esp32

Hay diferentes versiones del esp32, en este ejemplo, se muestra como realizar
esta tarea en dos versiones diferentes, seleccione la suya según el esp32
corresponda. En el caso de tener otra versión o probar otras imágenes
actualizadas, visite [la página oficial de descargas de
micropython](https://micropython.org/download/?port=esp32).

* Ejemplo de instalación de Micropython en esp32-wroom-32X

```bash
make erase
make flash-mpy i=../upy-images/ESP32_GENERIC-20250415-v1.25.0.bin p=/dev/ttyUSB0
```

* Ejemplo de instalación de Micropython en esp32-c3

```bash
make erase
make flash-mpy i=../upy-images/ESP32_GENERIC_C3-20250415-v1.25.0.bin p=/dev/ttyACM0
```

## Instalación de scripts para la comunicación OSC con Chuck

Deberá modificar el archivo [./dev1.py](./dev1.py) para que el ejemplo pueda funcionar.

1. En primer lugar debe saber la **IP** donde se está ejecutando el servicio de chuck,
para ello puede ejecutar el comando `ip a` en la máquina que contiene el servicio de chuck, ejemplo:

```bash
ip a
```
Resultado:
```bash
2: wlp0s20f3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 18:cc:1c:e0:0c:f9 brd ff:ff:ff:ff:ff:ff
    altname wlx18cc18e00cf9
    inet 192.168.2.100/24 brd 192.168.2.255 scope global dynamic noprefixroute wlp0s20f3
       valid_lft 80869sec preferred_lft 80869sec
    inet6 fe80::3cdd:7d4:4450:27c6/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

> En el ejemplo, la IP de la máquina que tiene el servicio de Chuck tiene el valor de **192.168.2.100**

Ese valor deberá ser puesto en la variable `OSC_SERVER` del archivo `./dev1.py`, ejemplo:

```py
# OSC DEFINITIONS
OSC_SERVER = "192.168.2.100"
OSC_PORT = 9001
CLIENT_ID = "/dev1"
TOPIC_FLUTE = CLIENT_ID + "/flauta"
```

2. Modifique los valores relacionados a SSID y PASSWORD en el archivo `./dev1.py` los cuales
están relacionados a la conexión WiFi del esp32 como estación.

```py
# NETWORK
SSID = "luna"
PASSWORD = "loderunner"
```

3. Instale los scripts de Micropython para el ejemplo:

```bash
make put f=common.py p=/dev/ttyUSB0 # Subir dependencia
make put f=client.py p=/dev/ttyUSB0 # Subir dependencia
make putAsMain f=dev1.py p=/dev/ttyUSB0 # Subir script como main.py
```

4. Oprima el botón de **reset** del esp32 y ejecute el siguiente comando para depurar los resultados:

```bash
make t p=/dev/ttyUSB0
```
> Para salir de picocom que conecta a Micropython, ejecute la secuencia **CTRL+a** y luego **CTRL+x**.

5. Si envía datos por UART a través de los pines indicados en `./dev1.py`
   (TX_PIN y RX_PIN) o si oprime el botón de BOOT/USER el esp32 enviará datos al
servicio de Chuck.
