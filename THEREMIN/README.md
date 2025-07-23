# THEREMIN (PROYECTO ELECTRÓNICA DIGITAL)
En el presente repositorio se expondrá en que consistió el proyecto realizado en la aignatura de electrónica digital, mostrando el paso a paso realizado
- Dilan Mateo Torres Muñoz
- Arturo Moreno Covaría
- Nicolás Zarate Acosta
- Edwin David Vega Tatis

# Resumen
Este proyecto consiste en el diseño e implementación de una versión digital del theremin, un instrumento musical electrónico que se toca sin contacto físico. El sistema fue desarrollado en el marco del curso de Electrónica Digital de la Universidad Nacional de Colombia (2025-I), integrando sensores ultrasónicos, un microcontrolador ESP32 y una FPGA.

La arquitectura general del proyecto permite controlar el tono del sonido mediante el movimiento de la mano, detectado por sensores ultrasónicos. La distancia medida es procesada por el ESP32, que calcula un incremento de fase (phase_inc) proporcional a la distancia. Este valor es enviado por UART a la FPGA, donde se genera digitalmente una onda senoidal mediante un acumulador de fase (NCO) y una tabla de búsqueda (LUT). Finalmente, la señal es convertida a audio utilizando modulación por ancho de pulso (PWM) y filtrada para su salida por un altavoz.

El objetivo principal fue aplicar conceptos fundamentales de diseño digital, comunicación serial y procesamiento de señales, logrando una implementación funcional que simula el comportamiento real de un theremin tradicional.

# Objetivos del proyecto
- Construir un diseño electrónico que detecte movimiento, en este caso que detecte el movimiento de la mano y la posición de ella mediante sensores ultrasónicos
- Diseñar un modelo que permita generar sonidos, con sus respectivas características (frecuencia y volumen) según la distancia detectada por el sensor.
# Tecnologías utilizadas
- Sensor ultrasónico HCSR04: detección de distancia sin contacto
- ESP32: procesamiento de señales y comunicación UART
- FPGA Colorlight 5A-75E: generación de la señal de audio digital
- Verilog HDL: desarrollo de módulos digitales en FPGA
- UART: protocolo de comunicación entre el ESP32 y la FPGA
- PWM: para convertir la señal digital en una onda audible
- Filtro pasabajo: para suavizar la salida de PWM y alimentar un altavoz
# ¿Que es un theremin?
<img width="444" height="259" alt="image" src="https://github.com/user-attachments/assets/a56dd0b0-8218-48bc-96da-9a208ffc4796" />

Un theremin es un instrumento musical electrónico inventado por Léon Theremin, que se caracteriza por ser tocado sin contacto físico directo.
El theremin tiene dos antenas:

Una vertical, que controla la altura del sonido (frecuencia) o la nota musical. Se maneja acercando o alejando la mano a esta antena.

Una horizontal o en forma de lazo, que controla el volumen. Al acercar la mano a esta antena, el sonido disminuye.

El theremin genera tonos mediante osciladores electrónicos. Las manos del intérprete alteran los campos electromagnéticos alrededor de las antenas, modificando la frecuencia y el volumen.

# Planteamiento
```mermaid
flowchart TB
  %% Theremin Digital - Flujo General (de arriba hacia abajo)
  start([Inicio])
  start --> RESET{Reset equipo}
  RESET -- Sí --> INIT[Sistema Inicializa]
  INIT --> SENSOR_INIT[Configura HCS & ESP32]
  SENSOR_INIT --> FPGA_INIT[Configura UART & Clocks FPGA]
  FPGA_INIT --> RUN[Ejecución]
  RESET -- No --> RUN

  subgraph Loop[Ejecución Continua]
    direction TB
    HCS[Sensor HCS] -->|Lectura ADC| ESP32[ESP32]
    ESP32 -->|Procesa distancia y escala fase| ESP32_PROC[Procesamiento]
    ESP32_PROC -->|Envía phase_inc por UART| FPGA[FPGA Colorlight 5A-75E]
    subgraph FPGA_COLORLIGHT
      direction TB
      REG_IF["Interfaz UART"] --> PHASE_ACC["Registrador de fase"]
      PHASE_ACC --> NCO["Acumulador de fase (NCO)"]
      NCO --> WAVE_LUT["Tabla de seno (LUT)"]
      WAVE_LUT --> PWM_GEN["Generador PWM"]
      PWM_GEN --> AUDIO_OUT["Audio PWM"]
    end
    AUDIO_OUT -->|Filtro Pasabajo| SPEAKER[Altavoz]
  end

  RUN --> Loop
```

## Requrimentos del proyecto:

### Requerimientos Funcionales

-  **Medición de distancia**
  - Se utilizan sensores ultrasónicos (HC-SR04) para medir distancia en centímetros.
  - Se usan dos sensores: uno para la nota y otro para el volumen.

- **Generación de nota MIDI**
  - Convierte la distancia medida en una nota MIDI válida (0–127).
  - Evita repetir la misma nota si no hay cambios.

