##Install DCU 2.4##
msiexec /i "DellCommandUpdate.msi" /qn
##Apply the DCU Policy##
"C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" /import /policy policy.xml
##Silently Launch DCU to implement the policy##
"C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" /silent /policy
