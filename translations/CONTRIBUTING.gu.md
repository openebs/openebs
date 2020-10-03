# Contributing to OpenEBS

સરસ!! અમે હંમેશા વધુ OpenEBS હેકરો શોધી રહ્યા છે. તમે આ વાંચીને પ્રારંભ કરી શકો છો [overview](./contribute/design/README.md)

સૌથી પહેલા, જો તમને કોઈ બાબતની ખાતરી ન હોય અથવા ભયભીત હોય, માત્ર પૂછો (issue) અથવા pull request સબમિટ કરી દો. તમારા શ્રેષ્ઠ પ્રયત્નો કરવા બદલ તમને હાલાકી થશે નહીં. સૌથી ખરાબ થઈ શકે છે તે છે કે તમને કંઈક બદલવા માટે નમ્રતાપૂર્વક પૂછવામાં આવશે. અમે કોઈપણ પ્રકારના યોગદાનની પ્રશંસા કરીએ છીએ અને તે મુજબના નિયમોની દિવાલ મેળવવા માંગતા નથી.

જો કે, તે વ્યક્તિઓ માટે કે જેઓ પ્રોજેક્ટમાં ફાળો આપવાની શ્રેષ્ઠ રીત પર થોડું વધુ માર્ગદર્શન ઇચ્છે છે, આગળ વાંચો. આ દસ્તાવેજ તમારા યોગદાનમાં આપણે શોધી રહ્યા છીએ તે બધા મુદ્દાઓને આવરી લેશે, તમારી તકો વધારવી ઝડપી merge અથવા તમારા યોગદાનને સંબોધિત.

એવું કહ્યા પછી, OpenEBS માં નવીનતા છે Open Source મા. તમે કરી શકો છો તે કોઈપણ રીતે ફાળો આપવા માટે તમારું સ્વાગત છે અને પૂરી પાડવામાં આવતી સહાયની ખૂબ પ્રશંસા કરવામાં આવે છે.

