#!/usr/bin/env python3
"""
Script para executar a limpeza de dados SAEB
"""
import subprocess
import sys
import os

# Caminho do script R
r_script = r"C:\Users\Usuario\Desktop\tcc\TESTE\1_LIMPEZA_E_TRANSFORMACAO\ajeitar_dados_fixo.r"

# Localizar o Rscript
r_paths = [
    r"C:\Program Files\R\R-4.4.2\bin\Rscript.exe",
    r"C:\Program Files\R\R-4.4.1\bin\Rscript.exe",
    r"C:\Program Files\R\R-4.4.0\bin\Rscript.exe",
    "Rscript.exe",  # Tenta usar a versão no PATH
]

rscript_path = None
for path in r_paths:
    if os.path.exists(path) if os.path.isabs(path) else True:
        rscript_path = path
        break

if rscript_path is None:
    print("❌ Rscript não encontrado. Instale R-Project.")
    sys.exit(1)

print(f"📦 Usando: {rscript_path}")
print(f"📄 Executando: {r_script}\n")

# Executar o script
result = subprocess.run(
    [rscript_path, r_script],
    capture_output=True,
    text=True
)

# Exibir saída
if result.stdout:
    print(result.stdout)
if result.stderr:
    print("STDERR:", result.stderr, file=sys.stderr)

# Retornar código de erro
sys.exit(result.returncode)
