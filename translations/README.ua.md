# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**OpenEBS** дозволяє використовувати контейнери для додатків, які потребують постійного сховища даних, а також для додатків, які перевіряють стан кластеру, наприклад, Prometheus. OpenEBS надає постійне контейнерне сховище даних та служби схову.
 
**OpenEBS** дозволяє працювати з контейнерізованими додатками, яким необхідно постійне сховище даних, такі як бази даних, так і звичайними контейнерами. Сам OpenEBS розгортається як ще один контейнер на хості й включає в себе служби схову, які можут бути налаштовані для подів, додатків, кластерів або контейнерів. Службы схову включають у себе:

- Зберігання даних на усіх нодах кластеру. Одним з відчутних переваг такого рішення є значне зменшення часу потрібного на відновлення кілець Кассандри.
- Синхронизація даних по достуним зонам й хмарним провайдером, що підвищує доступність даних й скорочує час витрачений  на прикріплення / від'єднання подів.
- Загальний рівень інтеграції. Незалежно від того з якою платформою ви працюєте - AKS, на фізичному сервері, GKE або AWS - відмінності у робочому процесі мінімальні.
- Інтеграція з Kubernetes, яка автоматично зв'язує розробку й роботу додатків з конфігурацією OpenEBS.
- Керування завантаженням даних у та з S3 й у інші системи.

**Наша філософія** проста: служби зберігання й постійне сховище даних повинні легко інтегруватись у будь яку інфраструктуру, щоб будь яка команда розробників або додатку могли повноцінно використовувати функціонал Kubernetes.

#### *[Читать іншими мовами](/translations#readme).*

## Масштабованість
 
OpenEBS може легко масштабуватись й включати будь-яку кількість контейнерізованих контролерів зберігання. Kubernetes надає базові елементи, такі як etcd. OpenEBS може масштабуватись настільки, наскільки дозволяє Kubernetes.

## Установка й початок роботи
 
OpenEBS можна налаштувати за допомогою декількох простих команд. Для цього потрібно встановити `open-iscsi` на Kubernetes нодах та запустити `openebs-operator` за допомогою `kubectl`.

Запустіть служби OpenEBS за допомогою `yaml` файла OpenEBS оператора:

```bash
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

Запустіть служби OpenEBS  с `helm`:

   ```bash
   helm repo update
   helm install --namespace openebs --name openebs stable/openebs
   ```

Ви також можете ознайомитись з нашою [Інструкцією з швидкого запуску](https://docs.openebs.io/docs/overview.html).

OpenEBS можна розгорнути на будь-якому Kubernetes кластері  - або в хмарині, або на локальному комп'ютері, або на ноутбуці розробника, використовуя mini-kube. Тому що OpenEBS працює у пространстві користувача, базове ядро Kubernetes лишається без змін. Щоб більш детально дізнатися, як налаштувати OpenEBS, читайте [Документацію] (https://docs.openebs.io/docs/overview.html). Ви можете також налаштувати OpenEBS, використовуючи [Vagrant](https://github.com/openebs/openebs/tree/master/k8s/vagrant), Це тестова Vagrant середа включає у себе приклад розгортання Kubernetes та симуляцію робочого навантаження, які можна використовувати для імітації продуктивності OpenEBS. Ще один цікавий проект в цій області зветься [Litmus](https://www.openebs.io/litmus), який реалізує концепцію хаотичної розробки (chaos engineering) у системах Kubernetes.

## Статус

У даний момент, проект знаходиться у бета стадії розвитку. Додаткову інформацію можна знайти в [Трекері проекту](https://github.com/openebs/openebs/wiki/Project-Tracker). Деякі користувачі використовують OpenEBS на великих підприємствах. Ранні версії коммерційних рішень доступні з вересня 2018 року через нашого основного спонсора [MayaData](https://www.mayadata.io).
 
## Як приєднатися до розробки?
 
Команда OpenEBS буде рада вашим відгукам, побажанням й пропозиціям:
 
- [приєднуйтесь до нашого товариства](https://kubernetes.slack.com).
  - Вже зареєстровані? Приєднуйтесь до наших обговорень в [#openebs](https://kubernetes.slack.com/messages/openebs/).
- Бажаєте задати питання?
  - Якщо ваше питання загальне (або «не зовсім певен»), ви можете задати його в  [issues](https://github.com/openebs/openebs/issues).
  - Специфічні проблеми проекту (репозиторія) також можна обговорити в [issues](https://github.com/openebs/openebs/issues) й відмічені окремими ярликами репозиторія, такими як * repo / maya \*.
- Бажаєте допомогти з виправленням багів й додаванням нових функцій? Читайте:
  - [Відкриті задачі](https://github.com/openebs/openebs/labels).
  - [Інструкція з контриб'юту](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.ru.md).
  - Приєднуйтесь до [OpenEBS community](https://github.com/openebs/openebs/blob/master/community/README.md).

## Де зберігається наш код?

Це мета-репозиторій для OpenEBS. Початковий код зберігається у наступних місцях:

* Початковий код для механизму зберігання знаходиться в `openebs/jiva`.
* Початковий код  керування сховищем даних знаходиться в `openebs/maya`.
* У той час як діректорії jiva и maya мають у собі значущу кількість фрагментів початкового коду, частина коду керування сховищем даних й автоматизації також розповсюджується у інших репозиторіях в организації OpenEBS.
Будь ласка, почніть роботу з вивчення  помічених (pinned) репозиторіїв або з прочитання документу OpenEBS _Architecture_.

## Ліцензія

OpenEBS розроблюється під лицензією Apache 2.0 на рівні проекту. Деякі компоненти проекту отримані з  інших проектів з відкритим початковим кодом й розповсюджуються згідно з відповідними ліцензіями.
