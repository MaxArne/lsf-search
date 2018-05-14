#!/bin/bash
# ------- Enter Database connection details here -------
# mein erster Eintrag

databaseUser=""
databasePassword=""
databaseName=""
databaseServer=""

#---------------------------------------

execSQL="mysql -u $databaseUser -p$databasePassword -h $databaseServer $databaseName"

function crawlEvents() {

  baseURL="https://lsf.htw-berlin.de/qisserver/rds?state=wsearchv&search=2&veranstaltung.veranstid="
  start=134000
  stop=135000

  output=$(pwd)/events_tmp.txt

  for (( i = $start; i <=$stop; i++ )); do
    EventID=$i
    URL="$baseURL$EventID"

    curl -s $URL > $output

    LecturerID=$(cat $output | grep -Po '(?<=personal\.pid=)([0-9]+)' | head -1)
    RoomID=$(cat $output | grep -Po '(?<=raum\.rgid=)([0-9]+)' | head -1 )
    EventName=$(cat $output | grep -Po '(?<=<strong>)([\w\s\(\)äÄöÖüÜß_\-]+)')

    if [[ (-n "$EventName") && (-n "$EventID") && (-n "$LecturerID") && (-n "$RoomID") ]]; then
      echo "Insert Event $EventID into Database"
      echo "Veranstaltung: $EventName"
      echo "Dozenten ID: $LecturerID"
      echo "Raum ID: $RoomID"
      echo
      $execSQL --execute="
        INSERT into Events (EventID, LecturerID, RoomID, EventName)
        VALUES ('$EventID', '$LecturerID', '$RoomID', '$EventName');
      "
    else
      echo "--------ERROR: Event $EventID could not be inserted because of missing values!"
    fi
  done

  rm -f $output
}

function crawlRooms() {
  baseURL="https://lsf.htw-berlin.de/qisserver/rds?state=wsearchv&search=3&raum.rgid="
  start=5000
  stop=10000

  output=$(pwd)/rooms_tmp.txt

  for (( i = $start; i <=$stop; i++ )); do
    RoomID=$i
    URL="$baseURL$RoomID"

    curl  -s $URL > $output

    line=$(cat $output | nl | grep -P 'Raum-Nr\.' | grep -oP '^\s*[0-9]+')
    line=$(( $line + 1 ))
    RoomNumber=$(cat $output | nl | grep -E "$line" | grep -oP '>[0-9]+<' | grep -oP '[0-9]+')

    BuildingID=$(cat $output | grep -Po '(?<=gebaeude\.gebid=)([0-9]+)' | head -1 )

    if [[ (-n "$RoomID") && (-n "$RoomNumber") && (-n "$BuildingID") ]]; then
      echo "--------------------"
      echo "Insert Room $RoomID into Database"
      echo "Raum Nr: $RoomNumber"
      echo "Gebäude ID: $BuildingID"
      echo
      $execSQL --execute="
        INSERT into Rooms (RoomID, RoomNumber, BuildingID)
        VALUES ('$RoomID', '$RoomNumber', '$BuildingID');
      "
    else
      echo "--------ERROR: Room $RoomID could not be inserted because of missing values!"
    fi

  done

  rm -f $output
}

function crawlBuildings() {
  baseURL="https://lsf.htw-berlin.de/qisserver/rds?state=verpublish&status=init&vmfile=no&moduleCall=webInfo&publishConfFile=webInfoGeb&publishSubDir=gebaeude&keep=y&k_gebaeude.gebid="
  start=4000
  stop=10000

  output=$(pwd)/buildings_tmp.txt



  for (( i = $start; i <=$stop; i++ )); do
    BuildingID=$i
    URL="$baseURL$BuildingID"

    curl -s  $URL > $output

    BuildingName=$(cat $output | grep -P '<\/strong>' | tail -1 | grep -oP '(?<=\;)([\w\s\(\)äÄöÖüÜß_-]+)(?=\&)')
    BuildingNameLong=$(cat $output | grep -P '<\/strong>' | head -2 |tail -1 | grep -oP '(?<=\;)([\w\s\(\)äÄöÖüÜß_-]+)(?=\&)')
    BuildingNameShort=$(cat $output | grep -P '<\/strong>' | head -1 | grep -oP '(?<=\;)([\w\s\(\)äÄöÖüÜß_-]+)(?=\&)')

    if [[ (-n "$BuildingID") && (-n "$BuildingName") && (-n "$BuildingNameLong") && (-n "$BuildingNameShort") ]]; then
      echo "Insert Buidling $BuildingID into Database"
      echo "Gebäude Name: $BuildingName"
      echo "Gebäude Name kurz: $BuildingNameShort"
      echo "Gebäude Name lang: $BuildingNameLong"
      echo
      $execSQL --execute="
        INSERT into Buildings (BuildingID, BuildingName, BuildingNameShort, BuildingNameLong)
        VALUES ('$BuildingID', '$BuildingName', '$BuildingNameShort', '$BuildingNameLong');
      "
    else
      echo "--------ERROR: Building $BuildingID could not be inserted because of missing values!"
    fi

  done

  rm -f $output
}

