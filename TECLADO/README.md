# Teclado-Electronica digital 1
##Introducción

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
## Máquinas de estado

### Máquina de estado: `keyboard_pwm` / `perip_keyboard_pwm`

| Estado | Condición de entrada                          | Acciones / salidas                                                                 | Próximo estado                                                         |
|--------|-----------------------------------------------|------------------------------------------------------------------------------------|------------------------------------------------------------------------|
| IDLE   | `btn == 0` **y/o** `note_freq_from_soc == 0`  | `final_pwm_freq = 0`  &nbsp;•&nbsp; `PWM = 0`                                      | `PLAY` si `btn != 0` **o** `note_freq_from_soc != 0`                   |
| PLAY   | `btn != 0` **o** `note_freq_from_soc != 0`    | Calcula prioridad **DO > RE > MI > FA**. <br>`final_pwm_freq = (note_freq_from_soc != 0) ? soc : buttons` | `IDLE` si todo vuelve a 0. <br>Si cambia cualquier botón, permanece en `PLAY` y recalcula |

> **Notas:**
> - `btn` es un vector de 4 bits (Do, Re, Mi, Fa).  
> - `note_freq_from_soc` permite forzar la frecuencia desde el SoC (override).  
> - En `PLAY`, ante cualquier cambio de botones o del override, se recalcula la frecuencia sin salir del estado.

### Máquina de estado: `led_pwm` (generador PWM 50%)

| Estado    | Condición                         | Acción                              | Siguiente estado                                      |
|-----------|-----------------------------------|--------------------------------------|-------------------------------------------------------|
| WAIT_CFG  | `freq == 0`                       | `pwm = 0`, `counter = 0`             | `WAIT_CFG` (si `freq == 0`) <br>`HIGH` (si `freq != 0`) |
| HIGH      | `counter < freq`                  | `pwm = 1`, `counter++`               | `LOW` cuando `counter == freq`                        |
| LOW       | `counter < 2*freq`                | `pwm = 0`, `counter++`               | `HIGH` cuando `counter == 2*freq - 1` y `counter = 0` |

> **Notas:**
> - `freq` define la semiperiodo (la otra mitad es `2*freq - 1`).  
> - Se obtiene un **duty cycle ≈ 50%**: tiempo en HIGH ≈ tiempo en LOW.  
> - Si `freq` cambia a 0 en cualquier momento, se vuelve a `WAIT_CFG`, apagando el PWM.


### Máquina de estado: `perip_contador` (conteo de flancos)

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


## Explicación sobre cómo interactúa con aplicaciones externas (mqtt, chuck) etc.

### Captura de la nota en la FPGA
1. Presionas un botón en el teclado físico.  
2. El periférico `perip_keyboard_pwm` detecta la tecla, el SoC calcula la frecuencia y genera el PWM para el buzzer.  
3. El firmware del CPU lee ese evento (qué nota y si es ON/OFF).

### Envío del evento por UART
4. El firmware empaqueta el evento (por ejemplo: “nota 0 ON”) y lo manda por la UART del SoC.  
5. La línea TXD de la FPGA va al RX del ESP32.

### ESP32 como puente serie → WiFi/MQTT
6. El ESP32 recibe cada evento por UART.  
7. Conectado a la red WiFi, publica ese evento en un tópico MQTT acordado (ej. `orquesta/nota`).  
8. Cada FPGA/teclado puede usar su propio tópico o un campo “id” para distinguirse.

### Broker MQTT (PC del profesor o servidor local)
9. El broker recibe los mensajes de todos los ESP32.  
10. Los pone a disposición de cualquier cliente suscrito (en este caso, el PC con ChucK).

### PC del profesor escucha los eventos
11. En el PC, un proceso (puede ser un script intermedio o una herramienta) se suscribe al tópico MQTT.  
12. Cada mensaje recibido (nota ON/OFF) se traduce a un evento que ChucK pueda entender (por ejemplo, vía OSC o entrada estándar).

