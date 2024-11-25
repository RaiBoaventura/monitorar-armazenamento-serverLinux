#!/bin/bash

# Configurações de email
EMAIL="seu_email@example.com"
SUBJECT="Relatório de Armazenamento do Servidor"

# Gerar relatório de armazenamento
REPORT=$(df -h | awk 'NR==1 || /^\/dev\//')

# Adicionar informações ao relatório
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
REPORT_HEADER="Relatório de Armazenamento\nHost: $HOSTNAME\nData: $DATE\n\n"
FULL_REPORT="$REPORT_HEADER$REPORT"

# Enviar email diretamente no corpo
if command -v mail &> /dev/null; then
    echo -e "$FULL_REPORT" | mail -s "$SUBJECT" "$EMAIL"
    echo "Relatório enviado para $EMAIL"
else
    echo "Erro: O comando 'mail' não está instalado. Instale-o com 'sudo apt install mailutils'"
fi
