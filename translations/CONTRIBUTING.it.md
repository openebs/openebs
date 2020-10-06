# Contribuire a OpenEBS
Grande!! Siamo sempre alla ricerca di altri hacker OpenEBS. Puoi iniziare leggendo questa panoramica [panoramica](./contribute/design/README.md)

In primo luogo, se non sei sicuro o hai paura di qualcosa, chiedi o invia comunque il problema o richiama comunque. Non sarai sgridato per aver fatto del tuo meglio. La cosa peggiore che può succedere è che ti venga chiesto cortesemente di cambiare qualcosa. Apprezziamo qualsiasi tipo di contributo e non vogliamo che un muro di regole si intrometta.

Tuttavia, per coloro che desiderano un po 'più di indicazioni sul modo migliore per contribuire al progetto, continua a leggere. Questo documento coprirà tutti i punti che stiamo cercando nei tuoi contributi, aumentando le tue possibilità di unire rapidamente o affrontare i tuoi contributi.

Detto questo, OpenEBS è un'innovazione in Open Source. Sei il benvenuto a contribuire in ogni modo possibile e tutto l'aiuto fornito è molto apprezzato.

- [Solleva problemi per richiedere nuove funzionalità, correggere la documentazione o segnalare bug.](#sollevare problemi)
- [Invia modifiche per migliorare la documentazione.](# presentare-modifica-per-migliorare-documentazione)
- [Invia proposte per nuove funzionalità / miglioramenti.](#presentare-proposte-per-nuove-funzionalità)
- [Risolvi i problemi esistenti relativi alla documentazione o al codice.](#contributo al codice sorgente e correzioni di bug)

Ci sono alcune semplici linee guida che devi seguire prima di fornire i tuoi hack.

## Sollevare problemi
Quando si sollevano problemi, specificare quanto segue:
- I dettagli della configurazione devono essere compilati chiaramente come specificato nel modello del problema affinché il revisore possa controllarli.
- Uno scenario in cui si è verificato il problema (con dettagli su come riprodurlo).
- Errori e messaggi di registro visualizzati dal software.
- Qualsiasi altro dettaglio che potrebbe essere utile.
- Invia modifica per migliorare la documentazione
- Ottenere la documentazione corretta è difficile! Fare riferimento a questa pagina per ulteriori informazioni su come migliorare la documentazione per sviluppatori inviando richieste pull con tag appropriati. Ecco un elenco di tag che potrebbero essere utilizzati per lo stesso. Aiutaci a mantenere la nostra documentazione pulita, di facile comprensione e accessibile.

##Invia proposte per nuove funzionalità

C'è sempre qualcosa di più che è necessario per rendere più facile l'adattamento ai tuoi casi d'uso. Sentiti libero di partecipare alla discussione sulle nuove funzionalità o aumentare un PR con la tua proposta di modifica.

- [Unisciti alla community OpenEBS su Kubernetes Slack](https://kubernetes.slack.com)
- Già registrato? Vai alle nostre discussioni su [#openebs](https://kubernetes.slack.com/messages/openebs/)

##Contribuire al codice sorgente e alla correzione di bug
Fornire ai PR i tag appropriati per correzioni di bug o miglioramenti al codice sorgente. Per un elenco di tag che potrebbero essere utilizzati, vedere questo.

* Per contribuire alla demo di K8s, fare riferimento a questo [documento](./contribute/CONTRIBUTING-TO-K8S-DEMO.md).
Per verificare come OpenEBS funziona con K8, fare riferimento a questo [documento](./k8s/README.md) 
Per contribuire a Kubernetes OpenEBS Provisioner, fai riferimento a questo [documento](./contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).
Fare riferimento a questo [documento](./contribute/design/code-structuring.md) per ulteriori informazioni sulla struttura del codice e le linee guida da seguire sullo stesso.

## Risolvi i problemi esistenti
Vai ai [problemi](https://github.com/openebs/openebs/issues) per trovare problemi per i quali è necessario l'aiuto dei contributori. Consulta il nostro elenco di guida alle 
etichette per trovare i problemi che puoi risolvere più rapidamente.

Una persona che desidera contribuire può risolvere un problema rivendicandolo come commento / assegnandogli il proprio ID GitHub. Nel caso in cui non ci siano PR o 
aggiornamenti in corso per una settimana su detto problema, il problema si riapre e chiunque lo riprenda. Dobbiamo considerare problemi / regressioni ad alta priorità in cui
il tempo di risposta deve essere di circa un giorno.

---
### Firma il tuo lavoro
Usiamo il Developer Certificate of Origin (DCO) come ulteriore salvaguardia per il progetto OpenEBS. Questo è un meccanismo ben consolidato e ampiamente utilizzato per
assicurare che i contributori abbiano confermato il loro diritto di concedere in licenza il loro contributo sotto la licenza del progetto. Leggi il 
[developer-certificate-of-origin](./contribute/developer-certificate-of-origin).

Se puoi certificarlo, aggiungi una riga a ogni messaggio di git commit:
````
  Firmato da: Random J Developer <random@developer.example.org>
````
oppure usa il comando git commit -s -m "il messaggio di commit arriva qui" per firmare i tuoi commit.

Usa il tuo vero nome (scusa, niente pseudonimi o contributi anonimi). Se imposti le tue configurazioni git user.name e user.email, puoi firmare il tuo commit automaticamente
con git commit -s. Puoi anche usare git [aliases] (https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) come git config --global alias.ci 'commit -s'. Ora puoi eseguire il
commit con git ci e il commit verrà firmato.

---
## Unisciti alla nostra comunità
Per sviluppare attivamente e contribuire alla comunità OpenEBS, fare riferimento a questo [documento](./community/README.md).
