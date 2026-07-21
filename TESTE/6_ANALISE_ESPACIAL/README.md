# Fase 6 — Análise Espacial (Mapas Coropléticos)

Mapas de proficiência e INSE por município de Minas Gerais.

## Execução

```r
source("TESTE/6_ANALISE_ESPACIAL/Scripts/mapa_municipios.r")
```

## Dependências

```r
install.packages(c("sf", "geobr", "tmap"))
```

## Saídas

| Arquivo | Descrição |
|---------|-----------|
| `outputs/figuras/mapa_MT_municipios_*.png` | Figura 16: Proficiência MT por município |
| `outputs/figuras/mapa_LP_municipios_*.png` | Figura 17: Proficiência LP por município |
| `outputs/figuras/mapa_INSE_municipios_*.png` | Figura 18: INSE por município |
| `outputs/tabelas/municipios_agregados_*.csv` | Dados agregados por município |

## Metodologia

1. Integra `metadados_escolas` com `TS_ESCOLA.csv` via `ID_ESCOLA` para obter `ID_MUNICIPIO`
2. Agrega proficiência e INSE por município
3. Download do shapefile de MG via `geobr::read_municipality(code_muni = "MG")`
4. Gera mapas coropléticos com `tmap` (5 quantis)
