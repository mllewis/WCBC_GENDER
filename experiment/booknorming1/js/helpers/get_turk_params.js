// this code is adopted from martin

//general function for grabbing parameter from a URL
  function getParamFromURL( name ) {
    name = name.replace(/[\[]/,"\\[").replace(/[\]]/,"\\]");
    var regexS = "[\?&]"+name+"=([^&#]*)";
    var regex = new RegExp( regexS );
    var results = regex.exec( window.location.href );
    if( results == null )
      return "";
    else
      return results[1];
  }

  function getWorkerId(){
    // generate a random subject ID (just to be safe)
    var subject_id = Math.floor(Math.random()*1000000);
    subject_id="p"+subject_id.toString();

    var subject_id_isodate = subject_id.concat("_",iso_date);

    //save workerId if it is part of the survey URL ?id=
    var workerId  = getParamFromURL( 'workerId' );

    //otherwise just use the randomly generated subject ID
    if (workerId==="") {
      workerId=subject_id;
    };
    //make sure that nobody can enter anything damaging or crazy for workerId
    workerId.replace(/[^A-Za-z0-9_]/g, "");

    return(workerId)
}

  function getQualtricsId(){

    //save qualtricsID if it is part of the survey URL ?qualtricsId=
    var qualtricsId = getParamFromURL( 'qualtricsId' );
    //otherwise just use the randomly generated subject ID
    if (qualtricsId==="") {
      qualtricsId="NA";
    };
    //make sure that nobody can enter anything damaging or crazy for qualtricsId
    qualtricsId.replace(/[^A-Za-z0-9_]/g, "")

    return(qualtricsId)

}

function getAssignmentId(){
    //save assignment_id if it is part of the survey URL ?id=
    var assignmentId  = getParamFromURL( 'assignmentId' );

    //otherwise just use the randomly generated id
    if (assignmentId==="") {
      assignmentId="";
    };
    //make sure that nobody can enter anything damaging or crazy for id
    assignmentId.replace(/[^A-Za-z0-9_]/g, "");

    return(assignmentId)
}

function getHitId(){
    //save assignment_id if it is part of the survey URL ?id=
    var hitId  = getParamFromURL( 'hitId' );

    //otherwise just use the randomly generated id
    if (hitId==="") {
      hitId="";
    };
    //make sure that nobody can enter anything damaging or crazy for id
    hitId.replace(/[^A-Za-z0-9_]/g, "");

    return(hitId)
}

function getDate(){
    var date = new Date();
    var iso_date = date.toISOString();
    
    return(date)
}

