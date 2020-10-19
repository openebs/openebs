# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**اقرأ هذا باللغة**
[🇩🇪](/translations/README.de.md)	
[🇷🇺](/translations/README.ru.md)	
[🇹🇷](/translations/README.tr.md)	
[🇺🇦](/translations/README.ua.md)	
[🇨🇳](/translations/README.zh.md)	
[🇫🇷](/translations/README.fr.md)

**[لغات اخرى](/translations/#readme).**

**OpenEBS** هو حل التخزين مفتوح المصدر الأكثر انتشارًا وسهل الاستخدام لـ Kubernetes.

**OpenEBS** هو مثال مفتوح المصدر رائد لفئة من حلول التخزين تسمى أحيانًا [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** مدرج كمثال مفتوح المصدر في ملف [CNCF Storage Landscape White Paper](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) تحت حلول التخزين فائقة التقارب.

بعض الجوانب الرئيسية التي تجعل OpenEBS مختلفًا عن حلول التخزين التقليدية الأخرى:
- تم إنشاؤه باستخدام بنية الخدمات الدقيقة مثل التطبيقات التي تخدمها. يتم نشر OpenEBS نفسها كمجموعة من الحاويات على عقد Kubernetes العاملة. يستخدم Kubernetes نفسه لتنظيم وإدارة مكونات OpenEBS
- مدمج بالكامل في مساحة المستخدمين مما يجعله قابلاً للنقل للغاية ليتم تشغيله عبر أي نظام تشغيل / نظام أساسي
- يحركها النية تمامًا ، وترث نفس المبادئ التي تعزز سهولة الاستخدام مع Kubernetes
- يدعم OpenEBS مجموعة من محركات التخزين بحيث يمكن للمطورين نشر تقنية التخزين المناسبة لأهداف تصميم تطبيقاتهم. يمكن للتطبيقات الموزعة مثل Cassandra استخدام محرك LocalPV لكتابة أقل زمن انتقال. يمكن للتطبيقات الأحادية مثل MySQL و PostgreSQL استخدام محرك ZFS (cStor) من أجل المرونة. يمكن لتطبيقات البث مثل Kafka استخدام محرك NVMe [Mayastor](https://github.com/openebs/Mayastor) للحصول على أفضل أداء في البيئات المتطورة. عبر أنواع المحركات ، يوفر OpenEBS إطارًا ثابتًا للإتاحة العالية واللقطات والنسخ وإمكانية الإدارة.

يتم نشر OpenEBS نفسه باعتباره مجرد حاوية أخرى على مضيفك ويمكّن خدمات التخزين التي يمكن تخصيصها على مستوى كل جراب أو تطبيق أو مجموعة أو حاوية ، بما في ذلك:
- أتمتة إدارة التخزين المرفقة بعقد عمال Kubernetes والسماح باستخدام التخزين للتزويد الديناميكي لـ OpenEBS PVs أو PVs المحلية.
- استمرار البيانات عبر العقد ، مما يقلل بشكل كبير من الوقت الذي يقضيه في إعادة بناء حلقات كاساندرا على سبيل المثال.
- مزامنة البيانات عبر مناطق التوفر وموفري الخدمات السحابية مما يحسن التوافر ويقلل من أوقات الربط / الفصل على سبيل المثال.
- طبقة شائعة ، سواء كنت تعمل على AKS ، أو المعدن المكشوف ، أو GKE ، أو AWS - فإن تجربة الأسلاك والمطور الخاصة بك لخدمات التخزين متشابهة قدر الإمكان.
- إدارة التدريج من وإلى S3 والأهداف الأخرى.

ميزة إضافية لكونه حلًا أصليًا تمامًا لـ Kubernetes هو أنه يمكن للمسؤولين والمطورين التفاعل وإدارة OpenEBS باستخدام جميع الأدوات الرائعة المتوفرة لـ Kubernetes مثل kubectl و Helm و Prometheus و Grafana و Weave Scope وما إلى ذلك.

** رؤيتنا ** بسيطة: دع خدمات التخزين والتخزين لأحمال العمل المستمرة تتكامل بشكل كامل في البيئة بحيث يستفيد كل فريق وعبء عمل من دقة التحكم وسلوك Kubernetes الأصلي.

## قابلية التوسع

مكن لـ OpenEBS أن يتوسع ليشمل عددًا كبيرًا بشكل تعسفي من وحدات تحكم التخزين في حاويات. يتم استخدام Kubernetes لتوفير القطع الأساسية مثل استخدام etcd للمخزون. يتوسع OpenEBS إلى الحد الذي يقيس فيه Kubernetes.

## التثبيت والبدء

يمكن إعداد OpenEBS في بضع خطوات سهلة. يمكنك البدء في اختيارك لمجموعة Kubernetes من خلال تثبيت open-iscsi على عقد Kubernetes وتشغيل مشغل openebs باستخدام kubectl

**Start the OpenEBS Services using operator**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Start the OpenEBS Services using helm**
```bash

## قابلية التوسع

يمكن لـ OpenEBS أن يتوسع ليشمل عددًا كبيرًا بشكل تعسفي من وحدات تحكم التخزين في حاويات. يتم استخدام Kubernetes لتوفير القطع الأساسية مثل استخدام etcd للمخزون. يتوسع OpenEBS إلى الحد الذي يقيس فيه Kubernetes.

## التثبيت والبدء

يمكن إعداد OpenEBS في بضع خطوات سهلة. يمكنك البدء في اختيارك لمجموعة Kubernetes من خلال تثبيت open-iscsi على عقد Kubernetes وتشغيل مشغل openebs باستخدام kubectl

**Start the OpenEBS Services using operator**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Start the OpenEBS Services using helm**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

يمكنك أيضًا متابعة [QuickStart Guide](https://docs.openebs.io/docs/overview.html).

يمكن نشر OpenEBS على أي مجموعة Kubernetes - سواء في السحابة أو في مكان العمل أو كمبيوتر محمول للمطورين (minikube). لاحظ أنه لا توجد تغييرات على النواة الأساسية المطلوبة لأن OpenEBS يعمل في مساحة المستخدمين. يرجى اتباع وثائق [OpenEBS Setup](https://docs.openebs.io/docs/overview.html). أيضًا ، لدينا بيئة Vagrant المتاحة والتي تتضمن نموذجًا لنشر Kubernetes وحمل تركيبي يمكنك استخدامه لمحاكاة أداء OpenEBS. قد تجد أيضًا مشروعًا مثيرًا للاهتمام يسمى Litmus (https://litmuschaos.io) والذي يساعد في هندسة الفوضى لأعباء العمل ذات الحالة على Kubernetes

## الحالة

OpenEBS هي واحدة من البنى التحتية للتخزين Kubernetes الأكثر استخدامًا واختبارًا في الصناعة. مشروع CNCF Sandbox منذ مايو 2019 ، OpenEBS هو نظام التخزين الأول والوحيد الذي يوفر مجموعة متسقة من إمكانيات التخزين المحددة بالبرمجيات على العديد من الخلفيات الخلفية (local و nfs و zfs و nvme) عبر كل من الأنظمة المحلية والسحابة ، وكان أول من فتح المصدر إطار عمل Chaos Engineering الخاص بأحمال العمل ذات الحالة ، the [Litmus Project](https://litmuschaos.io) ، الذي يعتمد عليه المجتمع لتقييم الجاهزية تلقائيًا للإيقاع الشهري لإصدارات OpenEBS. يستخدم عملاء المؤسسات OpenEBS في الإنتاج منذ عام 2018 ويدعم المشروع 2.5M + docker يسحب في الأسبوع.

يتم توفير حالة محركات التخزين المختلفة التي تشغل وحدات التخزين الثابتة OpenEBS أدناه. يتم تلخيص الفرق الرئيسي بين الحالات أدناه:
- **alpha:** قد تتغير واجهة برمجة التطبيقات (API) بطرق غير متوافقة في إصدار لاحق للبرامج دون إشعار ، ويوصى باستخدامها فقط في مجموعات الاختبار قصيرة العمر ، بسبب زيادة خطر حدوث أخطاء ونقص الدعم على المدى الطويل.
- **beta**: لن يتم إسقاط دعم الميزات العامة ، على الرغم من أن التفاصيل قد تتغير. سيتم توفير الدعم للترقية أو الترحيل بين الإصدارات ، إما من خلال الأتمتة أو الخطوات اليدوية.
- **stable**: ستظهر الميزات في البرامج التي تم إصدارها للعديد من الإصدارات اللاحقة وسيتم توفير الدعم للترقية بين الإصدارات بأتمتة البرامج في الغالبية العظمى من السيناريوهات.


| Storage Engine | الحالة | تفاصيل |
|---|---|---|
| Jiva | stable | الأنسب لتشغيل التخزين المتماثل للكتل على العقد التي تستخدم التخزين المؤقت على عقد عمال Kubernetes |
| cStor | beta | خيار مفضل للتشغيل على العقد التي تحتوي على أجهزة حظر. الخيار الموصى به إذا كانت اللقطات والنسخ مطلوبة |
| Local Volumes | beta | الأنسب للتطبيق الموزع الذي يحتاج إلى تخزين بزمن انتقال منخفض - تخزين متصل مباشرة من عُقد Kubernetes. |
| Mayastor | alpha | محرك تخزين جديد يعمل بكفاءة التخزين المحلي ولكنه يقدم أيضًا خدمات التخزين مثل النسخ المتماثل. التطوير جار لدعم Snapshots and Clones. |

لمزيد من التفاصيل ، يرجى الرجوع إلى [OpenEBS Documentation](https://docs.openebs.io/docs/next/quickstart.html).

## المساهمة

ترحب OpenEBS بتعليقاتك ومساهماتك بأي شكل ممكن.

- [Join OpenEBS community on Kubernetes Slack](https://kubernetes.slack.com)
  - قمت بالتسجيل بالفعل؟ توجه إلى مناقشاتنا في [#openebs](https://kubernetes.slack.com/messages/openebs/)
- هل تريد إثارة مشكلة أو المساعدة في الإصلاحات والميزات؟
  - نرى [open issues](https://github.com/openebs/openebs/issues)
  - نرى [contributing guide](./CONTRIBUTING.md)
  - تريد الانضمام إلى اجتماعات مجتمع المساهمين لدينا, [check this out](./community/README.md).
- انضم الينا OpenEBS CNCF Mailing lists
  - لتحديثات مشروع OpenEBS ، اشترك في [OpenEBS Announcements](https://lists.cncf.io/g/cncf-openebs-announcements)
  - للتفاعل مع مستخدمي OpenEBS الآخرين ، اشترك في [OpenEBS Users](https://lists.cncf.io/g/cncf-openebs-users)

## أرني the Code
هذا هو meta-repository لـ OpenEBS. يرجى البدء بـ pinned repositories أو بـ [OpenEBS Architecture](./contribute/design/README.md) وثيقة. 

## رخصة

تم تطوير OpenEBS بموجب ترخيص [Apache License 2.0] (https://github.com/openebs/openebs/blob/master/LICENSE) على مستوى المشروع. بعض مكونات المشروع مستمدة من مشاريع أخرى مفتوحة المصدر ويتم توزيعها بموجب تراخيص كل منها.

OpenEBS هو جزء من CNCF Projects
[![CNCF Sandbox Project](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)

## العروض التجارية

هذه قائمة بشركات الجهات الخارجية والأفراد الذين يقدمون منتجات أو خدمات ذات صلة بـ OpenEBS. OpenEBS هي شركة CNCF project  التي لا تدعم أي شركة. القائمة مرتبة حسب الترتيب الأبجدي
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Gridworkz Cloud Services](https://gridworkz.com/)
- [MayaData](https://mayadata.io/)






# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)
