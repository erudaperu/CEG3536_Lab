import os,termios,time,select,json
from pathlib import Path
p=Path('output/lab3/CEG3536_Lab3_Arikan_Zuze/preuves/materiel');control=Path('/tmp/lab3_serial_actions.txt');control.write_text('')
fd=os.open('/dev/ttyACM0',os.O_RDWR|os.O_NOCTTY|os.O_NONBLOCK);a=termios.tcgetattr(fd);a[0]=a[1]=a[3]=0;a[2]=termios.CS8|termios.CREAD|termios.CLOCAL;a[4]=a[5]=termios.B115200;a[6][termios.VMIN]=a[6][termios.VTIME]=0;termios.tcsetattr(fd,termios.TCSANOW,a);termios.tcflush(fd,termios.TCIFLUSH)
start=time.monotonic();done=0
with (p/'essais_physiques.csv').open('wb',buffering=0) as f,(p/'essais_physiques.timestamps.jsonl').open('w',buffering=1) as t:
 while time.monotonic()-start<1800:
  lines=control.read_text().splitlines()
  for l in lines[done:]:
   if l=='STOP':os.close(fd);raise SystemExit
   if l.startswith('SEND '):os.write(fd,l[5:].encode())
   t.write(json.dumps({'elapsed':time.monotonic()-start,'action':l})+'\n')
  done=len(lines)
  if select.select([fd],[],[],.1)[0]:
   b=os.read(fd,8192)
   if b:f.write(b);t.write(json.dumps({'elapsed':time.monotonic()-start,'ascii':b.decode('ascii','replace')})+'\n')
os.close(fd)
