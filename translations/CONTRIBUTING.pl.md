# Wkład w OpenEBS

Wspaniale!! Zawsze szukamy kolejnych kontrybutorów do OpenEBS. Możesz zacząć od przeczytania tego [omówienia](./contrib/design/README.md).

Po pierwsze, jeśli nie masz pewności lub czegoś się boisz, po prostu zapytaj lub prześlij zgłoszenie lub mimo wszystko wycofaj żądanie. Nie będziemy krzyczeć, że robisz wszystko, co tylko w twojej mocy. Najgorsze, co może się zdarzyć, to grzeczna prośba o zmianę czegoś. Doceniamy wszelkiego rodzaju wkład i nie chcemy, aby ściana zasad stała na twojej drodze.

Jednak dla tych osób, które chcą nieco więcej wskazówek na temat najlepszego sposobu wniesienia wkładu do projektu, czytajcie dalej. Ten dokument obejmuje wszystkie punkty, których szukamy w Twoim wkładzie, zwiększając Twoje szanse na szybkie połączenie lub zajęcie się Twoim wkładem.

To powiedziawszy, OpenEBS jest innowacją w Open Source. Możesz wnieść swój wkład w każdy możliwy sposób, a wszelka udzielona pomoc jest bardzo cenna.

- [Zgłaszaj problemy, aby poprosić o nową funkcjonalność, naprawić dokumentację lub zgłosić błędy.](#zgłaszanie-problemów)
- [Prześlij zmiany, aby ulepszyć dokumentację.](#prześlij-zmianę-by-ulepszyć-dokumentację)
- [Prześlij propozycje nowych funkcji / ulepszeń.](#prześlij-propozycje-nowych-funkcji)
- [Rozwiąż istniejące problemy związane z dokumentacją lub kodem.](#współtworzenie-kodu-źródłowego-i-naprawianie-błędów)

Jest kilka prostych wskazówek, które musisz przestrzegać przed udostępnieniem wkładu.

## Zgłaszanie problemów

Zgłaszając problemy, proszę podać następujące informacje:
- Szczegóły konfiguracji muszą być wypełnione zgodnie z szablonem wydania, aby recenzent mógł to sprawdzić.
- Scenariusz, w którym wystąpił problem (ze szczegółowymi informacjami o tym, jak go odtworzyć).
- Błędy i komunikaty dziennika, które są wyświetlane przez oprogramowanie.
- Wszelkie inne szczegóły, które mogą być przydatne.

## Prześlij zmianę by ulepszyć dokumentację

Stworzenie właściwej dokumentacji jest trudnym zadaniem! Więcej informacji o tym, jak ulepszyć dokumentację, przesyłając swój PR z odpowiednimi tagami, znajdziesz na tej [stronie](./contrib/CONTRIBUTING-TO-DEVELOPER-DOC.md). Oto [lista tagów](./contrib/labels-of-issues.md), których można użyć do tego samego. Pomóż nam zachować czystość, zrozumiałość i dostępność naszej dokumentacji.

## Prześlij propozycje nowych funkcji

Zawsze są pewne rzeczy, które są potrzebne w oprogramowaniu, które mogłyby ułatwić dostosowanie go do różnych przypadków użycia. Zapraszam do przyłączenia się do dyskusji na temat nowych funkcji lub zgłoszenia PR z proponowaną zmianą.

- [Dołącz do społeczności OpenEBS na Kubernetes Slack](https://kubernetes.slack.com)
- Już się zapisałeś? Przejdź do naszych dyskusji pod adresem [#openebs](https://kubernetes.slack.com/messages/openebs/)

## Współtworzenie kodu źródłowego i naprawianie błędów

Dostarcz PR z odpowiednimi tagami do poprawek błędów lub ulepszeń w kodzie źródłowym. Aby zapoznać się z listą tagów, których można użyć, zobacz [ten dokument](./contrib/labels-of-issues.md).

* Aby wnieść wkład w demo K8s, zapoznaj się z tym [dokumentem](./contrib/CONTRIBUTING-TO-K8S-DEMO.md).
    - Aby sprawdzić, jak OpenEBS współpracuje z K8s, zapoznaj się z tym [dokumentem](./k8s/README.md)
- Aby wnieść wkład w Kubernetes OpenEBS Provisioner, zapoznaj się z tym [dokumentem](./contrib/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).
    
Zapoznaj się z tym [dokumentem](./contrib/design/code-structuring.md), aby uzyskać więcej informacji na temat struktury kodu i wskazówek, jak postępować.

## Rozwiąż istniejące problemy
Udaj się do [problemów](https://github.com/openebs/openebs/issues), aby znaleźć problemy wymagające pomocy od współpracowników. Zobacz nasz [przewodnik po etykietach](./contrib/labels-of-issues.md), aby pomóc Ci znaleźć problemy, które możesz szybciej rozwiązać.

Osoba, która chce wnieść swój wkład, może zająć się problemem, zgłaszając go jako komentarz / przypisując do niego swój identyfikator GitHub. W przypadku braku PR lub aktualizacji w toku przez tydzień w tej sprawie, sprawa zostanie ponownie otwarta, aby każdy mógł się ponownie zająć. Musimy wziąć pod uwagę kwestie / regresje o wysokim priorytecie, w przypadku których czas reakcji musi trwać około jednego dnia.

---
### Podpisz swoją pracę

Używamy Developer Certificate of Origin (DCO) jako dodatkowego zabezpieczenia dla projektu OpenEBS. Jest to dobrze ugruntowany i szeroko stosowany mechanizm zapewniający, że współautorzy potwierdzą swoje prawo do licencjonowania ich wkładu na podstawie licencji projektu. Przeczytaj [certyfikat-pochodzenia-dewelopera](./contribute/developer-certificate-of-origin).

Jeśli możesz to poświadczyć, po prostu dodaj wiersz do każdego komunikatu o zatwierdzeniu git:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````

lub użyj polecenia `git commit -s -m "commit message comes here"` do podpisywania twoich commitów.

Użyj swojego prawdziwego imienia i nazwiska (przepraszamy, bez pseudonimów ani anonimowych wpisów). Jeśli ustawisz konfiguracje git dla `user.name` i `user.email`, możesz podpisać swoje zatwierdzenie automatycznie za pomocą `git commit -s`. Możesz także użyć git [aliasów](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases), np. `Git config --global alias.ci 'commit -s'`. Teraz możesz zatwierdzić za pomocą `git ci` i zatwierdzenie zostanie podpisane.

---

## Dołącz do naszej społeczności

Chcesz aktywnie rozwijać się i wnosić do społeczności OpenEBS, zapoznaj się z tym [dokumentem](./community/README.md).