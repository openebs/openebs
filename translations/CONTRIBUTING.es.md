# Contribuir a OpenEBS

¡¡Gran!! Siempre estamos en la búsqueda de más hackers OpenEBS. Puede comenzar leyendo esta [overview](./contribute/design/README.md)

En primer lugar, si no está seguro o tiene miedo de algo, simplemente pregunte o envíe el problema o solicitud de extracción de todos modos. No te gritarán por dar tu mejor esfuerzo. Lo peor que puede pasar es que te pidan educadamente que cambies algo. Apreciamos cualquier tipo de contribuciones y no queremos que un muro de reglas se ponga en el camino de eso.

Sin embargo, para aquellas personas que quieren un poco más de orientación sobre la mejor manera de contribuir al proyecto, siga leyendo. Este documento cubrirá todos los puntos que estamos buscando en sus contribuciones, aumentando sus posibilidades de fusionarse rápidamente o abordar sus contribuciones.

Dicho esto, OpenEBS es una innovación en código abierto. Le invitamos a contribuir de cualquier manera que pueda, y toda la ayuda proporcionada es muy apreciada. 

- [Plantee problemas para solicitar nuevas funciones, corregir documentación o informar errores.](#raising-issues)
- [Envíe cambios para mejorar la documentación.](#submit-change-to-improve-documentation) 
- [Envíe propuestas para nuevas funciones / mejoras.](#submit-proposals-for-new-features)
- [Resuelva problemas existentes relacionados con la documentación o el código.](#contributing-to-source-code-and-bug-fixes)

Hay algunas pautas simples que debe seguir antes de proporcionar sus hacks. 

## Aumento de problemas

Al plantear problemas, especifique lo siguiente:
- Los detalles de configuración deben rellenarse como se especifica en la plantilla de emisión claramente para que el revisor la compruebe.
- Un escenario en el que se produjo el problema (con detalles sobre cómo reproducirlo).
- Errores y mensajes de registro que se muestran por el software.
- Cualquier otro detalle que pueda ser útil.

## Enviar cambios para mejorar la documentación

¡Conseguir la documentación correcta es difícil! Consulte esta [página](./contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) para obtener más información sobre cómo podría mejorar la documentación del desarrollador enviando solicitudes de extracción con etiquetas adecuadas. Aquí hay una [lista de etiquetas](./contribute/labels-of-issues.md) que se podría usar para la misma. Ayúdenos a mantener nuestra documentación limpia, fácil de entender y accesible.

## Enviar propuestas para nuevas características

Siempre hay algo más que se requiere para que sea más fácil adaptarse a sus casos de uso. Siéntase libre de unirse a la discusión sobre nuevas características o plantear un PR con su cambio propuesto. 

- [Unirse a la comunidad OpenEBS en Kubernetes Slack](https://kubernetes.slack.com)
	- ¿Ya te has registrado? Dirígete a nuestras discusiones en [#openebs](https://kubernetes.slack.com/messages/openebs/)
	
## Contribuir al código fuente y a las correcciones de errores

Proporcione a los archivos P etiquetas las etiquetas adecuadas para correcciones de errores o mejoras en el código fuente. Para obtener una lista de las etiquetas que se podrían utilizar, consulte [this](./contribute/labels-of-issues.md).

* Para contribuir a la demostración de K8s, consulte este [documento](./contribute/CONTRIBUTING-TO-K8S-DEMO.md).
  - Para comprobar cómo funciona OpenEBS con K8, consulte este [documento](./k8s/README.md)
- Para contribuir a Kubernetes OpenEBS Provisioner, consulte este [documento](./contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).

Consulte este [documento](./contribute/design/code-structuriing.md) para obtener más información sobre la estructuración de código y las directrices a seguir en el mismo.

## Resolver problemas existentes
Dirígete a [issues](https://github.com/openebs/openebs/issues) para encontrar problemas donde se necesita ayuda de los colaboradores. Consulte nuestra [guía de etiquetas](./contribute/labels-of-issues.md) para ayudarle a encontrar problemas que puede resolver más rápido.

Una persona que desee contribuir puede ocupar un problema asignándolo como un comentario/asignar su ID de GitHub a él. En caso de que no haya relaciones públicas o actualizaciones en curso durante una semana sobre dicho problema, el problema se reabre para que alguien vuelva a ocuparse. Tenemos que considerar problemas/regresiones de alta prioridad donde el tiempo de respuesta debe ser un día más o menos.

---
### Firma tu trabajo

Utilizamos el Certificado de Origen para Desarrolladores (DCO) como una salvaguardia adicional para el proyecto OpenEBS. Se trata de un mecanismo bien establecido y ampliamente utilizado para asegurar que los contribuyentes hayan confirmado su derecho a licenciar su contribución bajo la licencia del proyecto. Lea [developer-certificate-of-origin](./contribute/developer-certificate-of-origin).

Si puede certificarlo, simplemente agregue una línea a cada mensaje de confirmación de git:

````
Firmado: Random J Developer <random@developer.example.org>
````
o utilice el comando `git commit -s -m "commit message comes here"` para cerrar la sesión de sus confirmaciones.

Utilice su nombre real (lo siento, sin seudónimos o contribuciones anónimas). Si estableces tus configs git `user.name` y `user.email`, puedes firmar tu confirmación automáticamente con `git commit -s`. También puede utilizar git [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) como `git config --global alias.ci 'commit -s'`. Ahora puede confirmar con `git ci`, y se firmará la confirmación.

---

## Unirse a nuestra comunidad

Desea desarrollar y contribuir a la comunidad OpenEBS activamente, refiérase a este [documento](./community/README.md).