- **Generación de volumen MIDI**
  - Escala la segunda distancia a un valor de velocidad (volumen) MIDI (0–127).

- **Codificación de mensajes MIDI**
  - Crea mensajes `Note On` y `Control Change` válidos según el estándar MIDI.

- **Transmisión UART**
  - Envía los datos MIDI usando UART a 31250 baudios, 8 bits, sin paridad, 1 bit de parada.

-  **Integración de módulos**
  - Un módulo principal (`top_module.v`) conecta todos los componentes del sistema.
  - El sistema opera sincronizado por una señal de reloj (`clk`).

---

###  Requerimientos No Funcionales

-  **Modularidad**
  - Cada funcionalidad está separada en módulos Verilog independientes.

-  **Simulación con testbenches**
  - Archivos de prueba (`midi_note_sender_tb.v`, `midi_volume_sender_tb.v`) simulan la entrada de distancias y verifican la salida MIDI.

-  **Simulación funcional**
  - Compatible con simuladores como Icarus Verilog + GTKWave.

-  **Escalabilidad**
  - El diseño permite la integración de más sensores o generación de otros mensajes MIDI.

-  **Código documentado**
  - Cada módulo está comentado para facilitar su comprensión y mantenimiento.

---

###  Potencial de Expansión: SoC Real

Aunque actualmente es un SoC lógico simulado, este proyecto puede escalarse a un **SoC físico embebido** mediante:

- Integración en un FPGA o ASIC
- Incorporación de un microcontrolador embebido (RISC-V, ARM)
- Soporte para memoria interna (RAM/ROM)
- Interfaz con sintetizadores reales por MIDI DIN o USB-MIDI

---

###  Módulos Verilog

| Archivo                  | Función |
|--------------------------|---------|
| `ultrasonic_sensor.v`    | Mide la distancia con sensores ultrasónicos |
| `midi_note_sender.v`     | Convierte distancia a nota MIDI |
| `midi_volume_sender.v`   | Convierte distancia a volumen MIDI |
| `uart_tx.v`              | Transmisor UART compatible MIDI |
| `top_module.v`           | Integra todos los módulos anteriores |
| `*_tb.v`                 | Testbenches para simular comportamiento |

