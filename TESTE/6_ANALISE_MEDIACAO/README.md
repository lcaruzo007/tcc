# Mediação exploratória · passo 10

Estuda a decomposição de associações entre contexto escolar, INSE médio e
proficiência. A descrição metodológica principal está em
[metodologia.md](../DOCUMENTACAO/metodologia.md#mediação-exploratória--passo-10).

## Executar

```powershell
Rscript executar_pipeline.r --passos=10
```

O executor gera metadados atualizados no passo 4 antes da mediação e registra
entradas, saídas, ambiente e logs no manifesto.

## Contrastes

| Análise | Tratamento | Referência | Base utilizada |
|---------|------------|------------|----------------|
| Tipo | Privada | Pública | Escolas elegíveis |
| Localização nas públicas | `Urbana_Interior` | `Urbana_Capital` | Somente públicas urbanas |
| Localização nas particulares | `Urbana_Interior` | `Urbana_Capital` | Somente particulares urbanas |
| Localização | Categoria observada de `AREA_LOCAL` | `Urbana_Capital` | Somente os dois grupos do contraste |
| Interior | `Rural_Interior` | `Urbana_Interior` | Somente escolas rurais e urbanas do interior |

A elegibilidade exige cinco notas válidas por disciplina, três valores válidos
de INSE e contexto completo. Não há covariáveis adicionais nas fórmulas.
Categorias sem variação são ignoradas. Os diagramas usam os modelos do contraste,
sem ajustar novamente outra amostra.

## Saídas

Todas ficam em `outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>`.

- `tabelas/mediacao_*.csv`: efeitos, intervalos, p-valores, proporção mediada,
  referência, tamanho de cada grupo e indicação do ajuste exploratório.
- `diagnosticos/fluxo_amostra_mediacao_*.csv`: denominadores e elegibilidade.
- `figuras/caminhos_mediacao_*.png`: diagramas dos modelos estimados.

As Figuras 18–19 comparam tipos de escola; 20–21 comparam interior e capital
nas públicas urbanas; 22–23 fazem o mesmo nas particulares urbanas; 24–25
comparam rural e urbana do interior; 26–27 comparam rural do interior e urbana
da capital; 28–29 comparam urbana do interior e urbana da capital.
Veja as [legendas para o TCC](legendas_figuras.md). Categorias não observadas,
como rural da capital no recorte atual, não geram figuras.
Os nomes dos novos PNGs incluem `Urbana_Interior_Publica` ou
`Urbana_Interior_Privada`; a coluna `Tipo_Escola_Recorte` distingue os recortes
na tabela, com `Todas` nos contrastes gerais.

Bootstrap percentil com 1.000 simulações e semente 2023. O desenho observacional
agregado e o bootstrap, sozinhos, não identificam efeitos causais.

## Segunda versão das imagens

O passo 10 também gera diagramas em `figuras/sem_textos/`, somente com caixas,
setas e coeficientes a, b e c'. Sem título, subtítulo, R², rodapé ou texto sobre
a proporção mediada. Os grupos e a referência (0) aparecem dentro da caixa inicial.
As figuras completas continuam em `figuras/`.

Para gerar somente essa versão a partir dos modelos já salvos, sem repetir o bootstrap:

```powershell
Rscript TESTE/6_ANALISE_MEDIACAO/Scripts/gerar_figuras_sem_textos.r
```
