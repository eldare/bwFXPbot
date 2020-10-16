#!/usr/bin/perl

#######################################################################################
##
##  bwFXPbot is an IRC bot desinged for file sharing 
##  networks to transfer files between FTP servers.
##  bwFXPbot is free software, distributed under GNU GPL license.
##
##  bwFXPbot (C) 2006, Bloodware.
##
##  Version: 0.1
##  Release: August 19, 2006
##
##  WEB:    http://www.Bloodware.net
##  E-MAIL: bloodware@gmail.com
##
## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
##
##  Recomendent to Edit the code in Perl supported
##  Editor with TAB width of 3 spaces configured.
##
## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
##
#######################################################################################

## Include
####################################
use IO::Socket;
use Class::Struct;


## Dynamic Settings
####################################
$IRC_SERVER  = "irc.server.net";
$IRC_PORT    = 6669;
$IRC_CHANNEL = "#my_channel";

$BOT_NAME = "bwFXPbot";
$BOT_PASS = "bot_IRCpassword";

$LOG_USE  = "no";
$LOG_FILE = "/bwFXPbot/log.file";

$FTP_SERVERS = "/bwFXPbot/ftpsrv.lst";
@ACCESS_LIST=("user1", "user2");


####################################
####################################
##   DO NOT EDIT BLOW THIS LINE
##   Unless you REALLY know what
##        you're doing...
####################################
####################################


## Constant Settings
####################################
$BOT_STYLES = "color=4;";
$FTP_CMD = "ftp.cmd";
@CMD_LIST=("about", "spread_local", "spread_fxp");


## Structures
####################################

struct ServerInfo =>
[
	addr => '$',
	port => '$',
	user => '$',
	pass => '$',
	dir  => '$',
	ssl  => '$',
];


## Main Code
####################################
my($sock, $line, $Scmd, $data);

&UploadToListed(0, $FTP_SERVERS, 0, 1);
$sock = &ConnectServer();

while ($line = <$sock>)
{
	$line = lc($line);
	($Scmd, $data) = split(/ \:/, $line);
	&ProcessCommands($sock, $Scmd, $data);
}


#######################################################################################
##
##  Function Name:		ConnectServer
##  Description:        Establish a socket connection to the IRC server,
##                      and join a given IRC channel.
##
##  Received Values:		None.
##  Returned Values:		$sock  -  Active socket connection.
##
#######################################################################################
sub ConnectServer {
    
   my($sock);
	
	$sock = IO::Socket::INET->new(PeerAddr => $IRC_SERVER, PeerPort => $IRC_PORT, Proto => 'tcp') or die;
	
   sleep(2);   # allows the server to load
   print $sock "nick ",$BOT_NAME,"\n";
	print $sock "user ",$BOT_NAME," \* \* \:",$BOT_NAME,"\n";
  
   print $sock "pong \:",$pong_num,"\n";
   print $sock "pong \:",$IRC_SERVER,"\n";
   print $sock "quote pong \:",$pong_num,"\n";
   print $sock "nick ",$BOT_NAME,"\n";
  
   print $sock "NOTICE freenode-connect \:VERSION $BOT_NAME\n"; ## ????
  
   print $sock "privmsg nickserv \:identify ",$BOT_PASS,"\n";
   print $sock "join ",$IRC_CHANNEL,"\n";
	
	return($sock);
}

#######################################################################################
##
##  Function Name:		ProcessCommands
##  Description:        Process incoming commands to the bot.
##
##  Received Values:		$Scmd  -  Input type;
##                      $data  -  Possible bot command.
##  Returned Values:		None.
##
#######################################################################################
sub ProcessCommands
{
	my($sock, $Scmd, $data) = @_;
	my($nick, $source_dir, $dest_dir, $temp);
	
	# Reply to ping
	if ($Scmd =~ /ping/i)
   {
      print $sock "pong \:",$data,"\n";
   }
	
	# Bot Commands
   if ($data =~ /\!/)
   {
      if ($data =~ /\!$CMD_LIST[0]/i)  # Credits
      {
			&SendMsg($sock, "####################################### ", $BOT_STYLES);
         &SendMsg($sock, "##  ", $BOT_STYLES);
			&SendMsg($sock, "##  bwFXPbot v0.1", $BOT_STYLES);
			&SendMsg($sock, "##  Is a Free software distributed", $BOT_STYLES);
			&SendMsg($sock, "##  under GNU GPL license.", $BOT_STYLES);
			&SendMsg($sock, "##  ", $BOT_STYLES);
			&SendMsg($sock, "##  Copyright (C) 2006, Bloodware.", $BOT_STYLES);
			&SendMsg($sock, "##  http://www.Bloodware.net", $BOT_STYLES);
         &SendMsg($sock, "##  ", $BOT_STYLES);
			&SendMsg($sock, "####################################### ", $BOT_STYLES);
      }
      elsif ($nick = &CheckAccess($Scmd))  #Bot commands, need access.
      {
         if ($data =~ /\!$CMD_LIST[1] (.*)/i)  # spread_local Command
         {
				$source_dir = $1;
				chop($source_dir);
				&LogAction($nick, "$CMD_LIST[1] $source_dir");
				&UploadToListed($sock, $FTP_SERVERS, $source_dir, 0, "local");
         }
			elsif ($data =~ /\!$CMD_LIST[2] (.*)/i)  # spread_fxp Command
         {
				$temp = $1;
				&LogAction($nick, "$CMD_LIST[2] $temp");
				&UploadToListed($sock, $FTP_SERVERS, $temp, 0, "fxp");
         }
			elsif ($data =~ /\!$CMD_LIST[2]/i)  # spread_fxp Command without arguments
         {
				&LogAction($nick, "$CMD_LIST[2]");
				&UploadToListed($sock, $FTP_SERVERS, "", 0, "fxp");
         }
      }
   }
}

