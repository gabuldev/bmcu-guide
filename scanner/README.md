# BMCU Scanner (código)

App que acha impressoras Bambu na rede, lê o BMCU pelo MQTT local e explica
os alertas HMS usando a tabela do guia ([`data/hms-bmcu.json`](../data/hms-bmcu.json)).
O guia de uso está no [README principal](../README.md).

- `packages/bambu_core`: núcleo em Dart puro, com descoberta SSDP, cliente
  MQTT mínimo, detecção do BMCU e da versão e consulta da tabela. Tem CLI:
  `dart run bin/scan.dart [IP SERIAL CODIGO]`.
- `packages/bmcu_flash`: gravação do firmware pelo USB do BMCU (bootloader
  da WCH), portada do [BMCU Flasher](https://github.com/jarczakpawel/BMCU-Flasher)
  (MIT). Baixa a variante escolhida e confere com o `manifest.txt` oficial.
- `app`: Flutter. Com a impressora, só leitura: nunca manda comando que mexa
  nela. No Android, também grava o BMCU por um cabo USB OTG (BMCU desligado
  da impressora).

## Requisitos na impressora

LAN Only + Developer Mode ligados, e **reiniciar a impressora depois** de
ligar. Sem reiniciar, ela continua anunciando na rede mas não aceita conexão.

## Atualizar a tabela embutida

    cp ../data/hms-bmcu.json app/assets/

O app tenta baixar a tabela publicada primeiro; a embutida é o fallback sem
internet.

## APK de release

A assinatura vem de `app/android/key.properties`, que está no `.gitignore`.
O keystore fica fora do repositório:

    storeFile=/caminho/para/bmcu-scanner.jks
    storePassword=...
    keyAlias=bmcu-scanner
    keyPassword=...

Sem esse arquivo, o release sai assinado com a chave de debug. Toda versão
publicada precisa usar a mesma chave; senão o Android não instala por cima.

    cd app && flutter build apk --release
