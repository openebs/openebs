# OpenEBS

[! [Статус сборки] (https://img.shields.io/travis/openebs/openebs/master.svg?style=flat-square)] (https://travis-ci.org/openebs/jiva)
[! [Docker Pulls] (https://img.shields.io/docker/pulls/openebs/jiva.svg?style=flat-square)] (https://hub.docker.com/r/openebs/jiva /)
[! [Релизы] (https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)] (https://github.com/openebs/openebs/releases)
[! [Slack] (https://img.shields.io/badge/chat!!!-slack-ff1493.svg?style=flat-square)] (https://openebsslacksignup.herokuapp.com/)
[! [Twitter] (https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)] (https://twitter.com/intent/follow?screen_name=openebs)
[! [PRs Welcome] (https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)] (https://github.com/openebs/openebs/blob/master /CONTRIBUTING.md)
[! [Лицензия] (https://img.shields.io/badge/License-Apache%202.0-blue.svg)] (https://github.com/openebs/openebs/blob/master/LICENSE)

https://www.openebs.io/
 
**OpenEBS** позволяет использовать контейнеры для приложений, которые требуют постоянного хранилища данных, а также для приложений, которые проверяют состояние кластера, например, Prometheus. OpenEBS предоставляет постоянное контейнерное хранилище данных и службы хранения.
 
**OpenEBS** позволяет работать с контейнеризованными приложениями требующими постоянное хранилище данных, такие как базы данных, как с обычными контейнерами. Сам OpenEBS развертывается как еще один контейнер на хосте и включает службы хранения, которые могут быть настроены для подов, приложений, кластеров или контейнеров. Службы хранения включают:

- Сохранность данных на всех нодах кластера. Одним заметным преимуществом такого подхода является значительное сокращение времени затрачиваемого на восстановление колец Кассандры.
- Синхронизация данных по доступным зонам и облачным провайдерам, что повышает доступность данных и сокращает время затраченное на прикрепление / отсоединение к подам.
- Общий уровень интеграции. Вне зависимости от того с какой платформой вы работаете - AKS, на физическом сервере, GKE или AWS - различия в рабочем процессе минимальны.
- Интеграция с Kubernetes, которая автоматически связывает разработку и работу приложений с конфигурацией OpenEBS.
- Управление загрузкой данных в и из S3 и в другие системы.
  
**Наша философия** проста: службы хранения и постоянное хранилище данных должны легко интегрироваться в любую инфраструктуру, чтобы любая команда разработчиков или приложения могли полноценно использовать функционал Kubernetes.

## Масштабируемость
 
OpenEBS может легко масштабироваться и включать любое количество контейнеризованных контроллеров хранения. Kubernetes предоставляет базовые элементов, такие как etcd. OpenEBS может масштабироваться настолько, насколько позволяет Kubernetes.

## Установка и начало работы
 
OpenEBS можно настроить с помощью нескольких простых команд. Для этого необходимо установить `open-iscsi` на Kubernetes нодах и запустить `openebs-operator` с помощью `kubectl`.

1. Запустите службы OpenEBS с помощью `yaml` файла OpenEBS оператора:

```bash
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

1. Примените OpenEBS StorageClasses, используя `openebs-storageclasses.yaml`:

   ```bash
   kubectl apply -f https://openebs.github.io/charts/openebs-storageclasses.yaml
   ```

   Вы также можете ознакомиться с нашим [Руководством по быстрому запуску] (https://docs.openebs.io/docs/overview.html).

OpenEBS можно развернуть на любом Kubernetes кластере  - либо в облаке, либо на локальном компьютере, либо на ноутбуке разработчика, используя mini-kube. Так как OpenEBS работает в пользовательском пространстве, базовое ядро Kubernetes остается без изменений. Чтобы более подробно узнать как настроить OpenEBS, читайте [Документацию] (https://docs.openebs.io/docs/overview.html). Вы можете так же настроить OpenEBS, используя [Vagrant](https://github.com/openebs/openebs/tree/master/k8s/vagrant), Эта тестовая Vagrant среда включает в себя пример развертывания Kubernetes и симуляцию рабочей нагрузки, которые можно использовать для имитации производительности OpenEBS. Еще один интересный проект в этой области называется [Litmus](https://www.openebs.io/litmus), который реализует концепцию хаотической разработки (chaos engineering) в системах Kubernetes.

## Статус

В данный момент, проект находится в бета стадии развития. Дополнительную информацию смотрите в нашем [Трекере проекта] (https://github.com/openebs/openebs/wiki/Project-Tracker). Многие пользователи используют OpenEBS на больших предприятиях. Ранние версии коммерческие решения доступны с сентября 2018 года через нашего основного спонсора [MayaData](https://www.mayadata.io).
 
## Contributing
 
Команда OpenEBS будет рада вашим отзывам, пожеланиям и предложениям:
 
- Присоединяйтесь к нам в [Slack] (https://openebsslacksignup.herokuapp.com/).
  - Уже зарегистрированы? Присоединяйтесь к нашим обсуждениям на [# openebs-users] (https://openebs-community.slack.com/messages/openebs-users/).
- Хотите задать вопрос?
  - Если ваш вопрос общий (или «не совсем уверен»), вы можете его задать в [issues] (https://github.com/openebs/openebs/issues).
  - Особые проблемы проекта (репозитория) также можно обсудить в [issues] (https://github.com/openebs/openebs/issues) и помечены отдельными ярлыками репозитория, такими как * repo / maya \*.
- Хотите помочь с исправлениями багов и добавлением новых функций?
  - [Open issues] (https://github.com/openebs/openebs/labels).
  - [Contributing Guide](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md).
  - Присоединяйтесь к [OpenEBS community](https://github.com/openebs/openebs/blob/master/community/README.md).

## Покажите мне код

Это мета-репозиторий для OpenEBS. Исходный код хранится в следующих местах:

* Исходный код для механизма хранения находится в `openebs/jiva`.
* Исходный код управления хранилищем данных находится в `openebs/maya`.
* В то время как директории jiva и maya содержат значительное количество фрагментов исходного кода, часть кода управления хранилищем данных и автоматизации также распространяется в других репозиториях в организации OpenEBS.
Пожалуйста, начните работу с изучения помеченных (pinned) репозиториев или с прочтения документа OpenEBS Architecture.

## Лицензия

OpenEBS разрабатывается под лицензией Apache 2.0 на уровне проекта. Некоторые компоненты проекта получены из других проектов с открытым исходным кодом и распространяются по соответствующим лицензиям.
