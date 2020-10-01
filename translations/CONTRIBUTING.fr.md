# Contribuer à OpenEBS

Super!! Nous sommes toujours à la recherche de plus de hackers OpenEBS. Vous pouvez commencer en lisant cet [aperçu](/contribute/design/README.md).

Premièrement, si vous n'êtes pas sûr ou si vous avez peur de quoi que ce soit, il vous suffit de créer une issue ou de faire une pull request. On ne vous reprochera pas d'avoir fait de votre mieux. Le pire qui puisse arriver, c'est que l'on vous demande poliment de changer quelque chose. Nous apprécions toutes sortes de contributions et nous ne voulons pas qu'un mur de règles entrave cela.

Cependant, pour les personnes qui souhaitent un peu plus de conseils sur la meilleure façon de contribuer au projet, lisez la suite. Ce document couvrira tous les points que nous recherchons dans vos contributions, augmentant vos chances d'intégrer ou de traiter rapidement vos contributions.

Cela dit, OpenEBS est une innovation en Open Source. Vous êtes invités à contribuer de toutes les manières possibles et toute l'aide fournie est très appréciée.

- [Créer des issues pour demander de nouvelles fonctionnalités, corriger la documentation ou signaler des bogues.](#Créer-des-issues)
- [Soumettre des modifications pour améliorer la documentation.](#Soumettre-des-modifications-pour-améliorer-la-documentation)
- [Soumettre des propositions pour de nouvelles fonctionnalités / améliorations.](#Soumettre-des-propositions-pour-de-nouvelles-fonctionnalités)
- [Résoudre les problèmes existants liés à la documentation ou au code.](#Contribuer-au-code-source-et-aux-corrections-de-bogues)

Il y a quelques directives simples que vous devez suivre avant de fournir vos hacks.

## Créer des issues

Lorsque vous créez des issues, veuillez préciser les éléments suivants:
- Les détails de la configuration doivent être clairement renseignés comme spécifié dans le template d'issue pour que le reviewer puisse les vérifier.
- Un scénario où le problème s'est produit (avec des détails sur la façon de le reproduire).
- Erreurs et messages de log affichés par le logiciel.
- Tout autre détail qui pourrait être utile.

## Soumettre des modifications pour améliorer la documentation

Obtenir une documentation correcte est difficile! Reportez-vous à cette [page](/contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) pour plus d'informations sur la façon dont vous pourriez améliorer la documentation du développeur en soumettant des pull requests avec les tags appropriées. Voici une [liste de tags](/contribute/labels-of-issues.md) qui pourraient être utilisées pour la même chose. Aidez-nous à garder notre documentation propre, facile à comprendre et accessible.

## Soumettre des propositions pour de nouvelles fonctionnalités

Il y a toujours quelque chose de plus qui est nécessaire, pour faciliter l'adaptation à vos cas d'utilisation. N'hésitez pas à participer à la discussion sur les nouvelles fonctionnalités ou à créer une PR avec votre proposition de modification.

- [Rejoignez la communauté OpenEBS sur le Slack Kubernetes](https://kubernetes.slack.com)
- Déjà inscrit? Dirigez-vous vers nos discussions sur [#openebs](https://kubernetes.slack.com/messages/openebs/)

## Contribuer au code source et aux corrections de bogues

Fournissez aux PR des tags appropriés pour les corrections de bogues ou les améliorations du code source. Pour une liste des balises qui pourraient être utilisées, voir [ceci](/contribute/labels-of-issues.md).

* Pour contribuer à la démo de K8, veuillez vous référer à ce [document](/contribute/CONTRIBUTING-TO-K8S-DEMO.md).
    - Pour savoir comment OpenEBS fonctionne avec K8, reportez-vous à ce [document](./k8s/README.md)
- Pour contribuer à Kubernetes OpenEBS Provisioner, veuillez vous référer à ce [document](/contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).

Reportez-vous à ce [document](/contribute/design/code-structuring.md) pour plus d'informations sur la structuration du code et les directives à suivre.

## Résoudre les problèmes existants

Rendez-vous sur [issues](https://github.com/openebs/openebs/issues) pour trouver les problèmes où l'aide des contributeurs est nécessaire. Consultez notre [guide de la liste des tags](/contribute/labels-of-issues.md) pour vous aider à trouver les problèmes que vous pouvez résoudre plus rapidement.

Une personne qui souhaite contribuer peut résoudre une issue en la réclamant avec un commentaire et/ou en lui attribuant son identifiant GitHub. Au cas où il n'y aurait pas de PR ou de mise à jour en cours pendant une semaine sur ladite issue, elle se rouvrira pour que quiconque puisse la reprendre. Nous devons tenir compte des problèmes / régressions hautement prioritaires pour lesquels le temps de réponse doit être d'environ un jour.

---

### Signez votre travail

Nous utilisons le certificat d'origine du développeur (DCO) comme garantie supplémentaire pour le projet OpenEBS. Il s'agit d'un mécanisme bien établi et largement utilisé pour garantir que les contributeurs ont confirmé leur droit d'accorder une licence à leur contribution sous la licence du projet. Veuillez lire [le certificat d'origine développeur](/contribute/developer-certificate-of-origin).

Si vous pouvez le certifier, ajoutez simplement une ligne à chaque message de validation git:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````
ou utilisez la commande `git commit -s -m "commit message comes here"` pour signer vos commits.

Utilisez votre vrai nom (désolé, pas de pseudonymes ou de contributions anonymes). Si vous définissez vos configurations git `user.name` et` user.email`, vous pouvez signer votre commit automatiquement avec `git commit -s`. Vous pouvez également utiliser git [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) avec `git config --global alias.ci 'commit -s'`. Vous pouvez maintenant commit avec `git ci` et le commit sera signé.

---

## Rejoignez notre communauté

Vous voulez développer activement et contribuer à la communauté OpenEBS, reportez-vous à ce [document](./community/README.md).
