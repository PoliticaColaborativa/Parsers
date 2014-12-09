# crfb-senado.rb

Um script para auxiliar o projeto [PoliticaColaborativa/ConstituicaoBrasileira](//github.com/PoliticaColaborativa/ConstituicaoBrasileira) a capturar o texto de 1988.

**Instruções para quem usa Windows**

Instalar as dependências:
- [Ruby](http://rubyinstaller.org/)
- [DevKit](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit)
- Nokogiri: `gem install nokogiri`
- [Curb](http://blog.cloud-mes.com/2014/08/19/how-to-install-gem-curb-in-windows/)

Configurar o ambiente no PowerShell do GitShell:
```powershell
PS> cd ConstituicaoBrasileira\Parsers
PS> $env:Path += ";" + $pwd.Path

PS> cd DIRETÓRIO_DE_INTERESSE_PARA_CONTER_ARTIGOS
```

**Exemplo de como pegar o artigo 2º**
```powershell
PS> cd ..\pt-br\titulo_i
PS> con1988.rb 2
```
