package Tk::DragDrop::XDNDSite;
use strict;
use vars qw($VERSION);
$VERSION = '3.010'; # $Id: //depot/Tk8/DragDrop/DragDrop/XDNDSite.pm#10 $
use base qw(Tk::DropSite);

sub XDND_PROTOCOL_VERSION () { 3 }

Tk::DropSite->Type('XDND');

sub InitSite
{my ($class,$site) = @_;
 my $w = $site->widget;
}

sub XdndEnter
{
 my ($t,$sites) = @_;
 my $event = $t->XEvent;
 my ($src,$flags,@types) = unpack('LLLLL',$event->A);
 # print "XdndEnter $src\n";
 my $ver = ($flags >> 24) & 0xFF;        
 if ($flags & 1)
  {
   my @prop;
   Tk::catch { @prop = $t->property('get','XdndTypeList',$src) };
   @types = @prop if (!$@ && shift(@prop) eq 'ATOM');
  }
 $t->{"XDND$src"} = { ver => $ver, types => \@types };
}

sub XdndLeave
{
 my ($t,$sites) = @_;
 my $event = $t->XEvent;
 my ($src,$flags,@types) = unpack('LLLLL',$event->A);
 # print "XdndLeave $src\n";
 my $info = $t->{"XDND$src"};
 if ($info)
  {
   my $over = $info->{site};
   if ($over)
    {   
     my $X = $info->{X};
     my $Y = $info->{Y};
     $over->Apply(-entercommand => $X, $Y, 0) 
    }
  }
 delete $t->{"XDND$src"};
}

sub XdndPosition
{
 my ($t,$sites) = @_;
 my $event = $t->XEvent;
 my ($src,$flags,$xy,$time,$action) = unpack('LLLLL',$event->A);
 my $X = $xy >> 16;
 my $Y = $xy & 0xFFFF;
 my $info = $t->{"XDND$src"};
 $info->{X}      = $X;
 $info->{Y}      = $Y;
 $info->{action} = $action;
 $info->{t}      = $time;
 my $id    = oct($t->id);
 my $sxy   = 0; 
 my $swh   = 0; 
 my $sflags = 0;
 my $saction = 0;
 my $over = $info->{site};
 foreach my $site (@$sites)
  {
   if ($site->Over($X,$Y))
    {
     $sxy = ($site->X << 16)     | $site->Y;    
     $swh = ($site->width << 16) | $site->height;
     $saction = $action;                        
     $sflags |= 1;                              
     if ($over)                                 
      {                                         
       if ($over == $site)                      
        {                                       
         $site->Apply(-motioncommand => $X, $Y);
        }                                       
       else                                     
        {                                       
         $over->Apply(-entercommand => $X, $Y, 0);
         $site->Apply(-entercommand => $X, $Y, 1);
        }                                       
      }                                         
     else                                       
      {                                         
       $site->Apply(-entercommand => $X, $Y, 1);
      }     
     $info->{site} = $site;                     
     last;
    }
  }
 unless ($sflags & 1)
  {
   if ($over)
    {
     $over->Apply(-entercommand => $X, $Y, 0) 
    }
   delete $info->{site};
  }
 my $data = pack('LLLLL',$id,$sflags,$sxy,$swh,$action);
 $t->SendClientMessage('XdndStatus',$src,32,$data);
}

sub XdndDrop
{
 my ($t,$sites) = @_;
 my $event = $t->XEvent;
 my ($src,$flags,$time,$res1,$res2) = unpack('LLLLL',$event->A);
 my $info   = $t->{"XDND$src"};        
 my $sflags = 0;
 if ($info)
  {         
   $info->{t} = $time;
   my $site = $info->{'site'};
   if ($site)
    {
     my $X = $info->{'X'};                  
     my $Y = $info->{'Y'};                  
     $site->Apply(-dropcommand => $Y, $Y, 'XdndSelection');
     $site->Apply(-entercommand => $X, $Y, 0);
    }
  }
 my $data  = pack('LLLLL',oct($t->id),$sflags,0,0,0);
 $t->SendClientMessage('XdndFinished',$src,32,$data);
}

sub NoteSites
{my ($class,$t,$sites) = @_;
 if (@$sites)
  {
   $t->BindClientMessage('XdndLeave',[\&XdndLeave,$sites]);
   $t->BindClientMessage('XdndEnter',[\&XdndEnter,$sites]);
   $t->BindClientMessage('XdndPosition',[\&XdndPosition,$sites]);
   $t->BindClientMessage('XdndDrop',[\&XdndDrop,$sites]);
   $t->property('set','XdndAware','ATOM',32,[XDND_PROTOCOL_VERSION]);
  }
 else
  {
   $t->property('delete','XdndAware');
  }
}

1;
__END__