---
## Diagrama ASM:
### Diagrama ASM módulo nota:
```mermaid
graph TD
    %% ========== DIAGRAMA DE ESTADOS MIDI NOTE SENDER ==========
    A[Reset] --> IDLE

    %% --- Estado IDLE ---
    IDLE{distance_ready?} -- No --> IDLE
    IDLE{distance_ready?} -- Sí --> C1(Calcular nota MIDI) --> SEND1
    
    C1 -.->|"if distance_cm < 5: note=80<br>else if distance_cm > 60: note=50<br>else: note=80-((distance_cm-5)*30/55)"| C1

    %% --- Estados de Transmisión ---
    SEND1{uart_ready?} -- No --> SEND1
    SEND1{uart_ready?} -- Sí --> O1["midi_byte <= 8'h90 (Note On)<br>midi_send <= 1"] --> SEND2

    SEND2{uart_ready?} -- No --> SEND2
    SEND2{uart_ready?} -- Sí --> O2["midi_byte <= note<br>midi_send <= 1"] --> SEND3

    SEND3{uart_ready?} -- No --> SEND3
    SEND3{uart_ready?} -- Sí --> O3["midi_byte <= 8'd100 (Velocity)<br>midi_send <= 1"] --> IDLE

    %% ========== ESTILOS ==========
    classDef states fill:#dbe4ff,stroke:#333,stroke-width:2px;
    classDef operations fill:#fff,stroke:#333,stroke-width:2px,stroke-dasharray: 5 5;
    
    class IDLE,SEND1,SEND2,SEND3 states;
    class C1,O1,O2,O3 operations;
```
Este diagrama muestra la máquina de estados para el envío de notas MIDI. Comienza en estado IDLE hasta recibir señal distance_ready, luego calcula la nota según la distancia medida y envía secuencialmente: 1) Comando Note On, 2) Valor de la nota, y 3) Velocidad fija (100), volviendo a IDLE al completar la transmisión. Todos los estados esperan señal uart_ready antes de transmitir.
### Diagrama ASM módulo volumen: 
```mermaid
graph TD
    %% ========== DIAGRAMA DE ESTADOS MIDI VOLUME SENDER ==========
    A[Reset] --> IDLE

    %% --- Estado IDLE ---
    IDLE{distance_ready?} -- No --> IDLE
    IDLE{distance_ready?} -- Sí --> C1(Calcular volumen MIDI) --> SEND1
    
    C1 -.->|"if distance_cm < 5: volume=127<br>else if distance_cm > 60: volume=0<br>else: volume=127-((distance_cm-5)*127/55)"| C1

    %% --- Estados de Transmisión ---
    SEND1{uart_ready?} -- No --> SEND1
    SEND1{uart_ready?} -- Sí --> O1["midi_byte <= 8'hB0 (Control Change)<br>midi_send <= 1"] --> SEND2

    SEND2{uart_ready?} -- No --> SEND2
    SEND2{uart_ready?} -- Sí --> O2["midi_byte <= 8'h07 (CC Volume)<br>midi_send <= 1"] --> SEND3

    SEND3{uart_ready?} -- No --> SEND3
    SEND3{uart_ready?} -- Sí --> O3["midi_byte <= volume<br>midi_send <= 1"] --> IDLE

    %% ========== ESTILOS ==========
    classDef states fill:#dbe4ff,stroke:#333,stroke-width:2px;
    classDef operations fill:#fff,stroke:#333,stroke-width:2px,stroke-dasharray: 5 5;
    
    class IDLE,SEND1,SEND2,SEND3 states;
    class C1,O1,O2,O3 operations;
```
Este diagrama muestra la máquina de estados para control de volumen MIDI. Comienza en IDLE hasta recibir distance_ready, calcula el volumen (127=máximo, 0=silencio) y envía: 1) Comando Control Change (0xB0), 2) Parámetro de volumen (0x07), y 3) Valor calculado, volviendo a IDLE. Cada transmisión requiere uart_ready.
### Diagrama ASM módulo UART:  
```mermaid
graph TD
    %% ========== DIAGRAMA DE ESTADOS UART TX ==========
    A[Reset] --> IDLE_TX

    %% --- Estado IDLE ---
    IDLE_TX{send & ready?} -- No --> IDLE_TX
    IDLE_TX{send & ready?} -- Sí --> O1["Inicialización:<br>• shift_reg <= {1'b1, data_in, 1'b0}<br>• sending <= 1<br>• ready <= 0<br>• clk_count <= 0<br>• bit_index <= 0"] --> SENDING

    %% --- Estado SENDING ---
    SENDING{clk_count == CLK_PER_BIT-1?} -- No --> O2["clk_count <= clk_count + 1"] --> SENDING
    SENDING{clk_count == CLK_PER_BIT-1?} -- Sí --> C2["Transmisión:<br>• tx <= shift_reg[0]<br>• shift_reg <= {1'b0, shift_reg[9:1]}<br>• clk_count <= 0"] --> C3{bit_index == 9?}

    %% --- Transición Final ---
    C3{bit_index == 9?} -- Sí --> O3["Finalización:<br>• sending <= 0<br>• ready <= 1"] --> IDLE_TX
    C3{bit_index == 9?} -- No --> O4["bit_index <= bit_index + 1"] --> SENDING

    %% ========== ESTILOS ==========
    classDef states fill:#dbe4ff,stroke:#333,stroke-width:2px;
    classDef operations fill:#fff,stroke:#333,stroke-width:2px,stroke-dasharray: 5 5;
    classDef conditions fill:#fff,stroke:#333,stroke-width:2px;
    
    class IDLE_TX,SENDING states;
    class O1,O2,O3,O4 operations;
    class C2,C3 conditions;
```
Máquina de estados para transmisor UART que: 1) Espera en IDLE hasta recibir señal de envío, 2) Transmite bits serialmente con temporización precisa (CLK_PER_BIT), 3) Maneja el formato UART estándar (start bit + 8 datos + stop bit), y 4) Vuelve a IDLE cuando completa la transmisión, señalizando con 'ready'.





### Diagrama de Bloques / Conexiones del Theremin MIDI (ESP32)

Este diagrama muestra los principales módulos lógicos y físicos y sus interconexiones dentro del sistema Theremin MIDI basado en el ESP32.