#######################################################################################
##
##  Function Name:		CheckAccess
##  Description:        Make sure the user who sent the command has access.
##
##  Received Values:		$Scmd    -  Contains user's information.
##  Returned Values:		0/$nick  -  0: for false, or $nick for success.
##
#######################################################################################
sub CheckAccess
{
   my($Scmd) = @_;
   my($i, $nick, $real, $host, $Schan);
	
   ($nick, $real, $host, $Schan) = &GetNickHost($Scmd);   # will be used for the log
   for ($i=0; $i<@ACCESS_LIST; $i++) {
      if ($nick eq $ACCESS_LIST[$i]) {
         return($nick);
      }
   }
   return(0);
}

#######################################################################################
##
##  Function Name:		GetNickHost
##  Description:        Gets user's information.
##
##  Received Values:		$Scmd   -  Contains user's information.
##  Returned Values:		$nick   -  User's nickname.
##                      $real   -  User's real name.
##                      $host   -  User's ISP.
##                      $Schan  -  
##
#######################################################################################
sub GetNickHost
{
   my($Scmd) = @_;
	
   $Scmd =~ /\:(.*)\!(.*)\@(.*) privmsg (.*)/;
   $nick = $1;
   $real = $2;
   $host = $3;
   $Schan = $4;
	
	return($nick, $real, $host, $Schan);
}

#######################################################################################
##
##  Function Name:		SengMsg
##  Description:        Sends a message to the IRC server on a specified channel.
##
##  Received Values:		$sock    -  Active socket connection.
##                      $msg     -  Message to send.
##                      $styles  -  Text decoration and styles.
##  Returned Values:		None.
##
#######################################################################################
sub SendMsg
{
   my($sock, $msg, $styles) = @_;
	my($irc_styles);
	
	if ($styles =~ /bold;/) {
		$irc_styles = $irc_styles."";
	}
	if ($styles =~ /color=(.*);/) {
		$irc_styles = $irc_styles."$1";
	}
	
   print $sock "privmsg $IRC_CHANNEL \:$irc_styles$msg\n";
}

#######################################################################################
##
##  Function Name:		LogAction
##  Description:        If activated will log access command sent to bot
##
##  Received Values:		$nick     -  Nickname.
##                      $command  -  Used command.
##  Returned Values:		None.
##
#######################################################################################
sub LogAction
{
   my($nick, $command) = @_;
	my(@month_list) = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");

	if ($LOG_USE eq "yes")
	{
		@mytime = localtime(time);
      open(LOG, ">>".$LOG_FILE);
		$mytime[5] += 1900;
      print LOG "$mytime[4] $month_list[$mytime[3]], $mytime[5]\:  ";
		print LOG "$nick - !$command\n";
      close(LOG);
	}
}

