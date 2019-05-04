# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# include .bashrc.common.sh if it exists
if [ -f "$HOME/.bashrc.common.sh" ]; then
. "$HOME/.bashrc.common.sh"
fi