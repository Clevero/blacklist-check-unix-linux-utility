#!/bin/bash


### Get Address for domain $1 = domain ###
getAddress(){
	cat /mnt/d/domains.csv | grep $1 | cut -d ';' -f2
}

### Sende Mail zum Kunden 
### $1 = result aus blacklist check, $2 = adresse, $3 = domain
sendMailBlacklisted(){

echo "Lieber Kunde, 

	wir haben folgende Domain auf mindestens einer Blacklist gefunden.
	Wenden Sie sich bitte ggf. an unseren IT-Support.
	
	
	Betroffene Domain: '$3'
	Blacklists:
	$1
	
	Mit freundlichen Grüßen
	
	
	
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
	$1
	
	Mit freundlichen Grüßen
	
	
	
	" | mail -s "UPDATE: Domain: '$3' auf Blacklist gefunden" $2

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
domains=$(csvtool -t ";" col 1 /mnt/d/domains.csv) 


# iteriere durch sie durch
for kunden_domain in $domains ; do

	result=$(./bl $kunden_domain | grep "blacklisted")

	if [ "$result" != "" ] ; then

		# IP wurde gefunden, lol
	
		# hole zugehörige addresse
		adresse=$(getAddress $kunden_domain)
		
		# prüfe ob es schon einen Status zu der Domain gibt
		# Merke: Es wird erst ein Status gespeichert wenn ein Vorfall vorliegt
		if [ -f $kunden_domain.blacklisted ] ; then
		
			# prüfe ob inhalt der Datei != result aka es hat sich am Status etwas geändert
			if [ $(cat $kunden_domain.blacklisted) != $result] ; then
				
				sendMailUpdates $result $kunden_domain $addresse
				
				# Schreibe neuen Status
				echo $result > $kunden_domain.blacklisted
			else
				
				# prüfe ob 24 stunden schon rum sind und wir ne neue mail schicken können
				if [ checkIfFileIsOldEnough $kunden_domain.blacklisted = "true" ] ; then
			
					sendMail $result $kunden_domain $addresse
			
				fi
				
			fi
		else
		
			sendMail $result $kunden_domain $addresse
			
		
		fi
		
	else
	
		echo "Für Kunden Domain: $kunden_domain nichts gefunden"

	fi


done
