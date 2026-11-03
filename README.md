# BMCU Scanner

App Android que atualiza o firmware do **BMCU-370C** pelo cabo USB do celular
e diagnostica o BMCU pela rede da impressora Bambu Lab. Não precisa de PC.

**[Baixar o APK](https://github.com/gabuldev/bmcu-guide/releases/latest/download/bmcu-scanner.apk)**
· [Todas as versões](https://github.com/gabuldev/bmcu-guide/releases)

> 🎥 Vídeo do passo a passo no canal Gabul: _link em breve_

## O que o app faz

- **Atualiza o BMCU para a V11.** O app baixa o firmware do
  [projeto oficial do BMCU](https://github.com/jarczakpawel/BMCU-C-PJARCZAK),
  confere o arquivo com o `manifest.txt` publicado e grava pelo cabo USB OTG.
- **Faz diagnóstico pela rede.** Acha a impressora no Wi-Fi e mostra a versão
  do BMCU e o estado de cada canal. Também explica os alertas HMS em português.
- **Não mexe na impressora.** Com a impressora, o app só lê dados e nunca
  manda comandos. O código de acesso fica salvo só no seu celular.

## Compatibilidade

| | Funciona | Não funciona |
|---|---|---|
| Placa | BMCU-370C (chip CH32V203) com porta USB-serial CH340 (aparece como `USB Serial 1a86:7523`) | Placas com USB nativo do chip |
| Firmware | Grava a V11 do projeto oficial; atualiza qualquer versão anterior | — |
| Impressora | A1 e A1 mini (força padrão ou suave); P1S e X1 (força alta) | — |
| Celular | Android com USB OTG | iPhone/iPad |

Para atualizar você precisa de um cabo **USB OTG** (USB-C ou micro-USB do
celular para o conector do BMCU).

Para o diagnóstico pela rede, a impressora precisa estar com **LAN Only** e
**Developer Mode** ligados. **Reinicie a impressora** depois de ligar esses
modos, senão ela aparece na rede mas não aceita conexão.

## Como instalar o APK

1. No celular, abra o link **Baixar o APK** acima.
2. Abra o arquivo baixado. Quando o Android pedir, deixe o navegador (ou o
   gerenciador de arquivos) **instalar apps desconhecidos**. Essa opção fica
   em *Configurações → Apps → Acesso especial → Instalar apps desconhecidos*.
3. Toque em **Instalar**. Se o Play Protect avisar, toque em
   *Mais detalhes → Instalar mesmo assim*. O app não está na Play Store, por
   isso aparece esse aviso.

Se você instalou uma versão de teste antes e o Android disser que o app
"não foi instalado" ou que há conflito, desinstale a versão antiga e instale
de novo.

## Atualizar o BMCU para a V11

1. Abra o app e toque em **Atualizar BMCU**.
2. Escolha a **mesma configuração que você usa hoje**: força de carregamento,
   autoload, LED na cor do filamento, número do AMS e distância de retração.
   Na dúvida, use *Padrão (A1)* para A1/A1 mini e *Forte (P1S/X1)* para P1S.
   Se a configuração não combinar com a impressora, o app avisa.
3. **Desligue a impressora.** Só então desconecte o cabo do BMCU que vai para
   a impressora.
4. Ligue o BMCU no celular com o cabo OTG e aceite a permissão de USB.
5. Marque a confirmação de segurança e toque em **Gravar**. **Não desconecte
   o cabo** até aparecer o ✅. A gravação leva menos de um minuto.
6. Desconecte o BMCU do celular e ligue ele na impressora, **com a impressora
   ainda desligada**. Depois ligue a impressora.
7. Se os LEDs ficarem amarelos, está pronto. Se ficarem **vermelhos**, calibre
   os buffers (veja abaixo).

### Calibrar os buffers

Na primeira atualização pelo app, a calibração **costuma ser apagada**. Isso
acontece porque o gravador antigo deixava o chip protegido, e tirar a
proteção apaga a memória inteira. Nas próximas atualizações a calibração
deve ser mantida.

1. Tire o filamento de todos os canais, até passar o sensor do BMCU.
2. Ligue a impressora sem encostar nos buffers. Os LEDs piscam amarelo
   enquanto o BMCU lê a posição de repouso.
3. Quando o LED do canal piscar **azul**, **empurre** o buffer até o fim por
   1 s e solte.
4. Quando piscar **vermelho**, **puxe** até o fim por 1 s e solte.
5. Repita nos outros canais. Duas piscadas verdes indicam que a calibração
   foi salva.

Faça na ordem certa: azul é empurrar e vermelho é puxar. Se fizer ao
contrário, o motor não percebe a pressão e continua empurrando o filamento
depois de chegar na extrusora. Para conferir, empurre o buffer com a mão: o
LED tem que ficar azul.

O diagnóstico do app mostra esses passos quando detecta um BMCU sem
calibração.

## Riscos

- **Ligar ou desligar o cabo com a impressora ligada pode queimar o BMCU ou a
  placa da impressora.** Desligue sempre a impressora antes.
- Se a gravação parar no meio, o BMCU fica sem firmware até você gravar de
  novo. Ele não estraga: o modo de gravação do chip não se apaga.
- A configuração errada (por exemplo, força alta numa A1) pode moer o
  filamento ou recusar carregamentos. Se isso acontecer, grave de novo com a
  configuração certa.
- Este app não é oficial da Bambu Lab nem do projeto BMCU. Use por sua conta.

## Se der erro

| Mensagem | O que fazer |
|---|---|
| Nenhum BMCU encontrado no USB | Confira o cabo OTG e se o BMCU acendeu. Alguns cabos só carregam e não passam dados; teste outro cabo. |
| Permissão USB negada | Desconecte, conecte de novo e toque em **Permitir**. |
| A gravação parou no meio | Toque em **Tentar de novo** sem desconectar. Se não for, desconecte, conecte e grave outra vez. |
| O BMCU não voltou ao modo de gravação | Desconecte o cabo, espere 5 s, conecte e tente de novo. |
| Falha ao baixar o firmware | Confira a internet do celular e tente de novo. |
| LEDs vermelhos depois de atualizar | Calibre os buffers (veja acima). |
| Motor continua empurrando o filamento na extrusora | A calibração foi feita ao contrário. Tire o filamento de todos os canais e segure um buffer na posição em que o LED fica azul por 5 s (com a calibração invertida, é puxando). O BMCU apaga a calibração e reinicia; calibre de novo. |
| Impressora não aparece no diagnóstico | Celular e impressora precisam estar na mesma rede, com LAN Only e Developer Mode ligados. Reinicie a impressora. |

Se o problema continuar, toque em **Detalhes** na tela do app, tire um print
do log e abra uma issue neste repositório.

## Este repositório

- `scanner/`: código do app em Flutter, com o gravador USB portado do
  [BMCU Flasher](https://github.com/jarczakpawel/BMCU-Flasher). Veja o
  [README do app](scanner/README.md) e os [avisos de licença](scanner/THIRD_PARTY_NOTICES.md).
- `index.html`, `assets/`, `data/`: site do guia do BMCU-370C, com a tabela
  de alertas HMS que o app usa.

Créditos: o firmware do BMCU e o gravador original são de Paweł Jarczak.
