# Dungeons & Dragons: Tower of Doom — Tradução PT-BR

Tradução para português do Brasil do arcade **Dungeons & Dragons: Tower of Doom** (Capcom, 1994, CPS2), romset `ddtodur1` (EUA, 940113).

> Este repositório contém **apenas** as ferramentas e os textos da tradução. Nenhuma ROM, chave de criptografia ou dado da Capcom é distribuído aqui. Para jogar, você precisa ter a sua própria cópia do jogo.

## O que está traduzido

- Introdução e história completa (incluindo os caminhos alternativos)
- Lojas e NPCs, escolhas de caminho, placas e dicas
- Falas dos chefes, magias, itens, nomes de inimigos
- Subida de nível ("chegou ao nível 8 / Seus PV máximos aumentaram…")
- Mensagens de ficha e start ("INSIRA FICHA", "APERTE START", "ENTRAR!", "FICHAS:")
- Gráficos redesenhados:
  - painel dos jogadores (nomes dos itens, iniciais das classes, "N" de nível)
  - tela de seleção: LUTADOR, CLÉRIGO, ELFA, ANÃO e as legendas das caixas
  - ranking
  - banner da demo
- Novos caracteres acentuados nas fontes (ã, õ, ç, â, ê, ô, à, Ç, Ã, Õ…)

Ainda em inglês (gráficos decorativos): "PLAYER SELECT", "CONTINUE", "GAME OVER", "RANKING", "BONUS/TOTAL" e o "L-10" do ranking.

## Como jogar

1. Baixe o patch na página de [Releases](../../releases).
2. Use o romset `ddtodur1` da versão atual do MAME/FinalBurn Neo, que já inclui o `ddtodu.key`.
3. Aplique o patch nos arquivos correspondentes (`dadu.03a`, `dadu.04a`, `dadu.05a`, `dad.13m`–`dad.20m`).

**FinalBurn Neo (RetroArch):**
- Coloque os arquivos modificados num zip chamado `ddtodur1.zip` em `system/fbneo/patched/`.
- Deixe ligada a opção do core *Allow patched romsets*.
- O zip original continua na pasta de ROMs, sem alteração. O FBNeo recusa arquivos modificados dentro do zip principal por causa do CRC.

**MAME:** substitua os arquivos dentro do `ddtodur1.zip`. O MAME avisa que o checksum não confere, mas o jogo roda normalmente.

## Compilando a partir do código

Requisitos:
- **Perl 5** com `Compress::Zlib` e `Digest::SHA`.
- **PHP com GD**, só para as ferramentas de análise de capturas de tela.
- No Windows, o Git Bash funciona bem.

```bash
# 1. extraia o ddtodur1.zip ORIGINAL numa pasta (ex.: rom/)
# 2. rode o build
T=projeto/tools perl projeto/tools/build.pl rom projeto/traducao out
```

O build lê os arquivos originais e aplica:
- os textos de `projeto/traducao/*.txt`;
- o redesenho de fontes e gráficos;
- o reapontamento de ponteiros.

Ele grava em `out/` os arquivos da ROM já modificados e lista no fim quais mudaram.

## Estrutura

```
projeto/
  tools/            scripts do build e de análise
    build.pl        build principal: aplica toda a tradução
    font.pl         fonte 8x16 dos diálogos e glifos acentuados novos
    labelfont.pl    rótulos do painel (INSIRA FICHA, itens…)
    tagfont.pl      legendas das caixas da tela de seleção
    namefont.pl     nomes das classes (seleção, painel e ranking)
    cps2crypt.pl    criptografia CPS2: o build re-encripta deslocamentos lea d16(pc)
    m68kdis.pl      disassembler 68000 simples
    xref.pl, findtxt.pl, strdump.pl …   busca de textos, ponteiros e referências
    match16.php, s1find.php, boxgrid.php …  localizam tiles a partir de capturas de tela
  traducao/         textos (formato "chave|texto", # = comentário)
    story.txt       história (registros do bloco principal)
    intro.txt       introdução
    shop.txt        lojas e NPCs
    choices.txt     escolhas de caminho
    hints.txt       placas e dicas
    bosses*.txt     falas dos chefes
    spells.txt      magias
    items.txt, enemies.txt
    textmap.txt     mensagens do sistema (substituição no lugar)
    bytemap.txt     textos ASCII de tamanho fixo
    …
```

## Notas técnicas

- **Programa:**
  - A imagem do programa é `dadu.03a`, `dadu.04a`, `dadu.05a`, `dad.06` e `dad.07` concatenados, com as palavras de 16 bits invertidas (byte-swap).
  - No CPS2, só as instruções são criptografadas. Os textos e as tabelas de ponteiros ficam em claro.
  - Leituras relativas ao PC (`lea d16(pc)`) passam pela criptografia, por isso o build re-encripta esses deslocamentos.
- **Textos:**
  - Cada caractere é uma palavra de 16 bits com o código do tile.
  - `0x2F2F` = quebra de linha, `0x4040` = fim da string.
  - As tabelas de idioma têm 9 entradas (JP, EN, ES, EN, EN, ES, FR, DE, IT); a versão americana usa a de índice 1.
  - Os blocos de texto de outros idiomas que não são usados viraram espaço livre para os textos em português, que são mais longos.
- **Gráficos:**
  - Os gráficos (`dad.13m`–`dad.20m`) estão intercalados de 64 bits e reorganizados em blocos de 2 MB.
  - Os tiles da camada de texto (8x8) ficam na unidade `0x20000 + código`; os sprites, em blocos de 16x16.

## Créditos

- Tradução, hacking e testes: **SEU NOME AQUI**
- Jogo original: © Capcom 1994 · Dungeons & Dragons © TSR, Inc. · licenciado pela SSI

Projeto de fã, sem fins lucrativos. Não venda o patch nem ROMs com ele aplicado.
