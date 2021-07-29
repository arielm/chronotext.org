function mailer(user, domain, msg)
{
  document.write("<a href='mailto:" + user + "@" + domain + "'>" + (msg != null ? msg : (user + "@" + domain)) + "</a>");
}

function popup(href, width, height, scroll)
{
  window.open(href, "", "width=" + width + ",height=" + height + ",scrollbars=" + (scroll ? "1" : "0") + ",resizable=0,status=0,menubar=0,location=0,toolbar=0");
}

function launch(url)
{
  location = url;
}
