# Bajo Láser

Este repositorio hace parte del proyecto de un sintetizador que incorpora distintos instrumentos realizados por los estudiantes que se comunican a través de una FPGA y que a través de Chuck se genere música. Específicamente en este repositorio se encuentra un módulo que busca simular un bajo a través de láseres, fotorresistencias y potenciómetros.

El módulo tiene 4 láseres que representan cada una de las cuerdas de un bajo, estos láseres siempre se encuentran encendidos; cuando el usuario interrumpa el haz, la fotorresistencia cambiará su estado y el efecto que tendrá será el de tocar la cuerda. Por otra parte, a través de un potenciometro se modulará la frecuencia, teniendo un comportamiento equivalente a la ubicación/altura en donde se presiona la cuerda.

## Láser como cuerda

Este proyecto busca construir un instrumento digital experimental, donde se tienen unos módulos láser económicos simulan las cuerdas de un bajo eléctrico. Cuando una persona interrumpe uno de estos rayos láser con la mano, se genera una señal que será interpretada como si se hubiese pulsado una cuerda, activando una respuesta digital.

En la carpeta "femtoriscvBase" se tiene el programa funcional en el cual se recibe la señal de los modulos fotoresistores que simula el toque de una cuerda, que en este caso se imprime desde la consola como un numero decimal de 0 a 15. Falta implementar la comunicacion por el protocolo OSC para enviar los datos de las cuerdas a chunk y que por alli mismo se programe la nota, por ahora aleatoria ya que no conocemos si existe alguna libreria de sonidos en chunk en la cual hallan sonidos de bajo.

En la carpeta de ejemplos de desarrollo, especificamente en el archivo "femtoriscvINTENTOS" se tienen los intentos autonomos para la programacion del potenciometro, el cual tendria el objetivo de variar la frecuencia de las notas que han sido tocadas por las cuerdas (las que son funcionales en femtoriscvV2). EL problema que tenemos es que no hemos podido integral el potenciometro a la FPGA asi como lo esta en programa de las cuerdas. Por ahora lo unico que se muestra en consola (al correr mpremote o picocom) son los datos del ADC entre 0 y 1024 datos.





