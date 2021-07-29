function isFirefox()
{
  return (typeof InstallTrigger !== 'undefined');
}

function backHack()
{
  if (isFirefox())
  {
    window.location.href += "#";
    setTimeout("changeHashAgain()", 50);
  }
}

function changeHashAgain()
{
  window.location.href += "1";
}

if (isFirefox())
{
	storedHash = window.location.hash;

  window.setInterval(function ()
  {
    if (window.location.hash != storedHash)
    {
      window.location.hash = storedHash;
    }
  }, 50);
}
