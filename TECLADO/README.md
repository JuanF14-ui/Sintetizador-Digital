# Teclado-Electronica digital 1
# Introducción

La evolución de los instrumentos musicales, desde los primeros arreglos puramente analógicos hasta las implementaciones digitales actuales, ha estado marcada por la búsqueda de precisión tonal y reproducibilidad. En los sistemas analógicos, mapear cada nota (frecuencia) implica tolerancias, inestabilidad y ajustes finos que vuelven el proceso laborioso. Con la lógica digital y los FPGAs, este reto se simplifica: es posible representar y generar sonidos a partir de valores discretos, controlados y reproducibles.

En este proyecto se implementa un “teclado” musical digital sobre una FPGA BlackIce iCE40. Cuatro botones físicos actúan como disparadores de notas predefinidas, mientras un periférico dedicado (perip_keyboard_pwm) calcula y entrega una señal PWM con la frecuencia correspondiente. Esta señal puede excitar un buzzer (sonido) o un LED (indicador visual), emulando el comportamiento de un instrumento real pero con la flexibilidad, modularidad y exactitud propias del dominio digital.

Además, la arquitectura del SoC permite extender la interacción hacia el exterior (por ejemplo, publicando eventos vía UART/MQTT para sintetizar audio en ChucK), construyendo así un entorno colaborativo y escalable, ideal para experimentación sonora y educativa.

# Funcion
El módulo está diseñado para leer cuatro botones físicos conectados a la FPGA (BlackIce iCE40) y, a partir de su estado, generar una señal PWM (Pulse Width Modulation) cuya frecuencia corresponde a la nota asociada a cada botón. Cuando ninguno está presionado, la salida permanece en silencio (PWM desactivado). Al detectarse una pulsación, el periférico `perip_keyboard_pwm` selecciona la nota según una prioridad predefinida (DO > RE > MI > FA) o, si el SoC lo indica, aplica una frecuencia forzada desde registro. La señal PWM resultante puede dirigirse a un buzzer para producir sonido o a un LED como indicador visual del tono, permitiendo construir un teclado musical digital básico con retroalimentación audible o luminosa.


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
# Máquinas de estado

## Máquina de estado: `keyboard_pwm` / `perip_keyboard_pwm`

| Estado | Condición de entrada                          | Acciones / salidas                                                                 | Próximo estado                                                         |
|--------|-----------------------------------------------|------------------------------------------------------------------------------------|------------------------------------------------------------------------|
| IDLE   | `btn == 0` **y/o** `note_freq_from_soc == 0`  | `final_pwm_freq = 0`  &nbsp;•&nbsp; `PWM = 0`                                      | `PLAY` si `btn != 0` **o** `note_freq_from_soc != 0`                   |
| PLAY   | `btn != 0` **o** `note_freq_from_soc != 0`    | Calcula prioridad **DO > RE > MI > FA**. <br>`final_pwm_freq = (note_freq_from_soc != 0) ? soc : buttons` | `IDLE` si todo vuelve a 0. <br>Si cambia cualquier botón, permanece en `PLAY` y recalcula |

> **Notas:**
> - `btn` es un vector de 4 bits (Do, Re, Mi, Fa).  
> - `note_freq_from_soc` permite forzar la frecuencia desde el SoC (override).  
> - En `PLAY`, ante cualquier cambio de botones o del override, se recalcula la frecuencia sin salir del estado.

## Máquina de estado: `led_pwm` (generador PWM 50%)

| Estado    | Condición                         | Acción                              | Siguiente estado                                      |
|-----------|-----------------------------------|--------------------------------------|-------------------------------------------------------|
| WAIT_CFG  | `freq == 0`                       | `pwm = 0`, `counter = 0`             | `WAIT_CFG` (si `freq == 0`) <br>`HIGH` (si `freq != 0`) |
| HIGH      | `counter < freq`                  | `pwm = 1`, `counter++`               | `LOW` cuando `counter == freq`                        |
| LOW       | `counter < 2*freq`                | `pwm = 0`, `counter++`               | `HIGH` cuando `counter == 2*freq - 1` y `counter = 0` |

> **Notas:**
> - `freq` define la semiperiodo (la otra mitad es `2*freq - 1`).  
> - Se obtiene un **duty cycle ≈ 50%**: tiempo en HIGH ≈ tiempo en LOW.  
> - Si `freq` cambia a 0 en cualquier momento, se vuelve a `WAIT_CFG`, apagando el PWM.


## Máquina de estado: `perip_contador` (conteo de flancos)

| Estado     | Condición                | Acción                       | Next        |
|------------|--------------------------|------------------------------|-------------|
| WAIT_EDGE  | *default*                | `key_prev <= key_state`      | `INC` si hay flanco ↑ |
| INC        | Flanco de subida detectado | `count++`                    | `WAIT_EDGE` |

> **Notas:**
> - Puede implementarse con un solo estado global y lógica de detección de flanco (`rising = key_state & ~key_prev`).  
> - `key_prev` se actualiza cada ciclo para comparar con `key_state`.




## Diagrama ASM

![Diagrama ASM del módulo PWM_AUDIO](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/7afd143a660e506a7a00f404d333cb289c0e7ce1/TECLADO/DIAGRAMA%20ASM.png)

