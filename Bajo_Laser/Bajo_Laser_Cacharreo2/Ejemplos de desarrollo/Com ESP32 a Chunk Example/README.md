<!-- LTeX: enabled=true language=es -->
<!-- :set spell! -->
<!-- :MarkdownPreview -->
<!-- :GenTocMarked -->

# Red de dispositivos que se conectan a un servicio de ChucK a través del protocolo OSC

Para ejecutar este ejemplo, siga estos pasos:

1. Instalación de micropython y los scripts en el esp32, estos pasos los puede encontrar en [./micropython-osc/](./micropython-osc/).

2. Lanzar el servicio de ChucK como se explica en [./chuck/](./chuck/), seguido,
puede oprimir el botón de usuario en el ESP32 (BOOT/USER), esto hará que se envíen datos al servicio
de chuck y pueden ser observados en la terminal de ChucK.

3. Envíe datos por el puerto UART que fue configurado desde micropython; puede enviar datos desde una FPGA, como se indica en [este ejemplo](https://github.com/johnnycubides/digital-electronic-1-101/tree/main/fpga-example/colorlight-5a-75e/femtoriscv), específicando el programa escrito en [osc-esp32-example.c](https://github.com/johnnycubides/digital-electronic-1-101/blob/main/fpga-example/colorlight-5a-75e/femtoriscv/firmware/c-code/osc-esp32-example.c).


2025-07-11

Johnny
