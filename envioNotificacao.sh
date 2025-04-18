#!/bin/bash

# Função para extrair dados da página usando Puppeteer

get_page_data() {
   node - <<EOF
const puppeteer = require('puppeteer');
const fs = require('fs').promises;

(async () => {
    const browser = await puppeteer.launch({ args: ['--no-sandbox'] });
    const page = await browser.newPage();
    const url = 'http://IP_DO_SERVIDOR/alerting';

    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(5000);

    const dataElements = await page.evaluate(() => {
        const elements = document.querySelectorAll('.message.mb-5.b');
        const dateElements = document.querySelectorAll('.g-sm-3.grey.sm.hide-xs.time-line.tr');

        return Array.from(elements).map((element, index) => ({
            text: element.textContent.trim(),
            date: dateElements[index]?.textContent.trim(), // Use optional chaining to avoid errors if dateElements[index] is undefined
        }));
    });

    await browser.close();

    // Salvar dados em um arquivo JSON
    const jsonData = JSON.stringify(dataElements, null, 2);
    await fs.writeFile('alarm_data.log', jsonData);

    // Imprimir dados no console para envio por e-mail
    console.log(jsonData);
})();
EOF
}

# Endereço de e-mail remetente (sua conta de e-mail corporativo)
from="coloque seu email@gmail.com"

# Endereço de e-mail destinatário (pode ser o seu e-mail do Gmail)
to="coloque seu email@gmail.com"

# Assunto do e-mail
subject="Alarmes extraídos do Skywalking- Script envioNotificacao"

# Comandos para capturar o conteúdo da página em uma variável
alarm_info=$(get_page_data)

# Componha o e-mail
email=$(cat <<EOF
From: $from
To: $to
Subject: $subject

$alarm_info
EOF
)

# Defina o nome do arquivo de log de erro
log_file="erro_envio_email.log"

# Envie o e-mail usando sendmail e o Gmail SMTP, redirecionando erros para o arquivo de log
echo "$email" | sendmail -t 2> "$log_file"

# Verifique se ocorreu algum erro e, se sim, registre-o no arquivo de log
if [ $? -ne 0 ]; then
    echo "Erro ao enviar e-mail. Veja o arquivo de log '$log_file' para detalhes."
else
    echo "Email enviado com sucesso em $(date)" >> "$log_file"
    echo "Enviado com sucesso"
fi

