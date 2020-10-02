# Contribuer à OpenEBS

Génial!! Nous sommes toujours à la recherche de plus de hackers OpenEBS. Vous pouvez commencer en lisant cette [présentation](./contribute/design/README.md)

Premièrement, si vous n'êtes pas sûr de quoi que ce soit ou si vous avez peur de quoi que ce soit, il vous suffit de demander ou de soumettre le problème ou de tirer la demande de toute façon. Vous ne serez pas crié après avoir fait de votre mieux. Le pire qui puisse arriver, c'est qu'on vous demandera poliment de changer quelque chose. Nous apprécions toutes sortes de contributions et nous ne voulons pas qu'un mur de règles entrave cela.

Cependant, pour les personnes qui souhaitent un peu plus de conseils sur la meilleure façon de contribuer au projet, lisez la suite. Ce document couvrira tous les points que nous recherchons dans vos contributions, augmentant vos chances de fusionner ou de traiter rapidement vos contributions.

Cela dit, OpenEBS est une innovation en Open Source. Vous êtes invités à contribuer de toutes les manières possibles et toute l'aide fournie est très appréciée.

- [Soulevez des problèmes pour demander de nouvelles fonctionnalités, corriger la documentation ou signaler des bogues.](#raising-issues)
- [Soumettre les modifications pour améliorer la documentation.](#Submit-change-to-better-documentation)
- [Soumettre des propositions pour de nouvelles fonctionnalités/améliorations.](#Submit-proposal-for-new-features)
- [Résoudre les problèmes existants liés à la documentation ou au code.](#Contribution-au-code-source-et-corrections-de-bogues)

Il y a quelques directives simples que vous devez suivre avant de fournir vos hacks.

## Problèmes soulevés

Lorsque vous soulevez des problèmes, veuillez préciser les éléments suivants:
- Les détails de la configuration doivent être renseignés clairement comme spécifié dans le modèle de problème pour que le réviseur puisse les vérifier.
- Un scénario où le problème s'est produit (avec des détails sur la façon de le reproduire).
- Erreurs et messages de journal affichés par le logiciel.
- Tout autre détail qui pourrait être utile.

## Soumettre les modifications pour améliorer la documentation

Obtenir une documentation correcte est difficile! Reportez-vous à cette [page](./contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) pour plus d'informations sur la façon dont vous pourriez améliorer la documentation du développeur en soumettant des pull requests avec les balises appropriées. Voici une [liste de balises](./contribuer/labels-of-issues.md) qui pourraient être utilisées pour la même chose. Aidez-nous à garder notre documentation propre, facile à comprendre et accessible.

## Soumettre des propositions pour de nouvelles fonctionnalités

Il y a toujours quelque chose de plus qui est nécessaire, pour faciliter l'adaptation à vos cas d'utilisation. N'hésitez pas à participer à la discussion sur les nouvelles fonctionnalités ou à soulever un PR avec votre proposition de modification.

- [Rejoignez la communauté OpenEBS sur Kubernetes Slack](https://kubernetes.slack.com)
- Déjà inscrit? Dirigez-vous vers nos discussions sur [#openebs](https://kubernetes.slack.com/messages/openebs/)

## Contribuer au code source et aux corrections de bogues

Fournissez aux PR des balises appropriées pour les corrections de bogues ou les améliorations du code source. Pour une liste des balises qui pourraient être utilisées, voir [this](./contribut/tiquettes-of-issues.md).

* Pour contribuer à la démo de K8, veuillez vous référer à ce [document](./contribut/ContribUTING-TO-K8S-DEMO.md).
    - Pour savoir comment OpenEBS fonctionne avec K8, reportez-vous à ce [document](./k8s/README.md)
- Pour contribuer à Kubernetes OpenEBS Provisioner, veuillez vous référer à ce [document](./contribut/CONTRIbUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).
    
Reportez-vous à ce [document](./contribut/design/code-structuring.md) pour plus d'informations sur la structuration du code et les directives à suivre.

## Résoudre les problèmes existants
Rendez-vous sur [issues](https://github.com/openebs/openebs/issues) pour trouver les problèmes où l'aide des contributeurs est nécessaire. Consultez notre [guide de la liste des étiquettes](./contribut/tiquettes-of-issues.md) pour vous aider à trouver les problèmes que vous pouvez résoudre plus rapidement.

Une personne qui souhaite contribuer peut résoudre un problème en le réclamant en tant que commentaire / en lui attribuant son identifiant GitHub. Au cas où il n'y aurait pas de PR ou de mise à jour en cours pendant une semaine sur ledit problème, le problème se rouvrira pour que quiconque puisse le reprendre. Nous devons tenir compte des problèmes / régressions hautement prioritaires pour lesquels le temps de réponse doit être d'environ un jour.

---
### Signez votre travail

Nous utilisons le certificat d'origine du développeur (DCO) comme garantie supplémentaire pour le projet OpenEBS. Il s'agit d'un mécanisme bien établi et largement utilisé pour garantir que les contributeurs ont confirmé leur droit d'accorder une licence à leur contribution sous la licence du projet. Veuillez lire [certificat-d'origine-développeur](./contribuer/certificat-d'origine-développeur).Si vous pouvez le certifier, ajoutez simplement une ligne à chaque message de validation git:

````
Signé par: Random J Developer <random@developer.example.org>
````
ou utilisez la commande `git commit -s -m " message de validation vient ici "` pour vous déconnecter de vos commits.

Utilisez votre vrai nom (désolé, pas de pseudonymes ou de contributions anonymes). Si vous définissez vos configurations git `user.name` et `user.email`, vous pouvez signer votre commit automatiquement avec `git commit -s`.Vous pouvez également utiliser git [alias](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) comme `git config --global alias.ci 'commit -s`.Vous pouvez maintenant vous engager avec `git ci` et le commit sera signé.

---

## Rejoignez notre communauté

Vous voulez développer activement et contribuer à la communauté OpenEBS, reportez-vous à ce [document](./community/README.md).
