# TROMPETA (PROYECTO ELECTRÓNICA DIGITAL)

Integrantes:

- Paula Quiroga Romero
- Jesús Sanchez Cobos
- Sergio Daniel Ávila Quintana
- Santiago Herrera Acuña

En este repositorio se encuentra el proceso de diseño e implementación de un modulo digital que simula el funcionamiento de un trombón a través de sistemas digitales usando dispositivos como la FPGA y sistemas de comunicaiones como la ESP32.

# Introducción

Par el desarrollo de los instrumentos musicales, pasando primero por procesos de generación de sonidos analógicos, era necesario utilizar distintos modelos que aprovecharan las propiedades dee transmisión de ondas que aprovecharan las frecuencia fundamentales del sistema; el inconveniente surge en lo complicado y dispendioso que puede llegar a ser el proceso de establecer correctamente las notas musicales (traducidas en frecuencia) al tener las limitaciones propias de un sistema analógico. De esta manera, con el entendimiento de la lógica digital, el problema se puede solucionar de más sencilla al utilizar valores discretos para la genracion de sonido. 

En el caso particular de los instrumentos de viento, estos aprovechan un flujo de aire que vibra dentro del instrumento, que cambia su afinación según los pistones que estén presionados, para finalmente ser amplificado; está lógica puede ser _simulada_ en un sistema digital como se verá a continuación

<p align="center">
<img width="444" height="259" alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/Trompeta-Hal-Gatewood-Unsplash.jpg" />
</p>

# Objetivos 

- Entender el comportamiento modular en el diseño de un sistema digital a través de la implementación de un instruemnto que tenga como base circuito lógicos digitales para modificación tonal de un sonido.
- Hacer uso de circuitos combinacionales como herramienta para la construcción de sistemas con un número finito de estados para amnipular las frecuencias enviadas.
- Utilizar lógica secuencial para detectar cambios en el tiempo de la implementación física representados en un sensor que interactue como transductor en el sistema.
- Plantear la interacción entre difreneets módulos del sistema para que funcionen y se complementen de manera simultánea.
- Establecer un sistema de comunicación para el módulo general del instrumento.
- Desarrollar un diseño físico que soporte y optimize el uso físico del instrumento a tarvés de modelado.

# Requerimientos del proyecto

## Requerimientos funcionales:

- **Selección de nota:**
  - A través de selectores se reproduce una única nota musical según la combinanción de los mismos.
  - Tras reconocer la combinación se envia una nota en formato MIDI.
  - Mantiene el tono hasta que se efectue algún cambio.

- **Selección de altura:**
   - Se mide la frecuencia de movimiento de una aspa que representa el flujo de aire impregnado al instrumento a través de un sensor.
   - A través de un intervalo limitado de tiempo, se realiza una cuenta, controlada por el pulso de reloj.
   - El resultado de la cuenta representa un factor multiplicativo que modifica la altura de la selección de nota del modulo anterior.
     
- **Sistema de comunicación:**
  - Se entregan ambos valores de los modulos anteriores a través de transmisión por UART.
 
## Requerimientos no funcionales:**

- **Modularidad:** Las funcionalidades de selección estan separadas entre sí, de modo que, una no afecta al desemepño de la otra.

- **Diseño físico:** Integra de manera óptima e integral para el usuario una carcasa que facilita el uso y disposición física del dispositivo.

# Planteamiento

De la sección de introducción, logra abstraen tres momentos importantes en el funcionamiento de un instrumento de viento:

- Generación de sonido a través debido a una vibración generada por el flujo del aire.
- Modificación de la frecuencia a través de actuadores (pistones).
- Amplificación del sonido ya modificado.

Estas tres partes serán los tres modulos principales del proyecto, dos de ellos funcionando de manera simultánea, la generación de flujo de aire, para finalizar en el último paso, que es la amplificación. De esta manera, lo primero que se establece es un orden en desarrollo de los modulos, a su vez, estableciendo su análogo digital:

1. **Sistema de pistones:** Se utiliza un sistema de pulsadores que funcione como _multiplexor_ para la selección mutuamente excluyente entre 8 notas diferentes.
2. **Actuador con flujo de aire:** Con ayuda de un sensor magnético, se utiliza un contador, limitado a través de un temporizador para obtener la rapidez del conteo de pulsos, y por ende, determinar la altura máxima del sonido.
3. **Producción de sonido:** Con el dato de la nota y la altura correspondiente, se transmiten los datos a través de la ESP33 por protocolo UART, y se llevan a un script de Chuck para su ejecución.

## Sistema de pulsadores

La unidad básica de la música se construye a través de notas musicales, que no son más, que una onda sonorá con cierta frecuencia característica reconocicle al oido humano.

En el sistema de música occidental, sin contar las frecuencias que son multiplos de otras, existen 12 notas musicales. Sin embargo, es común seleccionar 8 de estas notas con relaciones espeíficas entre sí para que suenen agradables (se le llama escala musical), y le brinden cierta sonoridad específica. La escala más conocida es la de Do mayor, que se representan a través de las 8 notas blancas de un teclado, y presenta las 7 notas qe se reconocen comunmente (Do, re, mi, fa, sol, la, si), y adicional, una nota que dobla en frecuencia al primer do (denominado en este proyecto como do alto).

<p align="center">
<img width="444" height="259" alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/escala-mayor-grados-tonos-semitonos-de-separacion.png" />
</p>

