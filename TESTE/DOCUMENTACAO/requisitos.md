# Ambiente e dependências

## Ambiente reproduzível

O ambiente registrado usa **R 4.6.0**. As versões exatas dos pacotes e suas
dependências transitivas estão em [renv.lock](../../renv.lock).

No R, a partir da raiz, para preparar outra máquina:

```r
install.packages("renv")
renv::restore(prompt = FALSE)
```

O executor confere a versão de R e todas as versões registradas antes de iniciar
as análises. Havendo uma biblioteca restaurada em `renv/library/`, ela é carregada
explicitamente tanto no processo principal quanto em cada subprocesso, mesmo com
`--vanilla`. Em um ambiente já compatível, é possível usar a biblioteca existente.

Não se instala nem atualiza pacote durante a análise. Para atualizar o ambiente
deliberadamente, valide a nova configuração antes de gerar outro lockfile.
`renv::restore()` restaura pacotes, mas não instala a versão do próprio R.

## Dependências diretas

| Pacotes | Uso |
|---------|-----|
| `tidyverse`, `data.table` | Leitura, transformação e gráficos |
| `caret` | Filtro near-zero opcional das correlações |
| `broom`, `car`, `patchwork` | Modelos, VIF e composição de figuras |
| `lmtest`, `sandwich` | Diagnósticos e erros-padrão HC3 |
| `ggdendro`, `dendextend` | Dendrogramas |
| `mediation`, `boot` | Mediação e bootstrap |
| `shiny` | Dashboard manual |
| `readxl` | Comparação manual com entrada XLSX |
| `jsonlite` | Leitura do lockfile; dependência transitiva registrada |

O pipe nativo exige R >= 4.1, mas isso é apenas um requisito de sintaxe.
O ambiente suportado pelo executor é o que está registrado no lockfile.

## Verificar

```powershell
Rscript TESTE/DOCUMENTACAO/verificar_dependencias.r
Rscript TESTE/DOCUMENTACAO/testar_contratos.r
Rscript TESTE/DOCUMENTACAO/validar_pipeline.r --exigir-dados
```

A verificação de dependências confere o lockfile e a disponibilidade dos pacotes.
Os testes sintéticos independem dos microdados. `--exigir-dados` solicita também
a validação dos metadados reais; sem esse argumento, sua ausência é explicitamente
reportada como validação parcial.

Se `Rscript` não estiver no PATH, use o executável da instalação ou configure o
PATH. RStudio é opcional. Referência de funcionamento:
[documentação do renv](https://pkgs.rstudio.com/renv/articles/renv.html).