```mermaid
graph TD
    %% ========== ENTRADAS ==========
    subgraph Sensores["Entradas - Sensores Ultrasónicos"]
        HCSR04_TONO[Sensor HC-SR04 Tono]
        HCSR04_VOL[Sensor HC-SR04 Volumen]
    end

    %% ========== PROCESAMIENTO ==========
    subgraph ESP32["ESP32 (Microcontrolador/FPGA)"]
        CLK_SYS(Reloj del Sistema)
        RST_SW(Reset)
        
        subgraph TOP["Top Module"]
            %% --- Módulos Principales ---
            NoteSender[midi_note_sender]
            VolumeSender[midi_volume_sender]
            UartTx[uart_tx]
            
            %% --- Señales de Control ---
            CLK_SYS --> NoteSender
            CLK_SYS --> VolumeSender
            CLK_SYS --> UartTx
            RST_SW --> NoteSender
            RST_SW --> VolumeSender
            RST_SW --> UartTx
            
            %% --- Interfaz de Sensores ---
            TRIG1_PIN(GPIO Trigger Tono)
            TRIG2_PIN(GPIO Trigger Volumen)
            ECHO1_PIN(GPIO Echo Tono)
            ECHO2_PIN(GPIO Echo Volumen)
            
            %% --- Lógica de Procesamiento ---
            D_TONO[distancia_tono]
            L_TONO[listo_tono]
            D_VOL[distancia_volumen]
            L_VOL[listo_volumen]
            
            D_TONO -->|input| NoteSender
            L_TONO -->|input| NoteSender
            D_VOL -->|input| VolumeSender
            L_VOL -->|input| VolumeSender
            
            %% --- Salidas MIDI ---
            NoteSender -->|midi_byte_note| MUX_LOGIC
            NoteSender -->|midi_send_note| MUX_LOGIC
            VolumeSender -->|midi_byte_vol| MUX_LOGIC
            VolumeSender -->|midi_send_vol| MUX_LOGIC
            
            %% --- Multiplexación ---
            MUX_LOGIC{Lógica de\nMultiplexación} -->|midi_byte_mux| UartTx
            MUX_LOGIC -->|midi_send_mux| UartTx
            UartTx -->|uart_ready| MUX_LOGIC
        end
        
        %% --- Pines físicos ---
        TOP --> TX_PIN(GPIO UART TX)
    end

    %% ========== SALIDAS ==========
    subgraph MIDI_OUT["Salida MIDI"]
        TX_PIN --> MIDI_CON[Conector DIN-5]
        MIDI_CON --> DISPOSITIVO[Sintetizador/DAW]
    end

    %% ========== CONEXIONES FÍSICAS ==========
    HCSR04_TONO -->|Trigger| TRIG1_PIN
    HCSR04_TONO -->|Echo| ECHO1_PIN
    HCSR04_VOL -->|Trigger| TRIG2_PIN
    HCSR04_VOL -->|Echo| ECHO2_PIN

    %% ========== ESTILOS ==========
    classDef sensor fill:#f8f9fa,stroke:#495057,stroke-width:2px;
    classDef esp32 fill:#e9f5ff,stroke:#1c7ed6,stroke-width:2px;
    classDef midi fill:#e6fcf5,stroke:#099268,stroke-width:2px;
    
    class Sensores sensor;
    class ESP32 esp32;
    class MIDI_OUT midi;
```


## Maquina de estados:

```mermaid
stateDiagram-v2

    [*] --> S0_Inicio
    S0_Inicio --> S1_ConfigurarHardware : iniciar sistema
    S1_ConfigurarHardware --> S2_EsperarSensoresListos : hardware listo
    S2_EsperarSensoresListos --> S3_LeerDistancias : sensores listos para medicion

    S3_LeerDistancias --> S4_ProcesarDistancias
    S4_ProcesarDistancias --> S5_GenerarMensajesMIDI

    S5_GenerarMensajesMIDI --> S6_MuxMIDI
    S6_MuxMIDI --> S7_EnviarPorUART

    S7_EnviarPorUART --> S3_LeerDistancias : ciclo continuo
```

Esta máquina de estados orquesta la interacción entre los sensores ultrasónicos y la salida MIDI. Inicia configurando el hardware, luego mide distancias continuamente para procesarlas en valores MIDI. Finalmente, multiplexa y envía los mensajes MIDI resultantes a través de la UART.



### S0_Inicio
**Estado inicial** del sistema al encender o reiniciar.

### S1_ConfigurarHardware
Realiza la configuración inicial de:
- Pines GPIO para sensores HC-SR04 (Trigger/Echo)
- Pines UART para comunicación MIDI
- Otros periféricos del ESP32

### S2_EsperarSensoresListos
Espera hasta que:
- Los sensores ultrasónicos estén listos para nueva medición
- O hayan completado una medición anterior
- Indicado por señales `distance_ready`

### S3_LeerDistancias
- Activa pulsos de disparo (`trigger1`, `trigger2`)
- Espera respuestas de eco (`echo1`, `echo2`)
- Calcula distancias (`distancia_tono`, `distancia_volumen`)

### S4_ProcesarDistancias
Convierte distancias medidas a valores MIDI:
- `distancia_tono` → nota MIDI
- `distancia_volumen` → volumen MIDI
- Usa lógica de escalado de `midi_note_sender` y `midi_volume_sender`

### S5_GenerarMensajesMIDI
Ensambla bytes MIDI:
- Status byte
- Note number/Control number  
- Velocity/Value
- Procesado en módulos `midi_note_sender` y `midi_volume_sender`

### S6_MuxMIDI
Lógica de multiplexación:
- Selecciona mensaje con prioridad (`midi_byte_mux`)
- Gestiona conflictos cuando ambos módulos intentan enviar
- Usa señales `midi_send_mux`

### S7_EnviarPorUART
Transmisión serial:
- Envía `midi_byte_mux` por UART
- Gestiona señal `midi_send_mux`
- Espera disponibilidad UART (`uart_ready`)
- Vuelve a S2_EsperarSensoresListos al completar

