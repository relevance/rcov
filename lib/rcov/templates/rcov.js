function toggleCode( id ) {
  if ( document.getElementById )
  elem = document.getElementById( id );
  else if ( document.all )
  elem = eval( "document.all." + id );
  else
  return false;

  elemStyle = elem.style;

  if ( elemStyle.display != "block" ) {
    elemStyle.display = "block"
  } else {
    elemStyle.display = "none"
  }

  return true;
}

// Make cross-references hidden by default
document.writeln( "<style type=\"text/css\">span.cross-ref { display: none }</style>" )