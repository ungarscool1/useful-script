@echo off
chcp 65001
cls
title Assistant de création de vm et de nat Network
echo Avant de commencer, il faut exécuter se script sur ce PC 1 seule fois si vous l'exécuter plusieurs fois il peut avoir des problèmes
echo "Appuyer sur ENTRER pour accepter, ou CTRL+C pour quitter"
pause > nul
echo Téléchargement de VirtualBox...
powershell -Command "Start-BitsTransfer -Source https://download.virtualbox.org/virtualbox/5.2.22/VirtualBox-5.2.22-126460-Win.exe -Destination VirtualBox-5.2.22-126460-Win.exe" 
VirtualBox-5.2.22-126460-Win.exe 
echo Appuyer sur ENTRER quand l'installation de VirtualBox est terminé !
pause > nul
echo Paramètrage du pare-feu...
netsh advfirewall firewall add rule name="VBox - Désactiver le réseau local" program="(VirtualBox.exe)" dir=out action=block profile=any interfacetype=lan
pause
cls
echo "Où est situé l'installation de virtualbox ? "
echo "Si vous n'avez pas changer le répertoire d'installation pour pouvez laisser vide
set /p vboxmanager="Executable: "
if [%vboxmanager%] == [] (
	set vboxmanager="C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
)
echo "Où voulez-vous enregistrer cette vm ?"
set /p vboxLocation="Chemin: "
if [%vboxLocation%] == [] (
	echo L'emplacement par défaut est sélectionner
) else (
	title Assistant de création de vm et de nat Network - Merci de patientez
	%vboxmanager% setproperty machinefolder %vboxLocation%
)
cls
title Assistant de création d'un Nat Network
echo Bienvenue sur l'assistant de création de Nat Network
:natname
set /p natnetName="Nom du réseau: "
if [%natnetName%] == [] (
	echo Le nom ne peut être vide
	goto natname
)
echo "Il est recommendé de prendre 10.0.2.0/24"
:natIP
set /p natnetIp="Ip du réseau: "
if [%natnetIp%] == [] (
	echo L'ip ne peut être vide
	goto natIP
)
:ipdhcp
set /p ipdhcp="Ip du serveur dhcp: "
if [%ipdhcp%] == [] (
	echo L'ip ne peut être vide
	goto ipdhcp
)
:lowip
set /p lowerip="Ip la plus basse: "
if [%lowerip%] == [] (
	echo L'ip ne peut être vide
	goto lowip
)
:upip
set /p upperip="Ip la plus haute: "
if [%upperip%] == [] (
	echo L'ip ne peut être vide
	goto upip
)
:subnetMask
set /p mask="Masque de sous-réseau: "
if [%mask%] == [] (
	echo Le masque de sous-réseau ne peut être vide
	goto subnetMask
)
cls
title Assistant de creation d'un Nat Network - Ne pas fermer la fenêtre - Création du réseau
%vboxmanager% natnetwork add --netname %natnetName% --network %natnetIp% --enable --dhcp on
%vboxmanager% dhcpserver add --netname %natnetName% --ip %ipdhcp% --lowerip %lowerip% --upperip %upperip% --netmask %mask%
%vboxmanager% dhcpserver modify --netname %natnetName% --enable
cls
echo Assistant de création de Nat Network est terminé
title Assistant de création de machine virtuel
:vmName
set /p vmName="Nom de la machine: "
if [%vmName%] == [] (
	echo Le nom de la machine ne peut être vide
	goto vmName
)
:vmOS
echo Exemple pour Windows Server 2016 64 bits ça sera: Windows2016_64
echo Pour Windows 7 32 bits ça sera: Windows7
set /p vmOS="Système d'exploitation: "
if [%vmOS%] == [] (
	echo Le système d'exploitation de la machine ne peut être vide
	goto vmOS
)
:vmDS
set /p vmDiskSize="Taille du disque (en mb): "
if [%vmDiskSize%] == [] (
	echo Le nom de la machine ne peut être vide
	goto vsDS
)
:vmR
set /p vmRam="Taille de la Ram (en mb): "
if [%vmRam%] == [] (
	echo Le nom de la machine ne peut être vide
	goto vmR
)
:vmISO
set /p vmISO="Emplacement de l'image ISO de %vmOS%"
if not exist [%vmISO%] (
	echo Le l'image iso d'installation de la machine ne peut être vide
	goto vmISO
)
cls
title Assistant de création de machine virtuel - Création de %vmName% en cours...
echo Création du disque virtuel
%vboxmanager% createhd --filename %vmName%.vdi --size %vmDiskSize%
echo Création de %vmName% sur %vmOS%
%vboxmanager% createvm --name %vmName% --ostype %vmOS% --register
echo Attachement d'un contrôleur SATA à %vmName%
%vboxmanager% storagectl %vmName% --name "SATA Controller" --add sata --controller IntelAHCI
echo Attachement du disque à %vmName%
%vboxmanager% storageattach %vmName% --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium %vmName%.vdi
echo Attachement d'un contrôleur IDE à %vmName%
%vboxmanager% storagectl %vmName% --name "IDE Controller" --add ide
echo Attachement de l'image ISO à %vmISO%
%vboxmanager% storageattach %vmName% --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium %vmISO%
echo Application des dernièrs paramètres...
%vboxmanager% modifyvm %vmName% --ioapic on
%vboxmanager% modifyvm %vmName% --boot1 dvd --boot2 disk --boot3 none --boot4 none
%vboxmanager% modifyvm %vmName% --memory %vmRam% --vram 128
%vboxmanager% modifyvm %vmName% --nic1 natnetwork --nat-network1 %natnetName%
%vboxmanager% modifyvm %vmName% --nic2 hostonly
cls
title Assistant de création de vm et de nat Network
echo L'assistant a terminé son travail !
echo Démarrage de %vmName%...
%vboxmanager% startvm %vmName% --type gui
PAUSE