El sistema comienza en un estado de inicialización con frecuencia cero y reset en alto. Luego verifica continuamente el estado de los botones físicos. Cuando uno está presionado, se asigna una nueva frecuencia.

---


## Diagramas RTL

A continuación se presentan los diagramas RTL (Register Transfer Level) generados para distintos módulos del sistema. Estos esquemas muestran la estructura interna sintetizada de cada componente, permitiendo entender cómo se traduce el diseño de alto nivel en lógica estructural, y cómo se interconectan los elementos básicos como registros, multiplexores, contadores, comparadores y lógica secuencial.

Los diagramas se obtuvieron tras la síntesis del código Verilog, y son útiles para verificar:
- Jerarquía correcta del diseño
- Uso y optimización de recursos
- Conexiones entre señales internas y periféricos
- Integración de cada módulo dentro del SoC

### Diagrama RTL del SoC

Este diagrama muestra la estructura general del sistema integrado, incluyendo el procesador, la memoria, los módulos periféricos (`keyboard_pwm`, `led_pwm`, `perip_contador`, etc.) y el sistema de interconexión (bus). Es útil para visualizar cómo se comunican los distintos bloques a través del bus, cómo se manejan las señales de control y datos, y cómo se implementa el decodificador de direcciones (`chip_select`).


![RTL SoC](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/c9b0b9e960c6adfaceaaf1664454107d37ef90d4/TECLADO/DIAGRAMA%20SOC.jpg)

---

### Diagrama RTL del Módulo Teclado (`keyboard_pwm`)

Este módulo detecta el estado de los botones físicos conectados al sistema, prioriza las entradas activas y selecciona la frecuencia PWM correspondiente a la nota musical. El diagrama muestra la lógica de sincronización de botones (doble flip-flop), los multiplexores para la selección de frecuencia, y la generación de la señal PWM con ciclo útil fijo. También incluye lógica adicional para permitir que el procesador fuerce una frecuencia personalizada desde el bus.

![RTL Teclado](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/c9b0b9e960c6adfaceaaf1664454107d37ef90d4/TECLADO/DIAGRAMA%20TECLADO.jpg)

---

### Diagrama RTL del Módulo LED PWM

Este componente genera una señal PWM con periodo configurable por el procesador. Se usa para controlar un LED (interno o externo) que puede visualizar el efecto del PWM. El RTL muestra cómo se implementa el generador de PWM, con contadores internos que comparan el valor del registro configurado con el reloj del sistema. Si la frecuencia se configura como cero, el módulo apaga la salida del LED.

![RTL LED](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/c9b0b9e960c6adfaceaaf1664454107d37ef90d4/TECLADO/DIAGRAMA%20LED.jpg)

### Diagrama RTL del Módulo Contador (`perip_contador`)

Este módulo cuenta cuántas veces se presiona cada uno de los cuatro botones (flancos de subida). Está compuesto por contadores independientes para cada entrada, lógica de flanco, y registros de salida que permiten al procesador leer los valores acumulados. El RTL permite visualizar claramente cada camino de datos y cómo se sincronizan las entradas con el reloj del sistema.

![RTL Contador](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/c9b0b9e960c6adfaceaaf1664454107d37ef90d4/TECLADO/DIAGRAMA%20CONTADOR.jpg)

---

Los diagramas permiten verificar la estructura sintetizada, el uso de recursos y la correcta jerarquía en el diseño de cada componente del sistema.


# Explicación sobre cómo interactúa con aplicaciones externas (mqtt, chuck) etc.

## Captura de la nota en la FPGA
1. Presionas un botón en el teclado físico.  
2. El periférico `perip_keyboard_pwm` detecta la tecla, el SoC calcula la frecuencia y genera el PWM para el buzzer.  
3. El firmware del CPU lee ese evento (qué nota y si es ON/OFF).

## Envío del evento por UART
4. El firmware empaqueta el evento (por ejemplo: “nota 0 ON”) y lo manda por la UART del SoC.  
5. La línea TXD de la FPGA va al RX del ESP32.

## ESP32 como puente serie → WiFi/MQTT
6. El ESP32 recibe cada evento por UART.  
7. Conectado a la red WiFi, publica ese evento en un tópico MQTT acordado (ej. `orquesta/nota`).  
8. Cada FPGA/teclado puede usar su propio tópico o un campo “id” para distinguirse.

## Broker MQTT (PC del profesor o servidor local)
9. El broker recibe los mensajes de todos los ESP32.  
10. Los pone a disposición de cualquier cliente suscrito (en este caso, el PC con ChucK).

## PC del profesor escucha los eventos
11. En el PC, un proceso (puede ser un script intermedio o una herramienta) se suscribe al tópico MQTT.  
12. Cada mensaje recibido (nota ON/OFF) se traduce a un evento que ChucK pueda entender (por ejemplo, vía OSC o entrada estándar).

## ChucK interpreta y reproduce
13. ChucK recibe el evento de “nota ON/OFF” con su identificador.  
14. Asigna un instrumento/sonido a cada “id” del alumno o a cada nota.  
15. Genera el audio en tiempo real, creando la “orquesta” virtual con todos los teclados.
EOF
	@echo "Archivo generado en docs/explicacion_ext.md"
