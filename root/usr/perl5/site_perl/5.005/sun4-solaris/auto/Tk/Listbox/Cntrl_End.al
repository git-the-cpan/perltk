# NOTE: Derived from ../blib/lib/Tk/Listbox.pm.
# Changes made here will be lost when autosplit again.
# See AutoSplit.pm.
package Tk::Listbox;

#line 153 "../blib/lib/Tk/Listbox.pm (autosplit into ../blib/lib/auto/Tk/Listbox/Cntrl_End.al)"
sub Cntrl_End
{
 my $w = shift;
 my $Ev = $w->XEvent;
 $w->activate('end');
 $w->see('end');
 $w->selectionClear(0,'end');
 $w->selectionSet('end')
}

# end of Tk::Listbox::Cntrl_End
1;
