#!/bin/bash

############
###CONFIG###
############
domainsCsvPath="domains.csv"
blacklistedFilesPath="blacklisted/"

### Get Address for domain $1 = domain ###
getAddress(){
	cat $domainsCsvPath | grep $1 | cut -d ';' -f2
}

### Sende Mail zum Kunden 
### $1 = result aus blacklist check, $2 = adresse, $3 = domain
sendMailBlacklisted(){
echo "fange an mail raus zu senden"
echo "Lieber Kunde, 

	wir haben folgende Domain auf mindestens einer Blacklist gefunden.
	Wenden Sie sich bitte ggf. an unseren IT-Support.
	
	
	Betroffene Domain: '$3'
	Blacklists:
	'$1'
	
	" | mail -s "Domain: '$3' auf Blacklist gefunden" $2

}


### Sendet eine Mail zum Kunden, wird aufgerufen wenn es einen Statusupdate gibt
### $1 = result aus blacklist check, $2 = adresse, $3 = domain
sendMailUpdates(){

echo "Lieber Kunde, 

	wir haben folgende Domain auf mindestens einer Blacklist gefunden.
	Wenden Sie sich bitte ggf. an unseren IT-Support.
	
	
	Betroffene Domain: '$3'
	Blacklists:
	'$1'
	
	" | mail -s "UPDATE: Domain: '$3' auf Blacklist gefunden" $2

}

### Sendet eine Mail raus, dass die Domain
### $1 = result aus blacklist check, $2 = adresse, $3 = domain
sendMailBlacklistFree(){
echo "Lieber Kunde, 

	folgende Domain ist nichtmehr auf einer Blacklist. Hurray!
	
	
	Betroffene Domain: '$3'
	
	Blacklists:
	'$1'
	
	" | mail -s "UPDATE: Domain: '$3' von Blacklist entfernt" $2
}

### Prüft ob die Datei vor mindestens 24 Stunden verändert wurde
### $1 = filepath
checkIfFileIsOldEnough(){

modified=$(stat -c %Y $1)

now=$(date +"%s")

difference= now - modified

if [ difference >= 86400 ] ; then

	echo "true"

fi


}


# hole Domains aus CSV
domains=$(csvtool -t ";" col 1 $domainsCsvPath) 


# iteriere durch sie durch
for kunden_domain in $domains ; do

	result=$(./bl $kunden_domain | grep "blacklisted")

	if [ "$result" != "" ] ; then

		# IP wurde gefunden, lol
	
		# hole zugehörige addresse
		addresse=$(getAddress $kunden_domain)
		
		# prüfe ob es schon einen Status zu der Domain gibt
		# Merke: Es wird erst ein Status gespeichert wenn ein Vorfall vorliegt
		if [ -f $blacklistedFilesPath$kunden_domain.blacklisted ] ; then
		
			# prüfe ob inhalt der Datei != result aka es hat sich am Status etwas geändert
			if [ $(cat $blacklistedFilesPath$kunden_domain.blacklisted) != $result] ; then
				echo "Sende Update raus"
				sendMailUpdates "$result" "$addresse" "$kunden_domain"
				
				# Schreibe neuen Status
				echo $result > $blacklistedFilesPath$kunden_domain.blacklisted
			else
				
				# prüfe ob 24 stunden schon rum sind und wir ne neue mail schicken können
				if [ checkIfFileIsOldEnough $blacklistedFilesPath$kunden_domain.blacklisted = "true" ] ; then
					echo "Sende Mail raus and $addresse an "$addresse""
					sendMailBlacklisted "$result" "$addresse" "$kunden_domain"
			
				fi
				
			fi
		else
			echo "Sende mail raus an $addresse"
			sendMailBlacklisted "$result" "$addresse" "$kunden_domain"
			echo $result > $blacklistedFilesPath$kunden_domain.blacklisted
		
		fi
		
	else
	
		echo "Für Kunden Domain: $kunden_domain nichts gefunden"
		
		# prüfen ob jetzt noch ein Status vorliegt, wenn ja mail rausschicken und status löschen
		if [ -f $blacklistedFilesPath$kunden_domain.blacklisted ] ; then
			$result=$(cat $blacklistedFilesPath$kunden_domain.blacklisted)
			echo "Sende Mail raus"
			sendMailBlacklistFree "$result" "$addresse" "$kunden_domain"
			rm $blacklistedFilesPath$kunden_domain.blacklisted
		fi

	fi


done

