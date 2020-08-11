//create random code for final message
//start code creation script
function randLetter(symbols) {
    if (symbols == "letters") {
      var possible_chars = "abcdefghijklmnoX";
    } else {
      var possible_chars = "123456789"
    }

     var int =  Math.floor((Math.random() * possible_chars.length));
     var rand_letter = possible_chars[int];
     return rand_letter;
}

function getCode(secretCodeIdentifier, n_left, n_right, random, symbols){
  var code="";

  if (random){
    var n_left_pad =  Math.floor((Math.random() * n_left));
    var n_right_pad =  Math.floor((Math.random() * n_right));
  } else {
    var n_left_pad = n_left
    var n_right_pad = n_right
  }

  for (var i = 0; i < n_left_pad; i++){
     code = code.concat(randLetter(symbols));
  }

  code = code.concat(secretCodeIdentifier);

  for (var i = 0; i < n_right_pad; i++){
    code = code.concat(randLetter());
  }

  return code
}

function getTurkParams(){
    // generate a random subject ID (just to be safe)
    var subject_id = Math.floor(Math.random()*1000000);
    subject_id="p"+subject_id.toString();

    var date = new Date();
    var iso_date = date.toISOString();

    var subject_id_isodate = subject_id.concat("_",iso_date);

    //save workerId if it is part of the survey URL ?id=
    var workerId  = getParamFromURL( 'workerId' );

    //otherwise just use the randomly generated subject ID
    if (workerId==="") {
      workerId=subject_id;
    };
    //make sure that nobody can enter anything damaging or crazy for workerId
    workerId.replace(/[^A-Za-z0-9_]/g, "");

    //save qualtricsID if it is part of the survey URL ?qualtricsId=
    var qualtricsId = getParamFromURL( 'qualtricsId' );
    //otherwise just use the randomly generated subject ID
    if (qualtricsId==="") {
      qualtricsId=subject_id;
    };
    //make sure that nobody can enter anything damaging or crazy for qualtricsId
    qualtricsId.replace(/[^A-Za-z0-9_]/g, "");

    //save assignment_id if it is part of the survey URL ?id=
    var assignmentId  = getParamFromURL( 'assignmentId' );

    //otherwise just use the randomly generated id
    if (assignmentId==="") {
      assignmentId="";
    };
    //make sure that nobody can enter anything damaging or crazy for id
    assignmentId.replace(/[^A-Za-z0-9_]/g, "");

    //save assignment_id if it is part of the survey URL ?id=
    var hitId  = getParamFromURL( 'hitId' );

    //otherwise just use the randomly generated id
    if (hitId==="") {
      hitId="";
    };
    //make sure that nobody can enter anything damaging or crazy for id
    hitId.replace(/[^A-Za-z0-9_]/g, "");
}