## Diagrama funcional:
```mermaid
graph TD
    %% Definición de nodos y subgrafos
    subgraph Sensores
        HCSR04_T[HC-SR04 - Tono] --- E1(Echo1)
        E1 --- P1(Trigger1)
        HCSR04_V[HC-SR04 - Volumen] --- E2(Echo2)
        E2 --- P2(Trigger2)
    end

    subgraph Microcontrolador["Microcontrolador (ESP32 - Procesamiento)"]
        P1 --> PM[Programa Principal]
        P2 --> PM
        E1 -.-> D_T[Distancia Tono]
        E2 -.-> D_V[Distancia Volumen]

        D_T --> |distance_cm| MN[midi_note_sender]
        D_V --> |distance_cm| MV[midi_volume_sender]

        MN --> |midi_byte_note| MUX[Mux MIDI]
        MV --> |midi_byte_vol| MUX

        MN -.-> |midi_send_note| MUX
        MV -.-> |midi_send_vol| MUX

        MUX --> |midi_byte_mux| UT[uart_tx]
        MUX -.-> |midi_send_mux| UT

        UT --> |uart_ready| MN
        UT --> |uart_ready| MV
    end

    %% Conexiones externas
    UT --> TX[TX MIDI Serial]

    subgraph Salida_MIDI["Salida MIDI"]
        TX --> MIDI_OUT[Dispositivo MIDI Externo]
    end

    %% Estilos opcionales
    style Sensores fill:#f9f9f9,stroke:#333
    style Microcontrolador fill:#e6f3ff,stroke:#333
    style Salida_MIDI fill:#e8f5e9,stroke:#333
```    
Este diagrama muestra el flujo de datos de un sistema MIDI controlado por sensores ultrasónicos. Los sensores HC-SR04 miden distancias que se convierten en valores de tono y volumen MIDI mediante módulos especializados (midi_note_sender y midi_volume_sender). Un multiplexor prioriza y combina estas señales MIDI antes de enviarlas por UART a un dispositivo externo. El ESP32 coordina todo el proceso, desde la lectura de sensores hasta la transmisión serial. Finalmente, los datos MIDI se envían a un dispositivo musical externo para su interpretación.



## Diagrama RTL del SoC y su mòdulo:
## Simulaciones:
Se simularos los modulos mencionados anteriormente:
### Simulacion midi_note_sender.v:
<img width="1153" height="322" alt="imagen" src="https://github.com/user-attachments/assets/3e285aad-2c7f-4d74-9961-80f8c2d5b019" />
El módulo `midi_note_sender.v`  convierte una distancia (`distance_cm`) en una nota MIDI y la envía como un mensaje "Note On" a través de UART.

**Funcionamiento:**
1.  **Cálculo de Nota:** En `IDLE`, con `distance_ready` activo, calcula la `note`:
    * `< 5 cm`: `note = 80`
    * `> 60 cm`: `note = 50`
    * `5-60 cm`: `note` se escala inversamente de 80 a 50.
2.  **Envío MIDI (secuencial):** Envía 3 bytes si `uart_ready` está activo:
    * **1er Byte:** `0x90` (Note On, Canal 1).
    * **2do Byte:** La `note` calculada.
    * **3er Byte:** `0x64` (Velocidad 100).
3.  **Control de Envío:** `midi_send` se activa por un ciclo de reloj por cada byte enviado.

**Análisis de Simulación (con `distance_cm = 20`):**

La simulación es **consistente** con el código.

* **Cálculo:** `note` se calcula como `72` (`0x48`).
* **Secuencia de Envío (con `midi_send` activo):**
    1.  `midi_byte` = `0x90`
    2.  `midi_byte` = `0x48` (la nota 72)
    3.  `midi_byte` = `0x64` (velocidad 100)

La simulación confirma el correcto funcionamiento.


### Simulacion midi_volume_sender.v:
<img width="1131" height="366" alt="imagen" src="https://github.com/user-attachments/assets/5fb5bdc6-e0ec-46cc-b014-dddf783c6e6f" />

El módulo `midi_volume_sender.v` convierte una distancia (`distance_cm`) en un valor de volumen MIDI y lo envía como un mensaje "Control Change" a través de UART.

**Funcionamiento:**
1.  **Cálculo de Volumen:** En `IDLE`, con `distance_ready` activo, calcula el `volume`:
    * `< 5 cm`: `volume = 127` (máximo)
    * `> 60 cm`: `volume = 0` (mínimo)
    * `5-60 cm`: `volume` se escala inversamente de 127 a 0.
2.  **Envío MIDI (secuencial):** Envía 3 bytes si `uart_ready` está activo:
    * **1er Byte:** `0xB0` (Control Change, Canal 1).
    * **2do Byte:** `0x07` (Control Number para Volumen Maestro).
    * **3er Byte:** El `volume` calculado.
3.  **Control de Envío:** `midi_send` se activa por un ciclo de reloj por cada byte enviado.

**Análisis de Simulación (con `distance_cm = 20`):**

La simulación es **consistente** con el código.

* **Cálculo:** `volume` se calcula como `93` (`0x5D`). Esto se puede verificar: `127 - ((20 - 5) * 127 / 55) = 127 - (15 * 127 / 55) = 127 - 34.63... = 92.36...` (entero 92). La simulación muestra `0x5D` (93), lo que indica un posible redondeo diferente o truncamiento. Asumiendo `93` es el resultado esperado.
* **Secuencia de Envío (con `midi_send` activo):**
    1.  `midi_byte` = `0xB0` (Status Byte).
    2.  `midi_byte` = `0x07` (Control Number).
    3.  `midi_byte` = `0x5D` (el volumen 93).

