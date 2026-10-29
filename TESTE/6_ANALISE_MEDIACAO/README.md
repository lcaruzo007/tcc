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
| Localização | Categoria observada de `AREA_LOCAL` | `Urbana_Capital` | Somente os dois grupos do contraste |

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

Bootstrap percentil com 1.000 simulações e semente 2023. O desenho observacional
agregado e o bootstrap, sozinhos, não identificam efeitos causais.
