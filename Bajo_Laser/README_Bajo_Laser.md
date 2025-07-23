# Bajo Láser - Electrónica Digital I

El presente repositorio describe el desarrollo de un "bajo láser" como componente del sintetizador digital diseñado para la asignatura Electrónica Digital I. El grupo estÁ conformado por:

- Jorge Hernan Arango Barragan
- Juan Felipe Gaitan Nocua
- Luciano Manrique Medina
- Samuel Mahecha Arango

El sistema se compone de cuatro módulos láser de punto (650 nm, 6 mm, 5 V, 5 mW, color rojo), orientados hacia cuatro sensores LDR (Sensores de luminosidad con fotoresistencia de salida digital). Cada sensor LDR entrega una señal de nivel alto cuando no se detecta una intensidad luminosa suficiente. Dicho umbral que puede ajustarse directamente en el módulo mediante un trimmer. Esta configuración permite que los haces láser funcionen como “cuerdas virtuales”, en donde al interrumpir alguno de ellos, el correspondiente LDR activa una señal de nivel alto, la cual es enviada directamente a la FPGA (BlackIce40), simulando el efecto de pulsar una cuerda en un instrumento tradicional, en este caso el de un bajo.

Además, se incorpora un potenciómetro en un divisor de tensión que genera una señal analógica proporcional a su resistencia. Esta señal es digitalizada mediante el ADC de un ESP32 y convertida a un número binaria de 10 bits, que se transfiere a la FPGA. El valor binario representa la "altura" sobre el mástil de un bajo, permitiendo modificar la frecuencia de la nota según la tensión recibida, tal como ocurre al presionar una cuerda en diferentes trastes.

## Requerimientos Funcionales

1. El sistema debe detectar 



