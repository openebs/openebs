अच्छा !! हम हमेशा अधिक OpenEBS हैकर्स की तलाश में रहते हैं। आप इसे [overview](./contribute/design/README.md) पढ़कर शुरू कर सकते हैं

सबसे पहले, यदि आप अनिश्चित हैं या किसी चीज से डरते हैं, तो बस एक मुद्दा जारी करें या एक pull request सबमिट करें। आप अपना सर्वश्रेष्ठ प्रदर्शन करने के लिए बर्बाद नहीं होंगे। सबसे बुरा यह हो सकता है कि आपको विनम्रता से कुछ बदलने के लिए कहा जाएगा। हम किसी भी तरह के योगदान की सराहना करते हैं और उसके अनुसार नियमों की दीवार प्राप्त नहीं करना चाहते हैं।

हालांकि, उन व्यक्तियों के लिए जो परियोजना में योगदान करने के सर्वोत्तम तरीके पर थोड़ा और मार्गदर्शन चाहते हैं, पर पढ़ें। यह दस्तावेज़ उन सभी मुद्दों को कवर करेगा, जिन्हें हम आपके योगदान के लिए देख रहे हैं, त्वरित मर्ज की संभावना बढ़ाएँ या आपके योगदान को संबोधित करें।

कहा जाता है कि, ओपन सोर्स में OpenEBS में एक नवीनता है। आप किसी भी तरह से योगदान करने के लिए स्वागत करते हैं और प्रदान की गई मदद की बहुत सराहना की जाती है।

- [Raise issues to request new functionality, fix documentation or for reporting bugs.](#raising-issues)
- [Submit changes to improve documentation.](#submit-change-to-improve-documentation) 
- [Submit proposals for new features/enhancements.](#submit-proposals-for-new-features)
- [Solve existing issues related to documentation or code.](#contributing-to-source-code-and-bug-fixes)

अपने हैक्स प्रदान करने से पहले आपको कुछ सरल दिशानिर्देशों का पालन करना होगा।

## मुद्दों को उठाने के लिए

समस्याएँ बढ़ाते समय, कृपया निम्नलिखित देखें:
- Setup details need to be filled as specified in the issue template clearly for the reviewer to check.
- A scenario where the issue occurred (with details on how to reproduce it).
- Errors and log messages that are displayed by the software.
- Any other details that might be useful.

## प्रलेखन में सुधार के लिए एक परिवर्तन सबमिट करें

सही दस्तावेज प्राप्त करना कठिन है! उपयुक्त टैग के साथ पुल अनुरोध सबमिट करके आप डेवलपर प्रलेखन को कैसे बेहतर बना सकते हैं, इसकी अधिक जानकारी के लिए [पेज] (/ ./ योगदान / CONTRIBUTING-TO-DEVELOPER-DOC.md) देखें। यहां आप [list of tags](./contribute/labels-of-issues.md) पा सकते हैं जिसका उपयोग किया जा सकता है। हमारे दस्तावेजों को साफ रखने, समझने में आसान और सुलभ होने में हमारी मदद करें।

## नई सुविधाओं के लिए प्रस्ताव भेजें

आपके उपयोग-मामलों के अनुरूप हमेशा कुछ और आवश्यक होता है। कृपया नई सुविधाओं पर चर्चा में शामिल होने या अपने प्रस्तावित बदलाव के साथ पीआर बढ़ाने में संकोच न करें।

- [Join OpenEBS community on Kubernetes Slack](https://kubernetes.slack.com)
	- पहले से ही साइन अप? हमारी चर्चा के लिए यहाँ जाएँ: [#openebs] (https://kubernetes.slack.com/messages/openebs/)
	
## स्रोत कोड और बग-फिक्स में योगदान करें

स्रोत कोड में सुधार या वृद्धि के लिए उचित टैग के साथ पीआर प्रदान करें। प्रयोग करने योग्य टैग की सूची के लिए,[this](./contribute/labels-of-issues.md).

* K8s डेमो में योगदान करने के लिए, कृपया [दस्तावेज़] [document](./contribute/CONTRIBUTING-TO-K8S-DEMO.md) देखें।
    - यह देखने के लिए कि OpenEBS K8s के साथ कैसे काम करता है, [document](./k8s/README.md) देखें
- Kubernetes OpenEBS प्रोविजनर योगदान करने के लिए, कृपया  [document](./contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md). देखें।

कोड संरचना और निम्नलिखित दिशानिर्देशों के लिए [document](./contribute/design/code-structuring.md) देखें।

## मौजूदा मुद्दों को हल करें
उन मुद्दों को खोजने के लिए [issues](https://github.com/openebs/openebs/issues) पर जाएं जहां योगदानकर्ताओं को सहायता की आवश्यकता है। हमारे [list of labels guide](./contribute/labels-of-issues.md) देखें ताकि आप उन मुद्दों को ढूंढ सकें, जिन्हें आप जल्दी हल कर सकते हैं।

कोई भी योगदान करने के इच्छुक एक टिप्पणी का दावा करके / उसकी GitHub आईडी असाइन करके मुद्दा उठा सकता है। यदि इस मुद्दे पर कोई पीआर या अपडेट एक सप्ताह से प्रगति में नहीं है, तो यह समस्या किसी के लिए भी फिर से संभालती है। हमें उच्च प्राथमिकता वाले मुद्दों / प्रतिगमन पर विचार करने की आवश्यकता है जहां प्रतिक्रिया समय एक दिन होना चाहिए।

---
### अपने काम पर हस्ताक्षर करें
हम OpenEBS परियोजना के लिए अतिरिक्त सुरक्षा के रूप में ओरिजिनल सर्टिफिकेट ऑफ़ ओरिजिन (DCO) का उपयोग करते हैं। यह योगदानकर्ताओं को आश्वस्त करने के लिए एक अच्छी तरह से स्थापित और व्यापक रूप से इस्तेमाल किया जाने वाला तंत्र है जिन्होंने लाइसेंस के तहत अपने लाइसेंस प्राप्त परियोजना अधिकारों की पुष्टि की है।
कृपया [developer-certificate-of-origin](./contribute/developer-certificate-of-origin). पढ़ें।

यदि आप इसे प्रमाणित कर सकते हैं, तो बस प्रत्येक Git प्रतिबद्ध संदेश में एक पंक्ति जोड़ें:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````

या command `git commit -s -m "commit message comes here"` commits sign-off करने के लिए।

अपने वास्तविक नाम का उपयोग करें (क्षमा करें, कोई उपनाम या अनाम योगदान नहीं)। यदि आप अपना `user.name` और `user.email` git कॉन्फ़िगर करते हैं
इसलिए, आप स्वचालित रूप से इस तरह अपनी प्रतिबद्धता के साथ साइन इन कर सकते हैं - `git commit -s`. आप 'git config --global alias.ci' कमिट के रूप में - git [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) like `git config --global alias.ci 'commit -s'`. अब आप इस तरह से कर सकते हैं - `git ci` और कमिट पर हस्ताक्षर किए जाएंगे।

---

## हमारी संस्था से जुड़े

यदि आप OpenEBS समुदाय को सक्रिय रूप से विकसित और योगदान करना चाहते हैं, तो [document](./community/README.md) को देखें।
