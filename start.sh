#!/bin/bash

# script pra rodar novamente o server automático em caso de crash
echo "Iniciando o programa"

cd /home/OTG-Premium-Version
mkdir -p logs

#configs necessárias para o Anti-rollback
ulimit -c unlimited
set -o pipefail

while true 		#repetir pra sempre
do
 	#roda o server e guarda o output ou qualquer erro no logs
	#PS: o arquivo antirollback_config deve estar na pasta do tfs	
	gdb --batch -return-child-result --command=antirollback_config --args ./tfs 2>&1 | awk '{ print strftime("%F %T - "), $0; fflush(); }' | tee "logs/$(date +"%F %H-%M-%S.log")"
	if [ $? -eq 0 ]; then							 
		echo "Exit code 0, aguardando 3 minutos..."	 #pra ser usado no backup do banco de dados
		sleep 180	#3 minutos						
	else											
		echo "Crash!! Reiniciando o servidor em 5 segundos (O arquivo de log está guardado na pasta logs)"
		echo "Se quiser encerrar o servidor, pressione CTRL + C..."		
		sleep 5										
	fi												
done;                  
