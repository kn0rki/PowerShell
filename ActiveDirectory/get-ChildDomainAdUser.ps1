#get all users from entire active directory. Includes childdomains
#gets all childdomains
$childdomains = (get-addomain).childdomains

#equests user informantion givenname, surname, telephonenumber, emailaddress, country and canonicalname from each childdomain-
$childdomains | %{echo "Starting for Domain $_"; get-aduser -server $_ -filter * -properties * | select-object Givenname, Surname, telephonenumber, emailaddress, country, canonicalname}