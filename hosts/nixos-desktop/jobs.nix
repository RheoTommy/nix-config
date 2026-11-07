# The commands this host runs on a schedule.
{ config, ... }:

{
  scheduledJobs.inbox-calendar-sync = {
    user = "rheotommy";
    command = "/home/rheotommy/.local/share/inbox-jobs/jobs/run inbox-calendar-sync";
    onCalendar = "hourly";
    maxHoursWithoutSuccess = 3;
    credentials = {
      calendar-id = config.opSecrets.files.calendar-id.path;
      calendar-service-account = config.opSecrets.files.calendar-service-account.path;
    };
  };
}
