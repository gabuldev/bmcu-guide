# bmcu_flash

Grava o firmware do BMCU-370C pela porta USB (CH340 da placa), sem Flutter.

- `BmcuFlasher`: protocolo do bootloader serial da WCH (CH32V203), com
  entrada automatica no bootloader pelas linhas DTR/RTS.
- `FirmwareRepository`: baixa a variante escolhida do repositorio do firmware
  e confere tamanho, CRC32 e SHA-256 com o `manifest.txt` publicado.

O transporte e uma interface (`SerialLink`); o app implementa sobre o
`usb-serial-for-android`, os testes usam um bootloader simulado.

`dart run tool/fetch.dart` baixa e confere uma variante de verdade.

## Credito

Protocolo e sequencia de gravacao portados do
[BMCU Flasher](https://github.com/jarczakpawel/BMCU-Flasher), de Pawel
Jarczak, licenca MIT:

> Copyright (c) 2026 Paweł Jarczak
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.
