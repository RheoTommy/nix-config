# The commands this host runs on a schedule.
{ config, lib, ... }:

{
  scheduledJobs =
    lib.mapAttrs
      (
        name: job:
        job
        // {
          user = "rheotommy";
          command = "/home/rheotommy/.local/share/inbox-jobs/jobs/run ${name}";
        }
      )
      {
        inbox-calendar-sync = {
          onCalendar = "hourly";
          maxHoursWithoutSuccess = 3;
          credentials = {
            calendar-id = config.opSecrets.files.calendar-id.path;
            calendar-service-account = config.opSecrets.files.calendar-service-account.path;
          };
        };
        # A failed run alerts at once. These catch the timer stopping: the
        # longest gap between runs, plus a day.
        inbox-watch = {
          onCalendar = "Mon,Thu 07:00";
          maxHoursWithoutSuccess = 120;
        };
        inbox-watchdog = {
          onCalendar = "Mon,Thu 07:00";
          maxHoursWithoutSuccess = 120;
        };
      };
}