Los pistones pueden ser simulados a través de un _multiplexor_, basado en selectores (pulsadores), donde cada combinación de estos representa una frecuencia que será reproducida. Como se definió que son necesarias 8 notas, el sistema estará basado en un multiplexor 8x1, que se caracteriza por tener 3 selectores de control.

<p align="center">
<img width="444" height="259" alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/multiplexor.png" />
</p>

| Pulsador 1    | Pulsador 2 | Pulsador 3 | Nota reproducida|
|---------------|------------|------------|-----------------|
| 0             |0           |0           |Do alto          |
| 0             |0           |1           |Do               |
| 0             |1           |0           |Re               |
| 0             |1           |1           |Fa               |
| 1             |0           |0           |Mi               |
| 1             |0           |1           |Sol              |
| 1             |1           |0           |La               |
| 1             |1           |1           |Si               |

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/IMG-20250722-WA0013.jpg" />
</p>

A continuación, a través de un Diagrama ASM, se sintetiza las combinaciones determinadas para cada nota, además, de su respectivo diagrama de maquina de estados finitos y diagrama rtl.

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/Diagrama_ASM.drawio.png" />
</p>

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/Diagrama_MEF_botones.drawio.png" />
</p>

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/IMG-20250722-WA0012.jpg" />
</p>

## Contador de pulsos

### Caracterización del sistema físico

Para simular la boquilla de la trompeta, se utiliza una aspa que tiene un iman en uno de sus extremos, que corresponde luego a un circuito con un sensor de Efecto Hall, que funciona como circuito abierto al estar en la cercanía del imán, esto con el final de generar una discontinuidad cada vez que este complete una revolución: Entrega una señal cuadarda con cierta frecuencia. AL montar y probar el sistema, se determina que la frecuencia máxima que alcanza es de 50 Hz, además de brondar una señal de rápido tiempo de bajada, por lo cuál, no se considera necearia la determinación de un tiempo de mantenimiento.

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/Sensor_efecto_hall.PNG" />
</p>

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/IMG-20250723-WA0006.jpg" />
</p>

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/IMG-20250723-WA0007.jpg" />
</p>


Con el sistema _transductor_ físico ya implemetado, se busca establecer una sería de límites en el número de pulsos en cierto intervalo de tiempo, para determinar la octava a utilizar.

> Una octava, en el contexto de la música, es una nota musical con un afrecuencia mínima de 2:1 (o vicerevrsa) referente a la otra. A efectos de percepción, la nota es la misma, pero más águda o grave.

Para el sistema de conteo se propone, esencialemnte, dos módulos:

- Un temporizador
- Un contador

El primero, fijado en un segundo, permite limitar el tiempo de conteo (o ciclo) sobre el cual se efectua el conteo. Al llegar al timempo determinado, este llega nuevamente a cero, y se repite indefinidamente. El segundo, en cada ciclo, efectua un incremento cuando el nivel de la señal recibida llega a bajo (Una vuelta de la aspa). Estos dependen del pulso de reloj de la FPGA, de mayor velocidad comparado a la frecuencia máxima alcanzada, por lo que no se preveén problemas de discontinuidad en el conteo.

Al llegar al límite del temporizador, se definen los límites a partir de la frecuencia máxima. Como se determinó en la caraterización, el máximo de vueltas que alcanza la aspa son de 50 por segundo, por lo que se definen 4 intervalos de octava, con los siguiente sidentificadores:

| Pulsos contados    | Código identificador |
|--------------------|----------------------|
| 0 a 15 pulsos      | 2                    |
| 16 a 30 pulsos     | 3                    |
| Más de 30 pulsos   | 4                    |

Luego de ese proceso, se guarda el identificador de octava, y se envia por UART; tanto el contador como el temporizador va a 0. El identificador sive de manera que, a través de la siguiente formula, puede pasarse de un código de nota MIDI base a su nota correspondiente:

```
nota_base + octava * 12
```

A continuación, se muestra el diagrama ASM que sintetiza el proceso con su respectivo diagrama de máquina de estados finitos y diagrama rtl.

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/Diagrama_ASM_contador_de_pulsos.drawio%20(1).png" />
</p>

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/Diagrama_MEF_contador_de_pulsos.drawio.png" />
</p>

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/IMG-20250722-WA0019.jpg" />
</p>

# Diseño de prototipo

Para el desarrollo integral del proyecto, se diseñó, modeló e implementó un prototipo utilizando impresión 3D. Este diseño tiene como propósito proteger y almacenar los componentes de hardware utilizados en la aplicación: la hélice encargada de captar los pulsos, los botones que generan un código binario traducido en notas musicales, las tarjetas de desarrollo (ESP32 y FPGA) y el sistema de alimentación, compuesto por una batería externa (power bank).

Inicialmente, el modelo fue concebido como una caja dividida en tres secciones: alimentación, sensores y sistema de control del circuito. No obstante, con el objetivo de optimizar el espacio y mejorar la funcionalidad, se rediseñó en dos secciones: una destinada a la alimentación, y otra en forma de escalón que permite una conexión eficiente entre la ESP32 y la FPGA, facilitando además el acceso a los pines necesarios para conectar tanto el módulo de la hélice como el de los pulsadores.

Adicionalmente, se incorporaron dos elementos estéticos en la parte frontal y posterior del prototipo, con el fin de simular la forma de una trompeta real y así reforzar la identidad musical del dispositivo.

<p align="center">
<img alt="image" src="https://github.com/SantiH75/Sintetizador-de-Chuck-Digital-1/blob/main/Trompeta_/IMG-20250723-WA0001.jpg" />
</p>