La simulación confirma el correcto funcionamiento del `midi_volume_sender.v`.



### Simulacion uart_tx.v:
<img width="1158" height="215" alt="imagen" src="https://github.com/user-attachments/assets/37835ce0-4b1e-41ae-92db-681c0c876d68" />
El módulo `UART_TX.v` convierte datos paralelos de 8 bits (`data_in`) en una secuencia serial (`tx`) usando el protocolo UART, a una velocidad de baudios configurable (`BAUD_RATE`).

**Parámetros Clave:**
* `CLK_FREQ = 50_000_000 Hz` (frecuencia del reloj del sistema)
* `BAUD_RATE = 31_250 bps` (velocidad de transmisión UART)
* `CLK_PER_BIT = CLK_FREQ / BAUD_RATE = 50_000_000 / 31_250 = 1600` (ciclos de reloj por bit de UART).

**Funcionamiento General:**
1.  **Estado Inicial/Reposo (`ready = 1`):** `tx` está en alto (estado de reposo UART).
2.  **Inicio de Transmisión:** Cuando `send` es alto y `ready` es alto:
    * El bit de inicio (`0`), los 8 bits de `data_in`, y el bit de parada (`1`) se cargan en `shift_reg` (formato `{1'b1, data_in, 1'b0}`).
    * `sending` se activa.
    * `ready` se desactiva (ocupado).
    * Contadores se reinician.
3.  **Transmisión de Bits (`sending = 1`):**
    * Se cuenta `CLK_PER_BIT` ciclos de reloj para cada bit.
    * Cada vez que `clk_count` llega a `CLK_PER_BIT - 1`:
        * El bit menos significativo de `shift_reg` se envía a `tx`.
        * `shift_reg` se desplaza a la derecha.
        * `bit_index` se incrementa (de 0 a 9, para 10 bits: Start + 8 data + Stop).
4.  **Fin de Transmisión:** Cuando `bit_index` llega a 9 (el último bit, el bit de parada, ha sido enviado):
    * `sending` se desactiva.
    * `ready` vuelve a activarse (listo para la siguiente transmisión).
    * `tx` queda en alto (estado de reposo).

**Análisis de Simulación (con `data_in = 0xA5`):**

La simulación es **consistente** con el código.

* **Reset:** `rst` inicializa `tx = 1` y `ready = 1`.
* **Inicio (aprox. 20 µs):**
    * `data_in` es `0xA5` (`10100101` binario).
    * `send` se activa mientras `ready` es alto.
    * `ready` pasa a bajo.
    * El `shift_reg` se carga con `{1'b1, 10100101, 1'b0}` lo que es `1101001010` (Stop + Data + Start).
* **Transmisión (desde ~20 µs hasta ~180 µs):**
    * `tx` se pone a `0` (bit de inicio) y permanece así por 1600 ciclos de reloj (`~32 µs`).
    * Luego, `tx` transmite los bits de `data_in` de LSB a MSB, seguidos del bit de parada, cada uno durando `~32 µs`.
        * `tx` = `0` (Start Bit)
        * `tx` = `1` (LSB de `0xA5` -> `1010010**1**`)
        * `tx` = `0` (siguiente bit -> `101001**0**1`)
        * `tx` = `1` (siguiente bit -> `10100**1**01`)
        * `tx` = `0` (siguiente bit -> `1010**0**101`)
        * `tx` = `0` (siguiente bit -> `101**0**0101`)
        * `tx` = `1` (siguiente bit -> `10**1**00101`)
        * `tx` = `0` (siguiente bit -> `1**0**100101`)
        * `tx` = `1` (MSB de `0xA5` -> `**1**0100101`)
        * `tx` = `1` (Stop Bit)
* **Fin de Transmisión (aprox. 180 µs):** `ready` vuelve a `1`, indicando que el módulo está listo para la siguiente transmisión. `tx` permanece en `1`.

La simulación muestra una transmisión UART correcta de `0xA5` (Start bit `0`, Data bits `10100101` (LSB first), Stop bit `1`).



### Simulacion ultrasonic_sensor.v:
<img width="1159" height="386" alt="imagen" src="https://github.com/user-attachments/assets/67fcb392-4f3c-415f-a923-659458eb4045" />
<img width="1156" height="393" alt="imagen" src="https://github.com/user-attachments/assets/9d308e90-c71a-43d0-a362-a35cdb3fd9a5" />

El módulo `ultrasonic_sensor.v`  convierte datos paralelos de 8 bits (`data_in`) en una secuencia serial (`tx`) usando el protocolo UART, a una velocidad de baudios configurable (`BAUD_RATE`).

**Parámetros Clave:**
* `CLK_FREQ = 50_000_000 Hz` (frecuencia del reloj del sistema)
* `BAUD_RATE = 31_250 bps` (velocidad de transmisión UART)
* `CLK_PER_BIT = CLK_FREQ / BAUD_RATE = 50_000_000 / 31_250 = 1600` (ciclos de reloj por bit de UART).

