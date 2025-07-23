<!-- LTeX: enabled=true language=es -->
<!-- :set spell! -->
<!-- :MarkdownPreview -->
<!-- :GenTocMarked -->

# Ejemplo de chuck

Para ejecutar el ejemplo de ChucK con comunicación OSC,
ejecute el siguiente comando. Este inicia ChucK como servicio,
permitiendo recibir e interpretar datos de red como notas MIDI.

```bash
# Recuerde ejecutar el comando en el directorio ./chuck/
ls -l # listar el contenido
```
```bash
# Resultado:
# chuck  osc_piano.ck  osc_piano_flauta.ck  README.md
```

```bash
./chuck osc_piano_flauta.ck # lanzar el servicio # lanzar el servicio
```