function crawlLecturers() {


  baseURL="https://lsf.htw-berlin.de/qisserver/rds?state=verpublish&status=init&vmfile=no&moduleCall=webInfo&publishConfFile=webInfoPerson&publishSubDir=personal&keep=y&purge=y&personal.pid="
  start=0
  stop=20000

  output=$(pwd)/lecturers_tmp.txt

  for (( i = $start; i <=$stop; i++ )); do
    LecturerID=$i
    URL="$baseURL$LecturerID"

    curl -s $URL > $output

    line=$(cat $output | nl | grep -P '<strong>' | grep -oP '^\s*[0-9]+')
    line=$(( $line + 1 ))
    FormalTitle=$(cat $output | nl | grep -P $line | grep -oP '[\w]+$')
    line=$(( $line + 1 ))
    string=$(cat $output | nl | grep -P $line | grep -oP '([\w\s\(\)äÄöÖüÜß\_\-\,\.]+)(?=<\/strong>)' | sed 's/^\s*[0-9]\+\s\+//g' )

    echo $string
    FirstName=$(echo $string | grep -oP '([\wäÄöÖüÜß\-]+)$')
    LastName=$(echo $string | grep -oP '([\wäÄöÖüÜß\-]+)(?=\,)')
    # regex="([\wäÄöÖüÜß\-\.\s]+)(?=$FirstName\,\s$FirstName)"
    regex="^(Dr\.|Prof\.|Prof\. Dr\.|Dr\.\-Ing\.|Prof\. Dr\.\-Ing\.|Prof\. Dr\. phil\. habil\.|Dipl.\-Kfm\.|Prof. Dr\. jur\. LL\.M\.|Prof\. Dr\.\-Ing\. habil\.|Prof\. Prof\. h\.c\. Dr\. rer\. nat\.|Dipl\.\-Prähist\.)(?=\s$LastName\,\s$FirstName)"
    AcademicTitle=$(echo $string | grep -oP "$regex" | head -1)

    if [[ (-n "$FirstName") && (-z "$AcademicTitle" ) ]]; then
      AcademicTitle="NONE"
    fi

    if [[ (-n "$FirstName") && (-n "$LastName") && (-n "$AcademicTitle") && (-n "$FormalTitle") ]]; then

      if [[ "$AcademicTitle" == "Prof." ]]; then
        AcademicTitle="Prof. Dr."
      fi
      echo "Insert Lecturer $LecturerID into Database"
      echo "Vorname: $FirstName"
      echo "Nachmame: $LastName"
      echo "Akademischer Grad: $AcademicTitle"
      echo "Formale Ansprache: $FormalTitle"
      echo
      $execSQL --execute="
        INSERT into Lecturers (LecturerID, FirstName, LastName, AcademicTitle, FormalTitle)
        VALUES ('$LecturerID', '$FirstName', '$LastName', '$AcademicTitle', '$FormalTitle');
      "
    else
      echo "--------ERROR: Lecturer $LecturerID could not be inserted because of missing values!"
    fi



    # if [[ (-n "$EventName") && (-n "$EventID") && (-n "$LecturerID") && (-n "$RoomID") ]]; then
    #   echo "Insert Event $EventID into Database"
    #   $execSQL --execute="
    #     INSERT into Events (EventID, LecturerID, RoomID, EventName)
    #     VALUES ('$EventID', '$LecturerID', '$RoomID', '$EventName');
    #   "
    # else
    #   echo "--------ERROR: Event $EventID could not be inserted because of missing values!"
    # fi
  done

  # rm -f $output


}

$1
