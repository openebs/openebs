# المساهمة في OpenEBS
عظيم!! نحن نبحث دائمًا عن المزيد من OpenEBS hackers. يمكنك البدء بقراءة هذا [overview](./contribute/design/README.md)

أولاً ، إذا كنت غير متأكد أو تخشى أي شيء ، فما عليك سوى طرح المشكلة أو إرسالها أو سحب الطلب على أي حال. لن تصرخ على بذل قصارى جهدك. أسوأ ما يمكن أن يحدث هو أنه سيُطلب منك بأدب تغيير شيء ما. نحن نقدر أي نوع من المساهمات ولا نريد جدارًا من القواعد يعيق ذلك.

ومع ذلك ، بالنسبة لأولئك الأفراد الذين يريدون المزيد من الإرشادات حول أفضل طريقة للمساهمة في المشروع ، تابع القراءة. سيغطي هذا المستند جميع النقاط التي نبحث عنها في مساهماتك ، مما يزيد من فرصك في دمج مساهماتك أو معالجتها بسرعة.

ومع ذلك ، فإن OpenEBS هو ابتكار في المصدر المفتوح. نرحب بك للمساهمة بأي طريقة ممكنة وكل المساعدة المقدمة محل تقدير كبير.

- [Raise issues to request new functionality, fix documentation or for reporting bugs.](#raising-issues)
- [Submit changes to improve documentation.](#submit-change-to-improve-documentation) 
- [Submit proposals for new features/enhancements.](#submit-proposals-for-new-features)
- [Solve existing issues related to documentation or code.](#contributing-to-source-code-and-bug-fixes)

هناك بعض الإرشادات البسيطة التي يجب عليك اتباعها قبل تقديم hacks الخاص بك

## إثارة القضايا

عند إثارة المشكلات ، يرجى تحديد ما يلي:
- يجب ملء تفاصيل الإعداد كما هو محدد في نموذج المشكلة بوضوح لكي يتحقق المراجع.
- سيناريو حيث حدثت المشكلة (مع تفاصيل حول كيفية إعادة إنتاجها).
- الأخطاء وتسجيل الرسائل التي يتم عرضها بواسطة البرنامج.
- أي تفاصيل أخرى قد تكون مفيدة.

## إرسال التغيير لتحسين التوثيق

الحصول على الوثائق الصحيحة صعب! الرجوع إلى هذا [page](./contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) لمزيد من المعلومات حول كيفية تحسين وثائق المطور عن طريق إرسال طلبات السحب بالعلامات المناسبة. إليك [list of tags](./contribute/labels-of-issues.md) التي يمكن استخدامها لنفسها. ساعدنا في الحفاظ على وثائقنا نظيفة وسهلة الفهم ويمكن الوصول إليها.

## قم بإرسال مقترحات للميزات الجديدة

هناك دائمًا ما هو مطلوب أكثر ، لتسهيل ملاءمة حالات الاستخدام الخاصة بك. لا تتردد في الانضمام إلى المناقشة حول الميزات الجديدة أو رفع PR بالتغيير المقترح.

- [Join OpenEBS community on Kubernetes Slack](https://kubernetes.slack.com)
	- Already signed up? توجه إلى مناقشاتنا في [#openebs](https://kubernetes.slack.com/messages/openebs/)

## المساهمة في Source Code و Bug Fixes

قم بتزويد PRs بعلامات tags مناسبة لـ bug fixes أو enhancements إلى source code. للحصول على قائمة tags التي يمكن استخدامها ، راجع
[this](./contribute/labels-of-issues.md).

* للمساهمة في K8s demo, يرجى الرجوع إلى هذا [document](./contribute/CONTRIBUTING-TO-K8S-DEMO.md).
    - للتحقق من كيفية عمل OpenEBS مع K8s, الرجوع إلى هذا [document](./k8s/README.md) 
- للمساهمة في Kubernetes OpenEBS Provisioner ، يرجى الرجوع إلى هذا [document](./contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).
    
الرجوع إلى هذا [document](./contribute/design/code-structuring.md) لمزيد من المعلومات حول هيكلة الكود والمبادئ التوجيهية لاتباعها.


## حل المشكلات الموجودة
رئيس لأكثر من [issues](https://github.com/openebs/openebs/issues) للعثور على المشكلات التي تتطلب المساعدة من المساهمين. انظر لدينا [list of labels guide](./contribute/labels-of-issues.md) لمساعدتك في العثور على المشكلات التي يمكنك حلها بشكل أسرع

يمكن لأي شخص يتطلع إلى المساهمة أن يتعامل مع مشكلة من خلال المطالبة بأنها comment / assign GitHub ID لها. في حالة عدم وجود PR أو تحديث قيد التقدم لمدة أسبوع حول المشكلة المذكورة ، يتم إعادة فتح المشكلة لأي شخص لتناولها مرة أخرى. نحن بحاجة إلى النظر في القضايا ذات الأولوية العالية / الانحدارات حيث يجب أن يكون وقت الاستجابة يومًا أو نحو ذلك.

---
### التوقيع على عملك

نستخدم Developer Certificate of Origin (DCO) كإجراء وقائي إضافي لمشروع OpenEBS. هذه آلية راسخة ومستخدمة على نطاق واسع لضمان تأكيد المساهمين على حقهم في ترخيص مساهمتهم بموجب ترخيص المشروع. يرجى القراءة [developer-certificate-of-origin](./contribute/developer-certificate-of-origin).

إذا كان بإمكانك التصديق عليها ، فما عليك سوى إضافة سطر إلى كل رسالة git الالتزام:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````
or use the command `git commit -s -m "commit message comes here"` to sign-off on your commits.

استخدم اسمك الحقيقي (sorry ,no pseudonyms or anonymous contributions). إذا قمت بتعيين ملف `user.name` و `user.email` git configs, يمكنك sign الخاص بك commit تلقائيًا باستخدام `git commit -s`. تستطيع ايضا استخذام git [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) like `git config --global alias.ci 'commit -s'`. يمكنك الآن الالتزام بـ `git ci` وسيتم توقيع الالتزام.

---

## انضم إلى مجتمعنا

إذا كنت ترغب في تطوير مجتمع OpenEBS والمساهمة فيه ، فارجع إلى هذا [document](./community/README.md).