#######################################################################################
##
##  Function Name:		UploadToListed
##  Description:        Uploads files from a specified dir using the lftp program.
##
##  Received Values:		$ftpd_file    -  The file listing FTP servers.
##                      $local_dir    -  Local directory.
##                      $create_file  -  0: read existing file. 1: create new file.
##                      $copy_type    -  "local" / "fxp"
##
##  Returned Values:		None.
##
#######################################################################################
sub UploadToListed
{
	my($sock, $ftpd_file, $source_dir, $create_file, $copy_type) = @_;
	my($line, $first_fxp, $source_info, $dest_info, $ssl_mode, $temp_ddir, $temp_sdir);

	if ($source_dir ne "")
	{
		if ($source_dir =~ /source\:(.*) dest\:(.*)/i) 
		{
			$temp_sdir = $1;
			$temp_ddir = $2;
			#chop($temp_ddir);
		}
		else 
		{
			$temp_sdir = "";
			$temp_ddir = "";
		}
	}
	else
	{
		$temp_sdir = "";
		$temp_ddir = "";
	}
	
	if ($create_file==0)
	{
		$first_fxp = 0;
		open(FTPD_FILE, $ftpd_file);
		while ($line = <FTPD_FILE>)
		{
			if ((!($line =~ /\#/))&&($line =~ /[a-zA-Z]/))
			{
			   ## [FTPd address] [FTPd port] [Username] [Password] [Remote Dir] [SSL_Mode]
				$line =~ /(.*) (.*) (.*) (.*) (.*) (.*)/;
				
				$ssl_mode = $6;
				if ($ssl_mode =~ /\n/) {
					chop($ssl_mode);
				}
				
				if (($copy_type eq "fxp")&&($first_fxp==0))
				{
					$first_fxp = 1;
					## save all the values of the first server => FXP source server
					if ($temp_sdir eq "") {
						$temp_sdir = $5;
					}
					$source_info = ServerInfo->new(addr => $1, port => $2, user => $3, pass => $4, dir => $temp_sdir, ssl => $ssl_mode);
				}
				else ## continue with copy
				{
					if ($temp_ddir eq "") {
						$temp_ddir = $5;
					}
					$dest_info = ServerInfo->new(addr => $1, port => $2, user => $3, pass => $4, dir => $temp_ddir, ssl => $ssl_mode);
					&SendMsg($sock, ">> Upload Started To:  ".$dest_info->addr, $BOT_STYLES);
					
					if ($copy_type eq "local") {
						if ($temp_sdir eq "") {
							$temp_sdir = $source_dir;
						}
						&UploadLocalDir($temp_sdir, $dest_info);
					}
					elsif ($copy_type eq "fxp") {
						&UploadFxpDir($source_info, $dest_info);
					}
					
					&SendMsg($sock, ">> Upload Completed To:  ".$dest_info->addr, $BOT_STYLES);
				}
			}
		}
		close(FTPD_FILE);
		unlink($FTP_CMD);
		&SendMsg($sock, "(!) All Transfers Completed.", $BOT_STYLES);
	}
	elsif ($create_file==1)
	{
		if (open(FTPD_FILE, $ftpd_file)==0)
		{
			open(FTPD_FILE, ">".$ftpd_file);
			print FTPD_FILE "##############################################################################\n";
			print FTPD_FILE "#   \n";
			print FTPD_FILE "#   List of remote FTPd accounts\n";
			print FTPD_FILE "#   \n";
			print FTPD_FILE "#   File format as followed:\n";
			print FTPD_FILE "#   [FTPd address] [FTPd port] [Username] [Password] [Remote Dir] [SSL_Mode]\n";
			print FTPD_FILE "#   \n";
			print FTPD_FILE "#   Example:\n";
			print FTPD_FILE "#   192.168.1.1 1337 my_user my_passs /some_dir/files ON\n";
			print FTPD_FILE "#   ftp.domain.com 21 user1 pass1 /my_dir/files OFF\n";
			print FTPD_FILE "#   \n";
			print FTPD_FILE "#   bwFXPbot (C) 2006, http://www.Bloodware.net\n";
			print FTPD_FILE "#   \n";
			print FTPD_FILE "#   \n\n";
			close(FTPD_FILE);
		}
	}
}

#######################################################################################
##
##  Function Name:		UploadLocalDir
##  Description:        Uploads files from a specified dir using the lftp program.
##
##  Received Values:		$source_dir   -  Source directory
##                      $dest_info    -  Destination server structure.
##  Returned Values:		None.
##
#######################################################################################
sub UploadLocalDir
{
	my($source_dir, $dest_info) = @_;
	my($temp);
	
	open(FTP_CMD, ">".$FTP_CMD); ## add ssl check for dest
	$temp = lc($dest_info->ssl);
	if ($dest_info->ssl eq "on") {
		print FTP_CMD "set ftp\:ssl-force true\r\n";
	}
	
	print FTP_CMD "open -p ".$dest_info->port." ".$dest_info->addr."\r\n";
	print FTP_CMD "user ".$dest_info->user." ".$dest_info->pass."\r\n";
	print FTP_CMD "lcd ".$source_dir."\r\n";
	print FTP_CMD "cd ".$dest_info->dir."\r\n";
	print FTP_CMD "mput *.*\r\n";
	close(FTP_CMD);
	
	system("lftp -f $FTP_CMD");
}

#######################################################################################
##
##  Function Name:		UploadFxpDir
##  Description:        Uploads files from a remote FTP server to another server (FXP).
##
##  Received Values:		$source_info  -  Source server structure.
##                      $dest_info    -  Destination server structure.
##  Returned Values:		None.
##
#######################################################################################
sub UploadFxpDir
{
	my($source_info, $dest_info, $use_ssl) = @_;
	my($temp1, $temp2);

	open(FTP_CMD, ">".$FTP_CMD);
	$temp1 = lc($source_info->ssl);
	$temp2 = lc($dest_info->ssl);
	if (($temp1 eq "on")||($temp2 eq "on")) {
		print FTP_CMD "set ftp\:ssl-force true\r\n";
	}
	
	print FTP_CMD "set ftp:use-fxp true\r\n";
	print FTP_CMD "open -p ".$source_info->port." ".$source_info->addr."\r\n";
	print FTP_CMD "user ".$source_info->user." ".$source_info->pass."\r\n";
	print FTP_CMD "mirror ".$source_info->dir." ftp\://".$dest_info->user."\:".$dest_info->pass."\@".$dest_info->addr."\:".$dest_info->port."/".$dest_info->dir."\r\n";
	close(FTP_CMD);
	
	system("lftp -f $FTP_CMD");
}