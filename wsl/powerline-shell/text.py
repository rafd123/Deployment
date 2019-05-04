from ..utils import BasicSegment
import os
import getpass

class Segment(BasicSegment):
    def add_to_powerline(self):
        powerline = self.powerline
        content_file_path = os.path.join(os.path.expanduser('~'), '.powerline-shell.txt')
        if os.path.isfile(content_file_path):
            with open(content_file_path) as f:
                text = " " + f.readline().rstrip() + " "
        else:
            return
        
        bgcolor = powerline.theme.HOSTNAME_BG
        powerline.append(text, powerline.theme.HOSTNAME_FG, bgcolor)
