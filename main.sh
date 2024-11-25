#!/bin/bash

set -euo pipefail

# Configurações globais
MAIL_TO="admin@example.com"
HOSTNAME=$(hostname)
SUBJECT="Relatório de Uso de Armazenamento no Servidor $HOSTNAME"
TMP_REPORT="/tmp/storage_report.txt"

# Função para verificar espaço em disco
generate_report() {
    local report_file="$1"
    local threshold=80  # Limite de utilização em % para alerta

    printf "Relatório de Uso de Armazenamento - Servidor: %s\n" "$HOSTNAME" > "$report_file"
    printf "Gerado em: %s\n\n" "$(date +"%Y-%m-%d %H:%M:%S")" >> "$report_file"
    printf "%-25s %-10s %-10s %-10s %-10s\n" "Sistema de Arquivos" "Tamanho" "Usado" "Disponível" "Uso%" >> "$report_file"
    printf "%-25s %-10s %-10s %-10s %-10s\n" "-------------------" "-------" "-----" "----------" "----" >> "$report_file"

    local alert=0

    while read -r fs size used avail useperc mount; do
        printf "%-25s %-10s %-10s %-10s %-10s\n" "$fs" "$size" "$used" "$avail" "$useperc" >> "$report_file"
        local usage="${useperc%%%}"
        if (( usage >= threshold )); then
            alert=1
            printf "\n[ALERTA] O sistema de arquivos %s está com %s de uso.\n" "$fs" "$useperc" >> "$report_file"
        fi
    done < <(df -h --output=source,size,used,avail,pcent,target | tail -n +2)

    return $alert
}

# Função para enviar email
send_email() {
    local report_file="$1"
    if ! mail -s "$SUBJECT" "$MAIL_TO" < "$report_file"; then
        printf "Erro ao enviar o email para %s\n" "$MAIL_TO" >&2
        return 1
    fi
    return 0
}

main() {
    local report_status

    if ! generate_report "$TMP_REPORT"; then
        printf "Erro ao gerar relatório de armazenamento\n" >&2
        return 1
    fi

    report_status=$?

    if ! send_email "$TMP_REPORT"; then
        printf "Erro ao enviar relatório por email\n" >&2
        return 1
    fi

    if (( report_status == 0 )); then
        printf "Relatório enviado com sucesso e sem alertas.\n"
    else
        printf "Relatório enviado com alertas de uso elevado.\n"
    fi

    rm -f "$TMP_REPORT"
}

main "$@"
