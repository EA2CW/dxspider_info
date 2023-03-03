#!/usr/bin/perl

#
# Check if there is a new build.
# Setting 'Y' will backup to /home/sysop/backup
# Download and install.
#
# Only for the Mojo branch
# and in the Spanish and English languages.
#
# Include the following line in the crontab:
# 0 4 * * 1,2,3,4,5 run_cmd("check_build <Y/N>")
#
# Kin EA3CV, ea3cv@cronux.net
#
# 20230303 v1.9
#

use DXDebug;
#use DateTime;
use strict;
use warnings;

my $self = shift;
my $bckup = shift;

return 1 unless $self->{priv} >= 9;

my $res;
my @out;

# Change the working directory to /spider
chdir $main::root;

my $remote_status = `git remote show origin`;
my $has_new_build = $remote_status =~ /mojo/i && $remote_status =~ /mojo   pushes to mojo   \(up to date|mojo   publica a mojo   \(desactualizado local/i;

if ($has_new_build) {
		$res = "There is a new build";
		dbg('DXCron::spawn: $res') if isdbg('cron');
		push @out, $res;
		if ($bckup =~ /Y/i) {
			#my $dt = DateTime->now();
			#my $date = $dt->strftime('%Y%m%d.%H%M%S');
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
			$year += 1900;
			$mon++;
			my $date = sprintf('%04d%02d%02d.%02d%02d%02d', $year, $mon, $mday, $hour, $min, $sec);
			my $backup_dir = "$main::root/../spider.backup";
			unless (-d $backup_dir) {
            mkdir $backup_dir;
			}
		
			my $load = "*$self->{mycall}*   💾  *Backup Starts*";
			is_tg($load);

			system("rsync -zavh --exclude='/local_data/debug /local_data/log /local_data/spots' $main::root/ $backup_dir/$date.backup.z");

			$load = "*$self->{mycall}*   🆗  *Backup Completed*";
			is_tg($load);
		}

		# Reset and update the Git repository
		system('git reset --hard origin/mojo') == 0 or die push @out,"Failed to reset Git repository: $!";
		system('git pull') == 0 or die push @out,"Failed to pull updates from Git repository: $!";
		DXCron::run_cmd('shut');
		} else {
		$res = "There is no new build";
		push @out, $res;
		dbg('DXCron::spawn: $res') if isdbg('cron');
}

sub is_tg
{
    my $msg = shift;

    if (defined &Local::telegram) {
        my $r;
        eval { $r = Local::telegram($msg); };
        return if $r;
    }
}

return (1, @out);
