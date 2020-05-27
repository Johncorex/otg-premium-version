echo “Limpando Cache e Swap…”

echo 3 > /proc/sys/vm/drop_caches
sysctl -w vm.drop_caches=3
swapoff -a && swapon -a
clear
echo “Limpeza do Cache e Swap efetuada com sucesso”