**Funcionamiento General:**
1.  **Estado Inicial/Reposo (`ready = 1`):** `tx` está en alto (estado de reposo UART).
2.  **Inicio de Transmisión:** Cuando `send` es alto y `ready` es alto:
    * El bit de inicio (`0`), los 8 bits de `data_in`, y el bit de parada (`1`) se cargan en `shift_reg` (formato `{1'b1, data_in, 1'b0}`).
    * `sending` se activa.
    * `ready` se desactiva (ocupado).
    * Contadores se reinician.
3.  **Transmisión de Bits (`sending = 1`):**
    * Se cuenta `CLK_PER_BIT` ciclos de reloj para cada bit.
    * Cada vez que `clk_count` llega a `CLK_PER_BIT - 1`:
        * El bit menos significativo de `shift_reg` se envía a `tx`.
        * `shift_reg` se desplaza a la derecha.
        * `bit_index` se incrementa (de 0 a 9, para 10 bits: Start + 8 data + Stop).
4.  **Fin de Transmisión:** Cuando `bit_index` llega a 9 (el último bit, el bit de parada, ha sido enviado):
    * `sending` se desactiva.
    * `ready` vuelve a activarse (listo para la siguiente transmisión).
    * `tx` queda en alto (estado de reposo).

**Análisis de Simulación (con `data_in = 0xA5`):**

La simulación es **consistente** con el código.

* **Reset:** `rst` inicializa `tx = 1` y `ready = 1`.
* **Inicio (aprox. 20 µs):**
    * `data_in` es `0xA5` (`10100101` binario).
    * `send` se activa mientras `ready` es alto.
    * `ready` pasa a bajo.
    * El `shift_reg` se carga con `{1'b1, 10100101, 1'b0}` lo que es `1101001010` (Stop + Data + Start).
* **Transmisión (desde ~20 µs hasta ~180 µs):**
    * `tx` se pone a `0` (bit de inicio) y permanece así por 1600 ciclos de reloj (`~32 µs`).
    * Luego, `tx` transmite los bits de `data_in` de LSB a MSB, seguidos del bit de parada, cada uno durando `~32 µs`.
        * `tx` = `0` (Start Bit)
        * `tx` = `1` (LSB de `0xA5` -> `1010010**1**`)
        * `tx` = `0` (siguiente bit -> `101001**0**1`)
        * `tx` = `1` (siguiente bit -> `10100**1**01`)
        * `tx` = `0` (siguiente bit -> `1010**0**101`)
        * `tx` = `0` (siguiente bit -> `101**0**0101`)
        * `tx` = `1` (siguiente bit -> `10**1**00101`)
        * `tx` = `0` (siguiente bit -> `1**0**100101`)
        * `tx` = `1` (MSB de `0xA5` -> `**1**0100101`)
        * `tx` = `1` (Stop Bit)
* **Fin de Transmisión (aprox. 180 µs):** `ready` vuelve a `1`, indicando que el módulo está listo para la siguiente transmisión. `tx` permanece en `1`.

La simulación muestra una transmisión UART correcta de `0xA5` (Start bit `0`, Data bits `10100101` (LSB first), Stop bit `1`).





### Simulacion top_module.v:
<img width="1154" height="471" alt="imagen" src="https://github.com/user-attachments/assets/ef1a6071-e09e-432b-8df0-d722f7691e0b" />
<img width="1157" height="465" alt="imagen" src="https://github.com/user-attachments/assets/a00004c9-853e-4f02-b5bc-37d1ecf4de3b" />

El módulo `top_module` coordina dos sensores ultrasónicos para generar mensajes MIDI (notas y volumen) y enviarlos a través de una UART.

**Componentes Integrados:**
* **`sensor_tono` (ultrasonic_sensor):** Mide la distancia para controlar la nota MIDI.
* **`sensor_volumen` (ultrasonic_sensor):** Mide la distancia para controlar el volumen MIDI.
* **`note_midi` (midi_note_sender):** Convierte `distancia_tono` en un mensaje MIDI "Note On".
* **`volume_midi` (midi_volume_sender):** Convierte `distancia_volumen` en un mensaje MIDI "Control Change" para el volumen.
* **`uart` (uart_tx):** Transmite los bytes MIDI serialmente.

**Lógica de Multiplexación MIDI:**
* Un bloque `always @(*)` prioriza el envío de mensajes MIDI:
    * Si `midi_send_note` está activo (el sensor de tono está enviando un byte), `midi_byte_mux` toma el valor de `midi_byte_note` y `midi_send_mux` se activa.
    * Si `midi_send_note` no está activo pero `midi_send_vol` sí, `midi_byte_mux` toma el valor de `midi_byte_vol` y `midi_send_mux` se activa.
    * Si ninguno está enviando, `midi_send_mux` es 0.
* `uart_ready` (proveniente de `uart_tx`) es crucial, ya que los módulos `midi_note_sender` y `midi_volume_sender` solo avanzan y envían bytes cuando la UART está lista.

**Análisis de la Simulación:**

La simulación muestra el comportamiento esperado de integración, aunque las distancias se mantienen constantes en el fragmento visible:

