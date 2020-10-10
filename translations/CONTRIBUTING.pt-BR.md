# Contribuindo à OpenEBS

Ótimo!! Nós sempre estamos de olho para mais hackers OpenEBS. Você pode iniciar lendo este [overview](/contribute/design/README.md)

Primeiramente, se você está inseguro ou com medo de algo, apenas pergunte ou envie uma issue ou pull request de qualquer maneira. Ninguém irá gritar com você por dar o seu melhor. O pior que pode acontecer é que você pode ser politicamente solicitado para mudar algo. Nós apreciamos qualquer tipo de contribuição e não queremos uma parede de regras para ficar na frente disso.

Contudo, para os indivíduos que querem um pouco mais de orientação nas melhores maneiras de contribuir com o projeto, continuem lendo. Esse documento cobre todos os pontos que estamos olhando em suas contribuições, aumentando as chances de suas contribuições serem mergeadas ou endereçadas rapidamente.

Dito isso, OpenEBS é uma inovação em Open Source. Você tem boas vindas para contribuir em qualquer maineira que possa e toda a ajuda fornecida é muito apreciada.

- [Levante um problema para solicitar novas funcionalidades, corrigir documentação ou reportar bugs.](#levantando-problemas)
- [Envie alterações para aprimorar a documentação.](#envie-alterações-para-aprimorar-a-documentação)
- [Envie propostas para novas funcionalidades/melhorias.](#envie-propostas-para-novas-funcionalidades)
- [Corrija problemas existentes relacionados à documentação ou código.](#contribua-ao-código-fonte-e-correção-de-bugs)

Tem algumas diretrizes simples que você deve seguir antes de fornecer seus hacks.

## Levantando Problemas

Quando levantar um problema, por favor indique o seguinte:
- Detalhes de setup devem ser preenchidos como especificado no template de issue claramente para o reviewer poder checar.
- Um cenário em que o problema ocorreu (com detalhes de como reproduzir).
- Erros e mensagens de log que são exibidas pelo software.
- Qualquer outro detalhe que pode ser útil.

## Envie alterações para aprimorar a documentação

Deixar a documentação correta é difícil! Consulte esta [página](/contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) para mais informações em como você pode melhorar a documentação de desenvolvedores submetendo pull requests com as tags apropriadas. Aqui está uma [lista de tags](/contribute/labels-of-issues.md) que podem ser usadas. Ajude-nos a manter a documentação limpa, de fácil entendimento, e acessível.

## Envie propostas para novas funcionalidades

Sempre existe algo mais que é requerido, para tornar mais fácil e encaixar com seu caso de uso. Sinta-se livre para entrar na discussão de novas funcionalidades ou abra um Pull Request com suas mudanças propostas.

- [Entre na comunidade OpenEBS no Slack Kubernetes](https://kubernetes.slack.com)
  - Já está cadastrado? Entre nas nossas discussões em [#openebs](https://kubernetes.slack.com/messages/openebs/)

## Contribua ao código fonte e correção de bugs

Forneça Pull Requests com tags apropriadas para correções de bugs ou melhorias ao código fonte. Para uma lista de tags que podem ser utilizadas, veja [isto](/contribute/labels-of-issues.md).

* Para contribuir com demonstrações K8s, por favor consulte este [documento](/contribute/CONTRIBUTING-TO-K8S-DEMO.md).
    - Para verificar como OpenEBS funciona com K8s, consulte este [documento](/k8s/README.md)
- Para contribuir ao Provisioner Kubernetes OpenEBS, por favor consulte este [documento](/contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).

Consulte este [documento](/contribute/design/code-structuring.md) para mais informações sobre estruturação de código e guias para serem seguidos.

## Corrija problemas existentes

Vá até os [issues](https://github.com/openebs/openebs/issues) para encontrar problemas onde a ajuda de contribuintes é necessária. Veja nossa [lista de labels](/contribute/labels-of-issues.md) para te ajudar a encontrar um problema que possa resolver rapidamente.

Uma pessoa querendo contribuir pode pegar um problema através de um comentário/atribuição ao seu ID GitHub. Em caso de não ter um Pull Request ou atualização em progresso por uma semana no problema mencionado, o problema é aberto novamente para qualquer um pegar. Nós precisamos considerar problemas/regressões de alta prioridade onde o tempo de resposta precisa ser em torno de um dia.

---
### Assine seu trabalho

Nós utilizamos o Developer Certificate of Origin (DCO) como garantia adicional ao projeto OpenEBS. Isso é um mecanismo amplamente estabelecido e usado para garantir que contribuidores confirmem o seu direito de licenciar sua contribuição sob a licença do projeto. Por favor leia [developer-certificate-of-origin](/contribute/developer-certificate-of-origin).

Se você puder certificar, apenas adicione uma linha em cada mensagem de commit:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````
ou utilize o comando `git commit -s -m "mensagem de commit aqui"` para assinar seus commits.

Utilize seu nome real (desculpe, sem pseudônimos ou contribuições anônimas). Se você configurar seu `user.name` e `user.email` no git, você pode assinar seu commit automaticamente com `git commit -s`. Você também pode utilizar git [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) como `git config --global alias.ci 'commit -s'`. Agora você pode realizar o commit com `git ci` e o commit será assinado.

---

## Entre na nossa comunidade

Quer desenvolver ativamente e contribuir com a comunidade OpenEBS, consulte este [documento](/community/README.md).