### ChucK interpreta y reproduce
13. ChucK recibe el evento de “nota ON/OFF” con su identificador.  
14. Asigna un instrumento/sonido a cada “id” del alumno o a cada nota.  
15. Genera el audio en tiempo real, creando la “orquesta” virtual con todos los teclados.
EOF
	@echo "Archivo generado en docs/explicacion_ext.md"

### Simulación del módulo led_pwm

![Simulación de PWM en GTKWave](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/6a2fc039a764bf39cc6c69c2a2e3a019a119fdf5/TECLADO/docs/GTKW__1.png)

A continuación se presenta el análisis de la simulación obtenida mediante GTKWave, a partir del testbench correspondiente al módulo `led_pwm`.

#### Panel izquierdo (SST / Signals)

En el panel izquierdo se visualizan las siguientes señales y parámetros relevantes:

- `parm CLK_HZ = 25_000_000`: Frecuencia del reloj del testbench (25 MHz).
- `parm CLK_PER = 40`: Periodo del reloj en nanosegundos (25 MHz equivale a 40 ns por ciclo).
- `reg clk`: Reloj de entrada del DUT (Dispositivo Bajo Prueba), tren de pulsos continuo a 25 MHz.
- `reg freq[31:0] = 0x00005D34`: Valor aplicado por el testbench al puerto `freq` del módulo (0x5D34 hexadecimal = 23860 decimal). Este valor representa el semiperiodo del PWM.
- `wire pwm`: Salida del módulo, señal PWM generada.

#### Ventana de ondas

- `clk`: Señal superior, de color verde, muy densa debido a su alta frecuencia (25 MHz).
- `freq`: Bus constante representado con el valor `00005D34`, indicando el semiperiodo deseado.
- `pwm`: Señal de salida cuadrada. Se observan tres periodos completos de la señal. Cada pulso alto y bajo tiene el mismo ancho, lo que indica un ciclo de trabajo (duty cycle) del 50%.

#### Análisis temporal

- En la parte superior de GTKWave se puede leer `Marker: 9040 ns | Cursor: 1882 us`, lo cual permite medir tiempos entre eventos mediante cursores.
- El cálculo teórico del semiperiodo es:
Semiperiodo = freq / CLK_HZ = 23860 / 25_000_000 ≈ 954.4 µs

- Esto da un periodo total de aproximadamente 1.9088 ms, lo cual coincide con lo mostrado en la simulación.
- La señal `pwm` presenta un comportamiento cuadrado y estable: permanece en alto 23860 ciclos y luego en bajo otros 23860, cumpliendo exactamente con el comportamiento esperado.

#### Conclusión

El módulo `led_pwm` genera correctamente una señal PWM con un ciclo de trabajo del 50%, con la frecuencia determinada por la entrada `freq`. No se observan glitches ni irregularidades en la señal, por lo tanto el código y el testbench se comportan correctamente para el valor de prueba utilizado (freq = 23860).

### Simulación del módulo keyboard_pwm

![Simulación del módulo keyboard_pwm en GTKWave](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/6a2fc039a764bf39cc6c69c2a2e3a019a119fdf5/TECLADO/docs/GTKW_2.png)

En esta simulación se observa el comportamiento del módulo keyboard_pwm, el cual recibe entradas de botones y entrega como salida una señal PWM cuya frecuencia depende del divisor seleccionado.

A continuación se explican las señales visibles:

- pwm_out (arriba): señal cuadrada de salida. Cambia de periodo cada vez que se presiona una tecla distinta. Se observan bloques con distinta longitud → distintas notas.
- DIV_DO, DIV_RE, DIV_MI, DIV_FA: valores constantes definidos para cada nota musical. Sirven como referencia para verificar si el divisor de salida corresponde a la nota presionada.
- btn_raw[3:0]: entradas crudas del testbench (sin debounce). Se ven valores como 1, 2, 4, 8 dependiendo del botón activado.
- btn_stable[3:0]: mismas señales pero ya estabilizadas con lógica anti-rebote. Siguen a btn_raw con un retardo de ciclo.
- note_counter[31:0]: contador que incrementa cuando se detecta una nueva pulsación. Se ve cómo avanza en incrementos de 2, 4, 8, etc. según el botón.
- note_div_out[31:0]: divisor seleccionado por la nota actual. Toma uno de los siguientes valores:
  - 0x00005D34 = 23860 → DO
  - 0x00005336 = 21302 → RE
  - 0x00004A21 = 18977 → MI
  - 0x000045F2 = 17906 → FA

Se confirma también el uso de los parámetros:
- CLK_HZ = 25 MHz
- CLK_PER = 40 ns

#### Análisis funcional:

- Selección de nota: cuando btn_stable tiene exactamente un bit en alto, note_div_out toma el divisor correspondiente.
- Priorización: aunque no se prueba explícitamente, si dos teclas están activas, se espera que prime la nota más baja (ej. DO sobre RE).
- PWM coherente: pwm_out cambia su frecuencia inmediatamente al cambiar note_div_out.
- Estabilidad: no se observan glitches ni inconsistencias en las transiciones.
- Contador de notas: note_counter se incrementa correctamente por flanco de activación.

#### Conclusión

La simulación muestra un comportamiento correcto del sistema:

- La salida PWM se ajusta en frecuencia según la nota presionada.
- Los divisores se seleccionan de forma adecuada.
- El sistema de debounce y detección de flancos opera correctamente.
- Se reflejan los cambios esperados en todas las señales internas.

### Simulación del módulo perip_contador

![Simulación del módulo perip_contador en GTKWave](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/6a2fc039a764bf39cc6c69c2a2e3a019a119fdf5/TECLADO/docs/GTKW_3.png)

En esta simulación se evalúa el comportamiento del módulo perip_contador, el cual cuenta cuántas veces se pulsa cada tecla (DO, RE, MI, FA) mediante la detección de flancos positivos en las entradas.

A continuación se describen las señales observadas:

- clk: reloj del testbench (arriba), frecuencia de 25 MHz.
- reset: activo en alto al inicio, luego se libera. Durante el reset todos los contadores deben estar en cero.
- key_state[3:0]: vector de entradas del testbench. El testbench genera flancos positivos simulando pulsaciones de teclas.
- count0..count3: contadores individuales para cada una de las teclas. Se incrementan solamente en el flanco de subida de su bit correspondiente en key_state.

Análisis del comportamiento observado:

- Durante el reset (señal en alto), todos los contadores están en cero.
- Al liberarse el reset, se inicia la secuencia de prueba: key_state toma valores como 1, 2, 4, etc., representando la pulsación de distintas teclas.
- Cada vez que se detecta un nuevo flanco positivo en un bit de key_state, el contador correspondiente incrementa en uno.
- Por ejemplo:
  - Cuando key_state = 1 (0001), se incrementa count0.
  - Luego, con key_state = 2 (0010), se incrementa count1.
  - Más tarde, con key_state = 4 (0100), se incrementa count2.
  - Finalmente, con key_state = 8 (1000), se incrementa count3.
- En todo momento, el sistema ignora flancos de bajada y valores sostenidos (tecla mantenida presionada no incrementa el contador).

Conclusión:

- La lógica de detección de flancos positivos (~prev & curr) está funcionando correctamente.
- Cada contador incrementa una única vez por cada flanco positivo recibido.
- El sistema resetea correctamente los contadores al inicio.
- El módulo perip_contador y su testbench funcionan de acuerdo con lo esperado.

### Simulación del módulo keyboard_pwm + SoC completo

![Simulación del sistema completo: entrada de botones, PWM y UART](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/5cee717dcdfb01cf5979fc196f2acb34bbf46851/TECLADO/docs/GTKW_4.png)

