PROYECTO DIGITAL (BONGOES)

En este documento se puede observar el trabajo realizado a lo largo del semestre en la asignatura Electronica Digital a cargo del docente Johnny Cubides. Los integrantes del grupo son:

- Miguel Triana
- Steven Ortiz
- Julian Niño

# Objetivos 

- Diseñar e implementar un sistema digital en FPGA que permita detectar golpes de percusión en sensores físicos (piezoeléctricos o FSR) y convertirlos en eventos lógicos para generar sonido, simulando el funcionamiento de unos bongoes tradicionales.

- Documentar, simular y demostrar el funcionamiento del instrumento digital a través de máquinas de estado, diagramas ASM y simulaciones en Verilog, cumpliendo con los estándares de diseño y entrega requeridos por el curso.


# ¿Qué es un Bongoes digital?

Los bongoes digitales son una versión electrónica del tradicional instrumento de percusión conformado por dos tambores (uno agudo y otro grave). En lugar de emitir sonido por resonancia acústica, estos detectan los golpes mediante sensores (como piezoeléctricos o FSR) y los traducen en señales eléctricas que, al ser procesadas por un sistema digital (por ejemplo, una FPGA), permiten generar sonidos electrónicos o eventos musicales.

En este proyecto, los bongoes digitales permiten experimentar con percusión interactiva usando sensores conectados a un sistema digital, representando así la convergencia entre hardware físico, lógica digital y procesamiento de señales musicales.


# Requisitos funcionales

- Detección de golpe: El sistema debe ser capaz de detectar golpes individuales aplicados sobre sensores piezoeléctricos o FSR, generando una señal digital cuando se supere un umbral.
- Doble sensor: Debe poder distinguir entre dos sensores distintos (bongo izquierdo y derecho) para emitir señales diferentes según el tambor golpeado.
- Generación de tono: Al detectar un golpe, el sistema debe activar una salida digital que simule un tono audible o una nota musical diferente para cada bongo.
- Reset y estado inicial: El sistema debe iniciar en estado de reposo (sin sonido) y responder inmediatamente al primer golpe sin requerir configuración adicional.


# Requisitos no funcionales

- Modularidad del código: Los módulos Verilog deben estar organizados de forma estructurada.  
- Compatibilidad con FPGA: El diseño debe poder ser sintetizado e implementado en la FPGA disponible en el laboratorio, utilizando únicamente recursos digitales básicos.  
-  Documentación: Todo el proceso (diseño, código, pruebas, diagramas, resultados) debe estar debidamente documentado para su inclusión en el repositorio del proyecto.


# Diagrama del planteamiento: 

```` mermaid
flowchart TB
  %% Bongoes Digitales - Flujo General (de arriba hacia abajo)
  start([Inicio])
  start --> RESET{Reset equipo}
  RESET -- Sí --> INIT[Sistema Inicializa]
  INIT --> FPGA_INIT[Configura Clocks y UART en FPGA]
  INIT --> SENSOR_SETUP[Conecta sensores Piezoeléctricos/FSR]
  FPGA_INIT --> RUN[Ejecución]
  RESET -- No --> RUN

  subgraph Loop[Ejecución Continua]
    direction TB
    PIEZO1[Sensor Piezoeléctrico Bongó Izquierdo] -->|Pulso eléctrico| COMP1[Comparador / Trigger Digital]
    PIEZO2[Sensor Piezoeléctrico Bongó Derecho] -->|Pulso eléctrico| COMP2[Comparador / Trigger Digital]

    COMP1 --> FSM1[Maquina de estados Bongó Izquierdo]
    COMP2 --> FSM2[Maquina de estados Bongó Derecho]

    FSM1 --> TONE1["Generador PWM Tono Bongó 1"]
    FSM2 --> TONE2["Generador PWM Tono Bongó 2"]

    TONE1 --> MIXER[Mux / Mezclador de audio PWM]
    TONE2 --> MIXER

    MIXER --> AUDIO_OUT[Señal de Audio PWM]
    AUDIO_OUT -->|Filtro Pasabajo| SPEAKER[Altavoz / Salida Jack]
  end

  RUN --> Loop

````

# Diagrama de arquitectura de interconexión en FPGA: 

El diseño digital del sistema se implementa como un SoC (System-on-Chip) en la FPGA Colorlight 5A-75E, basado en un procesador FemtoRV32. La siguiente figura muestra el diagrama de interconexión generado automáticamente por la herramienta de síntesis lógica.

![Diagrama general](https://github.com/migueltriana37408/Sintetizador-de-Chuck-Digital/blob/main/BONGOES/WhatsApp%20Image%202025-07-23%20at%204.50.59%20PM.jpeg?raw=true)

# Diagrama bridge de memoria: 

Este diagrama muestra el diseño interno del puente (bridge) entre el sensor y el bus de memoria. Su función es permitir que la CPU lea la señal bongo_hit como si fuera un dato en memoria.

![Diagrama general](https://github.com/migueltriana37408/Sintetizador-de-Chuck-Digital/blob/main/BONGOES/WhatsApp%20Image%202025-07-23%20at%205.01.00%20PM.jpeg?raw=true)

# Diagrama del periferico bongoe_sensor: 

Este es el bloque encargado de generar la señal bongo_hit. Lo hace tomando como entrada dos señales binarias (left_sensor y right_sensor), luego usa multiplexores para formar un bus de 2 bits según qué sensor esté activo y genera una señal binaria bongo_hit si se detecta un cambio (probablemente con flanco o lógica combinacional).

![Diagrama general](https://github.com/migueltriana37408/Sintetizador-de-Chuck-Digital/blob/main/BONGOES/WhatsApp%20Image%202025-07-23%20at%205.13.05%20PM.jpeg?raw=true)
