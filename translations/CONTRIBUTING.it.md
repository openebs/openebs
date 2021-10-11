# Contributing to OpenEBS

Fantastico!! Siamo sempre alla ricerca di nuovi OpenEBS hackers. Puoi iniziare leggendo questa [panoramica](./contribute/design/README.md)

Innanzitutto, se ti senti insicuro o spaventato di qualcosa, chiedi o apri un issue o invia una pull request comunque. Nessuno ti aggredirà per aver fatto del tuo meglio. Il peggio che potrebbe accadere è che ti sarà chiesto gentilmente di modificare qualcosa. Apprezziamo qualsiasi tipo di contributo e non vogliamo porre un muro di regole per impedirlo.

Comunque, per coloro che desiderano avere un aiuto/una guida verso la strada migliore per contribuire al progetto, continuate a leggere. In questo documento verranno elencati tutto ciò che vorremmo vedere nelle tue pull requests, in modo da aumentare la possibilità di fare un merge veloce.

Detto questo, OpenEBS è un'innovazione nell'Open Source. Sei desideri contribuire in qualsiasi modo il tuo aiuto sarà caldamente apprezzato.

- [Aprire issues per richiedere nuove funzionalità. modificare documentazione o riportare bugs.](#raising-issues)
- [Modifiche per arricchire la documentazione.](#submit-change-to-improve-documentation)
- [Inviare proposte per nuove funzionalità.](#submit-proposals-for-new-features)
- [Risolvere problemi esistenti sia documentazione che codice.](#contributing-to-source-code-and-bug-fixes)

Ci sono alcune semplici linee guida che devi seguire prima di fornire le tue modifiche.

## Sollevare problematiche

Quando si sollevano problemi, è necessario specificare quanto segue:

- I dettagli di installazione devono essere inseriti chiaramente come specificato nel modello dell'issue affinché il reviewer possa controllarli.
- Uno scenario in cui si è verificato il problema (con dettagli su come riprodurlo).
- Errori e messaggi di registro visualizzati dal software.
- Qualsiasi altro dettaglio che potrebbe essere utile.

## Inviare una modifica per migliorare la documentazione

Ottenere la documentazione giusta è difficile! Fare riferimento a questa [pagina](./contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) per ulteriori informazioni su come migliorare la documentazione per sviluppatori inviando richieste pull con tag appropriati. Ecco un [elenco di tag](./contribute/labels-of-issues.md), qui potresti trovare il tag giusto. Aiutaci a mantenere la nostra documentazione pulita, di facile comprensione e accessibile.

## Invia proposte per nuove funzionalità

C'è sempre qualcosa in più che è necessario, per rendere più facile l'adattamento ai tuoi casi d'uso. Sentiti libero di unirti alla discussione sulle nuove funzionalità o di sollevare un PR con la modifica proposta.

- [Unisciti alla community OpenEBS su Kubernetes Slack](https://kubernetes.slack.com) - Sei già registrato? Vai alle nostre discussioni su [#openebs](https://kubernetes.slack.com/messages/openebs/) 

## Contribuire al codice sorgente e alle correzioni di bug

Specificare nelle PR i tag appropriati relativamente alle correzioni di bug o ai miglioramenti del codice sorgente. Per un elenco di tag che potrebbero essere utilizzati, vedere [questa pagina](./contribute/labels-of-issues.md).

- Per contribuire alla demo di K8, fare riferimento a questo [documento](./contribute/CONTRIBUTING-TO-K8S-DEMO.md).
   - Per verificare come funziona OpenEBS con K8, fare riferimento a questo [documento](./k8s/README.md)

* Per contribuire a Kubernetes OpenEBS Provisioner, fare riferimento a questo [documento](./contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).

Fare riferimento a questo [documento](./contribute/design/code-structuring.md) per ulteriori informazioni sulla strutturazione del codice e le linee guida da seguire.

## Risolvi i problemi esistenti

Vai su [issues](https://github.com/openebs/openebs/issues) per trovare problemi in cui è necessario l'aiuto dei contributori. Consulta la nostra [guida all'elenco delle etichette](./contribute/labels-of-issues.md) per aiutarti a trovare problemi che puoi risolvere più velocemente.

Una persona che cerca di contribuire a un problema può rivendicandolo con un commento o assegnandolo al proprio utente GitHub. Nel caso in cui non ci siano PR o aggiornamenti in corso per una settimana su detto problema, il problema si riapre affinché chiunque possa prenderlo in carico. Dobbiamo considerare problemi/regressioni ad alta priorità in cui il tempo di risposta deve essere di circa un giorno.

---

### Firma il tuo lavoro

Usiamo il Developer Certificate of Origin (DCO) come ulteriore garanzia per il progetto OpenEBS. Questo è un meccanismo ben consolidato e ampiamente utilizzato per assicurare che i contributori abbiano confermato il loro diritto di concedere in licenza il loro contributo sotto la licenza del progetto. Si prega di leggere [developer-certificate-of-origin](./contribute/developer-certificate-of-origin).

Se puoi certificarlo, aggiungi semplicemente una riga a ogni messaggio di git commit: 

```
  Signed-off-by: Random J Developer <random@developer.example.org>
```

oppure usa il comando `git commit -s -m "il messaggio di commit va qui"` per firmare i tuoi commit.

Usa il tuo vero nome (niente pseudonimi o contributi anonimi). Se imposti le tue configurazioni git `user.name` e `user.email`, puoi firmare il tuo commit automaticamente con `git commit -s`. Puoi anche usare git [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) come `git config --global alias.ci 'commit -s'`. Ora puoi eseguire il commit con `git ci` e il commit sarà firmato.

---
## Unisciti alla nostra community

Vuoi sviluppare attivamente e contribuire alla comunità OpenEBS, fai riferimento a questo [documento](./community/README.md).
