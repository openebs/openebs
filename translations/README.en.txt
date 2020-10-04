• OpenEBS

[! [Liberaciones] (https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)] (https://github.com/openebs/openebs/releases)
[! [#openebs canal de Slack] (https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)] (https://kubernetes.slack.com/messages/openebs)
[! [Twitter] (https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)] (https://twitter.com/intent/follow?screen_name=openebs)
[! [Bienvenidos a los PRP] (https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)] (https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[! [Estado FOSSA] (https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)] (https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[! [Prácticas recomendadas de CII] (https://bestpractices.coreinfrastructure.org/projects/1754/badge)] (https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**OpenEBS** es la solución de almacenamiento de código abierto más ampliamente implementada y fácil de usar para Kubernetes.

**OpenEBS** es el ejemplo de código abierto líder de una categoría de soluciones de almacenamiento a veces llamada [Almacenamiento adjunto de contenedores](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** aparece como un ejemplo de código abierto en el [Papel técnico sobre el paisaje de almacenamiento CNCF](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) bajo las soluciones de almacenamiento hiperconverged.

Algunos aspectos clave que hacen que OpenEBS sea diferente en comparación con otras soluciones de almacenamiento tradicionales:
- Construido utilizando la arquitectura de microservicios como las aplicaciones a las que sirve. OpenEBS se implementa como un conjunto de contenedores en nodos de trabajo de Kubernetes. Utiliza Kubernetes para orquestar y gestionar componentes OpenEBS
- Construido completamente en el espacio de usuario por lo que es altamente portátil para ejecutar a través de cualquier sistema operativo / plataforma
- Completamente impulsado por la intención, heredando los mismos principios que impulsan la facilidad de uso con Kubernetes
- OpenEBS es compatible con una gama de motores de almacenamiento para que los desarrolladores puedan implementar la tecnología de almacenamiento adecuada a sus objetivos de diseño de aplicaciones. Las aplicaciones distribuidas como Cassandra pueden utilizar el motor LocalPV para escrituras de latencia más baja. Las aplicaciones monolíticas como MySQL y PostgreSQL pueden utilizar el motor ZFS (cStor) para la resiliencia. Las aplicaciones de streaming como Kafka pueden utilizar el motor NVMe [Mayastor](https://github.com/openebs/Mayastor) para obtener el mejor rendimiento en entornos perimetrales. En todos los tipos de motor, OpenEBS proporciona un marco coherente para alta disponibilidad, instantáneas, clones y capacidad de administración.

OpenEBS se implementa como un contenedor más en el host y habilita los servicios de almacenamiento que se pueden designar en un nivel por pod, aplicación, clúster o contenedor, incluidos:
- Automatizar la gestión del almacenamiento conectado a los nodos de trabajo de Kubernetes y permitir que el almacenamiento se utilice para aprovisionar dinámicamente PVs OpenEBS o CV locales.
- Persistencia de datos entre nodos, lo que reduce drásticamente el tiempo dedicado a reconstruir anillos Cassandra, por ejemplo.
- Sincronización de datos entre zonas de disponibilidad y proveedores de nube mejorando la disponibilidad y disminuyendo los tiempos de solicitud/desconexión, por ejemplo.
- Una capa común, por lo que si se está ejecutando en AKS, o su metal desnudo, O GKE, o AWS - su experiencia de cableado y desarrollador para los servicios de almacenamiento es lo más similar posible.
- Gestión de niveles hacia y desde S3 y otros objetivos.

Una ventaja añadida de ser una solución nativa completamente Kubernetes es que los administradores y desarrolladores pueden interactuar y gestionar OpenEBS utilizando todas las maravillosas herramientas que están disponibles para Kubernetes como kubectl, Helm, Prometheus, Grafana, Weave Scope, etc.

**Nuestra visión** es simple: permita que los servicios de almacenamiento y almacenamiento para cargas de trabajo persistentes se integren completamente en el entorno para que cada equipo y carga de trabajo se beneficie de la granularidad del control y el comportamiento nativo de Kubernetes.

• *Leer esto en [otros idiomas](traducciones/TRANSLATIONS.md).*

[🇩🇪] (traducciones/README.de.md)
[🇷🇺] (traducciones/README.ru.md)
[🇹🇷] (traducciones/README.tr.md)
[🇺🇦] (traducciones/README.ua.md)
[🇨🇳] (traducciones/README.zh.md)
[🇫🇷] (traducciones/README.fr.md)

• Escalabilidad

OpenEBS puede escalar para incluir un gran número arbitrariamente de controladores de almacenamiento en contenedores. Kubernetes se utiliza para proporcionar piezas fundamentales como el uso de etcd para el inventario. OpenEBS escala en la medida en que sus escalas de Kubernetes.

• Instalación y introducción

OpenEBS se puede configurar en unos sencillos pasos. Puede ponerse en marcha en su elección del clúster de Kubernetes teniendo open-iscsi instalado en los nodos de Kubernetes y ejecutando el openebs-operator mediante kubectl.

**Iniciar los servicios de OpenEBS utilizando el operador**
'''bash
• Aplicar este yaml
kubectl aplicar -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Iniciar los servicios de OpenEBS con el timón**
'''bash
actualización del repositorio del timón
helm install --namespace openebs --name openebs stable/openebs
```

También puede seguir nuestra [Guía de inicio rápido](https://docs.openebs.io/docs/overview.html).

OpenEBS se puede implementar en cualquier clúster de Kubernetes, ya sea en la nube, en las instalaciones o en el equipo portátil para desarrolladores (minikube). Tenga en cuenta que no hay cambios en el kernel subyacente que sean necesarios ya que OpenEBS opera en el espacio de usuario. Siga nuestra documentación de [OpenEBS Setup](https://docs.openebs.io/docs/overview.html). Además, tenemos un entorno Vagrant disponible que incluye una implementación de Kubernetes de ejemplo y carga sintética que puede usar para simular el rendimiento de OpenEBS. También puede encontrar interesante el proyecto relacionado llamado Litmus (https://litmuschaos.io) que ayuda con la ingeniería del caos para cargas de trabajo con estado en Kubernetes.

• Estado

OpenEBS es una de las infraestructuras de almacenamiento de Kubernetes más utilizadas y probadas en la industria. Un proyecto CNCF Sandbox desde mayo de 2019, OpenEBS es el primer y único sistema de almacenamiento en los sistemas locales y en la nube, y fue el primero en abrir su propio Marco de Ingeniería de Caos para cargas de trabajo con estado, el [Proyecto Litmus](https://litmuschaos.io), en el que la comunidad confía para evaluar automáticamente la cadencia mensual de OpenEBS. Los clientes empresariales han estado utilizando OpenEBS en producción desde 2018 y el proyecto admite tiradores de acopladores de 2.5M+ a la semana.

A continuación se proporciona el estado de varios motores de almacenamiento que alimentan los volúmenes persistentes de OpenEBS. La diferencia clave entre los estados se resume a continuación:
- **alpha:** La API puede cambiar de manera incompatible en una versión posterior del software sin previo aviso, recomendada para su uso solo en clústeres de pruebas de corta duración, debido al mayor riesgo de errores y la falta de soporte a largo plazo.
- **beta**: El soporte para las características generales no se eliminará, aunque los detalles pueden cambiar. Se proporcionará compatibilidad para actualizar o migrar entre versiones, ya sea mediante la automatización o pasos manuales.
- **stable**: Las características aparecerán en el software lanzado para muchas versiones posteriores y el soporte para la actualización entre versiones se proporcionará con automatización de software en la gran mayoría de escenarios.

| Motor de almacenamiento de información ? Estado ? Detalles ?
|---|---|---|
| Jiva ? estables ? Es el más adecuado para ejecutar almacenamiento de bloques replicados en nodos que utilizan el almacenamiento efímero en los nodos de trabajo de Kubernetes.
| cStor ? beta ? Una opción preferida para ejecutarse en nodos que tienen dispositivos de bloque. Opción recomendada si se requieren Instantáneas y Clones .
| Volúmenes locales ? beta ? Más adecuado para aplicaciones distribuidas que necesitan almacenamiento de baja latencia: almacenamiento con conexión directa desde los nodos de Kubernetes. |
| Mayastor ? alfa ? Un nuevo motor de almacenamiento que funciona con la eficiencia del almacenamiento local, pero también ofrece servicios de almacenamiento como replicación. El desarrollo está en marcha para admitir instantáneas y clones. |

Para obtener más información, consulte [Documentación de OpenEBS](https://docs.openebs.io/docs/next/quickstart.html).

• Contribuir

OpenEBS da la bienvenida a sus comentarios y contribuciones en cualquier forma posible.

- [Unirse a la comunidad OpenEBS en Kubernetes Slack](https://kubernetes.slack.com)
- ¿Ya te has registrado? Dirígete a nuestras discusiones en [#openebs](https://kubernetes.slack.com/messages/openebs/)
- ¿Quieres plantear un problema o ayudar con las correcciones y características?
- Ver [problemas abiertos](https://github.com/openebs/openebs/issues)
- Ver [guía colaboradora](./CONTRIBUTING.md)
- Quieres unirte a nuestras reuniones de la comunidad de colaboradores, [echa un vistazo a esto](./community/README.md).
- Unirse a nuestras listas de correo OpenEBS CNCF
- Para actualizaciones de proyectos OpenEBS, suscríbete a [Anuncios OpenEBS](https://lists.cncf.io/g/cncf-openebs-announcements)
- Para interactuar con otros usuarios de OpenEBS, suscríbete a [Usuarios de OpenEBS](https://lists.cncf.io/g/cncf-openebs-users)

• Muéstrame el código

Este es un meta-repositorio para OpenEBS. Comience con los repositorios anclados o con el documento [OpenEBS Architecture](./contribute/design/README.md). 

• Licencia

OpenEBS se desarrolla bajo la licencia [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE) en el nivel del proyecto. Algunos componentes del proyecto se derivan de otros proyectos de código abierto y se distribuyen bajo sus respectivas licencias.

OpenEBS forma parte de los Proyectos CNCF.

[! [Proyecto de caja de arena CNCF] (https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)] (https://landscape.cncf.io/selected=open-ebs)

• Ofertas Comerciales

Esta es una lista de terceras empresas e individuos que proporcionan productos o servicios relacionados con OpenEBS. OpenEBS es un proyecto CNCF que no respalda a ninguna empresa. La lista se proporciona en orden alfabético.
- [Clouds Sky GmbH](https://cloudssky.com/es/)
- [CodeWave](https://codewave.eu/)
- [Servicios en la nube de Gridworkz](https://gridworkz.com/)
- [MayaData](https://mayadata.io/)