En esta simulación se observa el comportamiento integrado del SoC ante la presión de teclas y la generación de la señal PWM de audio. También se verifican los canales UART para interacción con dispositivos externos.

#### Señales observadas

- BUTTONS_IN[3:0]: vector aplicado por el testbench. Cada valor hexadecimal representa una tecla presionada:
  - F = 1111 → Ningún botón presionado
  - E = 1110 → DO
  - D = 1101 → RE
  - B = 1011 → MI
  - 7 = 0111 → FA
  - 0 = 0000 → Todos los botones presionados
- DIV_DO / DIV_RE / DIV_MI / DIV_FA: divisores de referencia para comparación (23860, 21302, 18977, 17906).
- LEDS: salida de LED del SoC. Se mantiene baja en esta simulación.
- PWM_AUDIO_OUT: tren de pulsos de audio generado. Cambia su frecuencia cada vez que se pulsa una nueva tecla.
- PWM_LED_OUT: permanece bajo (no evaluado en este testbench).

#### Verificaciones realizadas

- El testbench aplica una secuencia de pulsaciones en BUTTONS_IN.
- Cada transición en BUTTONS_IN produce un cambio de divisor de frecuencia (note_div_out), lo que altera el periodo de PWM_AUDIO_OUT.
- La forma de onda muestra claramente bloques de pulsos de diferentes anchos → cada nota tiene su propia frecuencia.
- En estados F (ninguna tecla) o 0 (todas), el sistema entra en modo de silencio.
- No se observan glitches en la salida PWM, lo que indica estabilidad y buena sincronización.
- El LED no interfiere, lo que es esperado si no se estimula específicamente en este testbench.

#### Interacción con aplicaciones externas (UART, MQTT, ChucK)

El sistema no solo genera audio localmente con PWM, sino que además envía eventos por UART para integrarse con otras plataformas.

1. Captura del evento en la FPGA

- Al presionar una tecla, el periférico perip_keyboard_pwm detecta la nota.
- El SoC asigna el divisor de frecuencia correspondiente.
- El firmware del procesador empaqueta un mensaje (ejemplo: "nota 0 ON") indicando qué nota fue activada.

2. Transmisión UART a ESP32

- El mensaje se envía por la UART integrada del SoC (línea TXD).
- Esta línea está conectada físicamente al RX del ESP32.

3. Publicación vía MQTT

- El ESP32 actúa como puente entre UART y WiFi.
- Cada mensaje recibido se publica en un tópico MQTT predeterminado (ej. orquesta/nota).
- Se puede usar un identificador único por FPGA (por tópico o por campo "id").

4. Comunicación con el PC del profesor

- El PC (o servidor) ejecuta un broker MQTT.
- El broker distribuye los mensajes a los clientes suscritos.

5. Recepción por ChucK

- En el PC, un proceso (por ejemplo, Python o una app intermedia) se suscribe al tópico.
- Cada mensaje se traduce en tiempo real a un evento para ChucK (vía OSC o entrada estándar).
- ChucK interpreta los eventos y genera audio real (síntesis por software).

De esta forma, el sistema permite orquestar múltiples teclados conectados en red, con reproducción colectiva por ChucK en el computador del profesor o en un entorno distribuido.

### Logs de make log-pnr, make log-syn

![Logs de make log-pnr](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/5cee717dcdfb01cf5979fc196f2acb34bbf46851/TECLADO/docs/GTKW_4.png)
![Logs de make log-syn](https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/5cee717dcdfb01cf5979fc196f2acb34bbf46851/TECLADO/docs/GTKW_4.png)


-------------------------------------------------------------------------------------------------------------------------------------------
#### Problemas para implementar la ESP32 C6
##### Fallos durante la integración de la ESP32‑C6

Para conectar la FPGA con el puente serie→WiFi/MQTT (ESP32‑C6) se presentaron varios errores. A continuación se documentan los síntomas observados, el mensaje de consola y las acciones correctivas.  

