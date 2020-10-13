# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/
 
**OpenEBS** Kubernetes માટે એકદમ વ્યાપક જમાવટ અને ઉપયોગમાં સરળ ઓપન-સોર્સ સ્ટોરેજ સોલ્યુશન છે.

**OpenEBS** સ્ટોરેજ સોલ્યુશન્સની કેટેગરીનું અગ્રણી ઓપન સોર્સ ઉદાહરણ છે જેને કેટલીકવાર કહેવામાં આવે છે [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** ઓપન સોર્સ ઉદાહરણ તરીકે સૂચિબદ્ધ થયેલ છે [CNCF Storage Landscape White Paper](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) માં hyperconverged storage solutions નીચે.

અન્ય પરંપરાગત સ્ટોરેજ સોલ્યુશન્સની તુલનામાં કેટલાક મુખ્ય પાસાઓ કે જે OpenEBS ને જુદા બનાવે છે:
- Built using the micro-services architecture like the applications it serves. OpenEBS is itself deployed as a set of containers on Kubernetes worker nodes. Uses Kubernetes itself to orchestrate and manage OpenEBS components
- કોઈપણ OS/platform પર ચલાવવા માટે તે ખૂબ જ પોર્ટેબલ બનાવે છે તે સંપૂર્ણપણે યુઝરસ્પેસમાં બિલ્ટ
- સંપૂર્ણપણે ઉદ્દેશથી ચાલે છે, તે જ સિદ્ધાંતોનો વારસો મેળવે છે જે Kubernetes સાથે ઉપયોગમાં સરળતાને વાહન આપે છે
- OpenEBS supports a range of storage engines so that developers can deploy the storage technology appropriate to their application design objectives. Distributed applications like Cassandra can use the LocalPV engine for lowest latency writes. Monolithic applications like MySQL and PostgreSQL can use the ZFS engine (cStor) for resilience. Streaming applications like Kafka can use the NVMe engine [Mayastor](https://github.com/openebs/Mayastor) for best performance in edge environments. Across engine types, OpenEBS provides a consistent framework for high availability, snapshots, clones and manageability.

OpenEBS પોતે તમારા યજમાન પરના બીજા કન્ટેનર તરીકે જમાવટ થયેલ છે અને સ્ટોરેજ સેવાઓને સક્ષમ કરે છે જે પોડ, એપ્લિકેશન, ક્લસ્ટર અથવા કન્ટેનર સ્તર પર નિયુક્ત કરી શકાય છે, આ સહિત:
- Kubernetes કાર્યકર ગાંઠો સાથે જોડાયેલ સ્ટોરેજનું સંચાલન સ્વચાલિત કરો અને ગતિશીલ રીતે OpenEBS PVs અથવા Local PVs જોગવાઈ માટે સ્ટોરેજનો ઉપયોગ કરવાની મંજૂરી આપો.
- ગાંઠોમાં ડેટાની સાતત્યતા, ઉદાહરણ તરીકે, Cassandra રીંગ્સના પુનર્નિર્માણમાં ખર્ચવામાં આવેલા સમયને નાટકીય રીતે ઘટાડે છે.
- પ્રાપ્યતા ઝોન અને ક્લાઉડ પ્રદાતાઓમાં ડેટાના સિંક્રનાઇઝેશન ઉપલબ્ધતામાં સુધારો થાય છે અને ઉદાહરણ તરીકે ઘટતા જોડાણ / અલગ થવું.
- એક સામાન્ય સ્તર જેથી તમે AKS પર ચલાવી રહ્યા હો, અથવા તમારી બેર મેટલ, અથવા GKE, અથવા AWS - સ્ટોરેજ સેવાઓ માટેનો તમારો વાયરિંગ અને ડેવલપર અનુભવ શક્ય તેટલો જ છે.
- S3 અને અન્ય લક્ષ્યો પર અને તેમાંથી ટાઇરિંગનું સંચાલન.

સંપૂર્ણ રીતે Kubernetes નેટીવ સોલ્યુશન હોવાનો એક વધારાનો ફાયદો એ છે કે kubectl, Helm, Prometheus, Grafana, Weave Scope, વગેરે જેવા Kubernetes માટે ઉપલબ્ધ બધા અદભૂત ટૂલીંગનો ઉપયોગ કરીને એડમિનિસ્ટ્રેટર્સ અને ડેવલપર્સ ઓપનઇબીએસનો સંપર્ક અને સંચાલન કરી શકે છે.

**આપણી દ્રષ્ટિ** સરળ છે: સ્થિર વર્કલોડ માટે સ્ટોરેજ અને સ્ટોરેજ સેવાઓ સંપૂર્ણપણે પર્યાવરણમાં એકીકૃત થવા દો જેથી દરેક ટીમ અને વર્કલોડ નિયંત્રણના ગ્ર granularity અને kubernetes મૂળ વર્તનથી લાભ મેળવે.

#### *આને [અન્ય ભાષાઓમાં](/translations#readme) વાંચો.*

## સ્કેલેબિલીટી
 
OpenEBS મોટા પ્રમાણમાં મોટી સંખ્યામાં કન્ટેનરઇઝ્ડ સ્ટોરેજ નિયંત્રકોને સમાવવા માટે સ્કેલ કરી શકે છે. Kubernetes ઉપયોગ મૂળભૂત ટુકડાઓ પૂરા પાડવા માટે થાય છે જેમ કે ઇન્વેન્ટરીમાં વગેરેનો ઉપયોગ કરવો. તમારા Kubernetes ભીંગડાની હદ સુધી OpenEBS ભીંગડા.

## ઇન્સ્ટોલેશન અને પ્રારંભ
 
OpenEBS થોડા સરળ પગલાઓમાં સેટ કરી શકાય છે. 
તમે Kubernetes નોડો પર openebs-operator ઇન્સ્ટોલ કરીને અને kubectl ઉપયોગ કરીને open-iscsi-ઓપરેટર ચલાવીને Kubernetes ક્લસ્ટરની તમારી પસંદગી પર જઈ શકો છો.

** OpenEBS Services શરૂઆત operator કરીને**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**helm નો ઉપયોગ કરીને OpenEBS સેવાઓ પ્રારંભ કરો**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

તમે પણ અમારા અનુસરો કરી શકો છો [QuickStart Guide](https://docs.openebs.io/docs/overview.html).

ક્લાઉડમાં ક્યાં તો પૂર્વવર્તી અથવા ડેવલપર લેપટોપ (મિનીક્યુબ) પર - કોઈપણ Kubernetes ક્લસ્ટર પર OpenEBS ગોઠવી શકાય છે. 
નોટ લો કે અંતર્ગત કર્નલમાં કોઈ પરિવર્તન નથી કે જે જરૂરી છે કારણ કે ઓપનઇબીએસ યુઝર સ્પેસમાં કાર્ય કરે છે.  કૃપા કરીને અમારી [OpenEBS Setup](https://docs.openebs.io/docs/overview.html) દસ્તાવેજીકરણ અનુસરો. ઉપરાંત, અમારી પાસે એક Vagrant વાતાવરણ ઉપલબ્ધ છે જેમાં નમૂના Kubernetes જમાવટ અને કૃત્રિમ લોડનો સમાવેશ થાય છે જેનો ઉપયોગ તમે OpenEBS પ્રદર્શન માટે કરી શકો છો. તમને Litmus (https://litmuschaos.io) તરીકે ઓળખાતા સંબંધિત પ્રોજેક્ટને રસપ્રદ પણ મળી શકે છે જે Kubernetes પરના રાજ્યના વર્કલોડ માટે અરાજકતા એન્જિનિયરિંગમાં મદદ કરે છે.

## સ્થિતિ

OpenEBS  ઉદ્યોગમાં સૌથી વધુ ઉપયોગમાં લેવાતા અને ચકાસાયેલ Kubernetes સ્ટોરેજ ઇન્ફ્રાસ્ટ્રક્ચર્સમાંનું એક છે. A CNCF Sandbox project May 2019 તારીખથી, એ પ્રથમ અને એકમાત્ર સ્ટોરેજ સિસ્ટમ છે કે જેણે ઘણાબધા બેકએન્ડ્સ પર સ સોફ્ટવેર નિર્ધારિત સ્ટોરેજ ક્ષમતાઓનો સતત સેટ આપ્યો છે (local, nfs, zfs, nvme) પક્ષ અને મેઘ સિસ્ટમ્સ બંને પર, અને સ્ટેટફૂલ વર્કલોડ્સ માટે તેના પોતાના કેઓસ એન્જિનિયરિંગ ફ્રેમવર્કને સ્રોત ખોલનારા પ્રથમ હતા, આ [Litmus Project](https://litmuschaos.io), જે સમુદાય ખુલ્લી તૈયારી પર આધાર રાખે છે OpenEBS સંસ્કરણોના માસિક અનુરૂપતાનું મૂલ્યાંકન. એન્ટરપ્રાઇઝ ગ્રાહકો 2018 થી ઉત્પાદનમાં OpenEBS નો ઉપયોગ કરી રહ્યાં છે અને પ્રોજેક્ટ એક અઠવાડિયામાં 2.5M+ docker ખેંચીને સપોર્ટ કરે છે.

OpenEBS પર્સિન્ટન્ટ વોલ્યુમ્સને શક્તિ આપતા વિવિધ સ્ટોરેજ એન્જિનોની સ્થિતિ નીચે આપેલ છે. સ્થિતિઓ વચ્ચેનો મુખ્ય તફાવત નીચે સારાંશ આપ્યો છે:
- **alpha:** સૂચના વિના, API પછીના સોફ્ટવેર રિલીઝમાં અસંગત રીતે બદલાઇ શકે છે, ફક્ત ભૂલોના જોખમ અને લાંબા ગાળાના ટેકાના અભાવને લીધે, ટૂંકાગાળાના પરીક્ષણ ક્લસ્ટરોમાં ઉપયોગ માટે ભલામણ કરવામાં આવે છે.
- **beta**: એકંદર સુવિધાઓ માટેનો આધાર છોડી દેવામાં આવશે નહીં, તેમ છતાં વિગતો બદલાઇ શકે છે. વર્ઝન વચ્ચે અપગ્રેડ કરવા અથવા સ્થાનાંતરિત કરવા માટેનો આધાર ઓટોમેશન અથવા મેન્યુઅલ પગલાઓ દ્વારા પ્રદાન કરવામાં આવશે.
- **stable**: ઘણાં અનુગામી સંસ્કરણો માટે પ્રકાશિત સ સોફ્ટવેર સુવિધાઓ દેખાશે અને સંસ્કરણોના મોટાભાગનાં સંજોગોમાં સોફ્ટવેર ઓટોમેશન પ્રદાન કરવામાં આવશે.


| Storage Engine | Status | Details |
|---|---|---|
| Jiva | stable | Kubernetes કામદાર ગાંઠો પર અલ્પકાલિક સ્ટોરેજનો ઉપયોગ કરનારા ગાંઠો પર પ્રતિકૃતિવાળા બ્લોક સંગ્રહને ચલાવવા માટે શ્રેષ્ઠ અનુકૂળ |
| cStor | beta | અવરોધિત ઉપકરણો ધરાવતા ગાંઠો પર ચલાવવા માટે એક પસંદ કરેલો વિકલ્પ. જો સ્નેપશોટ અને ક્લોન્સ આવશ્યક હોય તો ભલામણ કરેલ વિકલ્પ |
| Local Volumes | beta | ડિસ્ટ્રિબ્યુટેડ એપ્લિકેશન માટે શ્રેષ્ઠ અનુકૂળ છે જેને ઓછી લેટન્સી સ્ટોરેજની જરૂર છે - Kubernetes ગાંઠોથી સીધો જોડાયેલ સ્ટોરેજ. |
| Mayastor | alpha | એક નવું સ્ટોરેજ એન્જિન જે સ્થાનિક સ્ટોરેજની કાર્યક્ષમતા પર કાર્ય કરે છે પરંતુ પ્રતિકૃતિ જેવી સ્ટોરેજ સેવાઓ પણ પ્રદાન કરે છે. સ્નેપશોટ અને ક્લોન્સને ટેકો આપવા માટે વિકાસ ચાલુ છે. |

વધુ વિગતો માટે, [OpenEBS Documentation](https://docs.openebs.io/docs/next/quickstart.html) નો સંદર્ભ લો.
 
## ફાળો
 
OpenEBS કોઈપણ સંભવિત સંભવમાં તમારા પ્રતિસાદ અને યોગદાનને આવકારે છે.
 
- [Join OpenEBS community on Kubernetes Slack](https://kubernetes.slack.com)
  - પહેલેથી સાઇન અપ કર્યું છે? અમારી ચર્ચાઓ પર જાઓ અહીંયા: [#openebs](https://kubernetes.slack.com/messages/openebs/)
- કોઈ મુદ્દો raise કરવો અથવા સુધારાઓ અને સુવિધાઓમાં મદદ કરવા માંગો છો?
  - જુઓ [open issues](https://github.com/openebs/openebs/issues)
  - જુઓ [contributing guide](./CONTRIBUTING.md)
  - અમારી ફાળો આપનાર સમુદાય બેઠકોમાં જોડાવા માંગો છો, [check this out](./community/README.md). 
- અમારા OpenEBS CNCF Mailing lists જોડાઓ
  - OpenEBS project updates માટે, subscribe to [OpenEBS Announcements](https://lists.cncf.io/g/cncf-openebs-announcements)
  - અન્ય OpenEBS વપરાશકર્તાઓ સાથે વાતચીત કરવા માટે, subscribe to [OpenEBS Users](https://lists.cncf.io/g/cncf-openebs-users)

## મને કોડ બતાવો

આ એક meta-repository છે OpenEBS માટે. કૃપા કરીને પિન કરેલા repositories અથવા [OpenEBS Architecture](./contribute/design/README.md) document સાથે પ્રારંભ કરો.

## લાઇસન્સ

OpenEBS વિકસિત થયેલ છે [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE) પ્રોજેક્ટ સ્તરે લાઇસન્સ. પ્રોજેક્ટના કેટલાક ઘટકો અન્ય ખુલ્લા સ્રોત પ્રોજેક્ટ્સમાંથી લેવામાં આવ્યા છે અને તેમના સંબંધિત લાઇસેંસ હેઠળ વિતરિત કરવામાં આવ્યા છે. 

OpenEBS CNCF Projects નો એક ભાગ છે.

[![CNCF Sandbox Project](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)

## Commercial Offerings

આ તૃતીય-પક્ષ કંપનીઓ અને વ્યક્તિઓની સૂચિ છે જેઓ OpenEBS થી સંબંધિત ઉત્પાદનો અથવા સેવાઓ પ્રદાન કરે છે. OpenEBS એ CNCF પ્રોજેક્ટ છે જે કોઈપણ કંપનીને સમર્થન આપતો નથી. સૂચિ મૂળાક્ષરોના ક્રમમાં આપવામાં આવી છે.
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Gridworkz Cloud Services](https://gridworkz.com/)
- [MayaData](https://mayadata.io/)
