self.addEventListener("push", event => {
  var title = (event.data && event.data.text().split("-")[0]) || "Message recieved";
  var body; body = event.data.text().split("-")[1];
  var tag = "push-simple-demo-notification-tag";
  var icon = 'logo.png';

  event.waitUntil(
      self.registration.showNotification(title, {
          body: body,
          icon: icon,
          tag: tag
      })
  );
});