- [Raise issues to request new functionality, fix documentation or for reporting bugs.](#raising-issues)
- [Submit changes to improve documentation.](#submit-change-to-improve-documentation) 
- [Submit proposals for new features/enhancements.](#submit-proposals-for-new-features)
- [Solve existing issues related to documentation or code.](#contributing-to-source-code-and-bug-fixes)

તમારા હેક્સ પ્રદાન કરતા પહેલા તમારે કેટલાક સરળ માર્ગદર્શિકાઓનું પાલન કરવાની જરૂર છે.

## મુદ્દાઓ ઉભા કરવા

મુદ્દાઓ ઉભા કરતી વખતે, કૃપા કરીને નીચેનાનો ઉલ્લેખ કરો:
- Setup details need to be filled as specified in the issue template clearly for the reviewer to check.
- A scenario where the issue occurred (with details on how to reproduce it).
- Errors and log messages that are displayed by the software.
- Any other details that might be useful.

## દસ્તાવેજીકરણ સુધારવા માટે બદલો સબમિટ કરો

અધિકાર દસ્તાવેજીકરણ મેળવવું મુશ્કેલ છે! આનો સંદર્ભ લો [page](./contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) યોગ્ય ટsગ્સ સાથે પુલ વિનંતીઓ સબમિટ કરીને તમે વિકાસકર્તા દસ્તાવેજીકરણને કેવી રીતે સુધારી શકશો તેના પર વધુ માહિતી માટે. અહિયાં [list of tags](./contribute/labels-of-issues.md) મળશે જે માટે વાપરી શકાય છે. અમારા દસ્તાવેજોને સ્વચ્છ, સમજવા માટે સરળ અને accessible રાખવામાં અમારી સહાય કરો.

## નવી સુવિધાઓ માટે દરખાસ્તો સબમિટ કરો

તમારા ઉપયોગ-કેસોને અનુકૂળ બનાવવા માટે હંમેશાં કંઈક વધુ જરૂરી છે. કૃપા કરીને નવી સુવિધાઓ પરની ચર્ચામાં જોડાવા અથવા તમારા સૂચિત પરિવર્તન સાથે PR વધારવા માટે અચકાશો નહીં. 

- [Join OpenEBS community on Kubernetes Slack](https://kubernetes.slack.com)
	- પહેલેથી સાઇન અપ કર્યું છે? અમારી ચર્ચાઓ માટે અહીં જાઓ: [#openebs](https://kubernetes.slack.com/messages/openebs/)

## Source Code અને bug-fixes માં ફાળો આપવો

Source code માં સુધારાઓ અથવા વૃદ્ધિ માટે યોગ્ય ટૅગ્સ સાથે PR પ્રદાન કરો. ઉપયોગ કરી શકાય તેવા ટૅગ્સની સૂચિ માટે, જુઓ [this](./contribute/labels-of-issues.md).

* K8s demo ને ફાળો આપવા માટે, કૃપા કરીને આનો સંદર્ભ લો [document](./contribute/CONTRIBUTING-TO-K8S-DEMO.md).
    - કેવી રીતે OpenEBS કામ કરે છે K8s સાથે, તે તપાસવા માટે આ નો સંદર્ભ લો [document](./k8s/README.md) 
- Kubernetes OpenEBS Provisioner ફાળો આપવા માટે, કૃપા કરીને આનો સંદર્ભ લો [document](./contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).
    
આનો સંદર્ભ લો [document](./contribute/design/code-structuring.md) code structuring અને guidelines ફોલ્લૉ કરવા માટે.

## હાલના મુદ્દાઓનું નિરાકરણ લાવો
અહીં જાઓ [issues](https://github.com/openebs/openebs/issues) શોધવા માટે જ્યાં ફાળો આપનારાઓની મદદની જરૂર છે. 
અમારા [list of labels guide](./contribute/labels-of-issues.md) જુઓ તમને તે મુદ્દાઓ શોધવા માટે મદદ કરવા માટે કે જે તમે ઝડપથી હલ કરી શકો.

યોગદાન આપવા માંગતા વ્યક્તિ કોઈ ટિપ્પણી તરીકે દાવો કરીને / તેના GitHub ID ને સોંપીને મુદ્દો ઉઠાવી શકે છે. આ મુદ્દે એક અઠવાડિયા માટે કોઈ PR અથવા અપડેટ પ્રગતિમાં ન હોવાના કિસ્સામાં, પછી કોઈ પણને ફરીથી હાથ ધરવા માટે આ ઇશ્યૂ ફરીથી ખુલે છે. અમારે ઉચ્ચ અગ્રતાના મુદ્દાઓ / રીગ્રેશનને ધ્યાનમાં લેવાની જરૂર છે જ્યાં પ્રતિસાદનો સમય એક દિવસ હોવો આવશ્યક છે.

---
### તમારા કામ પર સહી કરો
અમે Developer Certificate of Origin (DCO) વાપરીએ છે OpenEBS પ્રોજેક્ટ માટે વધારાના સલામતી તરીકે. ફાળો આપનારાઓને ખાતરી કરવા માટે આ એક સારી રીતે સ્થાપિત અને વ્યાપકપણે ઉપયોગમાં લેવામાં આવતી મિકેનિઝમ છે જેણે તેમના લાયસન્સના પ્રોજેક્ટના પરવાના હેઠળના અધિકારના પુષ્ટિ કરી છે. 
મહેરબાની કરીને વાંચો [developer-certificate-of-origin](./contribute/developer-certificate-of-origin).

જો તમે તેને પ્રમાણિત કરી શકો છો, તો પછી દરેક Git commit સંદેશમાં ફક્ત એક લાઇન ઉમેરો:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````
અથવા command `git commit -s -m "commit message comes here"` વાપરો commits sign-off કરવા માટે.

તમારું સાચું નામ વાપરો (માફ કરશો, કોઈ ઉપનામ અથવા અનામી યોગદાન નથી). જો તમે તમારા `user.name` and `user.email` સુયોજિત કરો git configs 
માટે, તમે તમારી commit સાથે આપમેળે સાઇન કરી શકો છો આ રીતે - `git commit -s`. તમે આનો પણ ઉપયોગ કરી શકો છો - git [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) આ રીતે `git config --global alias.ci 'commit -s'`. હવે તમે commit કરી શકો છો આ રીતે - `git ci` 
અને commit સાઇન કરી જશે.

---

## અમારા સમુદાયમાં જોડાઓ

OpenEBS સમુદાયમાં સક્રિય વિકાસ અને યોગદાન આપવા માંગો છો, આનો સંદર્ભ લો [document](./community/README.md).