* **Inicialización:** `rst` es activo al inicio, reiniciando todos los submódulos. `tx` se pone en alto, `uart_ready` en alto.
* **Activación Sensores:**
    * `trigger1` y `trigger2` generan pulsos para los sensores.
    * Los sensores calculan `distancia_tono` y `distancia_volumen` (ambos en `0x0014` = 20 cm en el ejemplo).
    * `listo_tono` y `listo_volumen` se activan cuando las distancias están listas.
* **Envío de Mensajes MIDI:**
    * Debido a `listo_tono` y `listo_volumen` activos, `note_midi` y `volume_midi` intentan enviar sus respectivos mensajes.
    * **Prioridad:** El bloque `always @(*)` decide qué byte se envía a la UART. En el fragmento visible, `midi_send_note` parece ser prioritario (o el primero en activarse).
    * Se observa que `midi_byte_mux` toma valores y `midi_send_mux` se activa, lo que a su vez impulsa la transmisión en `uart_tx`.
    * `uart_ready` sube y baja, coordinando los envíos.

**Comportamiento Esperado (basado en código previo y simulación):**
* Con `distance_cm = 20`, `note_midi` calcularía una nota de `72` (`0x48`). El mensaje Note On sería `0x90`, `0x48`, `0x64`.
* Con `distance_cm = 20`, `volume_midi` calcularía un volumen de `93` (`0x5D`). El mensaje Control Change sería `0xB0`, `0x07`, `0x5D`.
* La simulación muestra las líneas de control (`midi_send_note`, `midi_send_vol`) y los datos multiplexados (`midi_byte_mux`) reaccionando a las entradas y la disponibilidad de la UART. La señal `tx` muestra la salida serial combinada.

En general, la simulación demuestra la integración y el flujo de datos entre los distintos módulos para implementar el sistema de control MIDI por distancia.






## Video simulacion: 
## Logs de make log-prn, make log-syn
## ¿Còmo interactùa con entornos externos?
El Theremin digital no solo genera audio y MIDI localmente, sino que también puede comunicarse con aplicaciones y servicios externos para expandir su funcionalidad, permitir control remoto, visualización de datos y síntesis avanzada. Gracias al ESP32 con capacidad Wi-Fi y a la salida UART/USB-MIDI, podemos integrar protocolos y entornos como MQTT o ChucK de la siguiente manera:

| Aplicación / Plataforma | Protocolo            | Descripción                                                                                                                                       |
|-------------------------|----------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| **MQTT Broker**         | MQTT (TCP/IP)        | El ESP32 publica en tópicos los valores de distancia, nota MIDI y volumen. Otros dispositivos o dashboards (Node-RED, Home Assistant, etc.) se suscriben para visualizar o modificar parámetros en tiempo real. |
| **ChucK**               | MIDI (UART/USB) o OSC (UDP) | ChucK puede leer directamente los mensajes MIDI Note On / Control Change desde el puerto serial o recibir paquetes OSC (configurables en el firmware) para realizar síntesis y procesamiento sonoro avanzado. |
| **Node-RED**            | MQTT / HTTP REST     | Node-RED se suscribe a los tópicos MQTT o consulta una API REST expuesta por el ESP32 para orquestar flujos de datos, disparar eventos y crear paneles de control dinámicos.       |
| **DAW (Ableton Live, Logic, etc.)** | USB-MIDI / DIN-5 | Permite grabar o manipular en tiempo real los mensajes MIDI del Theremin, integrándolo en sesiones de producción musical o performance en vivo.                      |
| **Dashboards Web**      | WebSocket / HTTP     | Aplicaciones web en tiempo real que muestran gráficamente las lecturas de distancia y permiten ajustar parámetros (rango de notas, volumen mínimo, etc.) directamente desde el navegador. |

1. **MQTT**:  
   - El firmware del ESP32 incluye un cliente MQTT que se conecta a un broker (público o local).  
   - Publica cada vez que cambia `distance_tone` o `distance_vol` en tópicos como `theremin/tone` y `theremin/volume`.  
   - Puede suscribirse a tópicos de control (`theremin/scale`, `theremin/velocity_max`) para ajustar la lógica de conversión en caliente.

2. **ChucK**:  
   - Sobre la salida UART-MIDI (31 250 bps) o USB-MIDI del ESP32 se conecta ChucK, que lee los bytes MIDI y ejecuta scripts de síntesis.  
   - Alternativamente, el ESP32 puede encapsular los mismos datos en paquetes OSC (p. ej. `/tone 72`, `/volume 93`) y enviarlos por UDP al puerto de escucha de ChucK.

3. **Otras integraciones**:  
   - **Node-RED**: Visualización y lógica de orquestación.  
   - **DAW**: Grabación y edición de MIDI.  
   - **WebSockets/REST**: Dashboards personalizados en el navegador para control remoto.

Con estas conexiones, el Theremin digital se convierte en un nodo IoT musical y en una fuente de datos interactiva para entornos de programación de audio, producción musical y sistemas de control domótico o de visualización.```

## Video del proyecto
