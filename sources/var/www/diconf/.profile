# ~/.profile: executed by Bourne-compatible login shells.
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n

if [ -f /root/install_se4ad_phase2.sh ]; then
    /root/install_se4ad_phase2.sh  
fi

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

