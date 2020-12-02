serialNumber=$(ioreg -l | awk '/IOPlatformSerialNumber/ {​​print $4;}​​' | sed 's/"//g')
model=$(ioreg -l |grep "product-name" |cut -d ""="" -f 2 | sed 's/[0-9,<>"]*//g')
sudo scutil –-set HostName $model-$serialNumber 
sudo scutil –-set LocalHostName $model-$serialNumber
sudo scutil –-set ComputerName $model-$serialNumber