> **Evidencia:**  
> <img src="https://github.com/JuanF14-ui/Sintetizador-de-Chuck-Digital/blob/6bc22dbdc00c0e3b7e4319eb28a562d6083e357e/TECLADO/docs/falloesp32.png" width="40%" />

> (Mensaje repetitivo: `Invalid header: 0xffffffff`, `boot:0x7b (SPI FAST FLASH BOOT)`, `rst:0x7 (TG0 WDT HPSYS)`)

###### 1. Mensaje: `Invalid header: 0xffffffff`
| Síntoma | Causa probable | Solución aplicada |
|--------|-----------------|-------------------|
| La terminal muestra continuamente `Invalid header: 0xffffffff` y no arranca el firmware. | Flash vacío/corrupto o baudrate incorrecto al descargar; conexiones SPI/flash internas no inicializadas. | Reflashear con `esptool.py` o IDE (Arduino/IDF) a 460800 baudios; borrar flash completo (`erase_flash`) y volver a cargar el binario. Verificar que el binario sea para ESP32‑C6. |

###### 2. `boot:0x7b (SPI FAST FLASH BOOT)` pero reinicios constantes
| Síntoma | Causa probable | Solución aplicada |
|--------|-----------------|-------------------|
| Bootloader aparece pero el chip se reinicia en bucle. | Pines de *strapping* mal nivelados (GPIO0/BOOT, EN/RST), alimentación inestable o watchdog sin alimentar el loop principal. | Asegurar 3.3 V estables y GND comunes; comprobar que GPIO0 esté en alto para modo flash/run; deshabilitar WDT temporalmente o alimentar el loop. |

###### 3. `rst:0x7 (TG0 WDT HPSYS)`
| Síntoma | Causa probable | Solución aplicada |
|--------|-----------------|-------------------|
| Reset por watchdog de temporizador general (TG0). | Código queda bloqueado esperando UART o sin *feed* al WDT. | Añadir `esp_task_wdt_reset()` o desactivar WDT en pruebas; revisar bucles bloqueantes en lectura UART. |

###### 4. Ruido/garbage en UART después de flashear
| Síntoma | Causa probable | Solución aplicada |
|--------|-----------------|-------------------|
| Caracteres aleatorios en la consola. | Diferencia de baudrate entre ESP32‑C6 y terminal; nivel lógico o cableado cruzado TX/RX. | Fijar baudrate igual en ambos lados (ej. 115200); revisar que TXD_FPGA → RXD_ESP32 y RXD_FPGA → TXD_ESP32, ambos a 3.3 V. |

#### 5. Falta de comunicación con el broker MQTT
| Síntoma | Causa probable | Solución aplicada |
|--------|-----------------|-------------------|
| No llegan mensajes al tópico. | SSID/contraseña mal configurados, broker inaccesible o puerto bloqueado. | Comprobar conexión WiFi (ping), URL/puerto del broker, credenciales MQTT y QoS. Probar con `mosquitto_sub` en el PC para aislar el problema. |

###### Checklist de verificación rápida

- [ ] Flash borrada y firmware correcto para ESP32‑C6.  
- [ ] Pines BOOT/EN en niveles adecuados (modo RUN).  
- [ ] Alimentación 3.3 V estable, GND común con la FPGA.  
- [ ] Baudrate UART idéntico en ambos extremos.  
- [ ] TX/RX cruzados y sin invertir niveles.  
- [ ] WDT alimentado o deshabilitado durante pruebas.  
- [ ] Conexión WiFi/MQTT validada con herramientas externas.

-----------------------------------------------------------------------------

#### Videos funcionamiento del proyecto
[![Simulación en YouTube](https://img.youtube.com/vi/mxJqw3s66pg/hqdefault.jpg)](https://youtu.be/mxJqw3s66pg)

[![Simulación en YouTube](https://img.youtube.com/vi/etBYM3xEQlE/hqdefault.jpg)](https://youtu.be/etBYM3xEQlE)


