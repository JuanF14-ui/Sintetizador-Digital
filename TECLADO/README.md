# Módulo PWM_AUDIO

Este módulo tiene como propósito principal la detección de teclas presionadas en un conjunto de cuatro botones físicos conectados a una FPGA (BlackIce iCE40) y la generación de una señal PWM (Pulse Width Modulation) con una frecuencia correspondiente a la tecla presionada. Esta señal PWM puede usarse para activar un buzzer o un LED (como reemplazo visual del sonido), permitiendo construir un sistema básico de teclado musical digital.

---

## Requerimientos Funcionales

### Funcionalidad Global

- Generar audio PWM con 4 notas musicales fijas: **Do**, **Re**, **Mi** y **Fa**, cada una activada por un botón físico independiente.
- Garantizar **silencio total** cuando no se presiona ningún botón.
- Aplicar una **prioridad fija** al detectar múltiples teclas presionadas al mismo tiempo:  
  `Do > Re > Mi > Fa`.
- Implementar un **contador independiente por nota**, que registre cuántas veces ha sido presionada cada tecla. Los valores deben estar accesibles vía bus para ser leídos por la CPU.
- Controlar un **LED mediante un PWM separado**, independiente del PWM de audio.
- (Opcional) Habilitar **comunicación UART** para fines de depuración o telemetría.
- Usar un **único reloj de 25 MHz** para todo el sistema. Todas las frecuencias derivadas (PWM, UART, etc.) deben generarse a partir de este clock.
- (Opcional) Incorporar un **firmware mínimo** que permita acceder a los registros de los periféricos (lectura y escritura).

### Por Módulo

#### `keyboard_pwm`
- Detectar el estado de los 4 botones conectados (activos en **alto**) y sincronizarlos usando doble flip-flop.
- Seleccionar el divisor de frecuencia correcto para cada nota musical (usando un parámetro `CLK_HZ`).
- Priorizar automáticamente las notas cuando varias teclas están presionadas.
- Permitir al CPU forzar una frecuencia específica (si el registro de escritura es distinto de 0).
- Generar una señal PWM con 50% de ciclo útil hacia la salida `PWM_AUDIO_OUT`.
- Exponer el estado actual de los botones a través del bus (`d_out`).

#### `led_pwm`
- Generar una señal PWM con 50% de duty cycle y periodo configurable desde el bus.
- Si el valor de frecuencia configurado es `0`, apagar completamente la salida (LED OFF).
- Accesible vía bus en la región de memoria `0x0041_0000...`.

#### `perip_contador`
- Contar flancos de subida (transición de `0 → 1`) en cada uno de los 4 botones.
- Proveer acceso a los contadores desde el bus, mediante 4 registros independientes.
- Reiniciar los contadores al recibir la señal de reset global.

#### `chip_select`
- Decodificar direcciones de memoria para activar (chip select) el periférico correspondiente.
- Multiplexar la salida `mem_rdata` según el periférico activo.

#### `memory`
- Gestionar operaciones de lectura y escritura del CPU en la región RAM.
- Permitir la inicialización del contenido con un archivo `firmware.hex` durante simulación (si aplica).

#### `peripheral_uart`
- Implementar transmisión y recepción UART a **57 600 baudios** con base en un reloj de 25 MHz.
- (Opcional) Redirigir caracteres UART a la simulación mediante `$write`.

#### `peripheral_mult`
- Proveer un módulo simple de multiplicación por hardware, con registros de entrada/salida para interactuar desde el CPU.

---

## 🔁 Diagrama ASM

![Diagrama ASM del módulo PWM_AUDIO](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/b5a2995438b3b82fcb4e63dbe2cd7be1b3461952/TECLADO/DIAGRAMA%20ASM.png)

El sistema comienza en un estado de inicialización con frecuencia cero y reset en alto. Luego verifica continuamente el estado de los botones físicos. Cuando uno está presionado, se asigna una nueva frecuencia.

---

## 🏗️ Diagrama RTL

Puedes generar el diagrama con:

```bash
make rtl top=pwm_audio
